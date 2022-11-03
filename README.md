# navigator-scripts
Repository of useful scripts for Navigator 

# Pre-requsites

Some of the scripts rely on the following tooling being setup and configured:

- `git` 
- The `aws-cli` configured for each environment - see Notion
- `pyenv` with a venv created for navigator develpment (see "Use Case 1" below)


> **Note**
> You will also need to copy the `.env.example` to `.env` in the root of the `navigator` repo.

# Installation

1. Check out this repository locally to somewhere appropriate (recommended your home folder):

```
cd $HOME
git checkout git@github.com:climatepolicyradar/navigator-scripts.git
```


2. Add the following line to the end of your `~/.bashrc` or appropriate for your shell:

```
export PATH=$PATH:$HOME/navigator-scripts
```

# Scripts with documentation

## Docker
 - [dkr-copy-volume.sh](docs/dkr-copy-volume.md)
 - [dkr-rm-old-deploy-images.sh](docs/dkr-rm-old-deploy-images.md)

## Navigator
 - [nav-build-status.sh](docs/nav-build-status.md)
 - [nav-ecr-status.sh](docs/nav-ecr-status.md)
 - [nav-env.sh](docs/nav-env.md)
 - [nav-reset.sh](docs/nav-reset.md)

## Data Pipeline
 - [pip-execution-error.sh](docs/pip-execution-error.md)
 - [pip-list-executions.sh](docs/pip-list-executions.md)
 - [pip-show-execution.sh](docs/pip-show-execution.md)

# Use-Cases - Backend

## 1. Run backend code locally and not in docker

You'll need to do this if you want to locally generate migrations or just run a sub set of the tests.

First setup a python venv for the backend package requirements.

```
pyenv versions                     ## Determine what is already installed.
pyenv install 3.9.13               ## Install python at the correct version.
pyenv virtualenv 3.9.13 navigator  ## Create a new venv called navigator.
pyenv activate navigator           ## Activate the venv.
pip install poetry                 ## Install our selected package manager in the venv.
poetry install                     ## Install all the packages needed.
```

Now setup your local environment (this only needs to be done once for a shell).

```
. nav-env.sh
```
## 2. Run the alembic migrations  

After you have configured your env (see 1) -  you should be able to run for example the alembic generation of migrations:
```
alembic revision --autogenerate -m my-new-migration
```

## 3. Run a specific test

After you have configured your env (see 1) - you can run all the tests with just `pytest` like running `make test_backend`. 
Or, you can run a specific test. But first you might want to clean you environment with:

``` 
nav-reset.sh                        ## Run this if you want to ensure a clean start
docker-compose up --no-start        ## Make sure all the containers are built and created
docker start navigator_backend_db_1 ## Just run the backend_db
```

Now you'll be ready to run, for example just the document endpoint tests with:
```
cd backend
pytest tests/routes/test_documents.py 

```

## 4. Run a test when files change

If you have successfully setup (3) to run a specific test, you can now run these whenever a file changes with:

```
cd $(git rev-parse --show-toplevel)/backend
find $PWD | entr pytest tests/routes/test_documents.py
```

## 5. View the state of CI for navigator

For this you'll need to install the github-cli from https://github.com/cli/cli/.
Then you can run the following command to look at the most recent runs, these commands have 

```
gh workflow view CI      ## Output to shell
gh workflow view CI -w   ## Open in browser
```

If you want to use the shell then from the last column of this output - you can look at a particular run with:

```
gh run view 3298507580
```

and from there see the details of a particular job:
```
gh run view --job=9032964313
```

## 6. View the CI state for all navigator repos

Simples:

```
nav-build-status.sh
```

## 7. Run a python script against staging (e.g. initial_data.py)

There are certain times when you will want to run a python script against staging or in some circumstances, production. 
It should go without saying - any script run should have been reviewed and in a [CPR repository](https://github.com/climatepolicyradar.org)

Before proceeding ensure that your `AWS_PROFILE` matches the pulumi stack you have selected. Then:

```
source nav-env.sh                       ## Use your default env vars
nav-stack-connect.sh                    ## Connect to the stack you've selected in pulumi - see docs/nav-stack-connect.md
source ~/.aws/${AWS_PROFILE}_vars.sh    ## The exact file will be shown in the output of the above script
```

That should be your environment setup and ready to run the script. For example the `initial_data.py` script to populate the database
with the default values, you can now run from the `backend` directory:

```
PYTHONPATH=$PWD python app/initial_data.py skip-wait
```

## 7. Push a local Docker image to ECR

This should only be done to sandbox - as the other ECR repositories have images pushed in CI only.

The example below was used for running a front end with App Runner. This pushes a local image called `navigator_frontend:latest` to the remote ECR registry in `${DOCKER_REGISTRY}` renamed to `cclw:latest` ready to be used by App Runner

```
export AWS_PROFILE=sandbox
export DOCKER_REGISTRY=281621126254.dkr.ecr.eu-west-1.amazonaws.com

aws ecr get-login-password --region eu-west-1 |  docker login --username AWS --password-stdin "${DOCKER_REGISTRY}"
docker tag navigator_frontend:latest  ${DOCKER_REGISTRY}/cclw:latest
docker push ${DOCKER_REGISTRY}/cclw:latest
```

# Use-Cases - Pipeline

## 1. View the state of a StepFunction execution

Setup up `AWS_PROFILE`, if using the staging / dev environment then `AWS_PROFILE=dev`

```
aws stepfunctions list-state-machines
# Look for an arn e.g. arn:aws:states:eu-west-2:073457443605:stateMachine:stateMachine-staging-pipeline-07565ff

# Select the required `stateMachineArn` from above, then
aws stepfunctions list-executions --state-machine-arn arn:aws:states:eu-west-2:073457443605:stateMachine:stateMachine-staging-pipeline-07565ff

# Get the 3 most recent executions
aws stepfunctions list-executions --state-machine-arn arn:aws:states:eu-west-2:073457443605:stateMachine:stateMachine-staging-pipeline-07565ff --query 'reverse(sort_by(executions,& startDate))[0:3]'


# Select the required `executionArn` from the above, then
aws stepfunctions get-execution-history --execution-arn <arn-from-above>

```

## 2. Are there any jobs left in the queue

```
# List all job queues
aws batch describe-job-queues

# See if there is anything in the queue
aws batch list-jobs --job-queue testQueue-8864398

# Describe job 71cb58b5-64dc-4eb3-ae39-e5ee94e2bdb4
aws batch describe-jobs --jobs 71cb58b5-64dc-4eb3-ae39-e5ee94e2bdb4
```


## 3. The state of the S3 buckets
```
# input to the SFN / Ingest input
aws s3 cp s3://cpr-dev-data-pipeline-cache/input/docs_test_subset.json /tmp && cat /tmp/docs_test_subset.json | jq

# Ingest output / Parser input
aws s3 ls s3://cpr-dev-data-pipeline-cache/parser_input/

# Parser output / Embeddings input
aws s3 ls s3://cpr-dev-data-pipeline-cache/embeddings_input/

# Embeddings output /  Indexer input
aws s3 ls s3://cpr-dev-data-pipeline-cache/indexer_input/

```


## 4. View the latest ECR images for pipeline

Simples:

```
nav-ecr-status.sh
```

----

# Other useful tools

- `entr` https://github.com/eradman/entr (A utility for running arbitrary commands when files change. )
- `gh` https://github.com/cli/cli/ (The github cli)
- `jq` https://github.com/stedolan/jq  (a lightweight and flexible command-line JSON processor)
