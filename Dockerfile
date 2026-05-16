FROM caddy:2.10.2

COPY Caddyfile /etc/caddy/Caddyfile
COPY entrypoint.sh /

ENTRYPOINT ["tini", "-v", "--", "/entrypoint.sh"]

ENV LANG="C.UTF-8"

# Run as a non-root numeric UID so the image is compatible with Kubernetes
# PodSecurity restricted (which enforces runAsNonRoot=true plus
# capabilities.drop=[ALL]). 65532 is the kubernetes-distroless convention.
# Caddy's default ports of 80/443 require CAP_NET_BIND_SERVICE which the
# restricted profile drops, so the Caddyfile now defaults to :8080.
RUN apk add --no-cache bash tini tree && \
	\
	mkdir -p /etc/caddy.d /public /config /data; \
	chown -R 65532:65532 /etc/caddy.d /public /config /data /srv; \
	\
	caddy validate --config /etc/caddy/Caddyfile

USER 65532:65532