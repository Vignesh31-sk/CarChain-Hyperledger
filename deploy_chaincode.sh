#!/bin/bash

# Deploy Car Showroom Chaincode to Hyperledger Fabric Test Network
# This script automates the chaincode lifecycle operations (install, approve, commit)

set -e

# Default values
CHANNEL_NAME="mychannel"
CC_NAME="carshowroom"
CC_SRC_PATH=$(pwd)/chaincode-package
CC_VERSION="1.0.0"
CC_SEQUENCE=1  # Reset to 1 for fresh network
CC_INIT_FCN="initLedger"
CC_END_POLICY="OR('Org1MSP.peer','Org2MSP.peer')"
CC_COLL_CONFIG=""
# Fixed the path to be absolute instead of relative
FABRIC_SAMPLES_PATH="/home/viki/Programming/Projects/BCT-Mini/fabric-samples"

# Print usage message
function printHelp() {
  echo "Usage: "
  echo "  deploy_chaincode.sh [options]"
  echo "    -c <channel name> - Name of channel (default \"mychannel\")"
  echo "    -n <chaincode name> - Chaincode name (default \"carshowroom\")"
  echo "    -v <chaincode version> - Chaincode version (default \"1.0.0\")"
  echo "    -s <sequence> - Version sequence (default 1)"  # Updated help text
  echo "    -f <path to fabric samples> - Path to fabric-samples directory (default \"/home/viki/Programming/Projects/BCT-Mini/fabric-samples\")"
  echo "    -i - Initialize the chaincode with initLedger function"
  echo "    -h - Print this help message"
  echo ""
  echo "Example: "
  echo "  deploy_chaincode.sh -c mychannel -n carshowroom -v 1.0.0 -s 1 -f /home/viki/Programming/Projects/BCT-Mini/fabric-samples -i"  # Updated example
}

# Parse command line options
while getopts "h?c:n:v:s:f:i" opt; do
  case "$opt" in
  h | \?)
    printHelp
    exit 0
    ;;
  c)
    CHANNEL_NAME=$OPTARG
    ;;
  n)
    CC_NAME=$OPTARG
    ;;
  v)
    CC_VERSION=$OPTARG
    ;;
  s)
    CC_SEQUENCE=$OPTARG
    ;;
  f)
    FABRIC_SAMPLES_PATH=$OPTARG
    ;;
  i)
    INIT_REQUIRED="--init-required"
    ;;
  esac
done

CC_SRC_LANGUAGE="java"
CC_RUNTIME_LANGUAGE=java
CC_LABEL="${CC_NAME}_${CC_VERSION}"
PACKAGE_ID=""

echo "===================================="
echo "Channel Name: ${CHANNEL_NAME}"
echo "Chaincode Name: ${CC_NAME}"
echo "Chaincode Path: ${CC_SRC_PATH}"
echo "Chaincode Version: ${CC_VERSION}"
echo "Chaincode Sequence: ${CC_SEQUENCE}"  # Will now show 1
echo "Fabric Samples Path: ${FABRIC_SAMPLES_PATH}"
echo "===================================="

# Check if fabric-samples directory exists
if [ ! -d "$FABRIC_SAMPLES_PATH" ]; then
  echo "Error: Fabric samples directory not found at $FABRIC_SAMPLES_PATH"
  echo "Please specify the correct path using the -f option"
  exit 1
fi

# Setup environment variables
export PATH=${FABRIC_SAMPLES_PATH}/bin:$PATH
export FABRIC_CFG_PATH=${FABRIC_SAMPLES_PATH}/config/
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID="Org1MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=${FABRIC_SAMPLES_PATH}/test-network/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${FABRIC_SAMPLES_PATH}/test-network/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
export CORE_PEER_ADDRESS=localhost:7051

# Package the chaincode
packageChaincode() {
  echo "Packaging chaincode..."
  set -x
  peer lifecycle chaincode package ${CC_NAME}.tar.gz \
    --path ${CC_SRC_PATH} \
    --lang ${CC_RUNTIME_LANGUAGE} \
    --label ${CC_LABEL}
  res=$?
  { set +x; } 2>/dev/null
  echo "Chaincode packaging completed with status: $res"
  if [ $res -ne 0 ]; then
    echo "Error: Chaincode packaging failed"
    exit 1
  fi
}

# Get the package ID for the installed chaincode (whether newly installed or previously installed)
getPackageID() {
  echo "Getting package ID..."
  set -x
  PACKAGE_ID=$(peer lifecycle chaincode queryinstalled | grep "${CC_LABEL}" | sed -n 's/^Package ID: \(.*\), Label: .*$/\1/p' | head -n 1)
  { set +x; } 2>/dev/null
  echo "Package ID: ${PACKAGE_ID}"
  if [ -z "$PACKAGE_ID" ]; then
    echo "Error: Could not get package ID. The chaincode may not be installed correctly."
    exit 1
  fi
}

# Install chaincode on peer0.org1
installChaincode() {
  echo "Installing chaincode on peer0.org1.example.com..."
  
  # Check if the chaincode is already installed
  INSTALLED=$(peer lifecycle chaincode queryinstalled | grep "${CC_LABEL}" || true)
  
  if [ -n "$INSTALLED" ]; then
    echo "Chaincode already installed. Skipping installation."
  else
    set -x
    peer lifecycle chaincode install ${CC_NAME}.tar.gz
    res=$?
    { set +x; } 2>/dev/null
    echo "Chaincode installation completed with status: $res"
    if [ $res -ne 0 ]; then
      echo "Error: Chaincode installation failed"
      exit 1
    fi
  fi

  # Get package ID (whether newly installed or previously installed)
  getPackageID
}

# Approve chaincode for Org1
approveForOrg1() {
  echo "Approving chaincode for Org1..."
  set -x
  peer lifecycle chaincode approveformyorg -o localhost:7050 \
    --ordererTLSHostnameOverride orderer.example.com \
    --channelID $CHANNEL_NAME \
    --name ${CC_NAME} \
    --version ${CC_VERSION} \
    --package-id ${PACKAGE_ID} \
    --sequence ${CC_SEQUENCE} \
    ${INIT_REQUIRED} \
    --tls \
    --cafile ${FABRIC_SAMPLES_PATH}/test-network/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
  res=$?
  { set +x; } 2>/dev/null
  echo "Chaincode approval for Org1 completed with status: $res"
  if [ $res -ne 0 ]; then
    echo "Error: Chaincode approval for Org1 failed"
    exit 1
  fi
}

# Install chaincode on peer0.org2
installChaincodeOrg2() {
  echo "Installing chaincode on peer0.org2.example.com..."

  # Set environment variables for Org2
  export CORE_PEER_LOCALMSPID="Org2MSP"
  export CORE_PEER_TLS_ROOTCERT_FILE=${FABRIC_SAMPLES_PATH}/test-network/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt
  export CORE_PEER_MSPCONFIGPATH=${FABRIC_SAMPLES_PATH}/test-network/organizations/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp
  export CORE_PEER_ADDRESS=localhost:9051

  # Check if the chaincode is already installed
  INSTALLED=$(peer lifecycle chaincode queryinstalled | grep "${CC_LABEL}" || true)
  
  if [ -n "$INSTALLED" ]; then
    echo "Chaincode already installed on Org2. Skipping installation."
  else
    set -x
    peer lifecycle chaincode install ${CC_NAME}.tar.gz
    res=$?
    { set +x; } 2>/dev/null
    echo "Chaincode installation on peer0.org2 completed with status: $res"
    if [ $res -ne 0 ]; then
      echo "Error: Chaincode installation on Org2 failed"
      exit 1
    fi
  fi
}

# Approve chaincode for Org2
approveForOrg2() {
  echo "Approving chaincode for Org2..."

  # Ensure we're still using Org2 environment variables
  export CORE_PEER_LOCALMSPID="Org2MSP"
  export CORE_PEER_TLS_ROOTCERT_FILE=${FABRIC_SAMPLES_PATH}/test-network/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt
  export CORE_PEER_MSPCONFIGPATH=${FABRIC_SAMPLES_PATH}/test-network/organizations/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp
  export CORE_PEER_ADDRESS=localhost:9051

  set -x
  peer lifecycle chaincode approveformyorg -o localhost:7050 \
    --ordererTLSHostnameOverride orderer.example.com \
    --channelID $CHANNEL_NAME \
    --name ${CC_NAME} \
    --version ${CC_VERSION} \
    --package-id ${PACKAGE_ID} \
    --sequence ${CC_SEQUENCE} \
    ${INIT_REQUIRED} \
    --tls \
    --cafile ${FABRIC_SAMPLES_PATH}/test-network/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
  res=$?
  { set +x; } 2>/dev/null
  echo "Chaincode approval for Org2 completed with status: $res"
  if [ $res -ne 0 ]; then
    echo "Error: Chaincode approval for Org2 failed"
    exit 1
  fi
}

# Check if chaincode definition is ready to be committed
checkCommitReadiness() {
  echo "Checking commit readiness..."
  set -x
  peer lifecycle chaincode checkcommitreadiness \
    --channelID $CHANNEL_NAME \
    --name ${CC_NAME} \
    --version ${CC_VERSION} \
    --sequence ${CC_SEQUENCE} \
    ${INIT_REQUIRED} \
    --tls \
    --cafile ${FABRIC_SAMPLES_PATH}/test-network/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem \
    --output json
  res=$?
  { set +x; } 2>/dev/null
  if [ $res -ne 0 ]; then
    echo "Error: Chaincode definition not ready for commit"
    exit 1
  fi
}

# Commit chaincode definition to the channel
commitChaincodeDefinition() {
  echo "Committing chaincode definition to the channel..."
  
  # Switch back to Org1 for commit
  export CORE_PEER_LOCALMSPID="Org1MSP"
  export CORE_PEER_TLS_ROOTCERT_FILE=${FABRIC_SAMPLES_PATH}/test-network/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
  export CORE_PEER_MSPCONFIGPATH=${FABRIC_SAMPLES_PATH}/test-network/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
  export CORE_PEER_ADDRESS=localhost:7051

  set -x
  peer lifecycle chaincode commit -o localhost:7050 \
    --ordererTLSHostnameOverride orderer.example.com \
    --channelID $CHANNEL_NAME \
    --name ${CC_NAME} \
    --version ${CC_VERSION} \
    --sequence ${CC_SEQUENCE} \
    ${INIT_REQUIRED} \
    --tls \
    --cafile ${FABRIC_SAMPLES_PATH}/test-network/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem \
    --peerAddresses localhost:7051 \
    --tlsRootCertFiles ${FABRIC_SAMPLES_PATH}/test-network/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt \
    --peerAddresses localhost:9051 \
    --tlsRootCertFiles ${FABRIC_SAMPLES_PATH}/test-network/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt
  res=$?
  { set +x; } 2>/dev/null
  echo "Chaincode definition committed with status: $res"
  if [ $res -ne 0 ]; then
    echo "Error: Failed to commit chaincode definition"
    exit 1
  fi
}

# Query committed chaincode definitions to verify
queryCommitted() {
  echo "Querying committed chaincode definitions..."
  set -x
  peer lifecycle chaincode querycommitted \
    --channelID $CHANNEL_NAME \
    --name ${CC_NAME}
  res=$?
  { set +x; } 2>/dev/null
  if [ $res -ne 0 ]; then
    echo "Error: Failed to query committed chaincode definition"
    exit 1
  fi
}

# Initialize the ledger if required
initLedger() {
  if [ "$INIT_REQUIRED" == "--init-required" ]; then
    echo "Initializing the ledger with sample data (including both organizations)..."
    set -x
    peer chaincode invoke -o localhost:7050 \
      --ordererTLSHostnameOverride orderer.example.com \
      --tls \
      --cafile ${FABRIC_SAMPLES_PATH}/test-network/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem \
      --peerAddresses localhost:7051 \
      --tlsRootCertFiles ${FABRIC_SAMPLES_PATH}/test-network/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt \
      --peerAddresses localhost:9051 \
      --tlsRootCertFiles ${FABRIC_SAMPLES_PATH}/test-network/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt \
      -C $CHANNEL_NAME \
      -n ${CC_NAME} \
      --isInit \
      -c '{"function":"initLedger","Args":[]}'
    res=$?
    { set +x; } 2>/dev/null
    echo "Chaincode initialization completed with status: $res"
    if [ $res -ne 0 ]; then
      echo "Error: Failed to initialize the ledger"
      exit 1
    fi
  fi
}

# Main script execution
echo "Executing chaincode deployment process..."

# Run the deployment steps
packageChaincode
installChaincode
approveForOrg1
installChaincodeOrg2
approveForOrg2
checkCommitReadiness
commitChaincodeDefinition
queryCommitted
initLedger

echo "====================================="
echo "Chaincode deployment completed successfully!"
echo "Chaincode Name: ${CC_NAME}"
echo "Chaincode Version: ${CC_VERSION}"
echo "Channel Name: ${CHANNEL_NAME}"
echo "====================================="
echo ""
echo "You can now invoke the chaincode using commands like:"
echo ""
echo "# Create a new car"
echo "peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile \\"
echo "  ${FABRIC_SAMPLES_PATH}/test-network/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem \\"
echo "  -C ${CHANNEL_NAME} -n ${CC_NAME} \\"
echo "  -c '{\"function\":\"createCar\",\"Args\":[\"CAR006\",\"Tesla\",\"Model X\",\"Black\",\"2023\",\"Alice\"]}'"
echo ""
echo "# Query a car"
echo "peer chaincode query -C ${CHANNEL_NAME} -n ${CC_NAME} -c '{\"function\":\"queryCar\",\"Args\":[\"CAR001\"]}'"
echo ""
echo "# Transfer car ownership"
echo "peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile \\"
echo "  ${FABRIC_SAMPLES_PATH}/test-network/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem \\"
echo "  -C ${CHANNEL_NAME} -n ${CC_NAME} \\"
echo "  -c '{\"function\":\"transferCarOwnership\",\"Args\":[\"CAR001\",\"NewOwner\"]}'"
echo ""
echo "# Query all cars"
echo "peer chaincode query -C ${CHANNEL_NAME} -n ${CC_NAME} -c '{\"function\":\"queryAllCars\",\"Args\":[]}'"