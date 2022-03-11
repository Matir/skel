function dumpenv {
  tr '\0' '\n' < /proc/${1}/environ
}
