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
		opkg update
	elif [ "$1" -eq 1 ]; then
		#传入1 代表设置第三方软件源 先要删掉签名
		remove_check_signature_option
		# 先删除再添加以免重复
		echo "# add your custom package feeds here" >/etc/opkg/customfeeds.conf
		echo "src/gz third_party_source $third_party_source" >>/etc/opkg/customfeeds.conf
		# 设置第三方源后要更新
		opkg update
	else
		echo "无效选项。请提供0或1。"
	fi
}

# 下载和安装依赖
do_install_depends_ipk() {
	wget -O "/tmp/iptables-mod-socket_0.00-0_all.ipk" "https://raw.githubusercontent.com/anzpx/GL-MT3000-onescript/main/packages/iptables-mod-socket_0.00-0_all.ipk"
   wget -O "/tmp/kmod-inet-diag_0.00-0_all.ipk" "https://raw.githubusercontent.com/anzpx/GL-MT3000-onescript/main/packages/kmod-inet-diag_0.00-0_all.ipk"
   wget -O "/tmp/libopenssl3.ipk" "https://raw.githubusercontent.com/anzpx/GL-MT3000-onescript/main/packages/libopenssl3.ipk"
   wget -O "/tmp/luci-lua-runtime_all.ipk" "https://raw.githubusercontent.com/anzpx/GL-MT3000-onescript/main/packages/luci-lua-runtime_all.ipk"

	opkg install "/tmp/iptables-mod-socket_0.00-0_all.ipk"
   opkg install "/tmp/kmod-inet-diag_0.00-0_all.ipk"
   opkg install "/tmp/libopenssl3.ipk"
   opkg install "/tmp/luci-lua-runtime_all.ipk"
}

#单独安装argon主题
do_install_argon_skin() {
	echo "正在尝试安装argon主题......."
	#下载和安装argon的依赖
	do_install_depends_ipk
	setup_software_source 1
	opkg install luci-app-argon-config
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
	setup_software_source 0
}

## 安装主题
install_istore_os_style() {
	##设置Argon 紫色主题
	do_install_argon_skin
	#安装首页风格
	###is-opkg install luci-app-quickstart
	###is-opkg install 'app-meta-ddnsto'
	#安装首页需要的文件管理功能
	###is-opkg install 'app-meta-linkease'
	# 安装磁盘管理
	###is-opkg install 'app-meta-diskman'
	# 若已安装iStore商店则在概览中追加iStore字样
	###if ! grep -q " like iStoreOS" /tmp/sysinfo/model; then
		### sed -i '1s/$/ like iStoreOS/' /tmp/sysinfo/model
	###fi
}

update_luci_app_quickstart() {
	setup_software_source 1
	opkg install luci-app-quickstart
	setup_software_source 0
	echo "首页样式已经更新,请强制刷新网页,检查是否为中文字体"
}


#基础必备设置
setup_base_init
#安装iStore风格
install_istore_os_style
#再次更新 防止出现汉化不完整
update_luci_app_quickstart