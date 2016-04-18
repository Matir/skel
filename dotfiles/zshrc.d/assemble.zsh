if [ -f "`command which nasm 2>/dev/null`" -a -f "`command which objdump 2>/dev/null`" ] ; then
  assemble_shellcode() {
    if [ -z "$1" ] ; then echo "Usage: $0 <assembly file>" >&2 ; return 1 ; fi
    local NASM=`command which nasm`
    local OBJDUMP=`command which objdump`
    local TMPF=`mktemp`
    local bytes
    local byte
    $NASM -f elf -o $TMPF $1
    $OBJDUMP -M intel -d $TMPF | grep '^ ' | cut -f2 | while read -A bytes ; do
      for byte in $bytes ; do
        echo -n "\\\\x$byte"
      done
    done
    echo
    rm $TMPF
  }
fi
