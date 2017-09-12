function _jekyll_locate_dir {
  if [[ -n "${JEKYLL_DIR}" && -f "${JEKYLL_DIR}" ]] ; then
    echo ${JEKYLL_DIR}
  elif test -f `pwd`/_config.yml ; then
    pwd
  elif test -f ${HOME}/Projects/blog/_config.yml ; then
    echo ${HOME}/Projects/blog
  else
    echo "Jekyll instance not found!" >&2
  fi
}

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
  local jekyll_dir

  jekyll_dir="${3}"

  if [ -f "${1}" ] ; then
    printf -- "${1}"
    return 0
  fi
  if [ -f "${jekyll_dir}/_posts/${1}" ] ; then
    printf -- "${jekyll_dir}/_posts/${1}"
    return 0
  fi
  if [ -f "${jekyll_dir}/_drafts/${1}" ] ; then
    printf -- "${jekyll_dir}/_drafts/${1}"
    return 0
  fi
  fname=${2:-${1}}
  files=(${jekyll_dir}/_posts/*${fname}* ${jekyll_dir}/_drafts/*${fname}*)
  if [ ${#files} -eq "0" ] ; then
    echo "No post found for ${fname}" >&2
    return 1
  fi
  if [ ${#files} -gt "1" ] ; then
    echo "Ambiguous results: ${files}" >&2
    return 1
  fi
  printf -- ${files}
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
  local JEKYLL_DIR

  JEKYLL_DIR=`_jekyll_locate_dir`

  if [ -z "${JEKYLL_DIR}" ] ; then
    return 1
  fi

  JTEMPLATE="---\n"
  JTEMPLATE+="layout: post\n"
  JTEMPLATE+="title: \"%s\"\n"
  JTEMPLATE+="category: Blog\n"
  JTEMPLATE+="---\n\n"
  TITLE=${@[2,-1]}
  SLUG=$(echo -n ${TITLE}|tr A-Z a-z|tr -c -s -- a-z0-9 -)
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
      if [ -z "${SLUG}" ] ; then
        echo "slug is required."
        return 1
      fi
      mkdir -p "${JEKYLL_DIR}/_drafts"
      FILENAME="${JEKYLL_DIR}/_drafts/${SLUG}.md"
      printf -- "${JTEMPLATE}" "${TITLE}" > "${FILENAME}"
      vim "${FILENAME}" '+$' '+startinsert'
      ;;
    post)
      if [ -z "${SLUG}" ] ; then
        echo "slug is required."
        return 1
      fi
      FILENAME="${JEKYLL_DIR}/_posts/${DATE}-${SLUG}.md"
      printf -- "${JTEMPLATE}" "${TITLE}" > "${FILENAME}"
      _jekyll_set_date "${FILENAME}" "${DATE}"
      vim "${FILENAME}" '+$' '+startinsert'
      ;;
    publish)
      if [ -z "${SLUG}" ] ; then
        echo "slug is required."
        return 1
      fi
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
      if [ -z "${SLUG}" ] ; then
        echo "slug is required."
        return 1
      fi
      FILENAME=$(_jekyll_find_post "${TITLE}" "${SLUG}" "${JEKYLL_DIR}")
      if [ $? -ne 0 ] ; then
        return
      fi
      vim "${FILENAME}"
      ;;
    *)
      command jekyll "$@"
      ;;
  esac
}
