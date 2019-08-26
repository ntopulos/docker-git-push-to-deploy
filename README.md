# Docker git-push-to-deploy

A git server to which git can push to deploy, but whose content can also be directly modified.

The git repository automatically commits its modification before accepting a push.


## Installation

### Remote

**Warning:** This container should **only run on a remote environment**, not in your development environment as it accesses and modifies the git repository of its mounted directory.

1. Setup your remote docker environment.
2. The directory that will be mounted by this tool and where the app will be deployed can be:
   - empty | not empty
   - a git repository | not a git repository

   In any case, new files will be automatically committed on containers launch.

Example of `docker-compose.yml`:

```yaml
git-push-to-deploy:
    image: ntopulos/git-push-to-deploy:latest
    volumes:
        # Directory with the app to be deployed
        - .:/home/repository
        # Optional: path to the scripts that will run after a push
        #- ./docker/git-push-to-deploy/deploy-script.sh:/home/git-push-to-deploy/deploy-script.sh
    # Optional: git custom identity for automatic commits and git branch to be used
    # environment:
    #     - GPTD_GIT_USER_NAME=YourName
    #     - GPTD_GIT_USER_EMAIL=you@example.com
    #     - GPTD_GIT_WORKING_BRANCH=production
    # Local port for git ssh access
    ports:
        - "2222:22"
```

Example of a `deploy-script.sh` from the `docker-compose.yml` above:

```sh
#!/bin/sh

echo
echo "Doing something..."
echo
```

### Local

To deploy with git to the remote Docker container, we use an SSH tunnel through the remote server, thus we do not need to care about SSH keys in Docker.

1. In your SSH `config` add the connection to your remote server:

       Host YourServerName
           Hostname ...
           Port ...
           User ...

2. Add the connection to the git-push-to-deploy container using a tunnel with the previous connection:

       Host GitPushToDeploy
           StrictHostKeyChecking no
           Hostname 127.0.0.1
           Port 2222
           User www-data
           ProxyJump YourServerName

3. You should now be able to access the remote docker container directly with:

       ssh GitPushToDeploy

4. Add the remote to your local git repository:

       git remote add production GitPushToDeploy:/home/repository

## Deploy script

As described in above in the `docker-compose.yml` example, a deploy script can be automatically executed after a push.

Often such a script needs to execute commands on other containers, therefore it needs access to docker which is not provided in the image but can it be added by building your own image.

Example of a `Dockerfile` adding Docker to the base image:

```Dockerfile
FROM ntopulos/git-push-to-deploy:latest
RUN apk add --no-cache docker=18.09.8-r0
```

Add the UNIX socket to the `docker-composer.yml`:

```yaml
volumes:
    - /var/run/docker.sock:/var/run/docker.sock
```

Deploy script example with docker:

```sh
#!/bin/sh

echo
echo "Updating dependencies"
su-exec root docker exec example_name-php_1 sh -c "cd /var/www/html; composer udpate"
echo
```

## Requirements

- Git on local
- SSH access to the remote server

## Notes

- Do **not** expose the `2222` SSH port on your server, its access must be restricted to the server itself.
- This image was primarily designed to work with nginx-related deployment, thus the ownership of the mounted content is set to `www-data:www-data`.
- This image brings together the scripts from [git-push-to-deploy](https://github.com/ntopulos/git-push-to-deploy), and simplifies the overall method by using a git version that allows to push to a none-bare repository.