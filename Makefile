

# TODO: Replace with your new repo name
NEW_REPO_PATH='yourscmprovider.com/youruser/yourrepo'
CURRENT_REPO_PATH=$(shell go mod why | tail -n1)

BUF_REPO=$(shell cd ./redact && buf mod open)

BUF_VERSION:=$(shell curl -sSL https://api.github.com/repos/bufbuild/buf/releases/latest \
                   | grep '"name":' \
                   | head -1 \
                   | cut -d : -f 2,3 \
                   | tr -d '[:space:]\",')

buf_repos:
	@echo ${BUF_REPO}

buf_gen:
	buf --debug --verbose generate

generate: buf_gen
	protoc -I . \
	 --go_out=:. \
	 --go_opt=paths=source_relative \
	 --plugin=${GOPATH}/bin/version/v1.25.0/protoc-gen-go \
	 redact/redact.proto

fmt:
	GO111MODULE=on go fmt .

lint: fmt b_lint
	GO111MODULE=on go vet --vettool=${GOPATH}/bin/shadow .
	staticcheck .

clean: lint
	GO111MODULE=on go mod tidy
	rm -rf bin/*

build: clean b_clean
	GO111MODULE=on go build -o bin/protoc-gen-redact .

examples: build
	protoc -I . \
	 --go_out=:. \
	 --go_opt=paths=source_relative \
	 --plugin=${GOPATH}/bin/version/v1.25.0/protoc-gen-go \
	 --go-grpc_out=:. \
	 --go-grpc_opt=paths=source_relative \
	 --redact_out=:. \
	 --redact_opt=paths=source_relative \
	 --plugin=bin/protoc-gen-redact \
	 examples/user/pb/user.proto \
	 examples/tests/message.proto

b_lint:
	buf lint
	buf breaking --against 'https://github.com/johanbrandhorst/grpc-gateway-boilerplate.git#branch=master'

# Installs buf.build
# "https://github.com/bufbuild/buf/releases/download/v${BUF_VERSION}/buf-$(shell uname -s)-$(shell uname -m)"
install:
	curl -sSL \
    	"https://github.com/bufbuild/buf/releases/download/${BUF_VERSION}/buf-$(shell uname -s)-$(shell uname -m)" \
    	-o "$(shell go env GOPATH)/bin/buf" && \
  	chmod +x "$(shell go env GOPATH)/bin/buf"

update:
	buf --debug --verbose mod update

init:
	buf --debug --verbose mod init

b_clean:
	buf --debug --verbose mod clear-cache
# 1> Install buf with make install, which is necessary for us to generate the Go and OpenAPIv2 files.
# 2> If you forked this repo, or cloned it into a different directory from the github structure,
#	 you will need to correct the import paths.
#	 Here's a nice find one-liner for accomplishing this
#    (replace yourscmprovider.com/youruser/yourrepo with your cloned repo path):
# find . -path ./vendor -prune -o -type f \( -name '*.go' -o -name '*.proto' \) -exec sed -i -e "s;github.com/johanbrandhorst/grpc-gateway-boilerplate;yourscmprovider.com/youruser/yourrepo;g" {} +
# find . -path ./vendor -prune -o -type f \( -name '*.go' -o -name '*.proto' \) -exec sed -i -e "s;${CURRENT_REPO_PATH};${NEW_REPO_PATH};g" {} +

adjust_template:
ifeq ($(NEW_REPO_PATH),'yourscmprovider.com/youruser/yourrepo')
	@read -p "What is your new/cloned/forked repository's path? (e.g. ${NEW_REPO_PATH}): " new_repo; \
	NEW_REPO_PATH=$$new_repo; \
	find . -path ./vendor -prune -o -type f \( -name '*.go' -o -name '*.proto' -o -name 'go.mod' \) -exec sed -i -e "s;${CURRENT_REPO_PATH};$$NEW_REPO_PATH;g" {} +
else
	find . -path ./vendor -prune -o -type f \( -name '*.go' -o -name '*.proto' -o -name 'go.mod' \) -exec sed -i -e "s;${CURRENT_REPO_PATH};${NEW_REPO_PATH};g" {} +
endif

# purge_old removes the excess files and should be used after adjust_template
purge_old:
	find . -path ./vendor -o -type f \( -name '*.go-e' -o -name '*.proto-e' -o -name 'go.mod-e' \) | xargs rm



.PHONY: generate fmt lint clean build examples b_lint purge_old adjust_template
