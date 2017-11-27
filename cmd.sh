#!/usr/bin/env bash

ulimit -n 65536

chown -R rabbitmq:rabbitmq /var/lib/rabbitmq

# This is needed for statefulset service name resolution - needed for short name resolution
if [ -n "$RABBITMQ_SERVICE_DOMAIN" ]; then
    echo "search $RABBITMQ_SERVICE_DOMAIN" >> /etc/resolv.conf
fi

is_clustered="/var/lib/rabbitmq/is_clustered"

host=`hostname`

join_cluster () {
    if [ -e $is_clustered ]; then
        echo "Already clustered with $CLUSTER_WITH"
    else
        # Don't cluster with self or if already clustered
        if ! [[ $CLUSTER_WITH =~ $host ]]; then
            rabbitmq-server -detached
            rabbitmqctl stop_app
            rabbitmqctl join_cluster rabbit@$CLUSTER_WITH
            rabbitmqctl start_app

            # mark that this node is clustered
            mkdir $is_clustered
            # stopping because it we started it later in attached mode
            rabbitmqctl stop
            sleep 5
        fi
    fi
}

create_vhost() {
    rabbitmq-server -detached
    until rabbitmqctl node_health_check; do echo "Waiting to start..." && sleep 1; done;

    USER_EXISTS=`rabbitmqctl list_users | { grep $RABBITMQ_USERNAME || true; }`

    # create user only if it doesn't exist
    if [ -z "$USER_EXISTS" ]; then
        rabbitmqctl add_user $RABBITMQ_USERNAME $RABBITMQ_PASSWORD
        rabbitmqctl add_vhost $RABBITMQ_VHOST
        rabbitmqctl set_permissions -p $RABBITMQ_VHOST $RABBITMQ_USERNAME ".*" ".*" ".*"
        rabbitmqctl set_policy -p $RABBITMQ_VHOST ha-all "" '{"ha-mode":"all","ha-sync-mode":"automatic"}'
    fi
    # stopping because it we started it later in attached mode
    rabbitmqctl stop
    sleep 5
}

if [ -n "$CLUSTERED" ] && [ -n "$CLUSTER_WITH" ]; then
    join_cluster
fi

if [ -n "$RABBITMQ_USERNAME" -a -n "$RABBITMQ_PASSWORD" -a -n "$RABBITMQ_VHOST" ]; then
    create_vhost
fi

rabbitmq-server $RABBITMQ_SERVER_PARAMS
