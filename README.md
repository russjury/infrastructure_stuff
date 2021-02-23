# Creating VMs from Packer image

Assumes you're starting with a CentOS7 image created by [Packer](https://github.com/russjury/packer)

copy/clone VM image:
```
# HOSTNAME=myhost1
# cp /packer/packer-qemu /vm/directory/$HOSTNAME.qcow2
```

set hostname in image (using the set_vm_hostname.sh helper script):
```
# ./set_vm_hostname.sh $HOSTNAME /vm/directory/$HOSTNAME.qcow2
```

create VM (requires a modern version of QEMU - like what you'd find on Fedora, etc. If using a CentOS7 server for QEMU/KVM, remove the '--machine q35' part and suffer with horribly slow virtualization)
```
# virt-install --vcpus=2 --memory=8192 --cpu host --machine q35 --os-variant rhel7 --network bridge=br0 --graphics spice --noautoconsole --sound none --console pty,target.type=virtio --serial pty --import --disk /vm/directory/$HOSTNAME.qcow2 --name $HOSTNAME
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
# rm /path/to/vm/$HOSTNAME.qcow2
```

# Configure VMs with Ansible

coming soon...
