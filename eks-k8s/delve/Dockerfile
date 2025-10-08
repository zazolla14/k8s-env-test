# 第一阶段：基于 golang 构建 dlv
FROM golang:1.25.0 AS builder

RUN CGO_ENABLED=0 GOOS=linux \
    go install -ldflags '-extldflags "-static"' \
    github.com/go-delve/delve/cmd/dlv@latest

# 第二阶段：基于 alpine，复制 dlv
FROM alpine:latest

# 安装必要依赖（如有需要）
RUN apk --no-cache add ca-certificates tzdata bash libc6-compat file

COPY --from=builder /go/bin/dlv /usr/local/bin/dlv

ENV PATH="/usr/local/bin:${PATH}"

RUN dlv version