function site2pdf {
  setopt localoptions nounset
  local URL=${1}
  local OUTFILE=${2}
  command wkhtmltopdf -s Letter -q ${URL} ${OUTFILE}
}
