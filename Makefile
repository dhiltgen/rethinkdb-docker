ORG?=dockereng
PROJ?=rethinkdb-base
VERSION?=2.3.6-ubuntu
CARCH?=x86_64

image:
	docker build --build-arg CARCH=$(CARCH) -t $(ORG)/$(PROJ):$(VERSION) -f Dockerfile .

push:
	docker push $(ORG)/$(PROJ):$(VERSION)
