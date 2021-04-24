#Bring down docker containers

#Functions
#++++++++++++++++++++++++++++++++++++++++++++ Functions +++++++++++++++++++++++++++++++++++++++++++++++

# Obtain CONTAINER_IDS and remove them
# TODO Might want to make this optional - could clear other containers
# This function is called when you bring a network down
function clearContainers() {
  CONTAINER_IDS=$(sudo docker ps -a | awk '($2 ~ /dev-peer.*/) {print $1}')
  if [ -z "$CONTAINER_IDS" -o "$CONTAINER_IDS" == " " ]; then
    infoln "No containers available for deletion"
  else
    sudo docker rm -f $CONTAINER_IDS
  fi
}



#+++++++++++++++++++++++++++++++++++++++++++++ Execute ++++++++++++++++++++++++++++++++++++++++++
cd /home/atri/workspace_hlf/shipping-network/bin
sudo docker ps -a

echo "Bring down docker containers"

export IMAGETAG=latest
sudo docker-compose -f /home/atri/workspace_hlf/shipping-network/docker/docker-compose-test-net.yaml down --volumes --remove-orphans
rc=$?

if [[ $rc -ne 0 ]];then
	echo "Terminating process"
	exit 1
fi
clearContainers
sudo docker ps -a

#1.3 Star docker containers
#---------------------------
echo "Star docker containers"
export IMAGETAG=latest
sudo IMAGE_TAG=$IMAGETAG docker-compose -f /home/atri/workspace_hlf/shipping-network/docker/docker-compose-test-net.yaml up -d 2>&1
rc=$?

if [[ $rc -ne 0 ]];then
	echo "Terminating process"
	exit 1
fi


#1.4 Create Channel Transaction 
#-------------------------------
echo "Creating channel transaction"
export FABRIC_CFG_PATH=/home/atri/workspace_hlf/shipping-network/organizations/network
export CHANNEL_NAME=shippingchannel
set -x
configtxgen -profile ShippingChannel -outputCreateChannelTx /home/atri/workspace_hlf/shipping-network/organizations/network/channel-artifacts/${CHANNEL_NAME}.tx -channelID $CHANNEL_NAME
rc=$?

if [[ $rc -ne 0 ]];then
	echo "Terminating process"
	exit 1
fi


#1.5 Submit Channel transaction To orderer
#--------------------------------------------
echo "Submitting channel transaction"
export FABRIC_CFG_PATH=/home/atri/workspace_hlf/shipping-network/organizations/custom/conf
export CHANNEL_NAME=shippingchannel

export CORE_PEER_MSPCONFIGPATH=/home/atri/workspace_hlf/shipping-network/organizations/custom/organization/peerOrganizations/custom.metallica.gov/users/Admin@custom.metallica.gov/msp
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID="CustomMSP"
export CORE_PEER_TLS_ROOTCERT_FILE=/home/atri/workspace_hlf/shipping-network/organizations/custom/organization/peerOrganizations/custom.metallica.gov/peers/peer0.custom.metallica.gov/tls/ca.crt
export CORE_PEER_ADDRESS=localhost:7151
export ORDERER_CA=/home/atri/workspace_hlf/shipping-network/organizations/orderer/organization/ordererOrganizations/pinkflyod.com/orderers/orderer.pinkflyod.com/msp/tlscacerts/tlsca.pinkflyod.com-cert.pem


peer channel create -o localhost:8051 -c $CHANNEL_NAME --ordererTLSHostnameOverride orderer.pinkflyod.com -f /home/atri/workspace_hlf/shipping-network/organizations/network/channel-artifacts/${CHANNEL_NAME}.tx --outputBlock /home/atri/workspace_hlf/shipping-network/organizations/network/channel-artifacts/${CHANNEL_NAME}.block --tls --cafile ${ORDERER_CA} >&submitChannelTxlog.txt
rc=$?

if [[ $rc -ne 0 ]];then
	echo "Terminating process"
	exit 1
fi


#1.6 Join Channel
#-------------------

#1.6.1 Join Custom
#------------------
echo "Joining Custom to channel"
export FABRIC_CFG_PATH=/home/atri/workspace_hlf/shipping-network/organizations/custom/conf
export CHANNEL_NAME=shippingchannel
export ORDERER_CA=/home/atri/workspace_hlf/shipping-network/organizations/orderer/organization/ordererOrganizations/pinkflyod.com/orderers/orderer.pinkflyod.com/msp/tlscacerts/tlsca.pinkflyod.com-cert.pem

export CORE_PEER_MSPCONFIGPATH=/home/atri/workspace_hlf/shipping-network/organizations/custom/organization/peerOrganizations/custom.metallica.gov/users/Admin@custom.metallica.gov/msp
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID="CustomMSP"
export CORE_PEER_TLS_ROOTCERT_FILE=/home/atri/workspace_hlf/shipping-network/organizations/custom/organization/peerOrganizations/custom.metallica.gov/peers/peer0.custom.metallica.gov/tls/ca.crt
export CORE_PEER_ADDRESS=localhost:7151


peer channel join -b /home/atri/workspace_hlf/shipping-network/organizations/network/channel-artifacts/$CHANNEL_NAME.block
rc=$?

if [[ $rc -ne 0 ]];then
	echo "Terminating process"
	exit 1
fi

peer channel  list

#1.6.2 Join Shipping
#----------------------
echo "Joining Shipping to channel"
export FABRIC_CFG_PATH=/home/atri/workspace_hlf/shipping-network/organizations/shipping/conf
export CHANNEL_NAME=shippingchannel
export ORDERER_CA=/home/atri/workspace_hlf/shipping-network/organizations/orderer/organization/ordererOrganizations/pinkflyod.com/orderers/orderer.pinkflyod.com/msp/tlscacerts/tlsca.pinkflyod.com-cert.pem

export CORE_PEER_MSPCONFIGPATH=/home/atri/workspace_hlf/shipping-network/organizations/shipping/organization/peerOrganizations/shipping.acdc.com/users/Admin@shipping.acdc.com/msp
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID="ShippingMSP"
export CORE_PEER_TLS_ROOTCERT_FILE=/home/atri/workspace_hlf/shipping-network/organizations/shipping/organization/peerOrganizations/shipping.acdc.com/peers/peer0.shipping.acdc.com/tls/ca.crt
export CORE_PEER_ADDRESS=localhost:7051

peer channel join -b /home/atri/workspace_hlf/shipping-network/organizations/network/channel-artifacts/$CHANNEL_NAME.block
rc=$?

if [[ $rc -ne 0 ]];then
	echo "Terminating process"
	exit 1
fi

peer channel  list

#1.6.3 Join Buyer
#----------------
echo "Joining Buyer to channel"
export FABRIC_CFG_PATH=/home/atri/workspace_hlf/shipping-network/organizations/button.buyer/conf
export CHANNEL_NAME=shippingchannel
export ORDERER_CA=/home/atri/workspace_hlf/shipping-network/organizations/orderer/organization/ordererOrganizations/pinkflyod.com/orderers/orderer.pinkflyod.com/msp/tlscacerts/tlsca.pinkflyod.com-cert.pem

export CORE_PEER_MSPCONFIGPATH=/home/atri/workspace_hlf/shipping-network/organizations/button.buyer/organization/peerOrganizations/buyer.gunsnroses.com/users/Admin@buyer.gunsnroses.com/msp
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID="BuyerMSP"
export CORE_PEER_TLS_ROOTCERT_FILE=/home/atri/workspace_hlf/shipping-network/organizations/button.buyer/organization/peerOrganizations/buyer.gunsnroses.com/peers/peer0.buyer.gunsnroses.com/tls/ca.crt
export CORE_PEER_ADDRESS=localhost:7351

peer channel join -b /home/atri/workspace_hlf/shipping-network/organizations/network/channel-artifacts/$CHANNEL_NAME.block
rc=$?

if [[ $rc -ne 0 ]];then
	echo "Terminating process"
	exit 1
fi

peer channel  list

#1.6.4 Join Seller
#-------------------
echo "Joining Seller to channel"
export FABRIC_CFG_PATH=/home/atri/workspace_hlf/shipping-network/organizations/button.seller/conf
export CHANNEL_NAME=shippingchannel
export ORDERER_CA=/home/atri/workspace_hlf/shipping-network/organizations/orderer/organization/ordererOrganizations/pinkflyod.com/orderers/orderer.pinkflyod.com/msp/tlscacerts/tlsca.pinkflyod.com-cert.pem

export CORE_PEER_MSPCONFIGPATH=/home/atri/workspace_hlf/shipping-network/organizations/button.seller/organization/peerOrganizations/seller.ledzeppelin.com/users/Admin@seller.ledzeppelin.com/msp
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID="SellerMSP"
export CORE_PEER_TLS_ROOTCERT_FILE=/home/atri/workspace_hlf/shipping-network/organizations/button.seller/organization/peerOrganizations/seller.ledzeppelin.com/peers/peer0.seller.ledzeppelin.com/tls/ca.crt
export CORE_PEER_ADDRESS=localhost:7251


peer channel join -b /home/atri/workspace_hlf/shipping-network/organizations/network/channel-artifacts/$CHANNEL_NAME.block
rc=$?

if [[ $rc -ne 0 ]];then
	echo "Terminating process"
	exit 1
fi

peer channel  list


#1.7 Create Anchor Peer Transaction
#-----------------------------------

#1.7.1 Shipping Anchor Peer Tx
#----------------------------------
echo "Generating Shipping anchor peer tx"
export FABRIC_CFG_PATH=/home/atri/workspace_hlf/shipping-network/organizations/network
export CHANNEL_NAME=shippingchannel
export orgmsp=ShippingMSP

configtxgen -profile ShippingChannel -outputAnchorPeersUpdate /home/atri/workspace_hlf/shipping-network/organizations/network/channel-artifacts/${orgmsp}anchors.tx -channelID $CHANNEL_NAME -asOrg ${orgmsp}
rc=$?

if [[ $rc -ne 0 ]];then
	echo "Terminating process"
	exit 1
fi


#1.7.2 Custom Anchor Peer Tx
#---------------------------------
echo "Generating Custom anchor peer tx"
export FABRIC_CFG_PATH=/home/atri/workspace_hlf/shipping-network/organizations/network
export CHANNEL_NAME=shippingchannel
export orgmsp=CustomMSP

configtxgen -profile ShippingChannel -outputAnchorPeersUpdate /home/atri/workspace_hlf/shipping-network/organizations/network/channel-artifacts/${orgmsp}anchors.tx -channelID $CHANNEL_NAME -asOrg ${orgmsp}
rc=$?

if [[ $rc -ne 0 ]];then
	echo "Terminating process"
	exit 1
fi


#1.7.3 Buyer Anchor Peer Tx
#----------------------------------
echo "Generating Buyer anchor peer tx"
export FABRIC_CFG_PATH=/home/atri/workspace_hlf/shipping-network/organizations/network
export CHANNEL_NAME=shippingchannel
export orgmsp=BuyerMSP

configtxgen -profile ShippingChannel -outputAnchorPeersUpdate /home/atri/workspace_hlf/shipping-network/organizations/network/channel-artifacts/${orgmsp}anchors.tx -channelID $CHANNEL_NAME -asOrg ${orgmsp}
rc=$?

if [[ $rc -ne 0 ]];then
	echo "Terminating process"
	exit 1
fi


#1.7.4 Seller Anchor Peer Tx
#----------------------------------
echo "Generating Seller anchor peer tx"
export FABRIC_CFG_PATH=/home/atri/workspace_hlf/shipping-network/organizations/network
export CHANNEL_NAME=shippingchannel
export orgmsp=SellerMSP

configtxgen -profile ShippingChannel -outputAnchorPeersUpdate /home/atri/workspace_hlf/shipping-network/organizations/network/channel-artifacts/${orgmsp}anchors.tx -channelID $CHANNEL_NAME -asOrg ${orgmsp}
rc=$?

if [[ $rc -ne 0 ]];then
	echo "Terminating process"
	exit 1
fi


#1.8 Update Anchor Peer
#------------------------------

#1.8.1 Shipping Update Anchor Peer
#--------------------------------------
echo "Updating Shipping anchor peer"
export FABRIC_CFG_PATH=/home/atri/workspace_hlf/shipping-network/organizations/shipping/conf
export CHANNEL_NAME=shippingchannel
export ORDERER_CA=/home/atri/workspace_hlf/shipping-network/organizations/orderer/organization/ordererOrganizations/pinkflyod.com/orderers/orderer.pinkflyod.com/msp/tlscacerts/tlsca.pinkflyod.com-cert.pem
export CORE_PEER_LOCALMSPID=ShippingMSP

export CORE_PEER_MSPCONFIGPATH=/home/atri/workspace_hlf/shipping-network/organizations/shipping/organization/peerOrganizations/shipping.acdc.com/users/Admin@shipping.acdc.com/msp
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID="ShippingMSP"
export CORE_PEER_TLS_ROOTCERT_FILE=/home/atri/workspace_hlf/shipping-network/organizations/shipping/organization/peerOrganizations/shipping.acdc.com/peers/peer0.shipping.acdc.com/tls/ca.crt
export CORE_PEER_ADDRESS=localhost:7051

peer channel update -o localhost:8051 --ordererTLSHostnameOverride orderer.pinkflyod.com -c $CHANNEL_NAME -f /home/atri/workspace_hlf/shipping-network/organizations/network/channel-artifacts/${CORE_PEER_LOCALMSPID}anchors.tx --tls --cafile $ORDERER_CA 
rc=$?

if [[ $rc -ne 0 ]];then
	echo "Terminating process"
	exit 1
fi


#1.8.2 Custom Update Anchor Peer
#--------------------------------------
echo "Updating Custom anchor peer"
export FABRIC_CFG_PATH=/home/atri/workspace_hlf/shipping-network/organizations/custom/conf
export CHANNEL_NAME=shippingchannel
export ORDERER_CA=/home/atri/workspace_hlf/shipping-network/organizations/orderer/organization/ordererOrganizations/pinkflyod.com/orderers/orderer.pinkflyod.com/msp/tlscacerts/tlsca.pinkflyod.com-cert.pem
export CORE_PEER_LOCALMSPID=CustomMSP


export CORE_PEER_MSPCONFIGPATH=/home/atri/workspace_hlf/shipping-network/organizations/custom/organization/peerOrganizations/custom.metallica.gov/users/Admin@custom.metallica.gov/msp
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID="CustomMSP"
export CORE_PEER_TLS_ROOTCERT_FILE=/home/atri/workspace_hlf/shipping-network/organizations/custom/organization/peerOrganizations/custom.metallica.gov/peers/peer0.custom.metallica.gov/tls/ca.crt
export CORE_PEER_ADDRESS=localhost:7151

peer channel update -o localhost:8051 --ordererTLSHostnameOverride orderer.pinkflyod.com -c $CHANNEL_NAME -f /home/atri/workspace_hlf/shipping-network/organizations/network/channel-artifacts/${CORE_PEER_LOCALMSPID}anchors.tx --tls --cafile $ORDERER_CA 
rc=$?

if [[ $rc -ne 0 ]];then
	echo "Terminating process"
	exit 1
fi


#1.8.3 Seller Update Anchor Peer
#--------------------------------------
echo "Updating Seller anchor peer"
export FABRIC_CFG_PATH=/home/atri/workspace_hlf/shipping-network/organizations/button.seller/conf
export CHANNEL_NAME=shippingchannel
export ORDERER_CA=/home/atri/workspace_hlf/shipping-network/organizations/orderer/organization/ordererOrganizations/pinkflyod.com/orderers/orderer.pinkflyod.com/msp/tlscacerts/tlsca.pinkflyod.com-cert.pem
export CORE_PEER_LOCALMSPID=SellerMSP

export CORE_PEER_MSPCONFIGPATH=/home/atri/workspace_hlf/shipping-network/organizations/button.seller/organization/peerOrganizations/seller.ledzeppelin.com/users/Admin@seller.ledzeppelin.com/msp
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID="SellerMSP"
export CORE_PEER_TLS_ROOTCERT_FILE=/home/atri/workspace_hlf/shipping-network/organizations/button.seller/organization/peerOrganizations/seller.ledzeppelin.com/peers/peer0.seller.ledzeppelin.com/tls/ca.crt
export CORE_PEER_ADDRESS=localhost:7251

peer channel update -o localhost:8051 --ordererTLSHostnameOverride orderer.pinkflyod.com -c $CHANNEL_NAME -f /home/atri/workspace_hlf/shipping-network/organizations/network/channel-artifacts/${CORE_PEER_LOCALMSPID}anchors.tx --tls --cafile $ORDERER_CA 
rc=$?

if [[ $rc -ne 0 ]];then
	echo "Terminating process"
	exit 1
fi

#1.8.4 Buyer Update Anchor Peer
#--------------------------------------
echo "Updating Buyer anchor peer"
export FABRIC_CFG_PATH=/home/atri/workspace_hlf/shipping-network/organizations/button.buyer/conf
export CHANNEL_NAME=shippingchannel
export ORDERER_CA=/home/atri/workspace_hlf/shipping-network/organizations/orderer/organization/ordererOrganizations/pinkflyod.com/orderers/orderer.pinkflyod.com/msp/tlscacerts/tlsca.pinkflyod.com-cert.pem
export CORE_PEER_LOCALMSPID=BuyerMSP

export CORE_PEER_MSPCONFIGPATH=/home/atri/workspace_hlf/shipping-network/organizations/button.buyer/organization/peerOrganizations/buyer.gunsnroses.com/users/Admin@buyer.gunsnroses.com/msp
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID="BuyerMSP"
export CORE_PEER_TLS_ROOTCERT_FILE=/home/atri/workspace_hlf/shipping-network/organizations/button.buyer/organization/peerOrganizations/buyer.gunsnroses.com/peers/peer0.buyer.gunsnroses.com/tls/ca.crt
export CORE_PEER_ADDRESS=localhost:7351

peer channel update -o localhost:8051 --ordererTLSHostnameOverride orderer.pinkflyod.com -c $CHANNEL_NAME -f /home/atri/workspace_hlf/shipping-network/organizations/network/channel-artifacts/${CORE_PEER_LOCALMSPID}anchors.tx --tls --cafile $ORDERER_CA 
rc=$?

if [[ $rc -ne 0 ]];then
	echo "Terminating process"
	exit 1
fi

