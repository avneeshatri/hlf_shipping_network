export ORG_NAME=GuptaButtons
export ORG_BASE_DIR=/home/atri/workspace_hlf/shipping-network/organizations/gupta.buttons
export ORG_DOMAIN=gupta.buttons.linkinpark.com
export FABRIC_CFG_PATH=$ORG_BASE_DIR/conf
export ORG_MSP_ID=GuptaButtonsMSP
export CHANNEL_NAME=shippingchannel

#++++++++++++++++++++++++++ Generate Crypto ++++++++++++++++++++++
echo "Generating Crypto"
cryptogen generate --config=$ORG_BASE_DIR/conf/crypto-config.yaml --output="$ORG_BASE_DIR/organization"

#+++++++++++++++++++++++++++++++++ Print Org Definition +++++++++++++++
echo "Printing ORG definition"
configtxgen -printOrg $ORG_MSP_ID > $ORG_BASE_DIR/organization/peerOrganizations/$ORG_DOMAIN/$ORG_NAME.json

cd /home/atri/workspace_hlf/shipping-network/bin
sudo docker ps -a

sudo docker-compose -f /home/atri/workspace_hlf/shipping-network/organizations/gupta.buttons/docker/docker-compose-gupatbuttons.yaml up -d

sudo docker exec -it OrgToolscli bash


#++++++++++++++++++++++ Fetch Configuration +++++++++++++++++++++++++++++++++++++++++
export ORDERER_CA=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/orderer/organization/ordererOrganizations/pinkflyod.com/orderers/orderer.pinkflyod.com/msp/tlscacerts/tlsca.pinkflyod.com-cert.pem
export CHANNEL_NAME=shippingchannel
export CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/custom/organization/peerOrganizations/custom.metallica.gov/users/Admin@custom.metallica.gov/msp
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID="CustomMSP"
export CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/custom/organization/peerOrganizations/custom.metallica.gov/peers/peer0.custom.metallica.gov/tls/ca.crt
export CORE_PEER_ADDRESS=localhost:7151



peer channel fetch config config_block.pb -o orderer.pinkflyod.com:8051 -c $CHANNEL_NAME --tls --cafile ${ORDERER_CA}



#+++++++++++++++++++++++++ Convert Config to Json ++++++++++++++++++++++++++++

configtxlator proto_decode --input config_block.pb --type common.Block | jq .data.data[0].payload.data.config > config.json


#Add the new_org Crypto Material
#------------------------------
jq -s '.[0] * {"channel_group":{"groups":{"Application":{"groups": {"GuptaButtonsMSP":.[1]}}}}}' config.json ./organizations/gupta.buttons/organization/peerOrganizations/gupta.buttons.linkinpark.com/GuptaButtons.json > modified_config.json


configtxlator proto_encode --input config.json --type common.Config --output config.pb

configtxlator proto_encode --input modified_config.json --type common.Config --output modified_config.pb

configtxlator compute_update --channel_id $CHANNEL_NAME --original config.pb --updated modified_config.pb --output new_org_update.pb

configtxlator proto_decode --input new_org_update.pb --type common.ConfigUpdate | jq . > new_org_update.json

echo '{"payload":{"header":{"channel_header":{"channel_id":"'$CHANNEL_NAME'", "type":2}},"data":{"config_update":'$(cat new_org_update.json)'}}}' | jq . > new_org_update_in_envelope.json

configtxlator proto_encode --input new_org_update_in_envelope.json --type common.Envelope --output new_org_update_in_envelope.pb



#++++++++++++++++++++++++++++++++ Sign and Submit the Config Update++++++++++++++++++++++++++++++++++++
echo "Sign by custom"
export FABRIC_CFG_PATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/custom/conf
export ORDERER_CA=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/orderer/organization/ordererOrganizations/pinkflyod.com/orderers/orderer.pinkflyod.com/msp/tlscacerts/tlsca.pinkflyod.com-cert.pem

export CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/custom/organization/peerOrganizations/custom.metallica.gov/users/Admin@custom.metallica.gov/msp
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID="CustomMSP"
export CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/custom/organization/peerOrganizations/custom.metallica.gov/peers/peer0.custom.metallica.gov/tls/ca.crt
export CORE_PEER_ADDRESS=peer0.custom.metallica.gov:7151


peer channel signconfigtx -f new_org_update_in_envelope.pb


# Sign shipping

export FABRIC_CFG_PATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/shipping/conf
export CHANNEL_NAME=shippingchannel
export ORDERER_CA=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/orderer/organization/ordererOrganizations/pinkflyod.com/orderers/orderer.pinkflyod.com/msp/tlscacerts/tlsca.pinkflyod.com-cert.pem

export CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/shipping/organization/peerOrganizations/shipping.acdc.com/users/Admin@shipping.acdc.com/msp
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID="ShippingMSP"
export CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/shipping/organization/peerOrganizations/shipping.acdc.com/peers/peer0.shipping.acdc.com/tls/ca.crt
export CORE_PEER_ADDRESS=peer0.shipping.acdc.com:7051

peer channel signconfigtx -f new_org_update_in_envelope.pb

echo "Siginig by Buyer"

export FABRIC_CFG_PATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/button.buyer/conf
export CHANNEL_NAME=shippingchannel
export ORDERER_CA=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/orderer/organization/ordererOrganizations/pinkflyod.com/orderers/orderer.pinkflyod.com/msp/tlscacerts/tlsca.pinkflyod.com-cert.pem

export CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/button.buyer/organization/peerOrganizations/buyer.gunsnroses.com/users/Admin@buyer.gunsnroses.com/msp
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID="BuyerMSP"
export CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/button.buyer/organization/peerOrganizations/buyer.gunsnroses.com/peers/peer0.buyer.gunsnroses.com/tls/ca.crt
export CORE_PEER_ADDRESS=peer0.buyer.gunsnroses.com:7351


peer channel signconfigtx -f new_org_update_in_envelope.pb

echo "Update by buyer"

peer channel update -f new_org_update_in_envelope.pb -c $CHANNEL_NAME -o orderer.pinkflyod.com:8051 --tls --cafile $ORDERER_CA


#+++++++++++++++++++++++++++++++++++++++++++ Join Org3 to the Channel++++++++++++++++++++++++++++++++++++


export CORE_PEER_LOCALMSPID="GuptaButtonsMSP"
export CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/gupta.buttons/organization/peerOrganizations/gupta.buttons.linkinpark.com/peers/peer0.gupta.buttons.linkinpark.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/gupta.buttons/organization/peerOrganizations/gupta.buttons.linkinpark.com/users/Admin@gupta.buttons.linkinpark.com/msp/
export CORE_PEER_ADDRESS=peer0.gupta.buttons.linkinpark.com:7451

peer channel fetch 0 shipping.block -o orderer.pinkflyod.com:8051 -c $CHANNEL_NAME --tls --cafile $ORDERER_CA

peer channel join -b shipping.block


