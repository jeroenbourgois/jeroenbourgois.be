.SILENT: ;               		# no need for @
Makefile: ;              		# skip prerequisite discovery

deploy:
	hugo && rsync -avz --delete public/ root@198.211.121.251:/home/user-data/www/jeroenbourgois.be/
