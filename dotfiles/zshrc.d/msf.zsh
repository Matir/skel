function _find_msf {
  local CHOICES=("/opt/metasploit")
  for p in ${CHOICES} ; do
    if [ -d ${p} ] ; then
      export MSF_PATH=${p}
      break
    fi
  done
}

_find_msf

if [ -d ${MSF_PATH}/apps/pro/msf3/ ] ; then
  export PATH="${PATH}:${MSF_PATH}/apps/pro/msf3"
fi
alias pattern_create="${MSF_PATH}/apps/pro/msf3/tools/exploit/pattern_create.rb"
alias pattern_offset="${MSF_PATH}/apps/pro/msf3/tools/exploit/pattern_offset.rb"
