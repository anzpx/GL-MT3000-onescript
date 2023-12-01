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

# 初始化
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
