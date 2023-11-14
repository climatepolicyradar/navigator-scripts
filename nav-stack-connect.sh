#!/bin/bash

###############################################################################
# See: docs/nav-stack-connect.md
###############################################################################

OUTPUT=$(mktemp)

if [ -z "${AWS_PROFILE}" ] ; then  
    PS3="No AWS_PROFILE set, type one here: "

    select aws_profile in staging prod production q
    do
        case $aws_profile in
            "staging")
                AWS_PROFILE=$aws_profile; break;;
            "prod")
                AWS_PROFILE=$aws_profile; break;;
            "production")
                AWS_PROFILE=$aws_profile; break;;
            "q")
                exit;;
            *)
            echo "Ooops";;
        esac
    done
fi

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
RDS_DB=$(pulumi config get backend:rds_database)
BASTION_TARGET=$(grep bastion.id ${OUTPUT} | cut -d ' ' -f7 )
echo
echo "🔨 Building db connection string..."

# These values are exported so you can use a script in your current shell
VAR_FILE=~/.aws/${AWS_PROFILE}_vars.sh
echo export DATABASE_URL=postgresql://${DB_USER}:${DB_PASS}@localhost:5434/${RDS_DB} > ${VAR_FILE}
echo export BACKEND_DATABASE_URL=postgresql://${DB_USER}:${DB_PASS}@localhost:5434/${RDS_DB} >> ${VAR_FILE}
echo export SECRET_KEY=$(pulumi config get backend:backend_secret_key) >> ${VAR_FILE}
echo export SUPERUSER_EMAIL=$(pulumi config get backend:superuser_email) >> ${VAR_FILE}
echo export SUPERUSER_PASSWORD=$(pulumi config get backend:superuser_password) >> ${VAR_FILE}
echo export PGUSER=$DB_USER >> ${VAR_FILE}
echo export PGPASSWORD=$DB_PASS >> ${VAR_FILE}
echo export PGPORT=5434 >> ${VAR_FILE}
echo export PGHOST=localhost >> ${VAR_FILE}
echo export PGDATABASE=${RDS_DB} >> ${VAR_FILE}
chmod 0600 ${VAR_FILE}

echo
echo "🔨 Starting tunnel, using ${BASTION_TARGET}..."

if [ "$(uname -s)" = "Darwin" ] ; then
osascript <<END
    tell app "Terminal"
        do script "aws --profile ${AWS_PROFILE} --region eu-west-1 ssm start-session --target ${BASTION_TARGET}"
        do script "aws --profile ${AWS_PROFILE} --region eu-west-1 ssm start-session --target ${BASTION_TARGET} --document-name AWS-StartPortForwardingSession --parameters '{\"portNumber\":[\"5432\"],\"localPortNumber\":[\"5434\"]}'"
    end tell
END

else
    SH="gnome-terminal  -- "
    ${SH} aws --profile ${AWS_PROFILE} --region eu-west-1 ssm start-session --target ${BASTION_TARGET}
    ${SH} aws --profile ${AWS_PROFILE} --region eu-west-1 ssm start-session --target ${BASTION_TARGET} --document-name AWS-StartPortForwardingSession --parameters '{"portNumber":["5432"],"localPortNumber":["5434"]}'
fi

echo 
echo "☑️  Run the following command in the terminal with the sh prompt:"
echo "    socat TCP-LISTEN:5432,reuseaddr,fork TCP4:${RDS_ADDRESS}:5432"

echo
echo "⚠️  To use any scripts in this shell, please 'source ${VAR_FILE}'"
echo
