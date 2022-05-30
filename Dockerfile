FROM golang:1.16.2-alpine3.13 as builder
WORKDIR /app
COPY . ./
# This is where one could build the application code as well.


FROM alpine:latest as tailscale
WORKDIR /app
COPY . ./
ENV TSFILE=tailscale_1.24.2_amd64.tgz
RUN wget https://pkgs.tailscale.com/stable/${TSFILE} && \
  tar xzf ${TSFILE} --strip-components=1
COPY . ./


FROM alpine:latest
RUN apk update && apk add ca-certificates openssh sudo && rm -rf /var/cache/apk/*

# Copy binary to production image
COPY --from=builder /app/start.sh /app/start.sh
COPY --from=builder /app/my-app /app/my-app
COPY --from=tailscale /app/tailscaled /app/tailscaled
COPY --from=tailscale /app/tailscale /app/tailscale

RUN echo 'net.ipv4.ip_forward = 1' | sudo tee -a /etc/sysctl.conf
RUN echo 'net.ipv6.conf.all.forwarding = 1' | sudo tee -a /etc/sysctl.conf
RUN sudo sysctl -p /etc/sysctl.conf

RUN mkdir -p /var/run/tailscale /var/cache/tailscale /var/lib/tailscale


# Run on container startup.
CMD ["/app/start.sh"]
