#!/usr/bin/env bash
ip=$1
TEMP_FILE='ip.temp'

ARCHITECTURE="$(uname -m)"
case $ARCHITECTURE in
	x86_64 )  FILE=besttrace;;
	aarch64 ) FILE=besttracearm;;
	* ) echo -e "只支持 AMD64、ARM64 使用，问题反馈:[https://github.com/fscarmen/tools/issues]" && exit 1;;
esac

[[ -z "$ip" ]] && echo -e "请填入上对端 IP" && exit 1
echo -e "\n说明：测 VPS ——> 对端 经过的地区及线路，填本地IP就是测回程。"
[[ ! -e "$FILE" ]] && wget -qN https://cdn.jsdelivr.net/gh/fscarmen/tools/besttrace/$FILE
chmod +x "$FILE" >/dev/null 2>&1
 ./"$FILE" "$ip" -g cn > $TEMP_FILE
cat $TEMP_FILE | sed "s/.*\*\(.*\)/\1/g" | sed "s/.*AS[0-9]*//g" | sed "/\*$/d;/^$/d;1d" | uniq | awk '{printf("%d.%s\n"),NR,$0}'
rm -f $TEMP_FILE
