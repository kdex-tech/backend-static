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
#
# The upstream caddy image ships /usr/bin/caddy with `cap_net_bind_service=ep`
# file capabilities. Under runAsNonRoot=true + capabilities.drop=[ALL] +
# allowPrivilegeEscalation=false, the kernel refuses to exec a binary
# whose file caps can't be obtained from the bounding set - the container
# fails to start with "Operation not permitted". Since we listen on 8080
# (no privileged port), the file cap is useless; strip it via libcap's
# setcap so the binary exec's cleanly under restricted PSA.
RUN apk add --no-cache bash libcap tini tree && \
	\
	mkdir -p /etc/caddy.d /public /config /data; \
	chown -R 65532:65532 /etc/caddy.d /public /config /data /srv; \
	setcap -r /usr/bin/caddy; \
	\
	caddy validate --config /etc/caddy/Caddyfile

USER 65532:65532