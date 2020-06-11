#! /usr/bin/sh

# Exit code checking for each step
ecc () {
if [[ $? != 0 ]]; then
echo -e "\nERROR OCCURRED, EXITING....\n"
exit 1
fi
}

sudo -i
timestamp=`date "+%s"`
cd /tmp
startLog=/tmp/start.${timestamp}.log
echo "- beginning startup -" | tee -a ${startLog}

# get project name
hostname=`hostname`
project=`gcloud info --format="value(config.project)"`
zone=`gcloud compute instances list --filter="${hostname}" --format="value(zone)"`

# run prepare script
bucket_name=`gcloud compute instances describe ${hostname} --zone=${zone} --format="value(metadata.bucket_name)"`
cd /tmp
gsutil cp -r gs://${bucket_name}/scripts/precheck.sh /tmp
chmod -x precheck.sh
sh precheck.sh
echo "- precheck completed -" | tee -a ${startLog}

# install software
#gsutil cp gs://${bucket_name}/airflow-vm/CentOS-Base.repo /etc/yum.repos.d
gsutil cp gs://${bucket_name}/airflow-vm/installed-software.log /tmp
gsutil cp gs://${bucket_name}/airflow-vm/py-requirements.txt /tmp
yum -y install $(cat /tmp/installed-software.log)
ecc
echo "=============Copy installation linux package completed===================="
# Install Python 3.6
echo "=============Installing Python3===================="
#sudo cat > /etc/yum.repos.d/hub-usa-proxy.repo <<EOF

#[hub-usa-proxy]
#name=hub-usa-proxy
#baseurl=http://mirrors.163.com/centos/6/extras/x86_64
#enabled=1
#gpgcheck=0
#sslverify=0
#EOF
yum -y install python3 python3-devel
ecc
echo "=============Installing Python3 completed===================="
#Link python from 2 to 3
python --version
python3 --version
ls -l  /usr/bin/python*
mv /usr/bin/python /usr/bin/python.2.bak
ln -s /usr/bin/python3 /usr/bin/python
python --version
python3 --version
ls -l  /usr/bin/python*

#Installing python dependency
pip3 install --upgrade pip
pip3 install --upgrade setuptools
pip3 install --upgrade google-compute-engine
pip3 install -r /tmp/py-requirements.txt

#Start airflow
airflow initdb
airflow webserver -p 8080
exit
