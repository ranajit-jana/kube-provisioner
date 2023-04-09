echo 'git push --set-upstream origin' $1
git push --set-upstream origin $1

current_branch=$(git branch --show-current)
echo "$current_branch"

if [ "$1" != "" ]; then
    echo "create new branch"
    git checkout -b "$current_branch"
fi