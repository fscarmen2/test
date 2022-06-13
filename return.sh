#!/usr/bin/env bash
TEMP_FILE='ip.temp'

ARCHITECTURE="$(uname -m)"
case $ARCHITECTURE in
	x86_64 )  FILE=besttrace;;
	aarch64 ) FILE=besttracearm;;
	* ) echo -e "只支持 AMD64、ARM64 使用，问题反馈:[https://github.com/fscarmen/tools/issues]" && exit 1;;
esac

# 多方式判断操作系统，试到有值为止。只支持 Debian 10/11、Ubuntu 18.04/20.04 或 CentOS 7/8 ,如非上述操作系统，退出脚本
CMD=(	"$(grep -i pretty_name /etc/os-release 2>/dev/null | cut -d \" -f2)"
      	"$(hostnamectl 2>/dev/null | grep -i system | cut -d : -f2)"
	"$(lsb_release -sd 2>/dev/null)"
	"$(grep -i description /etc/lsb-release 2>/dev/null | cut -d \" -f2)"
	"$(grep . /etc/redhat-release 2>/dev/null)"
	"$(grep . /etc/issue 2>/dev/null | cut -d \\ -f1 | sed '/^[ ]*$/d')"
	)

for a in "${CMD[@]}"; do
	SYS="$a" && [[ -n $SYS ]] && break
done

[[ -z $SYS ]] && echo -e "本脚本只支持 Debian、Ubuntu、CentOS 和 Alpine 系统,问题反馈:[https://github.com/fscarmen/warp_unlock/issues]" && exit 1

ip=$1
[[ -z "$ip" ]] && echo -e "请填入上对端 IP" && exit 1
echo -e "\n说明：测 VPS ——> 对端 经过的地区及线路，填本地IP就是测回程。"
[[ ! -e "$FILE" ]] && wget -qN https://cdn.jsdelivr.net/gh/fscarmen/tools/besttrace/$FILE
chmod +x "$FILE" >/dev/null 2>&1
 ./"$FILE" "$ip" -g cn > $TEMP_FILE
cat $TEMP_FILE | sed "s/.*\*\(.*\)/\1/g" | sed "s/.*AS[0-9]*//g" | sed "/\*$/d;/^$/d;1d" | uniq | awk '{printf("%d.%s\n"),NR,$0}'
rm -f $TEMP_FILE
