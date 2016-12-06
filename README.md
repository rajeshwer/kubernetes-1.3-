# COREOS + KUBERNETES
### Deploying coreos on bare metal

Installing to disk
This Readme shows how to install to disk.
Boot the bare metal from any Linux liveCD (centos is bit faster )
Create DHCP server which automatically provides an Internet Protocol (IP) host with its IP address and other related configuration information such as the subnet mask and default gateway.
Create a script to download and install coreos . Can be run from any Linux distribution
copy the contents of link `https://raw.githubusercontent.com/coreos/init/master/bin/coreos-install` 
and paste it  in your local for eg: /tmp/ since you are using live cd you dont have storage.

The above created script will ONLY work IF you use a liveCD that contains ‘coreos-cloudinit’

Build your cloud-config.yaml validate it `http://www.yamllint.com/`

Build Coreos Binaries

 
```
git clone https://github.com/coreos/coreos-cloudinit.git
git checkout 0.10-release
cd coreos-cloudinit-master/
./build
cd bin 
```
 
 Copy those binaries into your bare metal server
Empty disk is needed on bare metal to install coreos 
Coreos cannot be booted on same device that is currently booted

Make sure to have all of the following in place
`https://raw.githubusercontent.com/coreos/init/master/bin/coreos-install)`
`cloud-config.yml` 
and the binaries that you have generated
you are all set to go 
go ahead and install coreos onto disk using this command

`coreos-install -d /dev/sda -c cloud-config.yaml`

You should be able to see this

`Success! CoreOS stable current is installed on /dev/sda`

reboot system

Deploying a Kubernetes cluster on Coreos :

1) Generate certificates for communication between Kubernetes components.
2) Configure flannel networking for the cluster.
3) Setting up a Kubernetes master node.
4) Setting up Kubernetes worker nodes.
5) Configure kubectl to work on the cluster.
6) Test the configuration.

Following keys should be generated before setting up the components

Root CA public and private key
ca.pem
ca-key.pem

API server public and private key
apiserver.pem
apiserver-key.pem

Worker node public and private key
<FQDN>-worker.pem
<FQDN>-worker-key.pem


Create a new directory on every node

`mkdir -p /etc/kubernetes/ssl`

Use the following commands to generate the certificates

```
openssl genrsa -out ca-key.pem 2048
openssl req -x509 -new -nodes -key ca-key.pem -days 10000 -out ca.pem -subj "/CN=kube-ca"

```

Create a openssl.cnf file with following contents & make sure to replace the "master ip's"

vi openssl.cnf

```
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name
[req_distinguished_name]
[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName = @alt_names
[alt_names]
DNS.1 = kubernetes
DNS.2 = kubernetes.default
DNS.3 = kubernetes.default.svc
DNS.4 = kubernetes.default.svc.cluster.local
IP.1 = 10.13.0.1
IP.2 = <master public IP>
IP.3 = <master private IP>
```

Now use the configuration file to generate the API server keys

openssl genrsa -out apiserver-key.pem 2048
openssl req -new -key apiserver-key.pem -out apiserver.csr -subj "/CN=kube-apiserver" -config openssl.cnf
openssl x509 -req -in apiserver.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out apiserver.pem -days 365 -extensions v3_req -extfile openssl.cnf

Now create a configuration file for Worker nodes

vi worker-openssl.cnf

```
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name
[req_distinguished_name]
[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName = @alt_names
[alt_names]
IP.1 = $ENV::WORKER_IP
```


```
openssl genrsa -out ${FQDN}-worker-key.pem 2048
WORKER_IP=${WORKER_IP} openssl req -new -key ${FQDN}-worker-key.pem -out ${FQDN}-worker.csr -subj "/CN=${FQDN}" -config worker-openssl.cnf
WORKER_IP=${WORKER_IP} openssl x509 -req -in ${FQDN}-worker.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out ${FQDN}-worker.pem -days 365 -extensions v3_req -extfile worker-openssl.cnf
```

Now generate Cluster Administrator Keypair

```
openssl genrsa -out admin-key.pem 2048
openssl req -new -key admin-key.pem -out admin.csr -subj "/CN=kube-admin"
openssl x509 -req -in admin.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out admin.pem -days 365
```

After generating the required certificates

we can startoff with deploying master node

Place the generated certs in the following location

```
mkdir -p /etc/kubernetes/ssl
```

copy the following keys to /etc/kubernetes/ssl

```
ca.pem, apiserver.pem, apiserver-key.pem 
```

Set permissions for the keys

```
sudo chmod 600 /etc/kubernetes/ssl/*-key.pem
sudo chown root:root /etc/kubernetes/ssl/*-key.pem
```

Deploying Master-node

```
Git clone https://github.com/rajeshwer/kubernetes-1.3-.git
```
Make sure to replace following in the files

```
MASTER_HOST
ETCD_ENDPOINTS
POD_NETWORK=10.2.0.0/16 (Default) or can use your own ip range
SERVICE_IP_RANGE=10.3.0.0/24 (Default)
K8S_SERVICE_IP=10.3.0.1 (Default)
DNS_SERVICE_IP=10.3.0.10 (Default)
```

Open service-files

Create following directories on msater node

```
mkdir -p /etc/flannel
mkdir -p /etc/systemd/system/flanneld.service.d
mkdir -p /etc/systemd/system/docker.service.d
mkdir -p /etc/kubernetes/manifests
```

Move master service-files to following loactions 

```
/etc/flannel/options.env
/etc/systemd/system/flanneld.service.d/40-ExecStartPre-symlink.conf
/etc/systemd/system/docker.service.d/40-flannel.conf
/etc/systemd/system/kubelet.service
/etc/kubernetes/manifests/kube-apiserver.yaml
/etc/kubernetes/manifests/kube-proxy.yaml
/etc/kubernetes/manifests/kube-controller-manager.yaml
/etc/kubernetes/manifests/kube-scheduler.yaml
```

Starting Services

```
sudo systemctl daemon-reload
```

Configure flannel Network

```
curl -X PUT -d "value={\"Network\":\"$POD_NETWORK\",\"Backend\":{\"Type\":\"vxlan\"}}" "$ETCD_SERVER/v2/keys/coreos.com/network/config"

sudo systemctl start flanneld
sudo systemctl enable flanneld
```

Starting kubelet

```
sudo systemctl start kubelet
sudo systemctl enable kubelet
```
Created symlink from /etc/systemd/system/multi-user.target.wants/kubelet.service to /etc/systemd/system/kubelet.service.

Checking if Kubernetes API is available

```
curl http://127.0.0.1:8080/version
```

response should look something like:

```
{
  "major": "1",
  "minor": "1",
  "gitVersion": "v1.1.7_coreos.2",
  "gitCommit": "388061f00f0d9e4d641f9ed4971c775e1654579d",
  "gitTreeState": "clean"
}
```

Creating namespace

```
curl -H "Content-Type: application/json" -XPOST -d'{"apiVersion":"v1","kind":"Namespace","metadata":{"name":"kube-system"}}' "http://127.0.0.1:8080/api/v1/namespaces"
```

checking if it's creating its pods via the metadata api

```
curl -s localhost:10255/pods | jq -r '.items[].metadata.name'
```

You should be able to see endpoints

Deploying Worker-Node

Create path /etc/kubernetes/ssl  and copy following certs

ca.pem
{WORKER_FQDN}-worker.pem
{WORKER_FQDN}-worker-key.pem

set the file file permissions

```
sudo chmod 600 /etc/kubernetes/ssl/*-key.pem
sudo chown root:root /etc/kubernetes/ssl/*-key.pem
cd /etc/kubernetes/ssl/
sudo ln -s ${WORKER_FQDN}-worker.pem worker.pem
sudo ln -s ${WORKER_FQDN}-worker-key.pem worker-key.pem
```
Create following directories on worker nodes

```
mkdir -p /etc/flannel
mkdir -p /etc/systemd/system/flanneld.service.d
mkdir -p /etc/systemd/system/docker.service.d
mkdir -p /etc/kubernetes/cni/net.d
mkdir -p /etc/kubernetes/manifests
```
Copy minion service-files from the cloned repository to following paths

```
/etc/flannel/options.env
/etc/systemd/system/flanneld.service.d/40-ExecStartPre-symlink.conf
/etc/systemd/system/docker.service.d/40-flannel.conf
/etc/systemd/system/kubelet.service
/etc/kubernetes/cni/net.d/10-calico.conf
/etc/kubernetes/manifests/kube-proxy.yaml
/etc/kubernetes/worker-kubeconfig.yaml
```
Starting the servies on Worker nodes

```
sudo systemctl daemon-reload
sudo systemctl start flanneld
sudo systemctl start kubelet
sudo systemctl enable flanneld
sudo systemctl enable kubelet
```

Setting up Kubectl

Download Kubectl binaries

```
curl -O https://storage.googleapis.com/kubernetes-release/release/v1.4.3/bin/linux/amd64/kubectl

chmod +x kubectl
mv kubectl /opt/bin/kubectl
```
Configuring kubectl

```
kubectl config set-cluster default-cluster --server=https://${MASTER_HOST} --certificate-authority=${CA_CERT}
kubectl config set-credentials default-admin --certificate-authority=${CA_CERT} --client-key=${ADMIN_KEY} --client-certificate=${ADMIN_CERT}
kubectl config set-context default-system --cluster=default-cluster --user=default-admin
kubectl config use-context default-system
```
Now you should be able to list the nodes

```
kubectl get nodes
NAME          LABELS                               STATUS
X.X.X.X       kubernetes.io/hostname=X.X.X.X       Ready
```
