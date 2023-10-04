#!/bin/bash

###############################################################################
# See: docs/nav-stack-connect.md
###############################################################################

OUTPUT=$(mktemp)
SH="gnome-terminal  -- "

if [ -z "${AWS_PROFILE}" ] ; then  echo "no AWS profile selected" ; exit 1 ; fi

# Changed to backend for new repo "navigator-infra"
cd $(git rev-parse --show-toplevel)/backend
echo
echo "🔨 Current Pulumi Stack..."
pulumi stack ls

echo
echo "🔨 Getting config..."

pulumi stack output > ${OUTPUT} 
DB_USER=$(pulumi config get backend:rds_username)
DB_PASS=$(pulumi config get backend:rds_password)
RDS_ADDRESS=$(pulumi config get backend:rds_address)
BASTION_TARGET=$(grep bastion.id ${OUTPUT} | cut -d ' ' -f7 )
echo
echo "🔨 Building db connection string..."

# These values are exported so you can use a script in your current shell
VAR_FILE=~/.aws/${AWS_PROFILE}_vars.sh
echo export DATABASE_URL=postgresql://${DB_USER}:${DB_PASS}@localhost:5434/navigator > ${VAR_FILE}
echo export SECRET_KEY=$(pulumi config get backend:backend_secret_key) >> ${VAR_FILE}
echo export SUPERUSER_EMAIL=$(pulumi config get backend:superuser_email) >> ${VAR_FILE}
echo export SUPERUSER_PASSWORD=$(pulumi config get backend:superuser_password) >> ${VAR_FILE}
echo export PGUSER=$DB_USER >> ${VAR_FILE}
echo export PGPASSWORD=$DB_PASS >> ${VAR_FILE}
echo export PGPORT=5434 >> ${VAR_FILE}
echo export PGDATABASE=navigator >> ${VAR_FILE}
chmod 0600 ${VAR_FILE}

echo
echo "🔨 Starting tunnel, using ${BASTION_TARGET}..."

${SH} aws --profile ${AWS_PROFILE} --region eu-west-1 ssm start-session --target ${BASTION_TARGET}
${SH} aws --profile ${AWS_PROFILE} --region eu-west-1 ssm start-session --target ${BASTION_TARGET} --document-name AWS-StartPortForwardingSession --parameters '{"portNumber":["5432"],"localPortNumber":["5434"]}'
echo 
echo "☑️  Run the following command in the terminal with the sh prompt:"
echo "    socat TCP-LISTEN:5432,reuseaddr,fork TCP4:${RDS_ADDRESS}:5432"

echo
echo "⚠️  To use any scripts in this shell, please 'source ${VAR_FILE}'"
echo
