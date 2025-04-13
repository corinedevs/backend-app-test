#!/bin/bash
sudo yum update -y
curl -sL https://rpm.nodesource.com/setup_18.x | sudo bash -
sudo yum install -y nodejs git

# App setup
git clone https://github.com/corinedevs/backend-app-test /home/ec2-user/app
cd /home/ec2-user/app

# Example env setup
cat <<EOF > .env
PORT=3000
PG_HOST=your-db-host
PG_USER=your-user
PG_PASSWORD=your-pass
PG_DATABASE=your-db
EOF

npm install

# Run app
nohup node index.js > output.log 2>&1 &
