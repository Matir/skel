if [ -d $HOME/Projects/blog/_posts ] ; then
  function new_blog_post {
    if [ $# -ne 1 ] ; then
      echo "Usage: $0 <title>"
      return 1
    fi
    WHEN=`date +%Y-%m-%d`
    SLUG=$(echo -n $1|tr A-Z a-z|tr -c -s -- a-z -)
    POSTS="${HOME}/Projects/blog/_posts"
    FNAME="${POSTS}/${WHEN}-${SLUG}.md"
    cat <<EOF >${FNAME}
---
layout: post
title: "${1}"
date: ${WHEN}
category: BLAH
---
EOF
    vi ${FNAME}
  }
fi
