

data = '''NAME                  TYPE           CLUSTER-IP       EXTERNAL-IP      PORT(S)                                  AGE
cinder                ClusterIP      10.98.239.34     <none>           80/TCP,443/TCP                           37m
cinder-api            ClusterIP      10.103.200.147   <none>           8776/TCP                                 37m
cloudformation        ClusterIP      10.108.107.105   <none>           80/TCP,443/TCP                           38m
glance                ClusterIP      10.100.201.240   <none>           80/TCP,443/TCP                           38m
glance-api            ClusterIP      10.100.185.243   <none>           9292/TCP                                 38m
heat                  ClusterIP      10.109.106.15    <none>           80/TCP,443/TCP                           38m
heat-api              ClusterIP      10.99.128.115    <none>           8004/TCP                                 38m
heat-cfn              ClusterIP      10.98.106.155    <none>           8000/TCP                                 38m
horizon               ClusterIP      10.110.67.113    <none>           80/TCP,443/TCP                           34m
horizon-int           NodePort       10.110.119.53    <none>           80:31000/TCP                             34m
keystone              ClusterIP      10.102.224.246   <none>           80/TCP,443/TCP                           71m
keystone-api          ClusterIP      10.104.50.253    <none>           5000/TCP                                 71m
mariadb               ClusterIP      10.106.253.86    <none>           3306/TCP                                 73m
mariadb-discovery     ClusterIP      None             <none>           3306/TCP,4567/TCP,4568/TCP,4444/TCP      73m
mariadb-server        ClusterIP      10.97.131.171    <none>           3306/TCP                                 73m
memcached             ClusterIP      10.100.126.26    <none>           11211/TCP                                73m
metadata              ClusterIP      10.103.116.204   <none>           80/TCP,443/TCP                           16m
neutron               ClusterIP      10.105.24.165    <none>           80/TCP,443/TCP                           16m
neutron-server        ClusterIP      10.105.210.181   <none>           9696/TCP                                 16m
nova                  ClusterIP      10.99.72.205     <none>           80/TCP,443/TCP                           16m
nova-api              ClusterIP      10.107.143.135   <none>           8774/TCP                                 16m
nova-metadata         ClusterIP      10.108.107.217   <none>           8775/TCP                                 16m
nova-novncproxy       ClusterIP      10.109.121.201   <none>           6080/TCP                                 16m
novncproxy            ClusterIP      10.107.173.60    <none>           80/TCP,443/TCP                           16m
placement             ClusterIP      10.107.195.54    <none>           80/TCP,443/TCP                           35m
placement-api         ClusterIP      10.102.133.15    <none>           8778/TCP                                 35m
public-openstack      LoadBalancer   10.105.250.19    172.24.128.100   80:30183/TCP,443:30180/TCP               81m
rabbitmq              ClusterIP      None             <none>           5672/TCP,25672/TCP,15672/TCP,15692/TCP   76m
rabbitmq-mgr-7b1733   ClusterIP      10.100.229.236   <none>           80/TCP,443/TCP                           76m'''

fdqn_suffix = '.openstack.svc.cluster.local'

for line in data.split('\n'):
    name, _type, clusterip, externalip, ports, age = line.split()
    if _type == 'ClusterIP':
        if clusterip != 'None': # deployment
            print(clusterip, name + fdqn_suffix)
        #else: # headless service
        #    print(clusterip, name + '-0.' + name + fdqn_suffix)
