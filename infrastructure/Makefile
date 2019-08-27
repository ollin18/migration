init:
	@docker-compose up -d
	# @docker-compose up --build -d

stop:
	@docker-compose stop

clean:
	@docker-compose rm

ingester:
	@docker build -t ingest:latest ingest/.
