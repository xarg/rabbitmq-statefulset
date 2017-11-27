# rabbitmq-statefulset helm chart

An example helm chart of RabbitMQ on Kubernetes (GKE) using StatefulSet.

Caveats:

 1. This example is GKE specific (it uses Persistent Volume Claims). There are no plans to support other providers. 
 2. Does not support SSL for now.


## Build/push your image: 

    docker build -t gcr.io/your-project/rabbitmq .
    gcloud docker -- push gcr.io/your-project/rabbitmq

### Install using helm

    helm upgrade -i rmq --set environment=production .
    
### Check that you have them

    $ kubectl get storageclass standard
    NAME       TYPE
    standard   kubernetes.io/gce-pd
    
    # kubectl get service rmq
    NAME      CLUSTER-IP   EXTERNAL-IP   PORT(S)                                 AGE
    rmq       None         <none>        4369/TCP,5672/TCP,15672/TCP,25672/TCP   1s 
    
### Check everything is working as expected 

    # check that they are up and then check their logs.
    kubectl get pod
    
    kubectl logs rmq-0
    kubectl logs rmq-1
    kubectl logs rmq-2
    
    # in case they are not up check the master logs to see what's happening 
    kubectl describe pod rmq-0
    

### Config

Environment variables can be used to configure your cluster.

 * `RABBITMQ_USERNAME` - create a username if it doesn't exist (useful for testing, but not recommended in production - do it manually or use secrets)
 * `RABBITMQ_PASSWORD` - username's password
 * `RABBITMQ_VHOST` - a vhost to which the username will be attached.
 * `RABBITMQ_ERLANG_COOKIE` - make sure you specify this in your values.yaml
    
### An important note about hosts

Make sure your app connects to the right hosts because of the domain name prefix that is added to StatefulSets. Example:

    amqp://USERNAME:PASSWORD@rmq-0.rmq.default.svc.cluster.local:5672/VHOST
    amqp://USERNAME:PASSWORD@rmq-1.rmq.default.svc.cluster.local:5672/VHOST
    amqp://USERNAME:PASSWORD@rmq-2.rmq.default.svc.cluster.local:5672/VHOST

