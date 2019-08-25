#!/bin/sh
set -e

# Configuration
repository_path="/home/repository"

# Configure ownership
echo "Changing ownership of the root folder to www-data."
su-exec root chown -R www-data:www-data $repository_path

# Git deploy setup
echo "Checking git repository..."

if [ $(git -C $repository_path rev-parse --is-inside-work-tree  2> /dev/null) ]; then
    echo "Git repository already exists."
else
    cd $repository_path
    git init

    # Create branch and checkout if needed
    if [ "$GPTD_GIT_WORKING_BRANCH" != "master" ]; then
        git checkout -b $GPTD_GIT_WORKING_BRANCH
    fi

    # Allow direct git pushes
    # https://github.blog/2015-02-06-git-2-3-has-been-released/
    git config receive.denyCurrentBranch updateInstead

    mv /home/git-push-to-deploy/hooks/pre-receive $repository_path"/.git/hooks"
    mv /home/git-push-to-deploy/hooks/post-receive $repository_path"/.git/hooks"
fi

echo "Ready"
exec "$@"
