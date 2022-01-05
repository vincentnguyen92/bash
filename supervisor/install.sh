#!/bin/bash
set -u

# Define variables
GITHUB_URL=https://raw.githubusercontent.com/vincentnguyen92/bash/master/supervisor
SUPERVISOR_DIR=/etc/supervisor

# The first at all we should to kill supervisord when the supervisord is running
pgrep supervisord && kill "$(pgrep supervisord)"

# If you want to have more than one application, and in just one of them to run the supervisor, uncomment the lines below, 
# and add the env variable IS_WORKER as true in the EBS application you want the supervisor
if [ "${IS_WORKER}" != "true" ]; then
    echo "Not a worker. Set variable IS_WORKER=true to run supervisor on this instance"
    exit 0
fi

echo "Supervisor - starting setup"
if [ ! -f /usr/bin/supervisord ]; then
    echo "Installing supervisor"
    easy_install supervisor || { echo "easy_install setup failure" && exit 1; }
else
    echo "Supervisor already installed"
fi

if [ ! -d /etc/supervisor ]; then
    mkdir /etc/supervisor
    echo "Create supervisor directory"
fi

if [ ! -d /etc/supervisor/conf.d ]; then
    mkdir /etc/supervisor/conf.d
    echo "Create supervisor configs directory"
fi

# Get the config files from GITHUB_URL
{
    curl ${GITHUB_URL}/supervisord.conf --output ${SUPERVISOR_DIR}/supervisord.conf && \
    curl ${GITHUB_URL}/sqs_queue_default.conf --output ${SUPERVISOR_DIR}/conf.d/sqs_queue_default.conf
} || echo "Get the files failure" && exit 1

if [ "${WORKER_ENV}" == "live" ]; then
    curl ${GITHUB_URL}/sqs_queue_live_notification.conf --output ${SUPERVISOR_DIR}/conf.d/sqs_queue_live_notification.conf && \
    curl ${GITHUB_URL}/sqs_queue_live_product.conf --output ${SUPERVISOR_DIR}/conf.d/sqs_queue_live_product.conf && \
    curl ${GITHUB_URL}/sqs_queue_live_store.conf --output ${SUPERVISOR_DIR}/conf.d/sqs_queue_live_store.conf
fi

echo "Starting supervisor"
{
    /usr/bin/supervisord && /usr/bin/supervisorctl reread && /usr/bin/supervisorctl update && \
    echo "Supervisor Is Running!"
} || echo "Something wrong...!"
