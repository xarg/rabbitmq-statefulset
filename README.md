# rabbitmq-statefulset

An example of RabbitMQ on Kubernetes using StatefulSet.

Caveats:

 1. This example is GKE specific (it uses Persistent Volume Claims). There are no plans to support other providers. 
 2. Does not support SSL for now.
 3. No Helm config - would be glad to accept one in a PR. 


## Build/push your image: 

    docker build -t gcr.io/your-project/rabbitmq .
    gcloud docker -- push gcr.io/your-project/rabbitmq

### Create StorageClass and RabbitMQ service

    kubectl create -f k8s/standard-storageclass.yaml
    kubectl create -f k8s/rmq-service.yaml
    
### Check that you have them

    $ kubectl get storageclass standard
    NAME       TYPE
    standard   kubernetes.io/gce-pd
    
    # kubectl get service rmq
    NAME      CLUSTER-IP   EXTERNAL-IP   PORT(S)                                 AGE
    rmq       None         <none>        4369/TCP,5672/TCP,15672/TCP,25672/TCP   1s 
    
### Create your StatefulSet

    kubectl create -f k8s/rmq-statefulset.yaml

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

 * `CLUSTERED` - the image will try to be in a cluster. 
 * `CLUSTERED_WITH` - the short hostname it should try to cluster with. Set this `rmq-0`. `rmq-0` itself will not try to cluster with itself.
 * `RABBITMQ_SERVICE_DOMAIN` - StatefulSet are usually attached to a service and this service has a prefix domain that is not added by default in `/etc/hosts`. So this value is important to be set.
 * `RAM_NODE` - make it a RAM node.
 * `RABBITMQ_USERNAME` - create a username if it doesn't exist (useful for testing, but not recommended in production - do it manually or use secrets)
 * `RABBITMQ_PASSWORD` - username's password
 * `RABBITMQ_VHOST` - a vhost to which the username will be attached.
    
### An important note about hosts

Make sure your app connects to the right hosts because of the domain name prefix that is added to StatefulSets. Example:

    amqp://USERNAME:PASSWORD@rmq-0.rmq.default.svc.cluster.local:5672/VHOST
    amqp://USERNAME:PASSWORD@rmq-1.rmq.default.svc.cluster.local:5672/VHOST
    amqp://USERNAME:PASSWORD@rmq-2.rmq.default.svc.cluster.local:5672/VHOST

