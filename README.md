# Creating VMs from Packer image

Assumes you're starting with a CentOS7 image created by [Packer](https://github.com/russjury/packer)

copy/clone VM image:
```
# HOSTNAME=myhost1
# cp /e/packer/centos8/packer-qemu /e/VMs/$HOSTNAME.qcow2
```

set hostname in image (using the set_vm_hostname.sh helper script):
```
# modprobe nbd max_part=63
# ./set_vm_hostname.sh $HOSTNAME /e/VMs/$HOSTNAME.qcow2
```

create VM (requires a modern version of QEMU - like what you'd find on Fedora, etc. If using a CentOS7 server for QEMU/KVM, remove the '--machine q35' part and suffer with horribly slow virtualization)
```
# virt-install --vcpus=2 --memory=8192 --cpu host --machine q35 --os-variant centos8 --network bridge=br0 --graphics none --noautoconsole --sound none --console pty,target.type=virtio --serial pty --import --disk /e/VMs/$HOSTNAME.qcow2 --name $HOSTNAME
```

At this point you should have a running VM with it's hostname set, and getting its network info from DHCP. The rest of the steps also assume your DHCP server registers this host's name in DNS... so if you can't ping your VM by name right now, that could be the problem.
```
# ping myhost1
```

### If things go wrong...

To shut down a VM:
```
# virsh destroy $HOSTNAME
```

To delete a VM that's bad:
```
# virsh undefine $HOSTNAME
# rm /e/VMs/$HOSTNAME.qcow2
```

# Configure VMs with Ansible and Create Kubernetes Cluster with Kubespray

Next, I'll be creating a simple Kubernetes cluster with 5 newly provisioned VMs (using the above steps). In my case, my VM names are:
- master01.localdomain
- master02.localdomain
- master03.localdomain
- worker01.localdomain
- worker02.localdomain

I'm using Fedora 31 to run Ansible and QEMU/KVM - you'll want something similarly modern so that your Ansible and QEMU libs are relatively new (i.e. don't try this on CentOS 7 - I'm using CentOS7 for my VMs but will be replacing the old kernel with a much more modern one).

Install Ansible:
```
dnf install ansible python-netaddr -y
```

Create some working directories:
```
mkdir ansible
mkdir ansible/inventory
```

Create ansible inventory file (in a format Kubespray likes):
```
[all]
master01
master02
master03
worker01
worker02

[kube-master]
master01
master02
master03

[etcd]
master01
master02
master03

[kube-node]
worker01
worker02

[k8s-cluster:children]
kube-master
kube-node
```

Clone kubespray:
```
cd ansible
git clone https://github.com/kubernetes-sigs/kubespray.git
```

Build cluster:
```
cd kubespray
ansible-playbook -i ../inventory/inventory.ini cluster.yml
```


