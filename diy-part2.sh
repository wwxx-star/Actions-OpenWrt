#!/bin/bash
#
# Copyright (c) 2019-2020 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part2.sh
# Description: OpenWrt DIY script part 2 (After Update feeds)
#

# Modify default IP
sed -i 's/192.168.1.1/192.168.7.1/g' package/base-files/files/bin/config_generate

git clone https://github.com/xiaorouji/openwrt-passwall-packages.git package/passwall/packages
git clone https://github.com/xiaorouji/openwrt-passwall.git package/passwall/luci
# #git clone -b master  https://github.com/vernesong/OpenClash.git package/luci-app-openclash
# #git clone https://github.com/Leslie-Wong/luci-app-passwall.git package/passwall/luci/luci-app-passwall
# #git clone https://github.com/Yangself666/luci-app-passwall.git package/passwall/luci
# # git clone https://github.com/xiaoxiao29/luci-app-adguardhome.git  package/luci-app-adguardhome 
# #git clone https://github.com/XiaoBinin/luci-app-adguardhome  package/luci-app-adguardhome 
# #git clone  https://github.com/Zane-E/luci-app-adguardhome.git  package/luci-app-adguardhome
# #git clone --depth=1 https://github.com/fw876/helloworld.git package/helloworld
# #git clone https://github.com/wwxx-star/openwrt-packages1  package/openwrt-packages

./scripts/feeds update -a
./scripts/feeds install -a
