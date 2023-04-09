#!/bin/bash
git stash
git checkout main
git pull

if [ "$1" != "" ]; then
    echo "create new branch"
    git checkout -b "$1"
fi