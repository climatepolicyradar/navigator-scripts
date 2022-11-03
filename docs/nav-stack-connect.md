# nav-stack-connect

This script allows you to connect your local PC to the remote RDS instance. 
This is done by selecting the relevant pulumi stack (hence the name).
From the `/infra` folder of the `navigator` repo select the stack with, e.g.:

```
pulumi stack select staging
```

Once complete set your AWS_PROFILE to the appropriate account in your environment or when you run the script:

```
AWS_PROFILE=dev nav-stack-connect.sh
```

When the script runs it will produce two extra `gnome-terminal`s (if you're using a Mac we need to update this):
  - one tunnels the remote port `5432` to the local port `5434` - this will open with the tunnel already running.
  - the second will tunnel the RDS instance to the bastion, but you will need you to copy and paste the `socat` command from the output of the script into the terminal to start this.
  **NOTE**: If the bastion has been rebuild the `socat` command may not be installed, you can do with with `sudo yum install socat`

Once the tunnels are runnning you should be able to connect to the remote database on the port `5435`

In order to run any commands / scripts that use the database you will need to set the relevant env vars. 
There will be a script you can source to do this, use:

```
source ~/.aws/${AWS_PROFILE}_vars.sh
```