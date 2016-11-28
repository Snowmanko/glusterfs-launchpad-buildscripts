#!/bin/bash
#
# build package with glusterfs support
#

if [ ! -f config ];then
    echo "config missing! create config from config.dist example before running this script!"
    exit 1
fi

#script
if [ -z $1 ] || [ -z $2 ] || [ -z $3 ] ; then
    echo -e "need os and gluster version! \nUsage: $0 trusty libvirt 3.8.6"
    exit 1
fi

#config
OS_VERSION="$1"
PACKAGE="$2"
GLUSTER_VERSION="$3"

. "config"

# build
export DEBFULLNAME=${DEBFULLNAME}

export DEBEMAIL=${DEBEMAIL}

sudo sh -c "sed "s/#OS_VERSION#/${OS_VERSION}/g" < sources.list.d/ubuntu-src.dist > /etc/apt/sources.list.d/ubuntu-src.list"

sudo apt-get update

test -d ${PACKAGEDIR} && rm -r ${PACKAGEDIR}

mkdir -p ${PACKAGEDIR}

cd ${PACKAGEDIR}

apt-get source ${PACKAGE}/${OS_VERSION}

REAL_PATH="$(realpath .)"

cd $(find ${REAL_PATH} -maxdepth 2 -mindepth 2 -type d -iname debian)

debchange -l ${PACKAGE_IDENTIFIER} ${DEBCOMMENT} -D ${OS_VERSION}

cp control control.org

if [ "${PACKAGE}" == "libvirt" ]; then
    sed 's# netcat-openbsd,# netcat-openbsd,\n glusterfs-common,\n libacl1-dev,#g' < control.org > control
elif [ "${PACKAGE}" == "qemu" ]; then
    sed 's#\#\#--enable-glusterfs todo#\# --enable-glusterfs\n glusterfs-common,\n libacl1-dev,#g' < control.org > control
elif [ "${PACKAGE}" == "samba" ]; then
    sed 's#bison,#bison,\n               glusterfs-common,\n               libacl1-dev,#' < control.org > control
fi

rm control.org

if [ "${LAUNCHPAD_UPLOAD}" == "yes" ]; then
    debuild -S

    dput ppa:${PPA_OWNER}/${PPA} $(find ${REAL_PATH} -name ${PACKAGE}*gluster*_source.changes | sort | tail -n 1)
else
    debuild -us -uc -i -I
fi
