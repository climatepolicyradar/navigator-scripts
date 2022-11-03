#!/bin/bash

###############################################################################
# See: docs/nav-stack-connect.md
###############################################################################

OUTPUT=$(mktemp)
SH="gnome-terminal  -- "

if [ -z "${AWS_PROFILE}" ] ; then  echo "no AWS profile selected" ; exit 1 ; fi

cd $(git rev-parse --show-toplevel)/infra
echo
echo "🔨 Current Pulumi Stack..."
pulumi stack ls

echo
echo "🔨 Getting config..."

pulumi stack output > ${OUTPUT} 
DB_USER=$(pulumi config get infra:db_username)
DB_PASS=$(pulumi config get infra:db_password)
RDS_ADDRESS=$(grep rds.address ${OUTPUT} | cut -c40-)
BASTION_TARGET=$(grep bastion.id ${OUTPUT} | cut -c40-)
echo
echo "🔨 Building db connection string..."

# These values are exported so you can use a script in your current shell
VAR_FILE=~/.aws/${AWS_PROFILE}_vars.sh
echo export DATABASE_URL=postgresql://${DB_USER}:${DB_PASS}@localhost:5434/navigator > ${VAR_FILE}
echo export BACKEND_DATABASE_URL=postgresql://${DB_USER}:${DB_PASS}@localhost:5434/navigator >> ${VAR_FILE}
echo export SECRET_KEY=$(pulumi config get infra:backend_secret_key) >> ${VAR_FILE}
echo export SUPERUSER_EMAIL=$(pulumi config get infra:SUPERUSER_EMAIL) >> ${VAR_FILE}
echo export SUPERUSER_PASSWORD=$(pulumi config get infra:SUPERUSER_PASSWORD) >> ${VAR_FILE}

echo
echo "🔨 Starting tunnel, using ${BASTION_TARGET}..."

${SH} aws --profile ${AWS_PROFILE} --region eu-west-2 ssm start-session --target ${BASTION_TARGET}
${SH} aws --profile ${AWS_PROFILE} --region eu-west-2 ssm start-session --target ${BASTION_TARGET} --document-name AWS-StartPortForwardingSession --parameters '{"portNumber":["5432"],"localPortNumber":["5434"]}'
echo 
echo "☑️  Run the following command in the terminal with the sh prompt:"
echo "    socat TCP-LISTEN:5432,reuseaddr,fork TCP4:${RDS_ADDRESS}:5432"

echo
echo "⚠️  To use any scripts in this shell, please 'source ${VAR_FILE}'"
echo
