red(){ echo -e "\033[31m\033[01m$1\033[0m"; }
green(){ echo -e "\033[32m\033[01m$1\033[0m"; }
reading(){ read -rp "$(green "$1")" "$2"; }

ARCHITECTURE="$(arch)"
case $ARCHITECTURE in
x86_64 )  FILE=besttrace;;
aarch64 ) FILE=besttracearm;;
i386 )    FILE=besttracemac;;
* ) red " 只支持 AMD64、ARM64、Mac 使用，问题反馈:[https://github.com/fscarmen/tools/issues] " && exit 1;;
esac

ip=$1
[[ -z "$ip" || $ip = '[DESTINATION_IP]' ]] && reading " 请输入目的地 IP: " ip
[[ ! -e "$FILE" ]] && wget -q https://cdn.jsdelivr.net/gh/fscarmen/tools/besttrace/$FILE
chmod +x "$FILE" >/dev/null 2>&1
sudo ./"$FILE" "$ip" -g cn > ip.temp
cat bb | tail -n +3 | grep -vE ".*\*$" | awk '{print $(NF-4) $(NF-3) $(NF-2) $(NF-1) $NF}' 2>/dev/null | uniq | awk '{printf("%d,%s\n",NR,$0)}' | sed "s/\(AS[0-9]*\)//g"
