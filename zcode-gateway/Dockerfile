# zcode-gateway — build Go (repo tidak menyediakan Dockerfile)
FROM golang:alpine AS build
# go.mod meminta go 1.27.2 → izinkan Go mengunduh toolchain yang sesuai bila base lebih lama
ENV GOTOOLCHAIN=auto
WORKDIR /src
COPY go.mod ./
RUN go mod download || true
COPY . .
RUN CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o /out/zcode-gateway ./cmd/zcode-gateway

FROM alpine:3.20
RUN apk add --no-cache ca-certificates tzdata
WORKDIR /app
COPY --from=build /out/zcode-gateway /app/zcode-gateway
ENV BIND_HOST=0.0.0.0 \
    PORT=20131 \
    ZCODE_STATE_DIR=/app/data \
    ZCODE_ACCOUNTS_FILE=/app/data/accounts.json \
    ZCODE_PLAN_JWT_FILE=/app/data/plan-jwt.json \
    ZCODE_DEFAULT_EFFORT=low \
    TZ=Asia/Jakarta
EXPOSE 20131
VOLUME ["/app/data"]
ENTRYPOINT ["/app/zcode-gateway"]
