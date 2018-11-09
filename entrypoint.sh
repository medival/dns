#!/bin/sh

printf " ========================================="
printf " =========================================\n"
printf " === CLOUDFLARE DNS OVER TLS CONTAINER ===\n"
printf " =========================================\n"
printf " =========================================\n"
printf " == by github.com/qdm12 - Quentin McGaw ==\n\n"

cat /etc/unbound/include.conf &> /dev/null
if [ $? != 0 ]; then
  printf "Can't access /etc/unbound/include.conf\n"
  printf "Please mount the file by setting its ownership and permissions with:\n"
  printf "  chown 1000:1000 include.conf && chmod 400 include.conf\n"
  exit 1
fi
printf "Unbound version: $(unbound -h | grep "Version" | cut -d" " -f2)\n"
printf "Verbosity level set to $VERBOSITY\n"
printf "Verbosity details level set to $VERBOSITY_DETAILS\n"
printf "Malicious hostnames and ips blocking is $BLOCK_MALICIOUS\n"
[[ "$VERBOSITY" == "" ]] || sed -i "s/verbosity: 0/verbosity: $VERBOSITY/g" /etc/unbound/unbound.conf
[[ "$VERBOSITY_DETAILS" == "" ]] || [[ "$VERBOSITY_DETAILS" == "0" ]] || ARGS=-$(for i in `seq $VERBOSITY_DETAILS`; do printf "v"; done)
if [ "$BLOCK_MALICIOUS" = "on" ] && [ ! -f /etc/unbound/blocks-malicious.conf ]; then
    printf "Extracting malicious hostnames archive...\n"
    tar -xjf /etc/unbound/malicious-hostnames.bz2 -C /etc/unbound/
    printf "Extracting malicious IPs archive...\n"
    tar -xjf /etc/unbound/malicious-ips.bz2 -C /etc/unbound/
    printf "Building blocks-malicious.conf for Unbound...\n"
    while read hostname; do
        echo "local-zone: \""$hostname"\" static" >> /etc/unbound/blocks-malicious.conf
    done < /etc/unbound/malicious-hostnames
    while read ip; do
        echo "private-address: $ip" >> /etc/unbound/blocks-malicious.conf
    done < /etc/unbound/malicious-ips
    printf " => $(cat /etc/unbound/malicious-hostnames | wc -l ) malicious hostnames and $(cat /etc/unbound/malicious-ips | wc -l) malicious IP addresses added\n"
    rm -f /etc/unbound/malicious-hostnames* /etc/unbound/malicious-ips*
else
    touch /etc/unbound/blocks-malicious.conf
fi
unbound -d $ARGS
status=$?
printf "\n =========================================\n"
printf " Unbound exit with status $status\n"
printf " =========================================\n"