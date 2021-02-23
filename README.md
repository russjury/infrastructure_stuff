# foobar

Assumes you're starting with a CentOS7 image created by [Packer](https://github.com/russjury/packer)

copy/clone VM image:
```
# HOSTNAME=myhost1
# cp /packer/packer-qemu /vm/directory/$HOSTNAME.qcow2
```

set hostname in image:
```
# 
```


```
# virt-install --vcpus=2 --memory=8192 --cpu host --machine q35 --os-variant rhel7 --network bridge=br0 --graphics spice --noautoconsole --sound none --console pty,target.type=virtio --serial pty --import --disk /vm/directory/$HOSTNAME.qcow2 --name $HOSTNAME
```
