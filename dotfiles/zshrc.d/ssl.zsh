retrieve_ssl_certificate_chain() {
  openssl s_client -connect $1 -showcerts < /dev/null | awk \
    ' BEGIN { incert = 0 }
      /-----BEGIN CERTIFICATE-----/ { incert = 1 }
      incert == 1 { print $0 }
      /-----END CERTIFICATE-----/ { incert = 0 }
    ' 2>/dev/null
}
