#!/bin/sh

# 第三方软件仓库
third_party_source="https://op.dllkids.xyz/packages/aarch64_cortex-a53"

#添加出处信息
add_author_info() {
   uci set system.@system[0].description='ayzpx'
   uci set system.@system[0].notes='文档说明:
    https://github.com/anzpx/GL-MT3000-onescript'
   uci commit system
}

# 添加主机名映射(解决安卓原生TV首次连不上wifi的问题)
add_dhcp_domain() {
   local domain_name="time.android.com"
   local domain_ip="203.107.6.88"

   # 检查是否存在相同的域名记录
   existing_records=$(uci show dhcp | grep "dhcp.@domain\[[0-9]\+\].name='$domain_name'")
   if [ -z "$existing_records" ]; then
      # 添加新的域名记录
      uci add dhcp domain
      uci set "dhcp.@domain[-1].name=$domain_name"
      uci set "dhcp.@domain[-1].ip=$domain_ip"
      uci commit dhcp
      echo
      echo "已添加新的域名记录"
   else
      echo "相同的域名记录已存在，无需重复添加"
   fi
   echo -e "\n"
   echo -e "time.android.com    203.107.6.88 "
}

# 基础必备设置
setup_base_init() {
   #添加出处信息
   add_author_info
   #添加安卓时间服务器
   add_dhcp_domain
   ##设置时区
   uci set system.@system[0].zonename='Asia/Shanghai'
   uci set system.@system[0].timezone='CST-8'
   uci commit system
   /etc/init.d/system reload

   ## 设置防火墙wan 打开,方便主路由访问
   uci set firewall.@zone[1].input='ACCEPT'
   uci commit firewall
}

# 判断系统是否为iStoreOS
is_iStoreOS() {
	DISTRIB_ID=$(cat /etc/openwrt_release | grep "DISTRIB_ID" | cut -d "'" -f 2)
	# 检查DISTRIB_ID的值是否等于'iStoreOS'
	if [ "$DISTRIB_ID" = "iStoreOS" ]; then
		return 0 # true
	else
		return 1 # false
	fi
}

## 去除opkg签名
remove_check_signature_option() {
	local opkg_conf="/etc/opkg.conf"
	sed -i '/option check_signature/d' "$opkg_conf"
}

## 添加opkg签名
add_check_signature_option() {
	local opkg_conf="/etc/opkg.conf"
	echo "option check_signature 1" >>"$opkg_conf"
}

#设置第三方软件源
setup_software_source() {
	## 传入0和1 分别代表原始和第三方软件源
	if [ "$1" -eq 0 ]; then
		echo "# add your custom package feeds here" >/etc/opkg/customfeeds.conf
		##如果是iStoreOS系统,还原软件源之后，要添加签名
		if is_iStoreOS; then
			add_check_signature_option
		else
			echo
		fi
		# 还原软件源之后更新
		echo "更新软件包列表"
		opkg update
		echo
	elif [ "$1" -eq 1 ]; then
		#传入1 代表设置第三方软件源 先要删掉签名
		remove_check_signature_option
		# 先删除再添加以免重复
		echo "# add your custom package feeds here" >/etc/opkg/customfeeds.conf
		echo "src/gz third_party_source $third_party_source" >>/etc/opkg/customfeeds.conf
		# 设置第三方源后要更新
		echo "更新软件包列表"
		opkg update
		echo
	else
		echo "无效选项。请提供0或1。"
	fi
}

# 下载和安装依赖
do_install_depends_ipk() {
   echo "正在下载并安装必要依赖"
   wget -O "/tmp/iptables-mod-socket_0.00-0_all.ipk" "https://raw.githubusercontent.com/anzpx/GL-MT3000-onescript/main/packages/iptables-mod-socket_0.00-0_all.ipk"
   wget -O "/tmp/kmod-inet-diag_0.00-0_all.ipk" "https://raw.githubusercontent.com/anzpx/GL-MT3000-onescript/main/packages/kmod-inet-diag_0.00-0_all.ipk"
   wget -O "/tmp/libopenssl3.ipk" "https://raw.githubusercontent.com/anzpx/GL-MT3000-onescript/main/packages/libopenssl3.ipk"
   wget -O "/tmp/luci-lua-runtime_all.ipk" "https://raw.githubusercontent.com/anzpx/GL-MT3000-onescript/main/packages/luci-lua-runtime_all.ipk"
   wget -O "/tmp/kmod-ipt-socket_0.00-0_all.ipk" "https://raw.githubusercontent.com/anzpx/GL-MT3000-onescript/main/packages/kmod-ipt-socket_0.00-0_all.ipk"


	opkg install "/tmp/iptables-mod-socket_0.00-0_all.ipk"
   opkg install "/tmp/kmod-inet-diag_0.00-0_all.ipk"
   opkg install "/tmp/libopenssl3.ipk"
   opkg install "/tmp/luci-lua-runtime_all.ipk"
   opkg install "/tmp/kmod-ipt-socket_0.00-0_all.ipk"
   echo
}

#单独安装argon主题
do_install_argon_skin() {
	echo "正在尝试安装argon主题......."
	opkg install luci-app-argon-config
   # luci-theme-edge
	# 检查上一个命令的返回值
	if [ $? -eq 0 ]; then
		echo "argon主题 安装成功"
		# 设置主题和语言
		uci set luci.main.mediaurlbase='/luci-static/argon'
		uci set luci.main.lang='zh_cn'
		uci commit
		echo "重新登录web页面后, 查看新主题 "
	else
		echo "argon主题 安装失败! 建议再执行一次!再给我一个机会!事不过三!"
	fi
   echo
}

#安装首页风格
do_install_luci_app_quickstart() {
	opkg install luci-app-quickstart
	echo "首页样式已经更新,请强制刷新网页,检查是否为中文字体"
}

# 安装首页及其所需软件
install_istore_os_style() {

   echo "安装首页风格"
   opkg install luci-app-quickstart
	echo

   echo "安装ddnsto app-meta-ddnsto"
   sh -c "$(wget --no-check-certificate -qO- http://fw.koolcenter.com/binary/ddnsto/openwrt/install_ddnsto.sh)"
   echo

   echo "安装易有云 app-meta-linkease"
   sh -c "$(wget --no-check-certificate -qO- http://fw.koolcenter.com/binary/LinkEase/Openwrt/install_linkease.sh)"
   echo

   echo "安装磁盘管理"
   opkg install luci-app-diskman
   echo

   # luci-app-aria2
   echo "安装Aria2 插件"
   opkg install luci-i18n-aria2-zh-cn
   echo

   echo "安装GoWebDAV 插件"
   opkg install luci-app-gowebdav
   echo

   #判断是否安装 json解析工具“jq”
   # if [ `command -v jq` ];then
   #    echo 'jq 已经安装'
   # else
   #    echo 'jq 未安装,开始安装json解析工具'
   # #安装jq
   #    brew install jq
   # fi

 
  
   # samba4
   
   # 带宽监控
   # Homebox 插件
   # SysTools 插件
   # feed


   # Transmission 插件
   # qBittorrent 插件


	# 若已安装iStore商店则在概览中追加iStore字样
	# if ! grep -q " like iStoreOS" /tmp/sysinfo/model; then
	# 	sed -i '1s/$/ like iStoreOS/' /tmp/sysinfo/model
	# fi
}

do_install_passwall(){
   echo "开始安装passwall......"
   opkg install luci-app-passwall
   echo
}

do_install_passwall2(){
   echo "开始安装passwall2......"
   opkg install luci-app-passwall2
   echo
}

echo "开始安装......"
echo

#基础必备设置
setup_base_init
#设置第三方软件仓库
setup_software_source 1
#下载和安装必须的依赖
#do_install_depends_ipk
#设置Argon 紫色主题
#do_install_argon_skin

# 安装首页及其所需软件
# install_istore_os_style

# 安装passwall
#do_install_passwall
# 安装passwall2
#do_install_passwall2

#再次更新 防止出现汉化不完整
#do_install_luci_app_quickstart

#恢复第三方软件仓库
#setup_software_source 0