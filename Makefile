.SILENT: ;               		# no need for @
Makefile: ;              		# skip prerequisite discovery

deploy: yoda_stats
	echo "==> Gen site"
	hugo && rsync -avz --delete public/ root@198.211.121.251:/home/user-data/www/jeroenbourgois.be/

yoda_stats:
	echo "==> Gen Yoda stats"
	cd ./data && gnuplot  yoda-weight.gnuplot > ../static/images/yoda/stats-weight.jpeg
	cd ./data && gnuplot  yoda-length.gnuplot > ../static/images/yoda/stats-length.jpeg

docker_run:
	docker build -t jeroenbourgoisbe .
	docker run --name jeroenbourgoisbe -p 8080:80 -d jeroenbourgoisbe
