#!/bin/bash

TAG=latest
if [ ! -z "$1" ];then
	TAG=$1
fi

WORKDIR=${PWD}
SRC_IMG=${WORKDIR}/openwrt-armvirt-64-default-rootfs.tar.gz
TMPDIR=openwrt_rootfs
OUTDIR=dockerimgs/docker
IMG_NAME=baltimore/openwrt-aarch64
[ -d "$OUTDIR" ] || mkdir -p ${OUTDIR}

[ -d "$TMPDIR" ] && rm -rf "$TMPDIR"

#mkdir -p "$TMPDIR"  && \
#mkdir -p "$OUTDIR"  && \
#gzip -dc openwrt-armvirt-64-default-rootfs.tar.gz | ( cd "$TMPDIR" && tar xf - ) && \
mkdir -p "$TMPDIR" && gzip -dc ${SRC_IMG} | ( cd "$TMPDIR" && tar xf - && rm -rf ./lib/firmware/* && rm -rf ./lib/modules/*)

[ -x $TMPDIR/bin/bash ] && \
	cp -f patches/30-sysinfo.sh $TMPDIR/etc/profile.d/ && \
	sed -e "s/\/bin\/ash/\/bin\/bash/" -i $TMPDIR/etc/passwd && \
	sed -e "s/\/bin\/ash/\/bin\/bash/" -i $TMPDIR/usr/libexec/login.sh
	
[ -f patches/banner ] && \
	cp -f patches/banner $TMPDIR/etc/ && \
	echo "The docker aarch64 special edition" >> $TMPDIR/etc/banner && \
	echo "\n" >> $TMPDIR/etc/banner
	
cat >> $TMPDIR/etc/sysupgrade.conf <<EOF
/etc/ssh/ssh_host_ed25519_key
/etc/ssh/ssh_host_ed25519_key.pub
/etc/ssh/ssh_host_rsa_key
/etc/ssh/ssh_host_rsa_key.pub
/root/.ssh/
EOF

cp -f patches/rc.local "$TMPDIR/etc/" && \
cp -f patches/99-custom.conf "$TMPDIR/etc/sysctl.d/" && \
cp -f patches/cpustat "$TMPDIR/usr/bin/" && chmod 755 "$TMPDIR/usr/bin/cpustat" && \
cp -f patches/getcpu "$TMPDIR/bin/" && chmod 755 "$TMPDIR/bin/getcpu" && \
cp -f patches/coremark.sh "$TMPDIR/etc/" && chmod 755 "$TMPDIR/etc/coremark.sh"
cp -f patches/kmod "$TMPDIR/sbin/" && \
	(
            cd $TMPDIR/sbin && \
		 chmod 755 kmod && \
                 rm insmod lsmod modinfo modprobe rmmod && \
		 ln -s kmod insmod && \
		 ln -s kmod lsmod && \
		 ln -s kmod modinfo && \
		 ln -s kmod modprobe && \
		 ln -s kmod rmmod 
	)

cat patches/luci-admin-status-index-html.patch | (cd "$TMPDIR/" && patch -p1) && \
	cat patches/luci-admin-status-index-html-02.patch | (cd "$TMPDIR/" && patch -p1)
	
cat patches/init.d_turboacc.patch | (cd "$TMPDIR/" && patch -p1 )
if ! cat patches/cbi_turboacc_new.patch | (cd "$TMPDIR/" && patch -p1 );then
    cat patches/cbi_turboacc.patch | (cd "$TMPDIR/" && patch -p1 )
    ( find "$TMPDIR" -name '*.rej' -exec rm {} \; 
      find "$TMPDIR" -name '*.orig' -exec rm {} \;
    )
fi
sed -e "s/hw_flow '1'/hw_flow '0'/" -i $TMPDIR/etc/config/turboacc
sed -e "s/sfe_flow '1'/sfe_flow '0'/" -i $TMPDIR/etc/config/turboacc

rm -f "$TMPDIR/etc/bench.log" && \
echo "17 3 * * * /etc/coremark.sh" >> "$TMPDIR/etc/crontabs/root"

[ -f ${TMPDIR}/etc/config/qbittorrent ] && sed -e 's/\/opt/\/etc/' -i "${TMPDIR}/etc/config/qbittorrent"

[ -f ${TMPDIR}/etc/ssh/sshd_config ] && sed -e "s/#PermitRootLogin prohibit-password/PermitRootLogin yes/" -i "${TMPDIR}/etc/ssh/sshd_config"

[ -f ${TMPDIR}/etc/samba/smb.conf.template ] && cat patches/smb4.11_enable_smb1.patch | (cd "$TMPDIR" && [ -f etc/samba/smb.conf.template ] && patch -p1)

	
#cp -f patches/rc.local "$TMPDIR/etc/" && \
#cp -f patches/cpustat "$TMPDIR/usr/bin/" && chmod 755 "$TMPDIR/usr/bin/cpustat" && \
#cp -f patches/getcpu "$TMPDIR/bin/" && chmod 755 "$TMPDIR/bin/getcpu" && \
#cat patches/luci-admin-status-index-html.patch | (cd "$TMPDIR/usr/lib/lua/luci/view/admin_status/" && patch -p0) && \
#rm -f "$TMPDIR/etc/bench.log" && \
#sed -e 's/\/opt/\/etc/' -i "${TMPDIR}/etc/config/qbittorrent" && \
#sed -e "s/#PermitRootLogin prohibit-password/PermitRootLogin yes/" -i "${TMPDIR}/etc/ssh/sshd_config" && \
sss=$(date +%s) && \
ddd=$((sss/86400)) && \
sed -e "s/:0:0:99999:7:::/:${ddd}:0:99999:7:::/" -i "${TMPDIR}/etc/shadow" && \
sed -e "s/root::/root:\$1\$0yUsq67p\$RC5cEtaQpM6KHQfhUSIAl\.:/" -i "${TMPDIR}/etc/shadow"

sed -i '/DISTRIB_REVISION/d' "${TMPDIR}/etc/openwrt_release" && \
echo "DISTRIB_REVISION='R23.4.4'" >> "${TMPDIR}/etc/openwrt_release" && \
sed -i '/DISTRIB_DESCRIPTION/d' "${TMPDIR}/etc/openwrt_release" && \
echo "DISTRIB_DESCRIPTION='OpenWrt'" >> "${TMPDIR}/etc/openwrt_release" && \

#echo "17 3 * * * /etc/coremark.sh" >> "$TMPDIR/etc/crontabs/root" && \
#rm -rf "$TMPDIR/lib/firmware/*" "$TMPDIR/lib/modules/*" && \

(cd "$TMPDIR" && tar cf ../openwrt-armvirt-64-default-rootfs.tar .) && \
rm -f DockerImg-OpenwrtArm64-${TAG}.gz && \
#docker build -t ${IMG_NAME}:${TAG} . && \
docker buildx build --no-cache --platform=linux/arm64 -o type=docker -t ${IMG_NAME}:${TAG} . && \
rm -f  openwrt-armvirt-64-default-rootfs.tar && \
rm -rf "$TMPDIR" && \
docker save ${IMG_NAME}:${TAG} | pigz -9 > $OUTDIR/docker-img-openwrt-aarch64-${TAG}.gz
