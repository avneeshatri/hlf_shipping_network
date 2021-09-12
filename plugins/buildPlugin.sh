apk add --no-cache      bash    gcc     git     make    musl-dev

cd /go/src/github.com/hyperledger/fabric

/go/src/github.com/hyperledger/fabric/build/bin go build -o release/linux-amd64/bin/customPlugin.so -tags "" -ldflags "-X github.com/hyperledger/fabric/common/metadata.Version=2.2.3 -X github.com/hyperledger/fabric/common/metadata.CommitSHA=8fd2ad8 -X github.com/hyperledger/fabric/common/metadata.BaseDockerLabel=org.hyperledger.fabric -X github.com/hyperledger/fabric/common/metadata.DockerNamespace=hyperledger" github.com/hyperledger/fabric/custom/plugin
