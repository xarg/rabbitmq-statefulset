#!/usr/bin/env bash

set -e

ulimit -n 1024
chown -R rabbitmq:rabbitmq /data

if [ -n "$RABBITMQ_SERVICE_DOMAIN" ]; then
    echo "search $RABBITMQ_SERVICE_DOMAIN" >> /etc/resolv.conf
fi

if [ -z "$CLUSTERED" ]; then
	# if not clustered then start it normally as if it is a single server
    rabbitmq-server -detached
else
	if [ -z "$CLUSTER_WITH" ]; then
		# If clustered, but cluster with is not specified then again start normally, could be the first server in the
		# cluster
        rabbitmq-server -detached
	else
        rabbitmq-server -detached

        host=`hostname`
        # Don't cluster with self
        if ! [[ $CLUSTER_WITH =~ $host ]]; then
            rabbitmqctl stop_app
            if [ -z "$RAM_NODE" ]; then
                rabbitmqctl join_cluster rabbit@$CLUSTER_WITH
            else
                rabbitmqctl join_cluster --ram rabbit@$CLUSTER_WITH
            fi
            rabbitmqctl start_app
        fi
	fi
fi

if [ -n "$RABBITMQ_USERNAME" -a -n "$RABBITMQ_PASSWORD" -a -n "$RABBITMQ_VHOST" ]; then
    create_vhost() {
        # Check that rabbitmq app is running before adding the vhost otherwise the container will crash
        if [[ `rabbitmqctl status` == *"rabbit,\"RabbitMQ\""* ]]; then
            # create users if provided as env vars
            USER_EXISTS=`rabbitmqctl list_users | { grep $RABBITMQ_USERNAME || true; }`
            # create user only if it doesn't exist
            if [ ! -n "$USER_EXISTS" ]; then
                rabbitmqctl add_user $RABBITMQ_USERNAME $RABBITMQ_PASSWORD
                rabbitmqctl add_vhost $RABBITMQ_VHOST
                rabbitmqctl set_permissions -p $RABBITMQ_VHOST $RABBITMQ_USERNAME ".*" ".*" ".*"
                rabbitmqctl set_policy -p $RABBITMQ_VHOST ha-all "" '{"ha-mode":"all","ha-sync-mode":"automatic"}'
            fi
        else
            echo "Waiting for the rabbitmq app to start..."
            sleep 1
            create_vhost
        fi
    }
    create_vhost
fi

# Tail to keep the a foreground process active..
if [ "$1" = 'tail' ]; then
    tail_log() {
        if [[ `rabbitmqctl status` == *"rabbit,\"RabbitMQ\""* ]]; then
            tail -f /data/log/rabbit\@$HOSTNAME.log
        else
            echo "Waiting for the rabbitmq app to start..."
            sleep 1
            tail_log
        fi
    }
    tail_log
else
    exec "$@"
fi
