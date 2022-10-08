# kalictf_docker - non-root container

This docker image was created for use in capture-the-flag events. I will be adding tools but currently, it is setup for for basic pwn and basic web. This container does not run as root by default. So if you use bind mounts the permissions can be tricky. See tip below:

### Setup for bind volume in non-root container:
 - Please create a group with the id `100999` and add your user to it. 

```bash
$ groupadd -g 100999 docker-share && \
    usermod -aG docker-share $USER
```

 - Then create the directory you want to share and change ownership to `<your user>:<the new 100999 group>`

```bash
$ mkdir -p ~/tools && chown -R $USER:docker-share ~/tools
```
---
### How to build and start the container:
 - This will build the image if it doesn't exist and start it:
 ```bash
 $ docker compose up -d
 ```
 - You can do each step individually with:
 ```bash
 $ docker compose build
 $ docker compose up -d
 ```

 ### How to stop the container:
  - can be stopped with `docker compose stop` which will not remove the container.
 ```bash
 $ docker compose down
 ```