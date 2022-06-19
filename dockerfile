## Multi-stages Dockerfile

# Fist Stage
FROM golang:1.18.3 as golang

RUN mkdir /app

COPY ./ /app
WORKDIR /app

RUN go mod download
RUN go mod tidy
RUN CGO_ENABLED=0 GOOS=linux go build -o ./golang-app -buildvcs=false

# Second Stage
FROM alpine:3.15

LABEL Maintainer="Arvy Renardi <arvy.devops@gmail.com>" \
      Description="Lightweight container for Golang based on Alpine Linux 3.15."

RUN apk --no-cache add supervisor curl tzdata vim wget bash sudo && \
    ln -sf /usr/share/zoneinfo/Asia/Jakarta /etc/localtime

RUN mkdir /app && chown -R nobody:nobody /app

RUN echo '%wheel ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/wheel && \
    chown -R nobody:nobody /var/log && \
    chown -R nobody:nobody /run && \ 
    chown -R nobody:nobody /etc/supervisord.conf

COPY --chown=nobody:nobody config/* /etc/

WORKDIR /app

COPY --from=golang --chown=nobody /app/golang-app /app/

USER nobody

ENV PORT 8000

EXPOSE 8000

CMD ["/usr/bin/supervisord", "-c", "/etc/golang-app.conf"]

HEALTHCHECK --timeout=10s CMD ps aux | grep "golang-app"
