# slow IO simulation under macOS
This repo helps you to setup an environment under macOS to simulate a disk with slow IO.

It uses Docker for implementing this, and all Docker's built-in support for IO limit could be simulated, including read/write IOPS, read/write bandwidth. IO latency is not included but it could be similarly simulated using tools like device-mapper's [delay feature](https://serverfault.com/questions/523509/linux-how-to-simulate-hard-disk-latency-i-want-to-increase-iowait-value-withou).

---

# how it works
```
application under macOS <==POSIX API==> samba shared volume <==samba==> samba server container in Docker <==cgroup limit==> disk
```

* a samba container will be run by Docker, in which we specify the IO limits such as read/write IOPS or read/write bandwidth
* macOS client will mount the samba volume shared by Docker, since Docker for Mac is running locally, it requires some specify set up to make it work
* application under macOS, when accessing the volume shared via Samba, its IO will be limited to the IO limit specified by Docker (unless the limit is larger than Samba's IO limit)
* page cache under Docker for Mac's Linux host needs to be cleared if you want to accurately measure this limit

---
# setting it up
1. pre-requisites
    * macOS
    * Docker for Mac
2. Start a sambda container with IO limit
    ```
    make up
    ```

    This runs the following command:
    ```
    docker run \
        --device-read-bps /dev/vda:50mb \
        -it --name samba --rm \
        -p 139:139 -p 445:445 \
        -v `pwd`:/mount \
        -d dperson/samba -p \
        -u "user;user" \
        -s "public;/shares"
    ```
    * by defualt, it sets read IO bps to 50 MiB
    * it starts a samba container using image `dperson/samba`
    * it mounts the current folder under macOS to `/mount` in the container
    * it creates a user `user:user` for samba (you need this info to login later)
    * it shares the `/shares` folder in the container via samba
    * you can verify the IO limit in the container (see commands.md for details)
    * it exposes 139/445 samba ports to localhost
3. Mount the samba shared folder under macOS
    * macOS's Finder has built-int capability to mount samba folder, however, since this samba server is running locally, there is some difficulty to do it.
    * You need to create a special SSH tunnel for doing this [1]:
    ```
	sudo ifconfig lo0 127.0.0.2 alias up
	ssh `$USER`@localhost -L 127.0.0.2:445:localhost:445
    ```
    * Use Finder to mount the samba shared folder
        * `Finder` ==> `Go` ==> `Connect to Server` ==> `smb://127.0.0.2`
        * When prompted, use `user:user` as username/password

4. Anything you copy into `/shares` folder under the samba container, you will be access via `/Volumes/public` under macOS, and its IO will be limited as specified.

---
# Additional useful things
## figure out which files are accessed via disk IO
* install page cache stat tool in the container (https://github.com/tobert/pcstat)

```shell
# it will show the page cache stat for a file
pcstat /path/to/your/file
```
* clear page cache in the container

```shell
# enter the docker for mac host vm
docker run -it --rm --privileged --pid=host justincormack/nsenter1

# drop the page cache, dentires and inodes from memory
echo 3 > /proc/sys/vm/drop_caches
```

* run your application under macOS, for example, running a test case
* view the page cache for your file to see how much of this file is accessed by your test case

```shell
pcstat /path/to/your/file
```

* you can find all the files IO under a folder by your app/test

```shell
find . -iname "*.*" -type f -exec /usr/bin/pcstat {} +
```

# References
1. https://apple.stackexchange.com/questions/98331/can-i-connect-to-a-local-smb-share
