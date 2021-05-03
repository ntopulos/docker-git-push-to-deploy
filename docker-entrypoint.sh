#!/bin/sh
set -e

# Configuration
repository_path="/home/repository"

# Git deploy setup
echo "Checking git repository..."

if [ $(git -C $repository_path rev-parse --is-inside-work-tree  2> /dev/null) ]; then
    echo "Git repository already exists."
else
    cd $repository_path
    git init
fi

cd $repository_path

# Create branch and checkout if needed
if [ "$GPTD_GIT_WORKING_BRANCH" != "main" ]; then
    current_branch=$(git -C $repository_path branch | sed -n -e 's/^\* \(.*\)/\1/p')
    if [ "current_branch" != "$GPTD_GIT_WORKING_BRANCH" ]; then
        git checkout -b $GPTD_GIT_WORKING_BRANCH
    fi
fi

# Allow direct git pushes
# https://github.blog/2015-02-06-git-2-3-has-been-released/
git config receive.denyCurrentBranch updateInstead

yes | cp -rf /home/git-push-to-deploy/hooks/* $repository_path"/.git/hooks"

# Committing any initial files to avoid issues on first push
git_live_status=$(git -C $repository_path status --porcelain)
if [ -n "$git_live_status" ]; then
    echo "Live repository not clean."
    echo "Committing live changes..."
    env -i git add -A
    env -i git -c user.email="$GPTD_GIT_USER_EMAIL" -c user.name="$GPTD_GIT_USER_NAME" commit -m "[autocommit]" --quiet
    echo "Done"
fi

# Configure ownership
echo "Changing ownership of the root folder to www-data."
su-exec root chown -R www-data:www-data $repository_path

echo "Ready"
exec "$@"
