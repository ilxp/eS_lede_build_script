#!/bin/bash -e

#######OprX的相关优化#######
#一、定义克隆功能函数
#第一种
#git clone -b 分支 --single-branch 仓库地址 到本地目录（如：package/文件名 #文件名不能相同）
#cd  package/文件名  #主注意目录级别（此处为二级，退出为cd ../..  一级：./diydata  退出为 cd ..  三级 package/文件名1/文件名2 退出为cd ../../..）
#git sparse-checkout init --cone 
#git sparse-checkout set 目标文件  #可以一级或者二级，三级，多个目录用空格隔开。注意是连上级目录一起。
#cd ../..  #退出本地目录（）
#例如1
#git clone -b main --single-branch https://github.com/ilxp/eS_lede_build_script.git ./diydata
#cd  ./diydata
#git sparse-checkout init --cone 
#git sparse-checkout set openwrt/data
#rm -rf .git
#rm -rf .github
#rm -rf .gitignore
#rm -rf *.md
#rm -rf .gitattributes
#rm -rf LICENSE
#cd ..

#例如2
#git clone -b master --single-branch https://github.com/QiuSimons/OpenWrt-Add.git package/add
#cd  package/add
#git sparse-checkout init --cone 
#git sparse-checkout set addition-trans-zh
#rm -rf .git
#rm -rf .github
#rm -rf .gitignore
#rm -rf *.md
#rm -rf .gitattributes
#rm -rf LICENSE
#cd ../..
#复制default-settings文件
#cp -f ./diydata/openwrt/data/default-settings-oR package/add/addition-trans-zh/files/zzz-default-settings


#第二种  来源https://github.com/Jejz168/OpenWrt
mkdir package/new
function merge_package() {
	# 参数1是分支名,参数2是库地址,参数3是所有文件下载到指定路径。
	# 同一个仓库下载多个文件夹直接在后面跟文件名或路径，空格分开。
	# 示例:
	# merge_package 分支 仓库地址 下载到指定路径(已存在或者自定义) 目标文件（多个空格分开）
	# 下载到不存在的目录时: rm -rf package/new; mkdir package/new
	# merge_package master https://github.com/WYC-2020/openwrt-packages package/openwrt-packages luci-app-eqos luci-app-openclash luci-app-ddnsto ddnsto 
	# merge_package master https://github.com/lisaac/luci-app-dockerman package/lean applications/luci-app-dockerman #结果是将luci-app-dockerman放在package/lean下
	# merge_package main https://github.com/linkease/nas-packages-luci package/new luci/luci-app-ddnsto  #结果是package/new/luci-app-ddnsto
	# merge_package master https://github.com/linkease/nas-packages package/new network/services/ddnsto  #结果是package/new/ddnsto 
	# merge_package master https://github.com/coolsnowwolf/lede package/kernel package/kernel/mac80211  #将目标仓库的package/kernel/mac80211克隆到本地package/kernel下
	#merge_package main https://github.com/Lienol/openwrt.git  ./tools tools/ucl tools/upx  #表示在根目录生成一个tools文件夹。本来就会有，所以报错。
    #merge_package main https://github.com/Lienol/openwrt.git tools tools/ucl tools/upx  #表示目标目录tool下的ucl和upx移动到根目录已经存在的tools文件夹。
	if [[ $# -lt 3 ]]; then
		echo "Syntax error: [$#] [$*]" >&2
		return 1
	fi
	trap 'rm -rf "$tmpdir"' EXIT
	branch="$1" curl="$2" target_dir="$3" && shift 3
	rootdir="$PWD"
	localdir="$target_dir"
	[ -d "$localdir" ] || mkdir -p "$localdir"
	tmpdir="$(mktemp -d)" || exit 1
        echo "开始下载：$(echo $curl | awk -F '/' '{print $(NF)}')"
	git clone -b "$branch" --depth 1 --filter=blob:none --sparse "$curl" "$tmpdir"
	cd "$tmpdir"
	git sparse-checkout init --cone
	git sparse-checkout set "$@"
	# 使用循环逐个移动文件夹
	for folder in "$@"; do
		mv -f "$folder" "$rootdir/$localdir"
	done
	cd "$rootdir"
}
###################

#二、导入自己data目录数据配置 【注意结果是./diydata/openwrt/data】

#配置文件	
#采用本地复制
#cp -rf ./diydata/openwrt/data/files ./package/base-files/
#cp -rf ./diydata/openwrt/data/files  files
#自定义app
#cp -rf ./diydata/openwrt/data/app/*  ./

#采用网络复制
merge_package main https://github.com/ilxp/eS_lede_build_script ./diydata openwrt/data   #注意结果是./diydata/data）
cp -rf ./diydata/data/files ./package/base-files/
#cp -rf ./diydata/data/files  files
#自定义app
cp -rf ./diydata/data/app/*  ./
#初始化文件

#Default-settings系统配置
#克隆default-settings 【采用lede默认的】
#merge_package master https://github.com/QiuSimons/OpenWrt-Add.git package/new addition-trans-zh
#复制default-settings文件
cp -f ./diydata/data/default-settings-eS package/lean/default-settings/files/zzz-default-settings

#三、编译出错的######【注意，609行编译解锁网易云音乐  只能用luci自带的，其余安装不上】
#替换grub2 【lede的编译出错】
rm -rf package/boot/grub2
merge_package openwrt-25.12 https://github.com/openwrt/openwrt.git package/boot package/boot/grub2
# grub2 -  disable `gc-sections` flag
sed -i '/PKG_BUILD_FLAGS/ s/$/ no-gc-sections/' package/boot/grub2/Makefile

rm -rf package/network/services/hostapd
merge_package openwrt-25.12 https://github.com/openwrt/openwrt.git package/network/services package/network/services/hostapd

rm -rf package/libs/ustream-ssl
merge_package openwrt-25.12 https://github.com/openwrt/openwrt.git package/libs package/libs/ustream-ssl

#ath10k-ct  报错
#rm -rf package/kernel/ath10k-ct
#merge_package openwrt-25.12 https://github.com/openwrt/openwrt.git  package/kernel package/kernel/ath10k-ct

###################

#四、系统优化########

# BBRv3  lede无法使用并且导致1天后无法登陆
#cp -rf ./diydata/data/bbr3-yaof6.6/* ./target/linux/generic/backport-6.12/
#修改turboacc的依赖 bbr为bbr3
#sed -i 's/kmod-tcp-bbr/kmod-tcp-bbr3/g' feeds/luci/applications/luci-app-turboacc/Makefile

# Modules  （package/kernel/linux/modules）  
#rm -rf package/kernel/linux/modules/hwmon.mk #修改CONFIG_ALL_KMODS
#rm -rf package/kernel/linux/modules/netsupport.mk   #tcp-bbr为tcp-bbr3
#cp -rf ./diydata/data/modules-lede/hwmon.mk ./package/kernel/linux/modules/
#cp -rf ./diydata/data/modules-lede/netsupport.mk ./package/kernel/linux/modules/

# kenrel Vermagic （安装ipk需要内核验证）即sbwml的 01-prepare_base-mainline.sh中的代码
sed -ie 's/^\(.\).*vermagic$/\1cp $(TOPDIR)\/.vermagic $(LINUX_DIR)\/.vermagic/' include/kernel-defaults.mk
#grep HASH include/kernel-6.12 | awk -F'HASH-' '{print $2}' | awk '{print $1}' | md5sum | awk '{print $1}' > .vermagic
grep HASH include/kernel-$kernel_version | awk -F'HASH-' '{print $2}' | awk '{print $1}' | md5sum | awk '{print $1}' > .vermagic

# Optimization level -Ofast
#sed -i 's/Os/O2/g' include/target.mk
#sed -i 's/Os/O2 -march=x86-64-v2/g' include/target.mk
sed -i 's/Os/O3 -mtune=generic/g' include/target.mk  #sbwml的target-modify_for_x86_64.patch代码

# All-komd -Fix x86 - CONFIG_ALL_KMODS（lede无法使用导致编译b53失败。已经失效，已经改在data/hwmon.mk）
#sed -i 's/hwmon, +PACKAGE_kmod-thermal:kmod-thermal/hwmon/g' package/kernel/linux/modules/hwmon.mk

# 固件版本号(21.3.2 %y : 年份的最后两位数字)
#date=`TZ=UTC-8 date +%m.%d.%Y`  #升级用，统一这样
ReV_Date=`TZ=UTC-8 date +%y.%-m.%-d`  #24年1月1日：24.1.1  #以上引用不用带{}，即$ReV_Date
#ReV_Date=$(TZ=UTC-8 date +'%y.%-m.%-d')  #这个引用要带{}，即${ReV_Date}
Build_DATE=$(TZ=UTC-8 date +'%Y%m%d')  #这个引用要带{}，即${Build_DATE} 
sed -i -e "/\(# \)\?REVISION:=/c\REVISION:=$ReV_Date" -e '/VERSION_CODE:=/c\VERSION_CODE:=$(REVISION)' include/version.mk  
#sed -i "s/DISTRIB_DESCRIPTION.*/DISTRIB_DESCRIPTION='LEDE eS%C @${Build_DATE}'/g" package/base-files/files/etc/openwrt_release
sed -i "s/DISTRIB_DESCRIPTION.*/DISTRIB_DESCRIPTION='eS built by ilxp@'/g" package/base-files/files/etc/openwrt_release  #lede新的luci-23.05加入会%c重复

# 固件的命名格式
##去版本号:openwrt-23.05.2-x86-64或者openwrt-23.05-snapshot-r0-60e49cf-x86-64改为openwrt-x86-64
sed -i 's/IMG_PREFIX:=$(VERSION_DIST_SANITIZED)-$(IMG_PREFIX_VERNUM)$(IMG_PREFIX_VERCODE)$(IMG_PREFIX_EXTRA)/IMG_PREFIX:=$(VERSION_DIST_SANITIZED)-/g' include/image.mk

##采用kiddin9大神的gpsysupgrade升级方式：https://github.com/ilxp/openwrt-gpsysupgrade-kiddin9：
#格式：10.23.2024-oprx-eS-x86-64-generic-squashfs-combined-efi.img.gz   #eS是固件分类标签
#sed -i 's/IMG_PREFIX:=$(VERSION_DIST_SANITIZED)/IMG_PREFIX:=$(shell date +%m.%d.%Y)-oprx-eS/g' include/image.mk  #在bulid.sh统一命名

# 登陆ip以及主机名【在default-setting中配置】
#sed -i "s/192.168.1.1/192.168.8.1/" package/base-files/files/bin/config_generate
#sed -i "s/LEDE/OprX/g" package/base-files/files/bin/config_generate
# 修改主机名openwrt为OprX （将系统所有包含openwrt改为oprx，慎用）
#sed -i "s/OpenWrt/OprX/g" package/base-files/files/bin/config_generate package/base-files/image-config.in config/Config-images.in Config.in include/u-boot.mk include/version.mk package/network/config/wifi-scripts/files/lib/wifi/mac80211.sh || true

# 内核版本【尽量不要修改，好komd】
#sed -i 's/KERNEL_PATCHVER:=6.12/KERNEL_PATCHVER:=6.6/g' target/linux/x86/Makefile

# 网络连接数
#sed -i 's/net.netfilter.nf_conntrack_max=16384/net.netfilter.nf_conntrack_max=65535/g' package/kernel/linux/files/sysctl-nf-conntrack.conf
echo -e "\nnet.netfilter.nf_conntrack_max=65535" >> package/kernel/linux/files/sysctl-nf-conntrack.conf

# Containerd修复依赖
sed -i 's/PKG_HASH.*/PKG_HASH:=skip/' feeds/packages/utils/containerd/Makefile

# Fix mt76 wireless driver
pushd package/kernel/mt76
sed -i '/mt7662u_rom_patch.bin/a\\techo mt76-usb disable_usb_sg=1 > $\(1\)\/etc\/modules.d\/mt76-usb' Makefile
popd

# ===Kiddin9大神的===for openwrt
#sed -i 's/=bbr/=cubic/' package/kernel/linux/files/sysctl-tcp-bbr.conf
#for X—86
sed -i 's/kmod-r8169/kmod-r8168/' target/linux/x86/image/64.mk

# ===Jejz168大神优化===for lede  https://github.com/Jejz168/OpenWrt
# 设置密码为空（安装固件时无需密码登陆，然后自己修改想要的密码）
#sed -i '/$1$V4UetPzk$CYXluq4wUazHjmCDBCqXF./d' package/lean/default-settings/files/zzz-default-settings

# 调整 x86 型号只显示 CPU 型号
sed -i 's/${g}.*/${a}${b}${c}${d}${e}${f}${hydrid}/g' package/lean/autocore/files/x86/autocore

# 修改版本号
#sed -i "s|DISTRIB_REVISION='.*'|DISTRIB_REVISION='R$(date +%y.%-m.%-d)'|g" package/lean/default-settings/files/zzz-default-settings

# 设置ttyd免帐号登录
sed -i 's/\/bin\/login/\/bin\/login -f root/' feeds/packages/utils/ttyd/files/ttyd.config

# Shell 为 bash 【在zsh中统一修改】
#sed -i 's/\/bin\/ash/\/bin\/bash/g' package/base-files/files/etc/passwd

# 精简 UPnP 菜单名称
sed -i 's#\"title\": \"UPnP IGD \& PCP/NAT-PMP\"#\"title\": \"UPnP\"#g' feeds/luci/applications/luci-app-upnp/root/usr/share/luci/menu.d/luci-app-upnp.json
sed -i 's,UPnP IGD 和 PCP,UPnP,g' feeds/luci/applications/luci-app-upnp/po/zh_Hans/upnp.po

# Samba解除root限制
sed -i 's/invalid users = root/#&/g' feeds/packages/net/samba4/files/smb.conf.template

# Coremark跑分定时清除
sed -i '/\* \* \* \/etc\/coremark.sh/d' feeds/packages/utils/coremark/*

# 最大连接数修改为65535
#sed -i '$a net.netfilter.nf_conntrack_max=65535' package/base-files/files/etc/sysctl.conf

#Nlbwmon 修复log警报
sed -i '$a net.core.wmem_max=16777216' package/base-files/files/etc/sysctl.conf
sed -i '$a net.core.rmem_max=16777216' package/base-files/files/etc/sysctl.conf

# 显示增加编译时间
#pushd package/lean/default-settings/files
#export orig_version=$(cat "zzz-default-settings" | grep DISTRIB_REVISION= | awk -F "'" '{print $2}')
#export date_version="By @Jejz build $(TZ=UTC-8 date '+%Y-%m-%d %H:%M')"
#sed -i "s/${orig_version}/${orig_version} (${date_version})/g" zzz-default-settings
#popd
#echo -e "\e[41m当前写入的编译时间:\e[0m \e[33m$(grep 'DISTRIB_REVISION=' package/lean/default-settings/files/zzz-default-settings)\e[0m"

# 修改makefile
find package/*/ -maxdepth 2 -path "*/Makefile" | xargs -i sed -i 's/include\ \.\.\/\.\.\/luci\.mk/include \$(TOPDIR)\/feeds\/luci\/luci\.mk/g' {}
find package/*/ -maxdepth 2 -path "*/Makefile" | xargs -i sed -i 's/include\ \.\.\/\.\.\/lang\/golang\/golang\-package\.mk/include \$(TOPDIR)\/feeds\/packages\/lang\/golang\/golang\-package\.mk/g' {}
find package/*/ -maxdepth 2 -path "*/Makefile" | xargs -i sed -i 's/PKG_SOURCE_URL:=\@GHREPO/PKG_SOURCE_URL:=https:\/\/github\.com/g' {}
find package/*/ -maxdepth 2 -path "*/Makefile" | xargs -i sed -i 's/PKG_SOURCE_URL:=\@GHCODELOAD/PKG_SOURCE_URL:=https:\/\/codeload\.github\.com/g' {}

#udpxy汉化      
cp -f ./diydata/data/udpxy.js ./feeds/luci/applications/luci-app-udpxy/htdocs/luci-static/resources/view

#=============== 以上来源骷髅头大神================

###############相关luci应用#############################
#一）、主题
#1）argon主题（18.06分支适合lean的lede是luci18）
rm -rf feeds/luci/themes/luci-theme-argon
git clone -b master https://github.com/jerrykuku/luci-theme-argon.git package/diy/luci-theme-argon

#2）修改 argon 为默认主题
sed -i '/set luci.main.mediaurlbase=\/luci-static\/bootstrap/d' feeds/luci/themes/luci-theme-bootstrap/root/etc/uci-defaults/30_luci-theme-bootstrap
sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' ./feeds/luci/collections/luci/Makefile
sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci-nginx/Makefile

#二）、翻墙系列（lede编译系统自带为SSR-Plus+openclash）
rm -rf feeds/packages/net/shadowsocks-libev
#1、ssr-plus
rm -rf package/new/helloworld
rm -rf feeds/luci/applications/luci-app-ssr-plus
git clone https://github.com/fw876/helloworld.git package/helloworld

#kenzok8的small库
#git clone https://github.com/kenzok8/small.git package/helloworld

# sbwml的SSRP & Passwall
#rm -rf feeds/packages/net/{xray-core,v2ray-core,v2ray-geodata,sing-box}
#git clone https://github.com/sbwml/openwrt_helloworld package/helloworld -b v5

##FQ全部调到VPN菜单
sed -i 's/services/vpn/g' package/helloworld/luci-app-ssr-plus/luasrc/controller/*.lua
sed -i 's/services/vpn/g' package/helloworld/luci-app-ssr-plus/luasrc/model/cbi/shadowsocksr/*.lua
sed -i 's/services/vpn/g' package/helloworld/luci-app-ssr-plus/luasrc/view/shadowsocksr/*.htm

#解决缺乏libopenssl-legacy依赖
#sed -i 's/ +libopenssl-legacy//g' package/helloworld/shadowsocksr-libev/Makefile

#2、passwall
#克隆官方的
#rm -rf feeds/luci/applications/luci-app-passwall
#git clone -b main https://github.com/xiaorouji/openwrt-passwall-packages.git package/diy/openwrt-passwall-packages
#git clone -b main https://github.com/xiaorouji/openwrt-passwall.git  package/diy/openwrt-passwall
# passwall
#merge_package main https://github.com/xiaorouji/openwrt-passwall package/custom luci-app-passwall

#采用kenzok8的small库
#git clone https://github.com/kenzok8/small.git package/diy/openwrt-passwall

##FQ全部调到VPN菜单
#sed -i 's/services/vpn/g' package/diy/openwrt-passwall/luci-app-passwall/luasrc/controller/*.lua
#sed -i 's/services/vpn/g' package/diy/openwrt-passwall/luci-app-passwall/luasrc/passwall/*.lua
#sed -i 's/services/vpn/g' package/diy/openwrt-passwall/luci-app-passwall/luasrc/model/cbi/passwall/client/*.lua
#sed -i 's/services/vpn/g' package/diy/openwrt-passwall/luci-app-passwall/luasrc/model/cbi/passwall/server/*.lua
#sed -i 's/services/vpn/g' package/diy/openwrt-passwall/luci-app-passwall/luasrc/view/passwall/app_update/*.htm
#sed -i 's/services/vpn/g' package/diy/openwrt-passwall/luci-app-passwall/luasrc/view/passwall/socks_auto_switch/*.htm
#sed -i 's/services/vpn/g' package/diy/openwrt-passwall/luci-app-passwall/luasrc/view/passwall/global/*.htm
#sed -i 's/services/vpn/g' package/diy/openwrt-passwall/luci-app-passwall/luasrc/view/passwall/haproxy/*.htm
#sed -i 's/services/vpn/g' package/diy/openwrt-passwall/luci-app-passwall/luasrc/view/passwall/log/*.htm
#sed -i 's/services/vpn/g' package/diy/openwrt-passwall/luci-app-passwall/luasrc/view/passwall/node_list/*.htm
#sed -i 's/services/vpn/g' package/diy/openwrt-passwall/luci-app-passwall/luasrc/view/passwall/rule/*.htm
#sed -i 's/services/vpn/g' package/diy/openwrt-passwall/luci-app-passwall/luasrc/view/passwall/server/*.htm
# Passwall 白名单
#echo '
#teamviewer.com
#epicgames.com
#dangdang.com
#account.synology.com
#ddns.synology.com
#checkip.synology.com
#checkip.dyndns.org
#checkipv6.synology.com
#ntp.aliyun.com
#cn.ntp.org.cn
#ntp.ntsc.ac.cn
#' >>./package/diy/openwrt-passwall/luci-app-passwall/root/usr/share/passwall/rules/direct_host

#3、clash（不编译luci，只编译带内核）
#1）openclash
rm -rf feeds/luci/applications/luci-app-openclash
rm -rf package/helloworld/luci-app-openclash
#sed -i '$a src-git openclash https://github.com/vernesong/OpenClash.git' feeds.conf.default
#注意master对应core打分master的分支，dev对应core的dev，
git clone -b master --single-branch https://github.com/vernesong/OpenClash.git  package/diy/openclash
# 添加内核（新版只支持meta内核）
wget https://github.com/vernesong/OpenClash/raw/core/master/meta/clash-linux-amd64-v1.tar.gz&&tar -zxvf *.tar.gz
chmod 0755 clash
rm -rf *.tar.gz&&mkdir -p package/base-files/files/etc/openclash/core&&mv clash package/base-files/files/etc/openclash/core/clash_meta
chmod +x package/base-files/files/etc/openclash/core/clash*
##FQ全部调到VPN菜单
sed -i 's/services/vpn/g' package/diy/openclash/luci-app-openclash/luasrc/controller/*.lua
sed -i 's/services/vpn/g' package/diy/openclash/luci-app-openclash/luasrc/*.lua
sed -i 's/services/vpn/g' package/diy/openclash/luci-app-openclash/luasrc/model/cbi/openclash/*.lua
sed -i 's/services/vpn/g' package/diy/openclash/luci-app-openclash/luasrc/view/openclash/*.htm

# DHDAXCW骷髅头的preset-clash-core.sh
#mkdir -p package/base-files/files/etc/openclash/core
#CLASH_DEV_URL="https://raw.githubusercontent.com/vernesong/OpenClash/core/master/dev/clash-linux-${1}.tar.gz"
#CLASH_TUN_URL=$(curl -fsSL https://api.github.com/repos/vernesong/OpenClash/contents/master/premium\?ref\=core | grep download_url | grep $1 | awk -F '"' '{print $4}' | grep -v "v3" )
#CLASH_META_URL="https://raw.githubusercontent.com/vernesong/OpenClash/core/master/meta/clash-linux-${1}.tar.gz"
GEOIP_URL="https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat"
GEOSITE_URL="https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat"
#wget -qO- $CLASH_DEV_URL | tar xOvz > package/base-files/files/etc/openclash/core/clash
#wget -qO- $CLASH_TUN_URL | gunzip -c > package/base-files/files/etc/openclash/core/clash_tun
#wget -qO- $CLASH_META_URL | tar xOvz > package/base-files/files/etc/openclash/core/clash_meta
#wget -qO- $GEOIP_URL > package/base-files/files/etc/openclash/GeoIP.dat #提示已经存在，无法编译
#wget -qO- $GEOSITE_URL > package/base-files/files/etc/openclash/GeoSite.dat #提示已经存在，无法编译
#chmod +x package/base-files/files/etc/openclash/core/clash*

# 4、mihomo nikki（只支持firewall4.lede无望）
#git clone --depth=1 https://github.com/nikkinikki-org/OpenWrt-nikki package/diy/OpenWrt-nikki
#sed -i 's/services/vpn/g' package/diy/OpenWrt-nikki/luci-app-nikki/root/usr/share/luci/menu.d/luci-app-mihomo.json

# 5、homeproxy（只支持firewall4.lede无望）
#git clone --depth=1 https://github.com/muink/luci-app-homeproxy.git package/diy/luci-app-homeproxy
#git clone --depth=1 https://github.com/immortalwrt/homeproxy.git package/diy/luci-app-homeproxy
#rm -rf ./feeds/packages/net/sing-box
#依赖组件
#merge_package v5 https://github.com/sbwml/openwrt_helloworld.git package/new chinadns-ng sing-box

#三）、istore应用商店
#istorex与quickstart
#git clone https://github.com/linkease/nas-packages.git  package/diy/nas-packages #quickstart
#git clone https://github.com/linkease/nas-packages-luci.git  package/diy/nas-packages-luci  
#istore
git clone https://github.com/linkease/istore.git  package/diy/istore
git clone https://github.com/linkease/istore-ui.git  package/diy/istore-ui
rm -rf package/diy/istore-ui/app-store-ui/src/dist/luci-static/istore/i18n/en.json

#四）、sirpdboy大神的相关插件
#中文netdata
rm -rf feeds/luci/applications/luci-app-netdata
git clone https://github.com/sirpdboy/luci-app-netdata.git package/diy/luci-app-netdata

#网络设置向导
git clone https://github.com/sirpdboy/luci-app-netwizard.git package/diy/netwizard
sed -i 's/Netwizard/设置向导/g' package/diy/netwizard/luci-app-netwizard/luasrc/controller/netwizard.lua
sed -i 's/eth1/eth0/g' package/diy/netwizard/luci-app-netwizard/root/etc/init.d/netwizard

#网络速度测试
git clone -b js https://github.com/sirpdboy/netspeedtest.git package/diy/netspeedtest
sed -i 's/NetSpeedtest/网络测速/g' package/diy/netspeedtest/luci-app-netspeedtest/root/usr/share/luci/menu.d/luci-app-netspeedtest.json

#任务设置（会产生一个control管控栏目）
rm -rf package/sirpdboy/luci-app-taskplan
git clone https://github.com/sirpdboy/luci-app-taskplan package/diy/taskplan
sed -i 's/Task Plan/任务设置/g' package/diy/taskplan/luci-app-taskplan/luasrc/controller/taskplan.lua
sed -i 's/Control/管控/g' package/diy/taskplan/luci-app-taskplan/luasrc/controller/taskplan.lua

#关机  编译不成功采用esir的
#git clone https://github.com/sirpdboy/luci-app-poweroffdevice package/diy/luci-app-poweroffdevice
#关机 poweroff（esir大神）
git clone https://github.com/esirplayground/luci-app-poweroff package/diy/luci-app-poweroff
sed -i 's/PowerOff/关机/g' package/diy/luci-app-poweroff/luasrc/controller/poweroff.lua

#家长控制（会生成Control管控栏目） #无法运行
#git clone https://github.com/sirpdboy/luci-app-parentcontrol package/diy/luci-app-parentcontrol
git clone https://github.com/ilxp/luci-app-parentcontrol package/diy/luci-app-parentcontrol
sed -i 's/Parent Control/家长控制/g' package/diy/luci-app-parentcontrol/luasrc/controller/parentcontrol.lua
sed -i 's/Control/管控/g' package/diy/luci-app-parentcontrol/luasrc/controller/parentcontrol.lua

#自动扩容分区
git clone https://github.com/sirpdboy/luci-app-partexp package/diy/partexp
sed -i 's/Partition Expansion/分区扩容/g' package/diy/partexp/luci-app-partexp/luasrc/controller/partexp.lua
#rm -rf package/diy/luci-app-partexp/po/zh_Hans  #sbwml上不能删除
sed -i 's, - !, -o !,g' package/diy/partexp/luci-app-partexp/root/etc/init.d/partexp
sed -i 's,expquit 1 ,#expquit 1 ,g' package/diy/partexp/luci-app-partexp/root/etc/init.d/partexp

#ddns-go
rm -rf feeds/packages/net/ddns-go
rm -rf feeds/luci/applications/luci-app-ddns-go
git clone https://github.com/sirpdboy/luci-app-ddns-go package/diy/luci-app-ddns-go

#luck
#rm -rf feeds/packages/net/lucky
#rm -rf feeds/luci/applications/luci-app-lucky #采用luci里的，其他安装不上.故改用ddns-go
#git clone https://github.com/gdy666/luci-app-lucky package/diy/op-lucky
#默认不开启
#sed -i 's/enabled '1'/enabled '0'/g' package/diy/op-lucky/lucky/files/luckyuci
 
#git clone https://github.com/sirpdboy/luci-app-lucky package/diy/op-lucky

#高级设置
git clone https://github.com/sirpdboy/luci-app-advanced.git package/diy/luci-app-advanced
#rm -rf package/diy/luci-app-advanced/htdocs #不能删除

##五）QOS相关
#石像鬼qos采用我自己的，会有一个QOS栏目生成
#git clone -b openwrt-2305 https://github.com/ilxp/gargoyle-qos-openwrt.git  package/diy/gargoyle-qos-openwrt
#sed -i 's/Gargoyle QoS/石像鬼 QoS/g' package/diy/gargoyle-qos-openwrt/luci-app-qos-gargoyle/luasrc/controller/qos_gargoyle.lua
#sed -i 's/Download Settings/下载设置/g' package/diy/gargoyle-qos-openwrt/luci-app-qos-gargoyle/luasrc/controller/qos_gargoyle.lua
#sed -i 's/Upload Settings/上传设置/g' package/diy/gargoyle-qos-openwrt/luci-app-qos-gargoyle/luasrc/controller/qos_gargoyle.lua
#wget -qO - https://raw.gitmirror.com/ilxp/gargoyle-qos-openwrt/openwrt-2203/010-revert_to_iptables.patch | patch -p1  #去除firwall4，用3

#2）eqos，采用luci自带的即可。把eqos放在管控下。不在列入Qos目录下
#rm -rf feeds/luci/applications/luci-app-eqos #lean库里没有eqos
#sed -i 's/network/QOS/g' feeds/luci/applications/luci-app-eqos/luasrc/controller/eqos.lua #将其移动到QOS或者control管控下
#git clone https://github.com/ilxp/luci-app-eqos.git  package/diy/luci-app-eqos  #我的会产生一个QOS栏目
#svn co https://github.com/kiddin9/openwrt-packages/trunk/eqos-master-wiwiz package/diy/luci-app-eqos
#sed -i 's/network/control/g' package/diy/luci-app-eqos/luasrc/controller/eqos.lua
#sed -i 's/EQoS/网速控制/g' package/diy/luci-app-eqos/luasrc/controller/eqos.lua
git clone https://github.com/sirpdboy/luci-app-eqosplus  package/diy/luci-app-eqosplus

#nft-qos
#rm -rf feeds/packages/net/nft-qos
#rm -rf feeds/luci/applications/luci-app-nft-qos
#git clone https://github.com/ilxp/openwrt-nft-qos.git  package/diy/openwrt-nft-qos
#merge_package master https://github.com/ilxp/openwrt-nft-qos.gi package/new luci-app-nft-qos nft-qos
#sed -i 's/services/qos/g' feeds/luci/applications/luci-app-nft-qos/luasrc/controller/nft-qos.lua   #将其移动到QOS目录下

#3)SQM
#sed -i 's/network/qos/g' feeds/luci/applications/luci-app-sqm/luasrc/controller/sqm.lua   #将其移动到QOS下
# SQM Translation
mkdir -p feeds/packages/net/sqm-scripts/patches
#curl -s https://init2.cooluc.com/openwrt/patch/sqm/001-help-translation.patch > feeds/packages/net/sqm-scripts/patches/001-help-translation.patch
cp -f ./diydata/data/sqm/001-help-translation.patch  feeds/packages/net/sqm-scripts/patches/001-help-translation.patch

#qosmate  需要nftables
git clone https://github.com/hudra0/luci-app-qosmate package/diy/luci-app-qosmate
git clone https://github.com/hudra0/qosmate package/diy/qosmate

#六）、DNS相关（lede带smartdns）
#1）smartdns（lede是lede的luci18-branch，master分支是js，lede的luci-23.05分支是js）
#rm -rf feeds/packages/net/smartdns
#rm -rf feeds/luci/applications/luci-app-smartdns
#git clone -b master https://github.com/pymumu/luci-app-smartdns.git package/diy/luci-app-smartdns  #官方的smartdns安装不上，只用luci库里的
#git clone https://github.com/pymumu/openwrt-smartdns.git package/diy/smartdns

mkdir -p package/base-files/files/etc/smartdns
#中国域名列表
#下载三个最新列表合并到cn.conf
wget -qO- "https://cdn.jsdelivr.net/gh/Loyalsoldier/v2ray-rules-dat@release/direct-list.txt"  >> package/base-files/files/etc/smartdns/cn.conf
wget -qO- "https://cdn.jsdelivr.net/gh/Loyalsoldier/v2ray-rules-datt@release/apple-cn.txt"    >> package/base-files/files/etc/smartdns/cn.conf
wget -qO- "https://cdn.jsdelivr.net/gh/Loyalsoldier/v2ray-rules-dat@release/google-cn.txt"   >> package/base-files/files/etc/smartdns/cn.conf
#去除full regexp并指定china组解析
sed "s/^full://g;s/^regexp:.*$//g;s/^/nameserver \//g;s/$/\/cn/g" -i package/base-files/files/etc/smartdns/cn.conf
chmod +x package/base-files/files/etc/smartdns/cn.conf

#广告域名列表
wget -qO- "https://cdn.jsdelivr.net/gh/Loyalsoldier/v2ray-rules-dat@release/reject-list.txt"  >> package/base-files/files/etc/smartdns/block.conf
wget -qO- "https://cdn.jsdelivr.net/gh/Loyalsoldier/v2ray-rules-dat@release/win-spy.txt"  >> package/base-files/files/etc/smartdns/block.conf
wget -qO- "https://cdn.jsdelivr.net/gh/Loyalsoldier/v2ray-rules-dat@release/win-extra.txt"  >> package/base-files/files/etc/smartdns/block.conf
sed "s/^full://g;s/^regexp:.*$//g;s/^/address \//g;s/$/\/#/g" -i package/base-files/files/etc/smartdns/block.conf
chmod +x package/base-files/files/etc/smartdns/block.conf

#2）mosdns【不支持lede了的luci18】
#rm -rf feeds/packages/net/mosdns
#rm -rf feeds/luci/applications/luci-app-mosdns
#rm -rf feeds/packages/net/v2ray-geodata
#git clone -b v5 --single-branch https://github.com/sbwml/luci-app-mosdns package/diy/luci-app-mosdns #需要v2ray-geodata依赖
#git clone -b master --single-branch https://github.com/QiuSimons/openwrt-mos  package/diy/openwrt-mos  #自带mosdns以及v2ray-geodata

#七、广告过滤
#1）adguardhome带核心安装。
rm -rf feeds/packages/net/adguardhome
rm -rf feeds/luci/applications/luci-app-adguardhome
rm -rf package/new/luci-app-adguardhome
#可以选择版本的luci-app-adguardhome
merge_package master https://github.com/Hyy2001X/AutoBuild-Packages.git package/new luci-app-adguardhome  
#kiddin9的luci-app-adguardhome
#merge_package main https://github.com/kiddin9/kwrt-packages.gitt package/new adguardhome r8101 luci-app-openvpn-server
#sed -i 's/services/vpn/g' package/kiddin/luci-app-openvpn-server/luasrc/controller/openvpn-server.lua
#git clone -b master --single-branch https://github.com/kiddin9/openwrt-adguardhome package/diy/openwrt-adguardhome #编译不成功

# 添加内核
#v0.107.X内核
latest_version="$(curl -s https://github.com/AdguardTeam/AdGuardHome/tags | grep -Eo "v[0-9\.]+\-*r*c*[0-9]*.tar.gz" | sed -n '/[0-9][0-9]/p' | sed -n 1p | sed 's/.tar.gz//g')"

#v0.108.X内核，api里面没有v0.107.
#latest_version="$(curl -s https://api.github.com/repos/AdguardTeam/AdGuardHome/tags | grep -Eo "v0.108.0-b.+[0-9\.]" | head -n 1)"
#解压缩
wget https://github.com/AdguardTeam/AdGuardHome/releases/download/${latest_version}/AdGuardHome_linux_amd64.tar.gz&&tar -zxvf *.tar.gz
chmod 0755 AdGuardHome
chmod 0755 AdGuardHome/AdGuardHome
rm -rf *.tar.gz&&mkdir -p package/base-files/files/usr/bin&&mv AdGuardHome/AdGuardHome package/base-files/files/usr/bin/ #软件包安装，不能带核心0.108，否则不能成功

#2）ikoolproxy与openssl
#由于openssl从1.1.1升级到了3.0.10导致ikoolproxy无法下载证书。故只能退回。https://github.com/coolsnowwolf/lede/commit/7494eb16185a176de226f55e842cadf94f1c5a11
#rm -rf package/libs/openssl
#rm -rf include/openssl-module.mk
#w版本
#git clone -b main --single-branch https://github.com/ilxp/opensslw.git  package/libs/openssl

#merge_package main https://github.com/ilxp/luci-app-ikoolproxy.git package/new luci-app-ikoolproxy
git clone -b main --single-branch https://github.com/ilxp/luci-app-ikoolproxy.git package/diy/luci-app-ikoolproxy

#3）dnsfilter过滤广告kiddin9大神
#git clone --depth 1 https://github.com/kiddin9/luci-app-dnsfilter package/diy/luci-app-dnsfilter

#七、管控相关
#1） APP 过滤
rm -rf feeds/packages/net/open-app-filter
git clone -b master --depth 1 https://github.com/destan19/OpenAppFilter.git package/diy/OpenAppFilter
sed -i 's/services/control/g' package/diy/OpenAppFilter/luci-app-oaf/luasrc/controller/appfilter.lua

#git clone -b master --depth 1 https://github.com/sbwml/OpenAppFilter.git  package/diy/OpenAppFilter
#sed -i 's/network/control/g' package/diy/OpenAppFilter/luci-app-oaf/luasrc/controller/appfilter.lua

#git clone -b master --depth 1 https://github.com/QiuSimons/OpenAppFilter-destan19  package/diy/OpenAppFilter
#sed -i 's/services/control/g' package/diy/OpenAppFilter/luci-app-oaf/luasrc/controller/appfilter.lua

#更新特征库
pushd package/diy/OpenAppFilter
#wget -qO - https://github.com/QiuSimons/OpenAppFilter-destan19/commit/9088cc2.patch | patch -p1 #失败
#wget https://www.openappfilter.com/assets/feature/feature2.0_cn_23.07.29.cfg -O ./open-app-filter/files/feature.cfg
wget https://github.com/ilxp/oaf/raw/main/feature.cfg -O ./open-app-filter/files/feature.cfg
popd
#翻译应用过滤
sed -i 's/App Filter/应用过滤/g' package/diy/OpenAppFilter/luci-app-oaf/luasrc/controller/appfilter.lua

#2、管控
rm -rf feeds/luci/applications/luci-app-control-webrestriction
rm -rf feeds/luci/applications/luci-app-accesscontrol
rm -rf feeds/luci/applications/luci-app-control-timewol
rm -rf feeds/luci/applications//luci-app-wol
rm -rf feeds/luci/applications/luci-app-control-weburl
rm -rf feeds/luci/applications/luci-app-timecontrol
rm -rf feeds/luci/applications/luci-app-filebrowser
rm -rf package/new/custom/luci-app-wolplus

rm -rf feeds/luci/applications/luci-app-openvpn-server  #采用lienol的，会生成一个vpn的栏目
merge_package main https://github.com/Lienol/openwrt-package.git package/new luci-app-openvpn-server

#采用我自己的control
git clone -b main --depth 1 https://github.com/ilxp/openwrt-control  package/diy/openwrt-control

#zxlhhyccc大佬的 修复无法运行问题。
#时间控制accesscontrol,timecontrol网络唤醒wolplus，访问限制webrestriction， 过滤控制weburl
#merge_package master https://github.com/zxlhhyccc/bf-package-master.git package/new zxlhhyccc/luci-app-wolplus lean/luci-app-accesscontrol zxlhhyccc/luci-app-control-webrestriction
#sed -i 's/services/control/g' package/new/luci-app-accesscontrol/luasrc/controller/mia.lua
#sed -i 's/Internet Access Schedule Control/上网时间控制/g' package/new/luci-app-accesscontrol/luasrc/controller/mia.lua

#sed -i 's/Control/管控/g' package/lienol/luci-app-control-webrestriction/luasrc/controller/webrestriction.lua
#sed -i 's/Control/管控/g' package/lienol/luci-app-control-weburl/luasrc/controller/weburl.lua
#sed -i 's/Internet Time Control/上网时间控制/g' package/lienol/luci-app-timecontrol/luasrc/controller/timecontrol.lua
#sed -i 's/Control/管控/g' package/lienol/luci-app-timecontrol/luasrc/controller/timecontrol.lua
#sed -i 's/Control/管控/g' package/lienol/luci-app-control-timewol/luasrc/controller/timewol.lua
#sed -i 's/File Browser/文件浏览器/g' package/lienol/luci-app-filebrowser/luasrc/controller/filebrowser.lua

#Lienol大佬的，无法运行
#merge_package main https://github.com/Lienol/openwrt-package.git package/new luci-app-control-webrestriction luci-app-control-weburl luci-app-timecontrol luci-app-control-timewol luci-app-filebrowser
#sed -i 's/Access Control/访问限制/g' package/new/luci-app-control-webrestriction/luasrc/controller/webrestriction.lua
#sed -i 's/Control/管控/g' package/new/luci-app-control-webrestriction/luasrc/controller/webrestriction.lua
#sed -i 's/Control/管控/g' package/new/luci-app-control-weburl/luasrc/controller/weburl.lua
#sed -i 's/Internet Time Control/上网时间控制/g' package/new/luci-app-timecontrol/luasrc/controller/timecontrol.lua
#sed -i 's/Control/管控/g' package/new/luci-app-timecontrol/luasrc/controller/timecontrol.lua
#sed -i 's/Control/管控/g' package/new/luci-app-control-timewol/luasrc/controller/timewol.lua
#sed -i 's/File Browser/文件浏览器/g' package/new/luci-app-filebrowser/luasrc/controller/filebrowser.lua

#采用lean的上网时间控制（23.05分支luci一直显示收集信息） 采用timecontrol
#rm -rf feeds/luci/applications/luci-app-accesscontrol
#sed -i 's/services/control/g' feeds/luci/applications/luci-app-accesscontrol/luasrc/controller/mia.lua
#merge_package openwrt-23.05 https://github.com/coolsnowwolf/luci.git  package/new applications/luci-app-accesscontrol
#sed -i 's/services/control/g' package/new/luci-app-accesscontrol/luasrc/controller/mia.lua
#sed -i 's/Internet Access Schedule Control/上网时间控制/g' package/new/luci-app-accesscontrol/luasrc/controller/mia.lua

#八、其他app
#1、turboacc去dns
#rm -rf feeds/luci/applications/luci-app-turboacc
#merge_package master https://github.com/xiangfeidexiaohuo/openwrt-packages.git package/new patch/luci-app-turboacc

#适配 firewall4 lede的luci23.05已经适配 firewall4
#merge_package luci https://github.com/chenmozhijin/turboacc.git package/new/turboacc luci-app-turboacc
#修改 bbr为bbr3
#sed -i 's/kmod-tcp-bbr/kmod-tcp-bbr3/g' package/new/turboacc/luci-app-turboacc/Makefile

#适lede的luci23.05已经适配 firewall4，#lede的在oR上安装，会让系统其他软件没有
#merge_package openwrt-24.10 https://github.com/coolsnowwolf/luci.git package/new applications/luci-app-turboacc
#修改 bbr为bbr3
#sed -i 's/kmod-tcp-bbr/kmod-tcp-bbr3/g' package/new/luci-app-turboacc/Makefile

#2、京东签到 By Jerrykuku 作者已关闭了
#git clone --depth 1 https://github.com/jerrykuku/node-request.git package/new/node-request
#git clone --depth 1 https://github.com/jerrykuku/luci-app-jd-dailybonus.git package/new/luci-app-jd-dailybonus

#3、网易云音乐解锁 js  【lede系列使用3.2的，新版】
rm -rf feeds/luci/applications/luci-app-unblockneteasemusic
rm -rf package/new/luci-app-unblockneteasemusic
git clone --depth 1 https://github.com/UnblockNeteaseMusic/luci-app-unblockneteasemusic.git package/new/luci-app-unblockneteasemusic
sed -i 's/解除网易云音乐播放限制/网易云音乐解锁/g' package/new/luci-app-unblockneteasemusic/root/usr/share/luci/menu.d/luci-app-unblockneteasemusic.json
sed -i 's, +node,,g' package/new/luci-app-unblockneteasemusic/Makefile
pushd package/new/luci-app-unblockneteasemusic
    wget -qO - https://github.com/UnblockNeteaseMusic/luci-app-unblockneteasemusic/commit/a880428.patch | patch -p1
popd

#4、filebrowser文件浏览器
#rm -rf feeds/luci/applications/luci-app-filebrowser
# filebrowser 文件浏览器
#merge_package main https://github.com/Lienol/openwrt-package package/custom luci-app-filebrowser
#sed -i 's/File Browser/文件浏览器/g' package/diy/luci-app-filebrowser/luasrc/controller/filebrowser.lua

#5、流量监视
git clone -b master --depth 1 https://github.com/brvphoenix/wrtbwmon.git package/new/wrtbwmon
git clone -b master --depth 1 https://github.com/brvphoenix/luci-app-wrtbwmon.git package/new/luci-app-wrtbwmon

#6、zerotier  #lede自带的已经是在vpn栏目
#rm -Rf feeds/luci/applications/luci-app-zerotier
#rm -Rf feeds/packages/net/zerotier #lede的版本新
#merge_package master https://github.com/coolsnowwolf/packages.git package/new net/zerotier 
#merge_package main https://github.com/sbwml/openwrt_pkgs.git package/new luci-app-zerotier
#移动搭配vpn栏目
#sed -i 's/services/vpn/g' package/new/luci-app-zerotier/root/usr/share/luci/menu.d/luci-app-zerotier.json

#7、终端ZSH工具
# DHDAXCW骷髅头的preset-terminal-tools.sh
mkdir -p files/root
pushd files/root
## Install oh-my-zsh
# Clone oh-my-zsh repository
git clone https://github.com/ohmyzsh/ohmyzsh ./.oh-my-zsh
# Install extra plugins
git clone https://github.com/zsh-users/zsh-autosuggestions ./.oh-my-zsh/custom/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ./.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-completions ./.oh-my-zsh/custom/plugins/zsh-completions
# Get .zshrc dotfile
cp ../.././diydata/data/zsh/.zshrc .
popd
# Change default shell to zsh将系统/bin/ash/改为/usr/bin/zsh
sed -i 's/\/bin\/ash/\/usr\/bin\/zsh/g' package/base-files/files/etc/passwd 
sed -i 's/\/bin\/bash/\/usr\/bin\/zsh/g' package/base-files/files/etc/passwd

#8、Docker 容器
## QiuSimons大神
#rm -rf feeds/luci/applications/luci-app-dockerman
#rm -rf feeds/luci/collections/luci-lib-docker
#merge_package master https://github.com/lisaac/luci-app-dockerman.git feeds/luci/applications applications/luci-app-dockerman
#sed -i '/auto_start/d' feeds/luci/applications/luci-app-dockerman/root/etc/uci-defaults/luci-app-dockerman
#pushd feeds/packages
#wget -qO- https://github.com/openwrt/packages/commit/e2e5ee69.patch | patch -p1
#wget -qO- https://github.com/openwrt/packages/pull/20054.patch | patch -p1
#popd
#sed -i '/sysctl.d/d' feeds/packages/utils/dockerd/Makefile
#rm -rf ./feeds/luci/collections/luci-lib-docker
#merge_package master https://github.com/lisaac/luci-lib-docker.git package/new collections/luci-lib-docker

# sbwml大神
# sbwml大神 【yaof使用sbwml的最新】
#rm -rf feeds/luci/applications/luci-app-dockerman
#git clone https://git.cooluc.com/sbwml/luci-app-dockerman -b openwrt-24.10 feeds/luci/applications/luci-app-dockerman
rm -rf feeds/packages/utils/{docker,dockerd,containerd,runc}
git clone https://github.com/sbwml/packages_utils_docker feeds/packages/utils/docker
git clone https://github.com/sbwml/packages_utils_dockerd feeds/packages/utils/dockerd
git clone https://github.com/sbwml/packages_utils_containerd feeds/packages/utils/containerd
git clone https://github.com/sbwml/packages_utils_runc feeds/packages/utils/runc

#为系统添加挂载目录：
pushd feeds/luci
    curl -s https://raw.githubusercontent.com/sbwml/r4s_build_script/master/openwrt/patch/luci/0006-luci-mod-system-mounts-add-docker-directory-mount-po.patch | patch -p1
popd

#9、全能推送（商店自己安装）
#rm -rf feeds/luci/applications/luci-app-pushbot
#git clone https://github.com/zzsj0928/luci-app-pushbot.git package/diy/luci-app-pushbot

#10、NIC driver - R8168 & R8125 & R8152 & R8101   #使用lede自带的
#rm -rf package/lean/r8152
#rm -rf package/kernel/{r8168,r8101,r8125,r8126,r8127}
#git clone https://$github/sbwml/package_kernel_r8168 package/kernel/r8168
#git clone https://$github/sbwml/package_kernel_r8152 package/kernel/r8152
#git clone https://$github/sbwml/package_kernel_r8101 package/kernel/r8101
#git clone https://$github/sbwml/package_kernel_r8125 package/kernel/r8125
#git clone https://$github/sbwml/package_kernel_r8126 package/kernel/r8126
#git clone https://$github/sbwml/package_kernel_r8127 package/kernel/r8127

#11、golang以及openlist
rm -rf feeds/packages/lang/golang
git clone https://github.com/sbwml/packages_lang_golang -b 26.x feeds/packages/lang/golang

rm -rf feeds/luci/applications/luci-app-openlist
rm -rf feeds/packages/net/openlist
git clone https://github.com/sbwml/luci-app-openlist2 package/new/openlist2
#移动到nas栏目
sed -i 's/services/nas/g' package/new/openlist2/luci-app-openlist2/root/usr/share/luci/menu.d/luci-app-openlist2.json

#12、diskman
merge_package master https://github.com/lisaac/luci-app-diskman.git package/new applications/luci-app-diskman

#13、lan口设置  不能在workflow上打。（只能打成功lede的patch）（新版采用default-setting配置）
#rm -rf target/linux/x86/base-files/etc/board.d/02_network  #清除系统自带的02，需要lede的才能patche成功。
#wget -N https://raw.githubusercontent.com/coolsnowwolf/lede/master/target/linux/x86/base-files/etc/board.d/02_network -P target/linux/x86/base-files/etc/board.d/
#patch -p1 <./diydata/data/patches/def_set_interfaces_lan_wan.patch

#14、chatgpt
#git clone --depth=1 https://github.com/sirpdboy/luci-app-chatgpt-web package/luci-app-chatgpt

#15、系统在线升级
#1）gpsysupgrade（通过对链接的前缀10.16.2024进行比较大小进行升级）
 #原地址：https://github.com/ilxp/builder/releases/download/标签名/10.16.2024-oprx-x86-64-generic-squashfs-combined-efi.img.gz
 #原地址：https://github.com/ilxp/builder/releases/download/标签名/vermd5.txt  其中firmware为固定的tag名称。在Release发布的时候注意。
git clone https://github.com/ilxp/openwrt-gpsysupgrade-kiddin9  package/diy/openwrt-gpsysupgrade
#改固件（要先改）
sed -i "s/oprx/oprx-eS/g" package/diy/openwrt-gpsysupgrade/luci-app-gpsysupgrade/luasrc/model/cbi/gpsysupgrade/sysupgrade.lua
#改仓库名builder
sed -i "s/builder/oprx-builder/g" package/diy/openwrt-gpsysupgrade/luci-app-gpsysupgrade/luasrc/model/cbi/gpsysupgrade/sysupgrade.lua
#改vermd5名称：
sed -i "s/vermd5/vermd5-eS/g" package/diy/openwrt-gpsysupgrade/luci-app-gpsysupgrade/luasrc/model/cbi/gpsysupgrade/sysupgrade.lua
##全部调到系统菜单
sed -i 's/services/system/g' package/diy/openwrt-gpsysupgrade/luci-app-gpsysupgrade/luasrc/controller/*.lua
sed -i 's/services/system/g' package/diy/openwrt-gpsysupgrade/luci-app-gpsysupgrade/luasrc/view/admin_status/index/*.htm
sed -i 's/services/system/g' package/diy/openwrt-gpsysupgrade/luci-app-gpsysupgrade/luasrc/view/gpsysupgrade/*.htm

#2）autoupdate
git clone -b main --single-branch https://github.com/ilxp/openwrt-autoupdate.git  package/diy/openwrt-autoupdate
#将版本号以及固件的相关信息写入默认配置文件。
#cat >> package/diy/openwrt-autoupdate/autoupdate/files/etc/autoupdate/default <<EOF
#Author=ilxp
#Github=https://github.com/ilxp/oprx-builder
#TARGET_PROFILE=x86_64
#TARGET_BOARD=x86
#TARGET_SUBTARGET=64
#TARGET_FLAG=${TARGET_FLAG}
#OP_VERSION=${OP_VERSION}
#OP_AUTHOR=openwrt  
#OP_REPO=openwrt
#OP_BRANCH=openwrt-24.10

#EOF

#修改内容
#1）固件标签
sed -i "s/TARGET_FLAG=Full/TARGET_FLAG=eS/g" package/diy/openwrt-autoupdate/autoupdate/files/etc/autoupdate/default
#2）版本号：需要固定成：R24.1.1-20240101
#Build_DATE=$(date +%Y%m%d%H)  #日期+小时
#Short_Date=`TZ=UTC-8 date +%y.%-m.%-d`  #24年1月1日：24.1.1
Short_Date=$(TZ=UTC-8 date +'%y.%-m.%-d') #24年1月1日：24.1.1
Compile_Date=$(TZ=UTC-8 date +'%Y%m%d')
OP_VERSION="R${Short_Date}-${Compile_Date}"

sed -i "s/OP_VERSION=R24.1.1-20240101/OP_VERSION=$OP_VERSION/g" package/diy/openwrt-autoupdate/autoupdate/files/etc/autoupdate/default  #使用双引号
#3）源码作者
sed -i 's/OP_AUTHOR=openwrt/OP_AUTHOR=coolsnowwolf/g' package/diy/openwrt-autoupdate/autoupdate/files/etc/autoupdate/default
#4）项目
sed -i 's/OP_REPO=openwrt/OP_REPO=lede/g' package/diy/openwrt-autoupdate/autoupdate/files/etc/autoupdate/default
#5）分支
sed -i 's/OP_BRANCH=main/OP_BRANCH=master/g' package/diy/openwrt-autoupdate/autoupdate/files/etc/autoupdate/default

#12、更换 Nodejs 版本
rm -rf feeds/packages/lang/node
git clone https://github.com/sbwml/feeds_packages_lang_node-prebuilt -b packages-24.10 feeds/packages/lang/node
#rm -rf ./feeds/packages/lang/node
#merge_package master https://github.com/QiuSimons/OpenWrt-Add  package/custom  feeds_packages_lang_node-prebuilt
#cp -rf ../package/custom/feeds_packages_lang_node-prebuilt ./feeds/packages/lang/node

#13、相关引擎（lede不采用）
# Shortcut Forwarding Engine
#git clone https://git.cooluc.com/sbwml/shortcut-fe package/new/shortcut-fe
# FullCone module
#git clone https://git.cooluc.com/sbwml/nft-fullcone package/new/nft-fullcone
# IPv6 NAT
#git clone https://github.com/sbwml/packages_new_nat6 package/new/nat6
# natflow
#git clone https://github.com/sbwml/package_new_natflow package/new/natflow
# iptables-mod-fullconenat for firewall3
#git clone https://github.com/sbwml/fullconenat package/new/fullconenat

#14、sbwml大神的优化
# x86 - disable intel_pstate & mitigations
sed -i 's/noinitrd/noinitrd intel_pstate=disable mitigations=off/g' target/linux/x86/image/grub-efi.cfg
# openssl -Ofast
sed -i "s/-O3/-Ofast/g" package/libs/openssl/Makefile
# procps-ng - top
sed -i 's/enable-skill/enable-skill --disable-modern-top/g' feeds/packages/utils/procps-ng/Makefile
# opkg  #lede无法使用。已删
#mkdir -p package/system/opkg/patches
#cp -rf ./diydata/data/patches/900-opkg-download-disable-hsts.patch ./package/system/opkg/patches/

#15、TTYD
sed -i 's/services/system/g' feeds/luci/applications/luci-app-ttyd/root/usr/share/luci/menu.d/luci-app-ttyd.json
sed -i '3 a\\t\t"order": 50,' feeds/luci/applications/luci-app-ttyd/root/usr/share/luci/menu.d/luci-app-ttyd.json
sed -i 's/procd_set_param stdout 1/procd_set_param stdout 0/g' feeds/packages/utils/ttyd/files/ttyd.init
sed -i 's/procd_set_param stderr 1/procd_set_param stderr 0/g' feeds/packages/utils/ttyd/files/ttyd.init

#16、autocore 【lede使用自带的】
#rm -rf package/system/autocore  #sbwml的cpu使用率有问题。
#git clone -b openwrt-24.10 --depth 1 https://github.com/sbwml/autocore-arm  package/system/autocore
#sed -i '/init/d' package/system/autocore/Makefile
#sed -i '/autocore.json/a\\	$(INSTALL_BIN) ./files/x86/autocore $(1)/etc/init.d/' package/system/autocore/Makefile
#sed -i '/autocore.json/a\\	$(INSTALL_DIR) $(1)/etc/init.d' package/system/autocore/Makefile
#cp -rf ./diydata/data/autocore  package/system/autocore/files/x86/  ##sbwml的cpu使用率有问题。采用yaof的

#17、samba4-luci
rm -rf feeds/luci/applications/luci-app-samba4
merge_package master https://github.com/openwrt/luci.git feeds/luci/applications applications/luci-app-samba4

#16、 samba4 - bump version
rm -rf feeds/packages/net/samba4  #lede的版本比较老 https://github.com/coolsnowwolf/packages/blob/master/net/samba4/Makefile 为4.14.14
git clone https://github.com/sbwml/feeds_packages_net_samba4 feeds/packages/net/samba4  #4.21.4
# liburing - 2.7 (samba-4.21.0)
rm -rf feeds/packages/libs/liburing
git clone https://github.com/sbwml/feeds_packages_libs_liburing feeds/packages/libs/liburing
# enable multi-channel
sed -i '/workgroup/a \\n\t## enable multi-channel' feeds/packages/net/samba4/files/smb.conf.template
sed -i '/enable multi-channel/a \\tserver multi channel support = yes' feeds/packages/net/samba4/files/smb.conf.template
# default config
sed -i 's/#aio read size = 0/aio read size = 0/g' feeds/packages/net/samba4/files/smb.conf.template
sed -i 's/#aio write size = 0/aio write size = 0/g' feeds/packages/net/samba4/files/smb.conf.template
sed -i 's/invalid users = root/#invalid users = root/g' feeds/packages/net/samba4/files/smb.conf.template
sed -i 's/bind interfaces only = yes/bind interfaces only = no/g' feeds/packages/net/samba4/files/smb.conf.template
sed -i 's/#create mask/create mask/g' feeds/packages/net/samba4/files/smb.conf.template
sed -i 's/#directory mask/directory mask/g' feeds/packages/net/samba4/files/smb.conf.template
sed -i 's/0666/0644/g;s/0744/0755/g;s/0777/0755/g' feeds/luci/applications/luci-app-samba4/htdocs/luci-static/resources/view/samba4.js
sed -i 's/0666/0644/g;s/0777/0755/g' feeds/packages/net/samba4/files/samba.config
sed -i 's/0666/0644/g;s/0777/0755/g' feeds/packages/net/samba4/files/smb.conf.template

# 17、移动栏目
sed -i 's/services/nas/g' feeds/luci/applications/luci-app-hd-idle/root/usr/share/luci/menu.d/luci-app-hd-idle.json
sed -i 's/services/nas/g' feeds/luci/applications/luci-app-samba4/root/usr/share/luci/menu.d/luci-app-samba4.json
#for ledede luci18.06
#sed -i 's/services/nas/g' feeds/luci/applications/luci-app-samba4/luasrc/controller/samba4.lua

#18、USB 打印机 （会产生一个nas项目）
merge_package master https://github.com/QiuSimons/OpenWrt-Add.git package/new openwrt_pkgs/luci-app-usb-printer

#18、KMS 激活助手
merge_package master https://github.com/QiuSimons/OpenWrt-Add.git package/new  openwrt_pkgs/luci-app-vlmcsd
merge_package master https://github.com/QiuSimons/OpenWrt-Add.git package/new  openwrt_pkgs/vlmcsd

#19、 清理内存
merge_package master https://github.com/QiuSimons/OpenWrt-Add.git package/new luci-app-ramfree

#20、 OLED 驱动程序
git clone -b master --depth 1 https://github.com/NateLol/luci-app-oled.git package/new/luci-app-oled

#22、 uwsgi
sed -i 's,procd_set_param stderr 1,procd_set_param stderr 0,g' feeds/packages/net/uwsgi/files/uwsgi.init
sed -i 's,buffer-size = 10000,buffer-size = 131072,g' feeds/packages/net/uwsgi/files-luci-support/luci-webui.ini
sed -i 's,logger = luci,#logger = luci,g' feeds/packages/net/uwsgi/files-luci-support/luci-webui.ini
sed -i '$a cgi-timeout = 600' feeds/packages/net/uwsgi/files-luci-support/luci-*.ini
sed -i 's/threads = 1/threads = 2/g' feeds/packages/net/uwsgi/files-luci-support/luci-webui.ini
sed -i 's/processes = 3/processes = 4/g' feeds/packages/net/uwsgi/files-luci-support/luci-webui.ini
sed -i 's/cheaper = 1/cheaper = 2/g' feeds/packages/net/uwsgi/files-luci-support/luci-webui.ini
# rpcd
sed -i 's/option timeout 30/option timeout 60/g' package/system/rpcd/files/rpcd.config
sed -i 's#20) \* 1000#60) \* 1000#g' feeds/luci/modules/luci-base/htdocs/luci-static/resources/rpc.js

#23、UPX 可执行软件压缩
sed -i '/patchelf pkgconf/i\tools-y += ucl upx' ./tools/Makefile
sed -i '\/autoconf\/compile :=/i\$(curdir)/upx/compile := $(curdir)/ucl/compile' ./tools/Makefile
##merge_package main https://github.com/Lienol/openwrt.git  ./tools tools/ucl tools/upx  #表示在根目录生成一个tools文件夹。本来就会有，所以报错。
#merge_package main https://github.com/Lienol/openwrt.git tools tools/ucl tools/upx  #表示在移动到根目录已经存在的tools文件夹。lienol版本有点旧3.95。
merge_package 24.10 https://github.com/Lienol/openwrt.git tools tools/ucl
merge_package main https://github.com/ilxp/upx-openwrt.git tools upx   #最新版4.2.4

#24、v2raya
git clone --depth 1 https://github.com/zxlhhyccc/luci-app-v2raya.git package/new/luci-app-v2raya
rm -rf ./feeds/packages/net/v2raya
merge_package master https://github.com/openwrt/packages.git package/new net/v2raya

#25、UPnP （lede还是用iptables，没有用nftables，故无法使用最新）
#删除lean大佬的旧版本
#rm -rf ./feeds/packages/net/miniupnpc
#merge_package master https://github.com/openwrt/packages.git feeds/packages/net net/miniupnpc

# UPnP（QiuSimons的，针对lede 23.05luci）
#rm -rf feeds/{packages/net/miniupnpd,luci/applications/luci-app-upnp}
#merge_package master https://github.com/openwrt/packages.git feeds/packages/net net/miniupnpd
#merge_package master https://github.com/openwrt/luci.git feeds/luci/applications applications/luci-app-upnp  #官方的是在services栏目下
# 精简 UPnP 菜单名称
#sed -i 's#\"title\": \"UPnP IGD \& PCP\"#\"title\": \"UPnP\"#g' feeds/luci/applications/luci-app-upnp/root/usr/share/luci/menu.d/luci-app-upnp.json
#sed -i "s/miniupnpd/miniupnpd-iptables/g" feeds/luci/applications/luci-app-upnp/Makefile  
 
#wget https://github.com/miniupnp/miniupnp/commit/0e8c68d.patch -O feeds/packages/net/miniupnpd/patches/0e8c68d.patch
#sed -i 's,/miniupnpd/,/,g' ./feeds/packages/net/miniupnpd/patches/0e8c68d.patch
#wget https://github.com/miniupnp/miniupnp/commit/21541fc.patch -O feeds/packages/net/miniupnpd/patches/21541fc.patch
#sed -i 's,/miniupnpd/,/,g' ./feeds/packages/net/miniupnpd/patches/21541fc.patch
#wget https://github.com/miniupnp/miniupnp/commit/b78a363.patch -O feeds/packages/net/miniupnpd/patches/b78a363.patch
#sed -i 's,/miniupnpd/,/,g' ./feeds/packages/net/miniupnpd/patches/b78a363.patch
#wget https://github.com/miniupnp/miniupnp/commit/8f2f392.patch -O feeds/packages/net/miniupnpd/patches/8f2f392.patch
#sed -i 's,/miniupnpd/,/,g' ./feeds/packages/net/miniupnpd/patches/8f2f392.patch
#wget https://github.com/miniupnp/miniupnp/commit/60f5705.patch -O feeds/packages/net/miniupnpd/patches/60f5705.patch
#sed -i 's,/miniupnpd/,/,g' ./feeds/packages/net/miniupnpd/patches/60f5705.patch
#wget https://github.com/miniupnp/miniupnp/commit/3f3582b.patch -O feeds/packages/net/miniupnpd/patches/3f3582b.patch
#sed -i 's,/miniupnpd/,/,g' ./feeds/packages/net/miniupnpd/patches/3f3582b.patch
#cp -rf ./diydata/data/patches/miniupnpd/301-options-force_forwarding-support.patch ./feeds/packages/net/miniupnpd/patches/
#pushd feeds/packages
#patch -p1 <../.././diydata/data/patches/miniupnpd/01-set-presentation_url.patch
#patch -p1 <../.././diydata/data/patches/miniupnpd/02-force_forwarding.patch
#popd
#pushd feeds/luci
#patch -p1 <../.././diydata/data/patches/miniupnpd/luci-upnp-support-force_forwarding-flag.patch
#popd

# UPnP（来源sbwml的，lede只能使用自带的）
#rm -rf feeds/{packages/net/miniupnpd,luci/applications/luci-app-upnp}
#git clone https://git.cooluc.com/sbwml/miniupnpd feeds/packages/net/miniupnpd -b v2.3.7
#git clone https://git.cooluc.com/sbwml/luci-app-upnp feeds/luci/applications/luci-app-upnp -b main
#设置miniupnpd-iptables #lede是iptables
#sed -i "s/miniupnpd/miniupnpd-iptables/g" feeds/luci/applications/luci-app-upnp/Makefile   
#sbwml的Upnp 移动以及翻译
#sed -i "s/network/services/g" feeds/luci/applications/luci-app-upnp/root/usr/share/luci/menu.d/luci-app-upnp.json
# 精简 UPnP 菜单名称（sbwml已经是UPNP）
#sed -i 's#\"title\": \"UPnP IGD \& PCP\"#\"title\": \"UPnP\"#g' feeds/luci/applications/luci-app-upnp/root/usr/share/luci/menu.d/luci-app-upnp.json

#26、bandix 网络流量监控应
git clone https://github.com/timsaya/luci-app-bandix  package/new/bandix-luci
git clone https://github.com/timsaya/openwrt-bandix  package/new/bandix

##########################################################################

chmod -R 755 ./
find ./ -name *.orig | xargs rm -f
find ./ -name *.rej | xargs rm -f

exit 0
