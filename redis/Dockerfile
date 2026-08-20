FROM redis:7-alpine

RUN apk add --no-cache gettext

COPY redis.conf.template /usr/local/etc/redis/redis.conf.template
COPY docker-entrypoint.sh /usr/local/bin/flexia-entrypoint.sh
RUN chmod +x /usr/local/bin/flexia-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/flexia-entrypoint.sh"]
