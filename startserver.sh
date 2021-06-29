# Gunicorn

#!/usr/bin/env bash
# start-server.sh
fi
(cd testeDocker2; gunicorn testeDocker2.wsgi --user www-data --bind 0.0.0.0:8000 --workers 3) &
nginx -g "daemon off;"