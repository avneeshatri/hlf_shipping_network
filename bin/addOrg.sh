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


#Start docker containers
#---------------------------

cd /home/atri/workspace_hlf/shipping-network/bin
sudo docker ps -a

echo "Star docker containers"

sudo docker-compose -f /home/atri/workspace_hlf/shipping-network/organizations/gupta.buttons/docker/docker-compose-gupatbuttons.yaml up -d 2>&1
rc=$?

if [[ $rc -ne 0 ]];then
	echo "Terminating process"
	exit 1
fi

#exit 0

#++++++++++++++++++++++ Fetch Configuration +++++++++++++++++++++++++++++++++++++++++


############################################################################
#Config is fetched by a existing member of consortium and shared with the 
#New Org which wants to be part of network
############################################################################

export FABRIC_CFG_PATH=/home/atri/workspace_hlf/shipping-network/organizations/custom/conf

export ORDERER_CA=/home/atri/workspace_hlf/shipping-network/organizations/orderer/organization/ordererOrganizations/pinkflyod.com/orderers/orderer.pinkflyod.com/msp/tlscacerts/tlsca.pinkflyod.com-cert.pem

export CORE_PEER_MSPCONFIGPATH=/home/atri/workspace_hlf/shipping-network/organizations/custom/organization/peerOrganizations/custom.metallica.gov/users/Admin@custom.metallica.gov/msp
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID="CustomMSP"
export CORE_PEER_TLS_ROOTCERT_FILE=/home/atri/workspace_hlf/shipping-network/organizations/custom/organization/peerOrganizations/custom.metallica.gov/peers/peer0.custom.metallica.gov/tls/ca.crt
export CORE_PEER_ADDRESS=localhost:7151


peer channel fetch config  /home/atri/workspace_hlf/shipping-network/organizations/network/staging/${ORG_MSP_ID}_config_block.pb -o localhost:8051 --ordererTLSHostnameOverride orderer.pinkflyod.com -c $CHANNEL_NAME --tls --cafile ${ORDERER_CA}


#+++++++++++++++++++++++++ Convert Config to Json ++++++++++++++++++++++++++++


configtxlator proto_decode --input /home/atri/workspace_hlf/shipping-network/organizations/network/staging/${ORG_MSP_ID}_config_block.pb --type common.Block --output /home/atri/workspace_hlf/shipping-network/organizations/network/staging/${ORG_MSP_ID}_config_block.json

jq .data.data[0].payload.data.config /home/atri/workspace_hlf/shipping-network/organizations/network/staging/${ORG_MSP_ID}_config_block.json > /home/atri/workspace_hlf/shipping-network/organizations/network/staging/${ORG_MSP_ID}_config.json

#++++++++++++++++++++++++++ Add New Org crypto materials ++++++++++++++++++++++++++

#Append the New Org configuration definition – [$ORG_BASE_DIR/organization/peerOrganizations/$ORG_DOMAIN/$ORG_NAME.json] – to the channel’s application groups field, and name the output

org_config=$(cat $ORG_BASE_DIR/organization/peerOrganizations/$ORG_DOMAIN/$ORG_NAME.json)


cat /home/atri/workspace_hlf/shipping-network/organizations/network/staging/${ORG_MSP_ID}_config.json | jq .channel_group.groups.Application.groups.GuptaButtonsMSP="${org_config}" > /home/atri/workspace_hlf/shipping-network/organizations/network/staging/${ORG_MSP_ID}_modified_config.json

#translate *_config.json back into a protobuf called config.pb


configtxlator proto_encode --input /home/atri/workspace_hlf/shipping-network/organizations/network/staging/${ORG_MSP_ID}_config.json --type common.Config --output /home/atri/workspace_hlf/shipping-network/organizations/network/staging/${ORG_MSP_ID}_config.pb


#encode modified_config.json to modified_config.pb

configtxlator proto_encode --input /home/atri/workspace_hlf/shipping-network/organizations/network/staging/${ORG_MSP_ID}_modified_config.json --type common.Config --output /home/atri/workspace_hlf/shipping-network/organizations/network/staging/${ORG_MSP_ID}_modified_config.pb


#configtxlator to calculate the delta between these two config protobufs

configtxlator compute_update --channel_id $CHANNEL_NAME --original /home/atri/workspace_hlf/shipping-network/organizations/network/staging/${ORG_MSP_ID}_config.pb --updated /home/atri/workspace_hlf/shipping-network/organizations/network/staging/${ORG_MSP_ID}_modified_config.pb --output /home/atri/workspace_hlf/shipping-network/organizations/network/staging/${ORG_MSP_ID}_update.pb


#Decode this object into editable JSON format and call it 

configtxlator proto_decode --input /home/atri/workspace_hlf/shipping-network/organizations/network/staging/${ORG_MSP_ID}_update.pb --type common.ConfigUpdate --output /home/atri/workspace_hlf/shipping-network/organizations/network/staging/${ORG_MSP_ID}_update.json

#wrap in an envelope message

echo '{"payload":{"header":{"channel_header":{"channel_id":"'$CHANNEL_NAME'", "type":2}},"data":{"config_update":'$(cat /home/atri/workspace_hlf/shipping-network/organizations/network/staging/${ORG_MSP_ID}_update.json)'}}}' | jq . > /home/atri/workspace_hlf/shipping-network/organizations/network/staging/${ORG_MSP_ID}_update_in_envelope.json


# convert it into the fully fledged protobuf format that Fabric requires
configtxlator proto_encode --input /home/atri/workspace_hlf/shipping-network/organizations/network/staging/${ORG_MSP_ID}_update_in_envelope.json --type common.Envelope --output /home/atri/workspace_hlf/shipping-network/organizations/network/staging/${ORG_MSP_ID}_update_in_envelope.pb


#++++++++++++++++++++++++++++++++ Sign and Submit the Config Update++++++++++++++++++++++++++++++++++++
echo "Sign by custom"
export FABRIC_CFG_PATH=/home/atri/workspace_hlf/shipping-network/organizations/custom/conf
export ORDERER_CA=/home/atri/workspace_hlf/shipping-network/organizations/orderer/organization/ordererOrganizations/pinkflyod.com/orderers/orderer.pinkflyod.com/msp/tlscacerts/tlsca.pinkflyod.com-cert.pem

export CORE_PEER_MSPCONFIGPATH=/home/atri/workspace_hlf/shipping-network/organizations/custom/organization/peerOrganizations/custom.metallica.gov/users/Admin@custom.metallica.gov/msp
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID="CustomMSP"
export CORE_PEER_TLS_ROOTCERT_FILE=/home/atri/workspace_hlf/shipping-network/organizations/custom/organization/peerOrganizations/custom.metallica.gov/peers/peer0.custom.metallica.gov/tls/ca.crt
export CORE_PEER_ADDRESS=localhost:7151


peer channel signconfigtx -f /home/atri/workspace_hlf/shipping-network/organizations/network/staging/${ORG_MSP_ID}_update_in_envelope.pb


# Sign shipping

export FABRIC_CFG_PATH=/home/atri/workspace_hlf/shipping-network/organizations/shipping/conf
export CHANNEL_NAME=shippingchannel
export ORDERER_CA=/home/atri/workspace_hlf/shipping-network/organizations/orderer/organization/ordererOrganizations/pinkflyod.com/orderers/orderer.pinkflyod.com/msp/tlscacerts/tlsca.pinkflyod.com-cert.pem

export CORE_PEER_MSPCONFIGPATH=/home/atri/workspace_hlf/shipping-network/organizations/shipping/organization/peerOrganizations/shipping.acdc.com/users/Admin@shipping.acdc.com/msp
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID="ShippingMSP"
export CORE_PEER_TLS_ROOTCERT_FILE=/home/atri/workspace_hlf/shipping-network/organizations/shipping/organization/peerOrganizations/shipping.acdc.com/peers/peer0.shipping.acdc.com/tls/ca.crt
export CORE_PEER_ADDRESS=localhost:7051

peer channel signconfigtx -f /home/atri/workspace_hlf/shipping-network/organizations/network/staging/${ORG_MSP_ID}_update_in_envelope.pb

echo "Siginig by Buyer"

export FABRIC_CFG_PATH=/home/atri/workspace_hlf/shipping-network/organizations/button.buyer/conf
export CHANNEL_NAME=shippingchannel
export ORDERER_CA=/home/atri/workspace_hlf/shipping-network/organizations/orderer/organization/ordererOrganizations/pinkflyod.com/orderers/orderer.pinkflyod.com/msp/tlscacerts/tlsca.pinkflyod.com-cert.pem

export CORE_PEER_MSPCONFIGPATH=/home/atri/workspace_hlf/shipping-network/organizations/button.buyer/organization/peerOrganizations/buyer.gunsnroses.com/users/Admin@buyer.gunsnroses.com/msp
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID="BuyerMSP"
export CORE_PEER_TLS_ROOTCERT_FILE=/home/atri/workspace_hlf/shipping-network/organizations/button.buyer/organization/peerOrganizations/buyer.gunsnroses.com/peers/peer0.buyer.gunsnroses.com/tls/ca.crt
export CORE_PEER_ADDRESS=localhost:7351


peer channel signconfigtx -f /home/atri/workspace_hlf/shipping-network/organizations/network/staging/${ORG_MSP_ID}_update_in_envelope.pb

echo "Update by buyer"

peer channel update -f /home/atri/workspace_hlf/shipping-network/organizations/network/staging/${ORG_MSP_ID}_update_in_envelope.pb -c $CHANNEL_NAME -o localhost:8051 --ordererTLSHostnameOverride orderer.pinkflyod.com  --tls --cafile ${ORDERER_CA}


#check logs of shipping
#docker logs -f peer0.org1.example.com

#+++++++++++++++++++++++++++++++++++++++++++ Join Org3 to the Channel++++++++++++++++++++++++++++++++++++
export FABRIC_CFG_PATH=$ORG_BASE_DIR/conf
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID=$ORG_MSP_ID
export CORE_PEER_TLS_ROOTCERT_FILE=/home/atri/workspace_hlf/shipping-network/organizations/gupta.buttons/organization/peerOrganizations/gupta.buttons.linkinpark.com/peers/peer0.gupta.buttons.linkinpark.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=/home/atri/workspace_hlf/shipping-network/organizations/gupta.buttons/organization/peerOrganizations/gupta.buttons.linkinpark.com/users/Admin@gupta.buttons.linkinpark.com/msp
export CORE_PEER_ADDRESS=localhost:7451
export CHANNEL_NAME=shippingchannel
export ORDERER_CA=/home/atri/workspace_hlf/shipping-network/organizations/orderer/organization/ordererOrganizations/pinkflyod.com/orderers/orderer.pinkflyod.com/msp/tlscacerts/tlsca.pinkflyod.com-cert.pem

########################################################################################
# We are passing a 0 to indicate that we want the first block on the channel’s ledger; the genesis block.
# If we simply passed the peer channel fetch config command, then we would have received latest block 
# – the updated config with New Org defined. However, we can’t begin our ledger with a downstream block – 
# we must start with #block 0
#######################################################################################

peer channel fetch 0  /home/atri/workspace_hlf/shipping-network/organizations/network/staging/${CHANNEL_NAME}_channel.block -c $CHANNEL_NAME -o localhost:8051 --ordererTLSHostnameOverride orderer.pinkflyod.com  --tls --cafile ${ORDERER_CA}

peer channel join -b /home/atri/workspace_hlf/shipping-network/organizations/network/staging/${CHANNEL_NAME}_channel.block









