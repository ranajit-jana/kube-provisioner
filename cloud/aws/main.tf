
locals {
  region = "ap-south-1"

  tags = {
    GithubRepo = "kube-provisioner"
    GithubOrg  = "ranajit-jana"
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version


  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids

  cluster_endpoint_public_access       = var.cluster_endpoint_public_access
  cluster_endpoint_private_access      = var.cluster_endpoint_private_access
  cluster_endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs
  create_kms_key                       = var.create_kms_key
  kms_key_enable_default_policy        = var.kms_key_enable_default_policy

  create_cni_ipv6_iam_policy = false

  # Extend cluster security group rules
  cluster_security_group_additional_rules = {
    egress_nodes_ephemeral_ports_tcp = {
      description                = "To node 1025-65535"
      protocol                   = "tcp"
      from_port                  = 1025
      to_port                    = 65535
      type                       = "egress"
      source_node_security_group = true
    }
  }

  # Extend node-to-node security group rules
  node_security_group_additional_rules = {
    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }
    egress_all = {
      description      = "Node all egress"
      protocol         = "-1"
      from_port        = 0
      to_port          = 0
      type             = "egress"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
    ingress_cluster_all = {
      description                = "Acess from control plane"
      protocol                   = "-1"
      from_port                  = 0
      to_port                    = 0
      type                       = "ingress"
      source_node_security_group = true
    }
  }

  #managed from outside
  manage_aws_auth_configmap = false




  tags = {
    Environment = "deployment"
    Terraform   = "true"
  }

  cluster_addons = {
    coredns = {
      most_recent       = true
      resolve_conflicts = "OVERWRITE"
    }
    kube-proxy = {
      most_recent       = true
      resolve_conflicts = "OVERWRITE"
    }
    vpc-cni = {
      most_recent       = true
      resolve_conflicts = "OVERWRITE"
    }
    aws-ebs-csi-driver = {
      service_account_role_arn = module.ebs_csi_irsa_role.iam_role_arn
    }
  }

  # OIDC Identity provider
  cluster_identity_providers = {
    sts = {
      client_id = "sts.amazonaws.com"
    }
  }

}


resource "kubernetes_config_map" "aws_auth" {

  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    "mapAccounts" = yamlencode([])
    "mapRoles" = yamlencode([
      {
        rolearn  = module.eks_managed_node_group.iam_role_arn
        username = "system:node:{{EC2PrivateDNSName}}"
        groups = [
          "system:bootstrappers",
          "system:nodes",
        ]
      },
      {
        rolearn  = "arn:aws:iam::890504605381:role/terraformuser"
        username = "terraformrunner"
        groups   = ["system:masters"]
      }

    ])
    "mapUsers" = yamlencode([])
  }

  lifecycle {
    # We are ignoring the data here since we will manage it with the resource below
    # This is only intended to be used in scenarios where the configmap does not exist
    ignore_changes = [data, metadata[0].labels, metadata[0].annotations]
  }

  depends_on = [
    module.eks, module.eks_managed_node_group
  ]
}


module "ebs_csi_irsa_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name = "${var.cluster_name}-AmazonEKS_EBS_CSI_DriverRole"

  attach_ebs_csi_policy = true
  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }

}

module "eks_managed_node_group" {
  source = "terraform-aws-modules/eks/aws//modules/eks-managed-node-group"
  # Default node group - as provided by AWS EKS
  name            = "eks-managed-ng"
  cluster_name    = module.eks.cluster_name
  cluster_version = module.eks.cluster_version
  default_node_group = {
    # By default, the module creates a launch template to ensure tags are propagated to instances, etc.,
    # so we need to disable it to use the default template provided by the AWS EKS managed node group service
    use_custom_launch_template = false

    disk_size = 50

    # Remote access cannot be specified with a launch template
    remote_access = {
      ec2_ssh_key               = module.key_pair.key_pair_name
      source_security_group_ids = [aws_security_group.remote_access.id]
    }
  }

  # Default node group - as provided by AWS EKS using Bottlerocket
  bottlerocket_default = {
    # By default, the module creates a launch template to ensure tags are propagated to instances, etc.,
    # so we need to disable it to use the default template provided by the AWS EKS managed node group service
    use_custom_launch_template = false

    ami_type = "BOTTLEROCKET_x86_64"
    platform = "bottlerocket"
  }

  # Adds to the AWS provided user data
  bottlerocket_add = {
    ami_type = "BOTTLEROCKET_x86_64"
    platform = "bottlerocket"

    # This will get added to what AWS provides
    bootstrap_extra_args = <<-EOT
        # extra args added
        [settings.kernel]
        lockdown = "integrity"
      EOT
  }

  # Custom AMI, using module provided bootstrap data
  bottlerocket_custom = {
    # Current bottlerocket AMI
    ami_id   = data.aws_ami.eks_default_bottlerocket.image_id
    platform = "bottlerocket"

    # Use module user data template to bootstrap
    enable_bootstrap_user_data = true
    # This will get added to the template
    bootstrap_extra_args = <<-EOT
        # The admin host container provides SSH access and runs with "superpowers".
        # It is disabled by default, but can be disabled explicitly.
        [settings.host-containers.admin]
        enabled = false
        # The control host container provides out-of-band access via SSM.
        # It is enabled by default, and can be disabled if you do not expect to use SSM.
        # This could leave you with no way to access the API and change settings on an existing node!
        [settings.host-containers.control]
        enabled = true
        # extra args added
        [settings.kernel]
        lockdown = "integrity"
        [settings.kubernetes.node-labels]
        label1 = "foo"
        label2 = "bar"
        [settings.kubernetes.node-taints]
        dedicated = "experimental:PreferNoSchedule"
        special = "true:NoSchedule"
      EOT
  }

  # Use a custom AMI
  custom_ami = {
    ami_type = "AL2_ARM_64"
    # Current default AMI used by managed node groups - pseudo "custom"
    ami_id = data.aws_ami.eks_default_arm.image_id

    # This will ensure the bootstrap user data is used to join the node
    # By default, EKS managed node groups will not append bootstrap script;
    # this adds it back in using the default template provided by the module
    # Note: this assumes the AMI provided is an EKS optimized AMI derivative
    enable_bootstrap_user_data = true

    instance_types = ["t4g.medium"]
  }

  # Complete
  complete = {
    name            = "complete-eks-mng"
    use_name_prefix = true

    subnet_ids = module.vpc.private_subnets

    min_size     = var.node_group_min_size
    max_size     = var.node_group_max_size
    desired_size = var.node_group_desired_size

    ami_id                     = data.aws_ami.eks_default.image_id
    enable_bootstrap_user_data = true

    pre_bootstrap_user_data = <<-EOT
        export FOO=bar
      EOT

    post_bootstrap_user_data = <<-EOT
        echo "you are free little kubelet!"
      EOT

    capacity_type        = "SPOT"
    force_update_version = true
    instance_types       = ["m6i.large", "m5.large", "m5n.large", "m5zn.large"]
    labels = {
      GithubRepo = "terraform-aws-eks"
      GithubOrg  = "terraform-aws-modules"
    }

    taints = [
      {
        key    = "dedicated"
        value  = "gpuGroup"
        effect = "NO_SCHEDULE"
      }
    ]

    update_config = {
      max_unavailable_percentage = 33 # or set `max_unavailable`
    }

    description = "EKS managed node group example launch template"

    ebs_optimized           = true
    disable_api_termination = false
    enable_monitoring       = true

    block_device_mappings = {
      xvda = {
        device_name = "/dev/xvda"
        ebs = {
          volume_size           = 75
          volume_type           = "gp3"
          iops                  = 3000
          throughput            = 150
          encrypted             = true
          kms_key_id            = module.ebs_kms_key.key_arn
          delete_on_termination = true
        }
      }
    }

    metadata_options = {
      http_endpoint               = "enabled"
      http_tokens                 = "required"
      http_put_response_hop_limit = 2
      instance_metadata_tags      = "disabled"
    }

    create_iam_role          = true
    iam_role_name            = "eks-managed-node-group-complete-example"
    iam_role_use_name_prefix = false
    iam_role_description     = "EKS managed node group complete example role"
    iam_role_tags = {
      Purpose = "Protector of the kubelet"
    }
    iam_role_additional_policies = {
      AmazonEC2ContainerRegistryReadOnly = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
      additional                         = aws_iam_policy.node_additional.arn
    }

    schedules = {
      scale-up = {
        min_size     = 2
        max_size     = "-1" # Retains current max size
        desired_size = 2
        start_time   = "2023-03-05T00:00:00Z"
        end_time     = "2024-03-05T00:00:00Z"
        timezone     = "Etc/GMT+0"
        recurrence   = "0 0 * * *"
      },
      scale-down = {
        min_size     = 0
        max_size     = "-1" # Retains current max size
        desired_size = 0
        start_time   = "2023-03-05T12:00:00Z"
        end_time     = "2024-03-05T12:00:00Z"
        timezone     = "Etc/GMT+0"
        recurrence   = "0 12 * * *"
      }
    }

    tags = {
      ExtraTag = "EKS managed node group complete example"
    }
  }


  tags = local.tags
}



resource "aws_iam_role_policy_attachment" "ng_worker" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = module.eks_managed_node_group.iam_role_arn
}


resource "aws_iam_role_policy_attachment" "ng_ecr" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = module.eks_managed_node_group.iam_role_arn
}


resource "aws_iam_role_policy_attachment" "ng_cni" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = module.eks_managed_node_group.iam_role_arn
}

resource "aws_iam_role" "ng_role" {
  name               = "kube-${var.cluster_name}-NodeGroupRole"
  assume_role_policy = <<POLICY
  {
  	"Version": "2012-10-17",
  	"Statement": [{
  		"Effect": "Allow",
  		"Principal": {
  			"Service": [
  				"ec2.amazonaws.com"
  			]
  		},
  		"Action": "sts:AssumeRole"
  	}]
  }
  POLICY
}

