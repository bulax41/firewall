
# Scripts for Managing IPTables on a CentOS Server as a Firewall

* CentOS 7
* Minimal install
* Recommend 4 GB for storage with VM's
* CPU's, Memory should be sized based on your requirements.

## Getting started
Clone from the master branch on github.
`yum install git`
`git clone https://github.com/bulax41/firewall`

### `setup.sh`
The setup script will
* Download RPM's
* Set sysctl variable defaults
* Enable/Disable systemctl unit files
* Set an initial iptables rules structure
* Tune selinux policy
* Update Grub for 'eth' style interface names

After setup has run reboot for Grub and systemctl unit file changes to be applied.
