mkdir -p /home/atri 
cd /home/atri/ 
wget https://golang.org/dl/go1.15.7.linux-amd64.tar.gz
tar -xvf go1.15.7.linux-amd64.tar.gz -C /usr/local/
apk add git
git clone https://github.com/hyperledger/fabric.git
cd fabric
https://github.com/hyperledger/fabric.git
cp -r /tmp/custom/ .
export PATH=$PATH:$GOROOT/bin
apk add --no-cache libc6-compatx
apk add build-base


GOOS=linux GOARCH=amd64 CGO_ENABLED=1 go build -o release/linux-amd64/bin/customPlugin.so -tags "" -ldflags "-X github.com/hyperledger/fabric/common/metadata.Version=2.2.3 -X github.com/hyperledger/fabric/common/metadata.CommitSHA=8fd2ad8c6 -X github.com/hyperledger/fabric/common/metadata.BaseDockerLabel=org.hyperledger.fabric -X github.com/hyperledger/fabric/common/metadata.DockerNamespace=hyperledger" -buildmode=plugin  github.com/hyperledger/fabric/custom/plugin

go run custom/test/plugin_check.go
