FROM alpine:3.4

ENV RABBITMQ_VERSION=3.6.6 \
    RABBITMQ_LOG_BASE=/data/log \
    RABBITMQ_MNESIA_BASE=/data/mnesia

RUN apk add --update --no-cache curl tar xz bash \
        erlang erlang-mnesia \
        erlang-public-key erlang-crypto \
        erlang-ssl erlang-sasl \
        erlang-asn1 erlang-inets \
        erlang-os-mon erlang-xmerl \
        erlang-eldap erlang-syntax-tools && \
    curl -sSL https://www.rabbitmq.com/releases/rabbitmq-server/v${RABBITMQ_VERSION}/rabbitmq-server-generic-unix-${RABBITMQ_VERSION}.tar.xz | tar -xJ -C / --strip-components 1 && \
    rm -rf /share/**/rabbitmq*.xz && \
    apk del --purge curl tar xz && \
    addgroup rabbitmq && \
    adduser -DS -g "" -G rabbitmq -s /bin/sh -h /var/lib/rabbitmq rabbitmq && \
    mkdir -p /data/ && \
    chown -R rabbitmq:rabbitmq /data/ && \
    rabbitmq-plugins --offline enable rabbitmq_management && \
    echo "[{rabbit, [{loopback_users, []}]}]." > /etc/rabbitmq/rabbitmq.config

# Make sure you change the value in this file
COPY .erlang.cookie /var/lib/rabbitmq/.erlang.cookie
RUN chown rabbitmq:rabbitmq /var/lib/rabbitmq/.erlang.cookie && \
    ln -sf /var/lib/rabbitmq/.erlang.cookie /root/ && \
    chmod 400 /var/lib/rabbitmq/.erlang.cookie /root/.erlang.cookie

# Define mount points.
VOLUME ["/data"]

# Define working directory.
WORKDIR /data

# Add files.
COPY rabbitmq.sh /

# Define default command.
ENTRYPOINT ["/rabbitmq.sh"]
CMD ["tail"]

EXPOSE \
    # epmd
    4369 \
    # RabbitMQ SSL
    5671 \
    # RabbitMQ Non-SSL
    5672 \
    # RabbitMQ Management SSL
    15671 \
    # RabbitMQ Management Non-SSL
    15672 \
    # epmd rabbit
    25672
