# Build the manager binary
FROM cr.loongnix.cn/library/golang:1.19-alpine  as builder

WORKDIR /workspace
# Copy the Go Modules manifests
COPY go.mod go.mod
COPY go.sum go.sum
# cache deps before building and copying source so that we don't need to re-download as much
# and so that source changes don't invalidate our downloaded layer

# In case of network error while building images manually
ENV GOPROXY=https://goproxy.cn,direct

RUN go mod download

# Copy the go source
COPY cmd/ cmd/
COPY pkg/ pkg/
COPY certs/ certs/
COPY vendor/ vendor/

# Build
RUN CGO_ENABLED=0 GOOS=linux  go build -mod=vendor -a -o proxy cmd/proxy/main.go
RUN CGO_ENABLED=0 GOOS=linux  go build -mod=vendor -a -o agent cmd/agent/main.go

# Use distroless as minimal base image to package the manager binary
# Refer to https://github.com/GoogleContainerTools/distroless for more details
FROM cr.loongnix.cn/library/alpine:3.11
WORKDIR /
COPY --from=builder /workspace/proxy .
COPY --from=builder /workspace/agent .
COPY --from=builder /workspace/certs .

ENTRYPOINT ["sh"]
