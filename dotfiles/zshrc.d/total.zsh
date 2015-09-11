total() {
  local sum
  local arr
  local n
  sum=0
  while read -A arr ; do
    for n in $arr ; do
      sum=$(($sum+n))
    done
  done
  print $sum
}
