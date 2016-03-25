JEKYLL_DIR=${JEKYLL_DIR:-${HOME}/Projects/blog}

function _jekyll_set_date {
  local FILENAME
  local DATE
  FILENAME=${1}
  DATE=${2}
  sed -i "2,/---/{s/^date:.*$/date: ${DATE}/;s/---/date: ${DATE}\n---/}" ${FILENAME}
}

function _jekyll_find_post {
  local files
  local fname
  if [ -f "${1}" ] ; then
    printf "${1}"
    return 0
  fi
  fname=${2:-${1}}
  files=(${JEKYLL_DIR}/_posts/*${fname}* ${JEKYLL_DIR}/_drafts/*${fname}*)
  if [ ${#files} -eq "0" ] ; then
    echo "No post found for ${fname}" >&2
    return 1
  fi
  if [ ${#files} -gt "1" ] ; then
    echo "Ambiguous results: ${files}" >&2
    return 1
  fi
  printf ${files}
  return 0
}

function jekyll {
  setopt localoptions nullglob
  local JTEMPLATE
  local TITLE
  local SLUG
  local FILENAME
  local DATE
  local NEWNAME

  JTEMPLATE="---\n"
  JTEMPLATE+="layout: post\n"
  JTEMPLATE+="title: %s\n"
  JTEMPLATE+="category: Blog\n"
  JTEMPLATE+="---\n"
  TITLE=${@[2,-1]}
  SLUG=$(echo -n ${TITLE}|tr A-Z a-z|tr -c -s -- a-z -)
  DATE=`date +%Y-%m-%d`

  case "${1:-help}" in
    help|--help)
      command jekyll help
      echo "Added by oh-my-zsh plugin:"
      echo "  draft                 Create a new draft post."
      echo "  post                  Create a new post to publish immediately."
      echo "  publish               Publish a draft post by name."
      echo "  edit                  Edit a post."
      ;;
    draft)
      mkdir -p "${JEKYLL_DIR}/_drafts"
      FILENAME="${JEKYLL_DIR}/_drafts/${SLUG}.md"
      printf "${JTEMPLATE}" "${TITLE}" > "${FILENAME}"
      vim "${FILENAME}" '+$'
      ;;
    post)
      FILENAME="${JEKYLL_DIR}/_posts/${DATE}-${SLUG}.md"
      printf "${JTEMPLATE}" "${TITLE}" > "${FILENAME}"
      _jekyll_set_date "${FILENAME}" "${DATE}"
      vim "${FILENAME}" '+$'
      ;;
    publish)
      FILENAME=$(_jekyll_find_post "${TITLE}" "${SLUG}")
      if [ $? -ne 0 ] ; then
        return
      fi
      if ! [[ "${FILENAME}" =~ '/_drafts/' ]] ; then
        echo "${FILENAME} is not a draft." >&2
        return
      fi
      NEWNAME=$(echo "${FILENAME}" | sed "s/_drafts\//_posts\/${DATE}-/")
      mv "${FILENAME}" "${NEWNAME}"
      _jekyll_set_date "${NEWNAME}" "${DATE}"
      ;;
    edit)
      FILENAME=$(_jekyll_find_post "${TITLE}" "${SLUG}")
      if [ $? -ne 0 ] ; then
        return
      fi
      vim "${FILENAME}" '+$'
      ;;
    *)
      command jekyll "$@"
      ;;
  esac
}
