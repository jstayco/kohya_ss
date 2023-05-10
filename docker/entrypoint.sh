#!/bin/sh

# Set the timezone
if [ -z "$TZ" ]; then
  echo "No timezone specified. Using the system's default timezone."
else
  ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
  echo "Timezone set to $TZ"
fi

# Call the launcher.py with all the optional arguments
exec python3 ./launcher.py --no-setup \
$(if [ -n "${FILE}" ]; then echo "--file=${FILE}"; fi) \
    $(if [ "${HEADLESS}" = "true" ]; then echo "--headless"; fi) \
    $(if [ -n "${LOG_DIR}" ]; then echo "--log-dir=${LOG_DIR}"; fi) \
    $(if [ -n "${VERBOSITY}" ]; then echo "-$(printf 'v%.0s' $(seq 1 ${VERBOSITY}))"; fi) \
    $(if [ -n "${LISTEN}" ]; then echo "--listen=${LISTEN}"; fi) \
    $(if [ -n "${USERNAME}" ]; then echo "--username=${USERNAME}"; fi) \
    $(if [ -n "${PASSWORD}" ]; then echo "--password=${PASSWORD}"; fi) \
    $(if [ -n "${SERVER_PORT}" ]; then echo "--server-port=${SERVER_PORT}"; fi) \
    $(if [ "${INBROWSER}" = "true" ]; then echo "--inbrowser"; fi) \
    $(if [ "${SHARE}" = "true" ]; then echo "--share"; fi)
