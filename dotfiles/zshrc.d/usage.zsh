function duh {
     du -sk "$@" | sort -n | while read size fname; do for unit in K M G T P E Z Y; do if [ $size -lt 1024 ]; then echo -e "${size}${unit}\t${fname}"; break; fi; size=$((size/1024)); done; done
}
