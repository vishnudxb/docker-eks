secret := foo
access := bar
region := us-east-1

all:
	docker build \
	--rm=true \
	--build-arg AWS_ACCESS_KEY=$(access) \
	--build-arg AWS_SECRET_KEY=$(secret) \
	--build-arg REGION=$(region) \
	--force-rm -t docker-eks:local .
