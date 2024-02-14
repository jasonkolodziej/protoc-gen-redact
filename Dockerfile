FROM golang as builder-local

ENV GOOS=linux GOARCH=amd64 CGO_ENABLED=0

WORKDIR /app

COPY go.mod ./
COPY go.sum ./

RUN go mod download

COPY ./redact ./redact
COPY template.tmp ./
COPY *.go ./


# RUN go install github.com/twitchtv/twirp/protoc-gen-twirp@v8.1.0+incompatible
RUN go build -o bin/protoc-gen-redact .
# Note, the Docker images must be built for amd64. If the host machine architecture is not amd64
# you need to cross-compile the binary and move it into /go/bin.
# Normally go install would install to $GOPATH/bin/$GOOS_$GOARCH when cross-compiling,
# so we added this line to copy the executable into the /go/bin path.

#RUN bash -c 'find /go/bin/${GOOS}_${GOARCH}/ -mindepth 1 -maxdepth 1 -exec mv {} /go/bin \;'

FROM scratch
#
## Runtime dependencies
# LABEL "build.buf.plugins.runtime_library_versions.0.name"="github.com/twitchtv/twirp"
LABEL "build.buf.plugins.runtime_library_versions.0.name"="github.com/jasonkolodziej/protoc-gen-redact@bufbuild"
LABEL "build.buf.plugins.runtime_library_versions.0.version"="v0.1.1"
LABEL "build.buf.plugins.runtime_library_versions.1.name"="google.golang.org/protobuf"
LABEL "build.buf.plugins.runtime_library_versions.1.version"="v1.27.1"
LABEL "build.buf.plugins.runtime_library_versions.2.name"="github.com/lyft/protoc-gen-star"
LABEL "build.buf.plugins.runtime_library_versions.2.version"="v0.5.2"
LABEL "build.buf.plugins.runtime_library_versions.3.name"="google.golang.org/grpc"
LABEL "build.buf.plugins.runtime_library_versions.3.version"="v1.34.0"
#
COPY --from=builder-local /app/template.tmp /
COPY --from=builder-local /app/bin /
#
ENTRYPOINT ["/protoc-gen-redact"]