#!/bin/sh


set -o errexit
# set -o errtrace
set -o pipefail
set -o nounset

Green_font_prefix="\033[32m"
Red_font_prefix="\033[31m"
Green_background_prefix="\033[42;37m"
Red_background_prefix="\033[41;37m"
Font_color_suffix="\033[0m"
INFO="[${Green_font_prefix}INFO${Font_color_suffix}]"
ERROR="[${Red_font_prefix}ERROR${Font_color_suffix}]"

# 安装passwall的依赖包
function do_install_passwall_packages() {
   echo -e "${INFO} 安装passwall的依赖包"
   local project_name='openwrt-passwall'
   local gh_api_url='https://api.github.com/repos/xiaorouji/openwrt-passwall/releases/latest'
   local local_dir='/tmp/passwall'
   local file_full_name='passwall_packages.zip'
   local local_file_path="${local_dir}/${file_full_name}"

   if [[ $(uname -s) != Linux ]]; then
      echo -e "${ERROR} 操作系统不被支持。"
      exit 1
   fi

   if [[ $(id -u) != 0 ]]; then
      echo -e "${ERROR} 脚本必须在root账户下运行。"
      exit 1
   fi

   echo -e "${INFO} 获取 ${project_name} 下载URL ..."
   local download_url=$(curl -fsSL ${gh_api_url} | grep 'browser_download_url' | grep 'passwall_packages_ipk_aarch64_cortex-a53.zip' | cut -d '"' -f 4)
   echo -e "${INFO} 下载URL: ${download_url}"

   echo -e "${INFO} 正在下载 ${project_name} ..."
   wget -O "${local_file_path}" "${download_url}"


   # 解压安装包
   # unzip $file_full_name
   # 安装所有软件包
   # opkg install *.ipk --force-reinstall
}

clear
echo "开始安装......"
# 安装passwall的依赖包
do_install_passwall_packages

