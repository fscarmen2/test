##### 为 macOS 添加 WGCF，IPv4走 warp #####

# 进入工作目录
cd /usr/local/bin
mkdir -p /etc/wireguard/ >/dev/null 2>&1

# 多方式判断操作系统
sw_vesrs 2>/dev/null | grep -qvi macos && red " 当前操作不是 macOS,脚本退出,问题反馈:[https://github.com/fscarmen/warp/issues] "

# 输入 Warp+ 账户（如有），限制位数为空或者26位以防输入错误
[[ -z $LICENSE ]] && read -rp "如有 Warp+ License 请输入，没有可回车继续:" LICENSE
i=5
until [[ -z $LICENSE || $LICENSE =~ ^[A-Z0-9a-z]{8}-[A-Z0-9a-z]{8}-[A-Z0-9a-z]{8}$ ]]
	do	(( i-- )) || true
		[[ $i = 0 ]] && red " 输入错误达5次，脚本退出 " && exit 1 || reading " License 应为26位字符，请重新输入 WARP+ License，没有可回车继续(剩余$i次): " LICENSE
done

[[ -n $LICENSE && -z $NAME ]] && read -rp " 请自定义 WARP+ 设备名 (如果不输入，默认为 [WARP]): " NAME
[[ -n $NAME ]] && NAME="${NAME//[[:space:]]/_}" || NAME=${NAME:-'WARP'}

# 安装 wireguard-tools
echo -e "\033[32m (1/3) 安装 wireguard-tools\033[0m"
! type -p wg >/dev/null 2>&1 && brew install wireguard-tools

echo -e "\033[32m (2/3) 安装 WGCF 和 wireguard-go\033[0m"
# 判断 wgcf 的最新版本
latest=$(curl -fsSL "https://api.github.com/repos/ViRb3/wgcf/releases/latest" | grep "tag_name" | head -n 1 | cut -d : -f2 | sed 's/[ \"v,]//g')
latest=${latest:-'2.2.12'}

# 安装 wgcf，尽量下载官方的最新版本，如官方 wgcf 下载不成功，将使用 githubusercontents 的 CDN，以更好的支持双栈。并添加执行权限
curl -o /usr/local/bin/wgcf https://raw.githubusercontents.com/fscarmen/warp/main/wgcf/wgcf_"$latest"_darwin_amd64

# 安装 wireguard-go
curl -o /usr/local/bin/wireguard-go_darwin_amd64.tar.gz https://raw.githubusercontents.com/fscarmen/warp/main/wireguard-go/wireguard-go_darwin_amd64.tar.gz &&
tar xzf /usr/local/bin/wireguard-go_darwin_amd64.tar.gz -C /usr/local/bin/ && rm -f /usr/local/bin/wireguard-go_darwin_amd64.tar.gz

# 添加执行权限
chmod +x /usr/local/bin/wireguard-go /usr/local/bin/wgcf

# 注册 WARP 账户 (将生成 wgcf-account.toml 文件保存账户信息，为避免文件已存在导致出错，先尝试删掉原文件)
rm -f wgcf-account.toml
echo -e "\033[33m wgcf 注册中…… \033[0m"
until [[ -e wgcf-account.toml ]] >/dev/null 2>&1; do
	wgcf register --accept-tos >/dev/null 2>&1 && break
done

# 如有 Warp+ 账户，修改 license 并升级
[[ -n $LICENSE ]] && echo -e "\033[33m 升级 Warp+ 账户 \033[0m" && sed -i '' "s/license_key.*/license_key = \"$LICENSE\"/g" wgcf-account.toml &&
( wgcf update --name "$NAME" > /etc/wireguard/info.log 2>&1 || echo -e "\033[31m 升级失败，Warp+ 账户错误或者已激活超过5台设备，自动更换免费 Warp 账户继续\033[0m " )

# 生成 Wire-Guard 配置文件 (wgcf-profile.conf)
wgcf generate >/dev/null 2>&1
  
# 修改配置文件 wgcf-profile.conf 的内容,使得 IPv4 的流量均被 WireGuard 接管
sed -i '' 's/engage.cloudflareclient.com/162.159.193.10/g' wgcf-profile.conf

# 把 wgcf-profile.conf 复制到/etc/wireguard/ 并命名为 wgcf.conf
sudo cp -f wgcf-profile.conf /etc/wireguard/wgcf.conf

# 自动刷直至成功（ warp bug，有时候获取不了ip地址）
echo -e "\033[32m (3/3) 运行 WGCF \033[0m"
echo -e "\033[33m 后台获取 warp IP 中…… \033[0m"
sudo wg-quick up wgcf >/dev/null 2>&1
until [[ -n $(curl -s4 https://ip.gs) ]]; do
	sudo wg-quick down wgcf >/dev/null 2>&1
	sudo wg-quick up wgcf >/dev/null 2>&1
done

# 结果提示
echo -e "\033[32m 恭喜！WARP已开启，IPv4地址为:$(curl -s4 https://ip.gs)，IPv6地址为:$(curl -s6 https://ip.gs) \033[0m"

# 删除临时文件
rm -f warp.sh wgcf-account.toml wgcf-profile.conf menu.sh
