Organizations:
--------------------
Orderer : orderer.pinkflyod.com
Shipping : shipping.acdc.com
Custom : custom.metallica.gov
ButtonSeller: seller.ledzeppelin.com
ButtonBuyer: buyer.gunsnroses.com


Ports:
Orderer: 8051
Shipping: 7051
Custom: 7151
ButtonSeller: 7251
ButtonBuyer: 7351


1.Steps to start Network
--------------------------
1) Generate MSP 
2) Generate Genesis block
3) Start Docker Containers for organizations
4) Create channel
5) Create channel transaction
6) Join channel
7) Create anchor peer transaction
8) Add Anchor Peers
9) Install chain code

1.1 Generate Crypto
-------------------------

Buyer
-----
cryptogen generate --config=/home/atri/workspace_hlf/shipping-network/organizations/button.buyer/conf/crypto-config.yaml --output="/home/atri/workspace_hlf/shipping-network/organizations/button.buyer/organization"

Seller
------

cryptogen generate --config=/home/atri/workspace_hlf/shipping-network/organizations/button.seller/conf/crypto-config.yaml --output="/home/atri/workspace_hlf/shipping-network/organizations/button.seller/organization"

Custom
------

cryptogen generate --config=/home/atri/workspace_hlf/shipping-network/organizations/custom/conf/crypto-config.yaml --output="/home/atri/workspace_hlf/shipping-network/organizations/custom/organization"

Shipping
---------
cryptogen generate --config=/home/atri/workspace_hlf/shipping-network/organizations/shipping/conf/crypto-config.yaml --output="/home/atri/workspace_hlf/shipping-network/organizations/shipping/organization"

Orderer
----------
cryptogen generate --config=/home/atri/workspace_hlf/shipping-network/organizations/orderer/conf/crypto-config-orderer.yaml --output="/home/atri/workspace_hlf/shipping-network/organizations/orderer/organization"

1.2 Create Genesis block
------------------------


export FABRIC_CFG_PATH=/home/atri/workspace_hlf/shipping-network/organizations/network
set -x
configtxgen -profile ShippingOrdererGenesis -channelID system-channel -outputBlock /home/atri/workspace_hlf/shipping-network/organizations/network/system-genesis-block/genesis.block

1.3 Star docker containers
---------------------------

export IMAGETAG=latest
sudo IMAGE_TAG=$IMAGETAG docker-compose -f /home/atri/workspace_hlf/shipping-network/docker/docker-compose-test-net.yaml up -d 2>&1

export IMAGETAG=latest
sudo docker-compose -f /home/atri/workspace_hlf/shipping-network/docker/docker-compose-test-net.yaml down --volumes --remove-orphans

1.4 Create Channel Transaction 
-------------------------------

export FABRIC_CFG_PATH=/home/atri/workspace_hlf/shipping-network/organizations/network
export CHANNEL_NAME=shippingchannel
set -x
configtxgen -profile ShippingChannel -outputCreateChannelTx /home/atri/workspace_hlf/shipping-network/organizations/network/channel-artifacts/${CHANNEL_NAME}.tx -channelID $CHANNEL_NAME


1.5 Submit Channel transaction To orderer
--------------------------------------------
export FABRIC_CFG_PATH=/home/atri/workspace_hlf/shipping-network/organizations/custom/conf
export CHANNEL_NAME=shippingchannel

export CORE_PEER_MSPCONFIGPATH=/home/atri/workspace_hlf/shipping-network/organizations/custom/organization/peerOrganizations/custom.metallica.gov/users/Admin@custom.metallica.gov/msp
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID="CustomMSP"
export CORE_PEER_TLS_ROOTCERT_FILE=/home/atri/workspace_hlf/shipping-network/organizations/custom/organization/peerOrganizations/custom.metallica.gov/peers/peer0.custom.metallica.gov/tls/ca.crt
export CORE_PEER_ADDRESS=localhost:7151
export ORDERER_CA=/home/atri/workspace_hlf/shipping-network/organizations/orderer/organization/ordererOrganizations/pinkflyod.com/orderers/orderer.pinkflyod.com/msp/tlscacerts/tlsca.pinkflyod.com-cert.pem


peer channel create -o localhost:8051 -c $CHANNEL_NAME --ordererTLSHostnameOverride orderer.pinkflyod.com -f /home/atri/workspace_hlf/shipping-network/organizations/network/channel-artifacts/${CHANNEL_NAME}.tx --outputBlock /home/atri/workspace_hlf/shipping-network/organizations/network/channel-artifacts/${CHANNEL_NAME}.block --tls --cafile ${ORDERER_CA} >&submitChannelTxlog.txt


1.6 Join Channel
-------------------

1.6.1 Join Custom
------------------
export FABRIC_CFG_PATH=/home/atri/workspace_hlf/shipping-network/organizations/custom/conf
export CHANNEL_NAME=shippingchannel
export ORDERER_CA=/home/atri/workspace_hlf/shipping-network/organizations/orderer/organization/ordererOrganizations/pinkflyod.com/orderers/orderer.pinkflyod.com/msp/tlscacerts/tlsca.pinkflyod.com-cert.pem

export CORE_PEER_MSPCONFIGPATH=/home/atri/workspace_hlf/shipping-network/organizations/custom/organization/peerOrganizations/custom.metallica.gov/users/Admin@custom.metallica.gov/msp
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID="CustomMSP"
export CORE_PEER_TLS_ROOTCERT_FILE=/home/atri/workspace_hlf/shipping-network/organizations/custom/organization/peerOrganizations/custom.metallica.gov/peers/peer0.custom.metallica.gov/tls/ca.crt
export CORE_PEER_ADDRESS=localhost:7151


peer channel join -b /home/atri/workspace_hlf/shipping-network/organizations/network/channel-artifacts/$CHANNEL_NAME.block

peer channel  list

1.6.2 Join Shipping
----------------------
export FABRIC_CFG_PATH=/home/atri/workspace_hlf/shipping-network/organizations/shipping/conf
export CHANNEL_NAME=shippingchannel
export ORDERER_CA=/home/atri/workspace_hlf/shipping-network/organizations/orderer/organization/ordererOrganizations/pinkflyod.com/orderers/orderer.pinkflyod.com/msp/tlscacerts/tlsca.pinkflyod.com-cert.pem

export CORE_PEER_MSPCONFIGPATH=/home/atri/workspace_hlf/shipping-network/organizations/shipping/organization/peerOrganizations/shipping.acdc.com/users/Admin@shipping.acdc.com/msp
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID="ShippingMSP"
export CORE_PEER_TLS_ROOTCERT_FILE=/home/atri/workspace_hlf/shipping-network/organizations/shipping/organization/peerOrganizations/shipping.acdc.com/peers/peer0.shipping.acdc.com/tls/ca.crt
export CORE_PEER_ADDRESS=localhost:7051

peer channel join -b /home/atri/workspace_hlf/shipping-network/organizations/network/channel-artifacts/$CHANNEL_NAME.block

peer channel  list

1.6.3 Join Buyer
----------------
export FABRIC_CFG_PATH=/home/atri/workspace_hlf/shipping-network/organizations/button.buyer/conf
export CHANNEL_NAME=shippingchannel
export ORDERER_CA=/home/atri/workspace_hlf/shipping-network/organizations/orderer/organization/ordererOrganizations/pinkflyod.com/orderers/orderer.pinkflyod.com/msp/tlscacerts/tlsca.pinkflyod.com-cert.pem

export CORE_PEER_MSPCONFIGPATH=/home/atri/workspace_hlf/shipping-network/organizations/button.buyer/organization/peerOrganizations/buyer.gunsnroses.com/users/Admin@buyer.gunsnroses.com/msp
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID="BuyerMSP"
export CORE_PEER_TLS_ROOTCERT_FILE=/home/atri/workspace_hlf/shipping-network/organizations/button.buyer/organization/peerOrganizations/buyer.gunsnroses.com/peers/peer0.buyer.gunsnroses.com/tls/ca.crt
export CORE_PEER_ADDRESS=localhost:7351

peer channel join -b /home/atri/workspace_hlf/shipping-network/organizations/network/channel-artifacts/$CHANNEL_NAME.block

peer channel  list

1.6.4 Join Seller
-------------------

export FABRIC_CFG_PATH=/home/atri/workspace_hlf/shipping-network/organizations/button.seller/conf
export CHANNEL_NAME=shippingchannel
export ORDERER_CA=/home/atri/workspace_hlf/shipping-network/organizations/orderer/organization/ordererOrganizations/pinkflyod.com/orderers/orderer.pinkflyod.com/msp/tlscacerts/tlsca.pinkflyod.com-cert.pem

export CORE_PEER_MSPCONFIGPATH=/home/atri/workspace_hlf/shipping-network/organizations/button.seller/organization/peerOrganizations/seller.ledzeppelin.com/users/Admin@seller.ledzeppelin.com/msp
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID="SellerMSP"
export CORE_PEER_TLS_ROOTCERT_FILE=/home/atri/workspace_hlf/shipping-network/organizations/button.seller/organization/peerOrganizations/seller.ledzeppelin.com/peers/peer0.seller.ledzeppelin.com/tls/ca.crt
export CORE_PEER_ADDRESS=localhost:7251


peer channel join -b /home/atri/workspace_hlf/shipping-network/organizations/network/channel-artifacts/$CHANNEL_NAME.block

peer channel  list


1.7 Create Anchor Peer Transaction
-----------------------------------

1.7.1 Shipping Anchor Peer Tx
----------------------------------
export FABRIC_CFG_PATH=/home/atri/workspace_hlf/shipping-network/organizations/network
export CHANNEL_NAME=shippingchannel
export orgmsp=ShippingMSP

configtxgen -profile ShippingChannel -outputAnchorPeersUpdate /home/atri/workspace_hlf/shipping-network/organizations/network/channel-artifacts/${orgmsp}anchors.tx -channelID $CHANNEL_NAME -asOrg ${orgmsp}

1.7.2 Custom Anchor Peer Tx
----------------------------------
export FABRIC_CFG_PATH=/home/atri/workspace_hlf/shipping-network/organizations/network
export CHANNEL_NAME=shippingchannel
export orgmsp=CustomMSP

configtxgen -profile ShippingChannel -outputAnchorPeersUpdate /home/atri/workspace_hlf/shipping-network/organizations/network/channel-artifacts/${orgmsp}anchors.tx -channelID $CHANNEL_NAME -asOrg ${orgmsp}


1.7.3 Buyer Anchor Peer Tx
----------------------------------
export FABRIC_CFG_PATH=/home/atri/workspace_hlf/shipping-network/organizations/network
export CHANNEL_NAME=shippingchannel
export orgmsp=BuyerMSP

configtxgen -profile ShippingChannel -outputAnchorPeersUpdate /home/atri/workspace_hlf/shipping-network/organizations/network/channel-artifacts/${orgmsp}anchors.tx -channelID $CHANNEL_NAME -asOrg ${orgmsp}


1.7.4 Seller Anchor Peer Tx
----------------------------------
export FABRIC_CFG_PATH=/home/atri/workspace_hlf/shipping-network/organizations/network
export CHANNEL_NAME=shippingchannel
export orgmsp=SellerMSP

configtxgen -profile ShippingChannel -outputAnchorPeersUpdate /home/atri/workspace_hlf/shipping-network/organizations/network/channel-artifacts/${orgmsp}anchors.tx -channelID $CHANNEL_NAME -asOrg ${orgmsp}

1.8 Update Anchor Peer
------------------------------

1.8.1 Shipping Update Anchor Peer
--------------------------------------
export FABRIC_CFG_PATH=/home/atri/workspace_hlf/shipping-network/organizations/shipping/conf
export CHANNEL_NAME=shippingchannel
export ORDERER_CA=/home/atri/workspace_hlf/shipping-network/organizations/orderer/organization/ordererOrganizations/pinkflyod.com/orderers/orderer.pinkflyod.com/msp/tlscacerts/tlsca.pinkflyod.com-cert.pem
export CORE_PEER_LOCALMSPID=ShippingMSP

peer channel update -o localhost:8051 --ordererTLSHostnameOverride orderer.pinkflyod.com -c $CHANNEL_NAME -f /home/atri/workspace_hlf/shipping-network/organizations/network/channel-artifacts/${CORE_PEER_LOCALMSPID}anchors.tx --tls --cafile $ORDERER_CA 


1.8.2 Custom Update Anchor Peer
--------------------------------------
export FABRIC_CFG_PATH=/home/atri/workspace_hlf/shipping-network/organizations/custom/conf
export CHANNEL_NAME=shippingchannel
export ORDERER_CA=/home/atri/workspace_hlf/shipping-network/organizations/orderer/organization/ordererOrganizations/pinkflyod.com/orderers/orderer.pinkflyod.com/msp/tlscacerts/tlsca.pinkflyod.com-cert.pem
export CORE_PEER_LOCALMSPID=CustomMSP

peer channel update -o localhost:8051 --ordererTLSHostnameOverride orderer.pinkflyod.com -c $CHANNEL_NAME -f /home/atri/workspace_hlf/shipping-network/organizations/network/channel-artifacts/${CORE_PEER_LOCALMSPID}anchors.tx --tls --cafile $ORDERER_CA 


1.8.3 Seller Update Anchor Peer
--------------------------------------
export FABRIC_CFG_PATH=/home/atri/workspace_hlf/shipping-network/organizations/button.seller/conf
export CHANNEL_NAME=shippingchannel
export ORDERER_CA=/home/atri/workspace_hlf/shipping-network/organizations/orderer/organization/ordererOrganizations/pinkflyod.com/orderers/orderer.pinkflyod.com/msp/tlscacerts/tlsca.pinkflyod.com-cert.pem
export CORE_PEER_LOCALMSPID=SellerMSP

peer channel update -o localhost:8051 --ordererTLSHostnameOverride orderer.pinkflyod.com -c $CHANNEL_NAME -f /home/atri/workspace_hlf/shipping-network/organizations/network/channel-artifacts/${CORE_PEER_LOCALMSPID}anchors.tx --tls --cafile $ORDERER_CA 

1.8.4 Buyer Update Anchor Peer
--------------------------------------
export FABRIC_CFG_PATH=/home/atri/workspace_hlf/shipping-network/organizations/button.buyer/conf
export CHANNEL_NAME=shippingchannel
export ORDERER_CA=/home/atri/workspace_hlf/shipping-network/organizations/orderer/organization/ordererOrganizations/pinkflyod.com/orderers/orderer.pinkflyod.com/msp/tlscacerts/tlsca.pinkflyod.com-cert.pem
export CORE_PEER_LOCALMSPID=BuyerMSP

peer channel update -o localhost:8051 --ordererTLSHostnameOverride orderer.pinkflyod.com -c $CHANNEL_NAME -f /home/atri/workspace_hlf/shipping-network/organizations/network/channel-artifacts/${CORE_PEER_LOCALMSPID}anchors.tx --tls --cafile $ORDERER_CA 

2 Phase-2
-----------
Add organization