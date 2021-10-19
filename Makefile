up:
	#--device-write-bps /dev/vda:10mb 
	docker run \
		--device-read-bps /dev/vda:50mb \
		-it --name samba --rm \
			-p 139:139 -p 445:445 \
            -v `pwd`:/mount \
            -d dperson/samba -p \
			-u "user;user" \
            -s "public;/shares" 

down:
	docker ps -aqf "name=samba" | xargs docker kill

ssh:
	docker exec -it `docker ps -aqf "name=samba"` bash

log:
	docker ps -aqf "name=samba" | xargs docker logs

# https://apple.stackexchange.com/questions/98331/can-i-connect-to-a-local-smb-share
tunnel:
	sudo ifconfig lo0 127.0.0.2 alias up
	ssh $$USER@localhost -L 127.0.0.2:445:localhost:445
