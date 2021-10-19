# write file
```
dd if=/dev/zero of=~/f512M bs=512M count=1
```

# clear cache
```
# enter the docker for mac host vm
docker run -it --rm --privileged --pid=host justincormack/nsenter1

# drop the cache
echo 3 > /proc/sys/vm/drop_caches
```

# show IO stats
```
iostat 2 -d -k
```

# show page cache
```
curl -L -o pcstat https://github.com/tobert/pcstat/raw/2014-05-02-01/pcstat.x86_64
ln -s /mount/pcstat /usr/bin/pcstat 
chmod +x /usr/bin/pcstat
pcstat /shares/f512M
```

# verify io speed
```
# in host container, drop inode/page cache
echo 3 > /proc/sys/vm/drop_caches

# generate file
# this cannot be written under /mount folder since it is not limited by the device
dd if=/dev/zero of=/shares/f512M bs=512M count=1

# verify page cache
pcstat /shares/f512M

# time the operation
time cp /shares/f512M /shares/f514M
```
