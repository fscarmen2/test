#!/usr/bin/env bash

export LANG=en_US.UTF-8

WGCF_DIR='/etc/wireguard'
DOCKER_DIR='/unlock'

# 自定义字体彩色，read 函数
red(){ echo -e "\033[31m\033[01m$1\033[0m"; }
green(){ echo -e "\033[32m\033[01m$1\033[0m"; }
yellow(){ echo -e "\033[33m\033[01m$1\033[0m"; }
reading(){ read -rp "$(green "$1")" "$2"; }

# 脚本当天及累计运行次数统计
statistics_of_run-times(){
COUNT=$(curl -sm1 "https://hits.seeyoufarm.com/api/count/incr/badge.svg?url=https%3A%2F%2Fraw.githubusercontent.com%2Ffscarmen%2Fwarp_unlock%2Fmain%2Fdocker.sh&count_bg=%2379C83D&title_bg=%23555555&icon=&icon_color=%23E7E7E7&title=hits&edge_flat=false" 2>&1) &&
TODAY=$(expr "$COUNT" : '.*\s\([0-9]\{1,\}\)\s/.*') && TOTAL=$(expr "$COUNT" : '.*/\s\([0-9]\{1,\}\)\s.*')
	}

wgcf_install(){
	# 判断处理器架构
	case $(tr '[:upper:]' '[:lower:]' <<< "$(arch)") in
	aarch64 ) ARCHITECTURE=arm64;;	x86_64 ) ARCHITECTURE=amd64;;	s390x ) ARCHITECTURE=s390x;;	* ) red " Curren architecture $(arch) is not supported. Feedback: [https://github.com/fscarmen/warp/issues] " && exit 1;;
	esac

	# 判断 wgcf 的最新版本,如因 github 接口问题未能获取，默认 v2.2.11
	green " \n Install WGCF \n "
	latest=$(wget -qO- -4 "https://api.github.com/repos/ViRb3/wgcf/releases/latest" | grep "tag_name" | head -n 1 | cut -d : -f2 | sed 's/[ \"v,]//g')
	latest=${latest:-'2.2.13'}

	# 安装 wgcf，尽量下载官方的最新版本，如官方 wgcf 下载不成功，将使用 jsDelivr 的 CDN，以更好的支持双栈。并添加执行权限
	wget -4 -O /usr/local/bin/wgcf https://github.com/ViRb3/wgcf/releases/download/v"$latest"/wgcf_"$latest"_linux_"$ARCHITECTURE" ||
	wget -4 -O /usr/local/bin/wgcf https://raw.githubusercontents.com/fscarmen/warp/main/wgcf/wgcf_"$latest"_linux_"$ARCHITECTURE"
	chmod +x /usr/local/bin/wgcf

	# 注册 WARP 账户 ( wgcf-account.toml 使用默认值加加快速度)。如有 WARP+ 账户，修改 license 并升级
	until [ -e wgcf-account.toml ] >/dev/null 2>&1; do
		wgcf register --accept-tos >/dev/null 2>&1 && break
	done

	# 生成 Wire-Guard 配置文件 (wgcf.conf)
	mkdir -p $WGCF_DIR >/dev/null 2>&1
	[ -e wgcf-account.toml ] && wgcf generate -p $WGCF_DIR/wgcf.conf >/dev/null 2>&1

	# 反复测试最佳 MTU。 Wireguard Header：IPv4=60 bytes,IPv6=80 bytes，1280 ≤1 MTU ≤ 1420。 ping = 8(ICMP回显示请求和回显应答报文格式长度) + 20(IP首部) 。
	# 详细说明：<[WireGuard] Header / MTU sizes for Wireguard>：https://lists.zx2c4.com/pipermail/wireguard/2017-December/002201.html
	MTU=$((1500-28))
	ping -c1 -W1 -s $MTU -Mdo 162.159.193.10 >/dev/null 2>&1
	until [[ $? = 0 || $MTU -le $((1280+80-28)) ]]
	do
	MTU=$((MTU-10))
	ping -c1 -W1 -s $MTU -Mdo 162.159.193.10 >/dev/null 2>&1
	done

	if [[ $MTU -eq $((1500-28)) ]]; then MTU=$MTU
	elif [[ $MTU -le $((1280+80-28)) ]]; then MTU=$((1280+80-28))
	else
		for ((i=0; i<9; i++)); do
		(( MTU++ ))
		ping -c1 -W1 -s $MTU -Mdo 162.159.193.10 >/dev/null 2>&1 || break
		done
		(( MTU-- ))
	fi

	MTU=$((MTU+28-80))

	[ -e $WGCF_DIR/wgcf.conf ] && sed -i "s/MTU.*/MTU = $MTU/g;s/^.*\:\:\/0/#&/g;s/engage.cloudflareclient.com/162.159.193.10/g" $WGCF_DIR/wgcf.conf
}

container_build(){
	green " \n Docker build and run \n "
	
	# 安装 docker,拉取镜像 + 创建容器
	! systemctl is-active docker >/dev/null 2>&1 && green " \n Install docker \n " && curl -sSL get.docker.com | sh
	! systemctl is-active docker >/dev/null 2>&1 && ( systemctl enable --now docker; sleep 2 )
	docker run -dit --kernel-memory --cpu-shares --restart=always --name wgcf --sysctl net.ipv6.conf.all.disable_ipv6=0 --device /dev/net/tun --privileged --cap-add net_admin --cap-add sys_module --log-opt max-size=1m -v /lib/modules:/lib/modules -v $WGCF_DIR:$WGCF_DIR fscarmen/wgcf_docker:latest

	# 清理临时文件
	rm -rf wgcf-account.toml /usr/local/bin/wgcf
	green " \n Done! The script runs on today: $TODAY. Total: $TOTAL \n "
}


statistics_of_run-times

wgcf_install

container_build
