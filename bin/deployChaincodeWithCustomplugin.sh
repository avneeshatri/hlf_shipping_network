seq=$1
vs=$2
if [[ -z $seq || -z $vs ]];then
	echo "Sequence of Version missing"
	exit 1
fi

cdir=/home/atri/workspace_hlf/shipping-network/chaincode
cd  $cdir
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++Function +++++++++++++++++++++++++++++++++++++++++++
function approveChaincode {
PACKAGE_ID=$(peer lifecycle chaincode queryinstalled | tail -1 | grep -oP '(?<=Package ID: ).*?(?=,)')
echo "PackageID: $PACKAGE_ID"

export CHANNEL_NAME=shippingchannel
export ORDERER_CA=/home/atri/workspace_hlf/shipping-network/organizations/orderer/organization/ordererOrganizations/pinkflyod.com/orderers/orderer.pinkflyod.com/msp/tlscacerts/tlsca.pinkflyod.com-cert.pem
export CC_PACKAGE_ID=$PACKAGE_ID
export CHAINCODE_NAME=shipping

peer lifecycle chaincode approveformyorg -o localhost:8051 --ordererTLSHostnameOverride orderer.pinkflyod.com -E custom --channelID $CHANNEL_NAME --name $CHAINCODE_NAME --version ${vs} --package-id $CC_PACKAGE_ID --sequence ${seq} --tls --cafile ${ORDERER_CA}


}

#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ Execute ++++++++++++++++++++++++++++++++++++++
#Package Install Custom Chaincode
#-------------------------------------
export FABRIC_CFG_PATH=/home/atri/workspace_hlf/shipping-network/organizations/custom/conf
export CORE_PEER_MSPCONFIGPATH=/home/atri/workspace_hlf/shipping-network/organizations/custom/organization/peerOrganizations/custom.metallica.gov/users/Admin@custom.metallica.gov/msp
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID="CustomMSP"
export CORE_PEER_TLS_ROOTCERT_FILE=/home/atri/workspace_hlf/shipping-network/organizations/custom/organization/peerOrganizations/custom.metallica.gov/peers/peer0.custom.metallica.gov/tls/ca.crt
export CORE_PEER_ADDRESS=localhost:7151

echo "Package Custom Chain Code"
peer lifecycle chaincode package custom_${vs}.tar.gz --path /home/atri/workspace_hlf/shipping-contract --lang java --label custom_${vs}

echo "Install Chaincode for Custom"
peer lifecycle chaincode install custom_${vs}.tar.gz

peer lifecycle chaincode queryinstalled

echo "Approve Chaincode"
approveChaincode

#Package Install Shipping Chaincode
#-------------------------------------

export FABRIC_CFG_PATH=/home/atri/workspace_hlf/shipping-network/organizations/shipping/conf
export CORE_PEER_MSPCONFIGPATH=/home/atri/workspace_hlf/shipping-network/organizations/shipping/organization/peerOrganizations/shipping.acdc.com/users/Admin@shipping.acdc.com/msp
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID="ShippingMSP"
export CORE_PEER_TLS_ROOTCERT_FILE=/home/atri/workspace_hlf/shipping-network/organizations/shipping/organization/peerOrganizations/shipping.acdc.com/peers/peer0.shipping.acdc.com/tls/ca.crt
export CORE_PEER_ADDRESS=localhost:7051

echo "Package Shipping Chain Code"
peer lifecycle chaincode package shipping_${vs}.tar.gz --path /home/atri/workspace_hlf/shipping-contract --lang java --label shipping_${vs}


echo "Install Chaincode for Shipping"
peer lifecycle chaincode install shipping_${vs}.tar.gz

peer lifecycle chaincode queryinstalled

echo "Approve Chaincode"
PACKAGE_ID=$(peer lifecycle chaincode queryinstalled | tail -1 | grep -oP '(?<=Package ID: ).*?(?=,)')
echo "PackageID: $PACKAGE_ID"

export CHANNEL_NAME=shippingchannel
export ORDERER_CA=/home/atri/workspace_hlf/shipping-network/organizations/orderer/organization/ordererOrganizations/pinkflyod.com/orderers/orderer.pinkflyod.com/msp/tlscacerts/tlsca.pinkflyod.com-cert.pem
export CC_PACKAGE_ID=$PACKAGE_ID
export CHAINCODE_NAME=shipping

peer lifecycle chaincode approveformyorg -o localhost:8051 --ordererTLSHostnameOverride orderer.pinkflyod.com -E custom --channelID $CHANNEL_NAME --name $CHAINCODE_NAME --version ${vs} --package-id $CC_PACKAGE_ID --sequence ${seq} --tls --cafile ${ORDERER_CA}


#Package Install Buyer Chaincode
#-------------------------------------

export FABRIC_CFG_PATH=/home/atri/workspace_hlf/shipping-network/organizations/button.buyer/conf
export CORE_PEER_MSPCONFIGPATH=/home/atri/workspace_hlf/shipping-network/organizations/button.buyer/organization/peerOrganizations/buyer.gunsnroses.com/users/Admin@buyer.gunsnroses.com/msp
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID="BuyerMSP"
export CORE_PEER_TLS_ROOTCERT_FILE=/home/atri/workspace_hlf/shipping-network/organizations/button.buyer/organization/peerOrganizations/buyer.gunsnroses.com/peers/peer0.buyer.gunsnroses.com/tls/ca.crt
export CORE_PEER_ADDRESS=localhost:7351


echo "Package Buyer Chain Code"
peer lifecycle chaincode package buyer_${vs}.tar.gz --path /home/atri/workspace_hlf/shipping-contract --lang java --label buyer_${vs}

echo "Install Chaincode for Buyer"
peer lifecycle chaincode install buyer_${vs}.tar.gz

peer lifecycle chaincode queryinstalled

echo "Approve Chaincode"
approveChaincode

#Package Install Seller Chaincode
#-------------------------------------

export FABRIC_CFG_PATH=/home/atri/workspace_hlf/shipping-network/organizations/button.seller/conf
export CORE_PEER_MSPCONFIGPATH=/home/atri/workspace_hlf/shipping-network/organizations/button.seller/organization/peerOrganizations/seller.ledzeppelin.com/users/Admin@seller.ledzeppelin.com/msp
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID="SellerMSP"
export CORE_PEER_TLS_ROOTCERT_FILE=/home/atri/workspace_hlf/shipping-network/organizations/button.seller/organization/peerOrganizations/seller.ledzeppelin.com/peers/peer0.seller.ledzeppelin.com/tls/ca.crt
export CORE_PEER_ADDRESS=localhost:7251

echo "Package Seller Chain Code"
peer lifecycle chaincode package seller_${vs}.tar.gz --path /home/atri/workspace_hlf/shipping-contract --lang java --label seller_${vs}

echo "Install Chaincode for Seller"
peer lifecycle chaincode install seller_${vs}.tar.gz

peer lifecycle chaincode queryinstalled

echo "Approve Chaincode"
approveChaincode

#Commit Readiness Status
#----------------------------

export CHANNEL_NAME=shippingchannel
export ORDERER_CA=/home/atri/workspace_hlf/shipping-network/organizations/orderer/organization/ordererOrganizations/pinkflyod.com/orderers/orderer.pinkflyod.com/msp/tlscacerts/tlsca.pinkflyod.com-cert.pem
export CC_PACKAGE_ID=$PACKAGE_ID
export CHAINCODE_NAME=shipping
echo "Checking commit readiness"
peer lifecycle chaincode checkcommitreadiness --channelID $CHANNEL_NAME --name $CHAINCODE_NAME --version ${vs} --sequence ${seq} -E custom  --tls --cafile $ORDERER_CA


#Commit Chaincode
#------------------------------
echo "Commit chain code as Shipping ORG"
export CHANNEL_NAME=shippingchannel
export ORDERER_CA=/home/atri/workspace_hlf/shipping-network/organizations/orderer/organization/ordererOrganizations/pinkflyod.com/orderers/orderer.pinkflyod.com/msp/tlscacerts/tlsca.pinkflyod.com-cert.pem
export CHAINCODE_NAME=shipping


export FABRIC_CFG_PATH=/home/atri/workspace_hlf/shipping-network/organizations/shipping/conf
export CORE_PEER_MSPCONFIGPATH=/home/atri/workspace_hlf/shipping-network/organizations/shipping/organization/peerOrganizations/shipping.acdc.com/users/Admin@shipping.acdc.com/msp
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID="ShippingMSP"


export SHIPPING_PEER_TLS_ROOTCERT_FILE=/home/atri/workspace_hlf/shipping-network/organizations/shipping/organization/peerOrganizations/shipping.acdc.com/peers/peer0.shipping.acdc.com/tls/ca.crt
export SHIPPING_PEER_ADDRESS=localhost:7051

export CUSTOM_PEER_TLS_ROOTCERT_FILE=/home/atri/workspace_hlf/shipping-network/organizations/custom/organization/peerOrganizations/custom.metallica.gov/peers/peer0.custom.metallica.gov/tls/ca.crt
export CUSTOM_PEER_ADDRESS=localhost:7151


export SELLER_PEER_TLS_ROOTCERT_FILE=/home/atri/workspace_hlf/shipping-network/organizations/button.seller/organization/peerOrganizations/seller.ledzeppelin.com/peers/peer0.seller.ledzeppelin.com/tls/ca.crt
export SELLER_PEER_ADDRESS=localhost:7251


peer lifecycle chaincode commit -o localhost:8051 --ordererTLSHostnameOverride orderer.pinkflyod.com --channelID $CHANNEL_NAME --name $CHAINCODE_NAME --version ${vs} --sequence ${seq} -E custom --tls --cafile $ORDERER_CA --peerAddresses $SHIPPING_PEER_ADDRESS --tlsRootCertFiles $SHIPPING_PEER_TLS_ROOTCERT_FILE --peerAddresses $CUSTOM_PEER_ADDRESS --tlsRootCertFiles $CUSTOM_PEER_TLS_ROOTCERT_FILE --peerAddresses $SELLER_PEER_ADDRESS --tlsRootCertFiles $SELLER_PEER_TLS_ROOTCERT_FILE 

# Query Chain code status on Channle
#----------------------------------------

echo "Chain code status on channel"

peer lifecycle chaincode querycommitted --channelID $CHANNEL_NAME --name $CHAINCODE_NAME --cafile $ORDERER_CA



echo "Chaincode Installation Complete"
