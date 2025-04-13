#!/bin/bash

sudo yum update -y
curl -sL https://rpm.nodesource.com/setup_18.x | sudo bash -
sudo yum install -y nodejs git

# App setup
git clone https://github.com/corinedevs/backend-app-test /home/ec2-user/app
cd /home/ec2-user/app

# Example env setup
cat <<EOF > .env
PORT=${port}
PG_HOST=${pg_host}
PG_USER=${pg_user}
PG_PASSWORD=${pg_password}
PG_DATABASE=${pg_database}
PG_PORT=${pg_port}
EOF

npm install

# Run app
nohup node index.js > output.log 2>&1 &
