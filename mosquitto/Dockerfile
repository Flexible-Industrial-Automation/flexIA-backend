FROM eclipse-mosquitto:2

RUN apk add --no-cache gettext

COPY mosquitto.conf.template /mosquitto/config/mosquitto.conf.template
COPY docker-entrypoint.sh /docker-entrypoint-flexia.sh
RUN chmod +x /docker-entrypoint-flexia.sh

ENTRYPOINT ["/docker-entrypoint-flexia.sh"]
