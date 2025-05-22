#!/bin/bash

# Chaincode Lifecycle Management Script
# This script provides tools to manage the chaincode lifecycle in Hyperledger Fabric
# It handles packaging, installing, approving, and committing chaincode definitions

set -e

# Colors for pretty output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default paths and values
FABRIC_SAMPLES_PATH="/home/viki/BCT_Mini/fabric-samples"
CHANNEL_NAME="mychannel"
CC_NAME="carshowroom"
CC_VERSION="1.0.0"
CC_SEQUENCE=1
CC_LABEL="${CC_NAME}_${CC_VERSION}"

# Setup environment variables
setup_environment() {
  echo -e "${BLUE}Setting up environment variables...${NC}"
  export PATH=${FABRIC_SAMPLES_PATH}/bin:$PATH
  export FABRIC_CFG_PATH=${FABRIC_SAMPLES_PATH}/config/
  export CORE_PEER_TLS_ENABLED=true
  export CORE_PEER_LOCALMSPID="Org1MSP"
  export CORE_PEER_TLS_ROOTCERT_FILE=${FABRIC_SAMPLES_PATH}/test-network/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
  export CORE_PEER_MSPCONFIGPATH=${FABRIC_SAMPLES_PATH}/test-network/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
  export CORE_PEER_ADDRESS=localhost:7051
  export CORE_CHAINCODE_STARTUPTIMEOUT=120s  # Added for longer startup timeout
  export CORE_PEER_CHAINCODE_EXECUTETIMEOUT=180s
}

# Function to parse command-line options
parse_options() {
  while getopts "f:c:n:v:s:h" opt; do
    case "$opt" in
    h)
      print_help
      exit 0
      ;;
    f)
      FABRIC_SAMPLES_PATH=$OPTARG
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
    esac
  done
  
  # Update CC_LABEL after parsing options
  CC_LABEL="${CC_NAME}_${CC_VERSION}"
}

# Print help message
print_help() {
  echo "Usage: "
  echo "  chaincode_lifecycle.sh [options]"
  echo "    -f <path to fabric samples> - Path to fabric-samples directory (default \"${FABRIC_SAMPLES_PATH}\")"
  echo "    -c <channel name> - Name of channel (default \"${CHANNEL_NAME}\")"
  echo "    -n <chaincode name> - Chaincode name (default \"${CC_NAME}\")"
  echo "    -v <chaincode version> - Chaincode version (default \"${CC_VERSION}\")"
  echo "    -s <sequence> - Version sequence (default ${CC_SEQUENCE})"
  echo "    -h - Print this help message"
}

# Function to print the result of a command
print_result() {
  local result=$1
  
  echo -e "\n${YELLOW}=== RESULT ====${NC}"
  echo "$result"
  echo -e "${YELLOW}==============${NC}\n"
}

# Package chaincode
function_package_chaincode() {
  echo -e "${BLUE}Packaging chaincode...${NC}"
  
  echo -e "${BLUE}Enter chaincode source path (default: $(pwd)/chaincode-package):${NC}"
  read cc_src_path
  cc_src_path=${cc_src_path:-$(pwd)/chaincode-package}
  
  echo -e "${BLUE}Enter chaincode language [java/javascript/typescript/go] (default: java):${NC}"
  read cc_lang
  cc_lang=${cc_lang:-java}
  
  echo -e "${BLUE}Enter chaincode label (default: ${CC_LABEL}):${NC}"
  read cc_label
  cc_label=${cc_label:-${CC_LABEL}}
  
  local result=$(peer lifecycle chaincode package ${CC_NAME}.tar.gz \
    --path ${cc_src_path} \
    --lang ${cc_lang} \
    --label ${cc_label} 2>&1)
    
  if [[ -f ${CC_NAME}.tar.gz ]]; then
    echo -e "${GREEN}✓ Package Chaincode - SUCCESS${NC}"
    echo -e "${GREEN}Package created: $(pwd)/${CC_NAME}.tar.gz${NC}"
  else
    echo -e "${RED}✗ Package Chaincode - FAILED${NC}"
    echo "$result"
  fi
}

# Install chaincode
function_install_chaincode() {
  echo -e "${BLUE}Installing chaincode ${CC_NAME}.tar.gz...${NC}"
  
  if [[ ! -f ${CC_NAME}.tar.gz ]]; then
    echo -e "${RED}Error: ${CC_NAME}.tar.gz does not exist in current directory.${NC}"
    echo -e "${YELLOW}Do you want to package the chaincode first? [y/n]${NC}"
    read should_package
    
    if [[ "$should_package" == "y" || "$should_package" == "Y" ]]; then
      function_package_chaincode
    else
      return 1
    fi
  fi
  
  local result=$(peer lifecycle chaincode install ${CC_NAME}.tar.gz --connTimeout ${CORE_PEER_CHAINCODE_EXECUTETIMEOUT} 2>&1)
  
  if [[ $result == *"Chaincode code package identifier"* ]]; then
    echo -e "${GREEN}✓ Install Chaincode - SUCCESS${NC}"
    print_result "$result"
    
    # Get package ID after installation
    function_get_package_id
  else
    echo -e "${RED}✗ Install Chaincode - FAILED${NC}"
    print_result "$result"
  fi
}

# Get the package ID for the installed chaincode
function_get_package_id() {
  echo -e "${BLUE}Getting package ID for ${CC_LABEL}...${NC}"
  
  local result=$(peer lifecycle chaincode queryinstalled | grep "${CC_LABEL}" || true)
  
  if [ -n "$result" ]; then
    local package_id=$(echo "$result" | sed -n 's/^Package ID: \(.*\), Label: .*$/\1/p' | head -n 1)
    echo -e "${GREEN}✓ Package ID found - SUCCESS${NC}"
    echo -e "${YELLOW}Package ID: ${package_id}${NC}"
    
    # Allow user to export it for use in other scripts
    echo -e "${BLUE}Export this package ID as PACKAGE_ID environment variable? [y/n]:${NC}"
    read export_id
    if [[ "$export_id" == "y" || "$export_id" == "Y" ]]; then
      export PACKAGE_ID=$package_id
      echo -e "${GREEN}✓ Package ID exported as PACKAGE_ID=${PACKAGE_ID}${NC}"
    fi
  else
    echo -e "${RED}✗ No package found with label ${CC_LABEL}${NC}"
  fi
}

# Function to check commit readiness
function_check_commit_readiness() {
  echo -e "${BLUE}Checking commit readiness for chaincode ${CC_NAME}...${NC}"
  
  echo -e "${BLUE}Include --init-required flag? [y/n]:${NC}"
  read use_init_flag
  
  local init_cmd=""
  if [[ "$use_init_flag" == "y" || "$use_init_flag" == "Y" ]]; then
    init_cmd="--init-required"
  fi
  
  local result=$(peer lifecycle chaincode checkcommitreadiness \
    --channelID $CHANNEL_NAME \
    --name ${CC_NAME} \
    --version ${CC_VERSION} \
    --sequence ${CC_SEQUENCE} \
    $init_cmd \
    --tls \
    --cafile ${FABRIC_SAMPLES_PATH}/test-network/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem \
    --output json)

  local status=$?

  if [ $status -eq 0 ]; then
    echo -e "${GREEN}✓ Check Commit Readiness - SUCCESS${NC}"
    print_result "$result"
  else
    echo -e "${RED}✗ Check Commit Readiness - FAILED${NC}"
    print_result "$result"
  fi
}

# Function to query committed chaincodes
function_query_committed() {
  echo -e "${BLUE}Querying committed chaincode definitions...${NC}"
  
  local result=$(peer lifecycle chaincode querycommitted \
    --channelID $CHANNEL_NAME \
    --name ${CC_NAME} 2>&1)
    
  if [[ $result == *"error"* || $result == *"Error"* ]]; then
    echo -e "${RED}✗ Query Committed Chaincode - FAILED${NC}"
    print_result "$result"
  else
    echo -e "${GREEN}✓ Query Committed Chaincode - SUCCESS${NC}"
    print_result "$result"
  fi
}

# Approve chaincode for organization
function_approve_chaincode() {
  echo -e "${BLUE}Approving chaincode for current organization...${NC}"
  
  if [ -z "$PACKAGE_ID" ]; then
    echo -e "${YELLOW}Package ID not set. Getting package ID first...${NC}"
    function_get_package_id
    
    if [ -z "$PACKAGE_ID" ]; then
      echo -e "${RED}Error: Could not find package ID.${NC}"
      echo -e "${BLUE}Please enter package ID manually:${NC}"
      read PACKAGE_ID
      
      if [ -z "$PACKAGE_ID" ]; then
        echo -e "${RED}No package ID provided. Cannot approve chaincode.${NC}"
        return 1
      fi
    fi
  fi
  
  echo -e "${BLUE}Include --init-required flag? [y/n]:${NC}"
  read use_init_flag
  
  local init_cmd=""
  if [[ "$use_init_flag" == "y" || "$use_init_flag" == "Y" ]]; then
    init_cmd="--init-required"
  fi
  
  local result=$(peer lifecycle chaincode approveformyorg -o localhost:7050 \
    --ordererTLSHostnameOverride orderer.example.com \
    --channelID $CHANNEL_NAME \
    --name ${CC_NAME} \
    --version ${CC_VERSION} \
    --package-id ${PACKAGE_ID} \
    --sequence ${CC_SEQUENCE} \
    $init_cmd \
    --tls \
    --cafile ${FABRIC_SAMPLES_PATH}/test-network/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem 2>&1)
    
  if [[ $result == *"committed"* || $result == *"approved"* || $result != *"Error"* ]]; then
    echo -e "${GREEN}✓ Approve Chaincode - SUCCESS${NC}"
    print_result "$result"
  else
    echo -e "${RED}✗ Approve Chaincode - FAILED${NC}"
    print_result "$result"
  fi
}

# Function to commit chaincode definition
function_commit_chaincode() {
  echo -e "${BLUE}Committing chaincode definition to the channel...${NC}"
  
  echo -e "${BLUE}Include --init-required flag? [y/n]:${NC}"
  read use_init_flag
  
  local init_cmd=""
  if [[ "$use_init_flag" == "y" || "$use_init_flag" == "Y" ]]; then
    init_cmd="--init-required"
  fi
  
  local result=$(peer lifecycle chaincode commit -o localhost:7050 \
    --ordererTLSHostnameOverride orderer.example.com \
    --channelID $CHANNEL_NAME \
    --name ${CC_NAME} \
    --version ${CC_VERSION} \
    --sequence ${CC_SEQUENCE} \
    $init_cmd \
    --tls \
    --cafile ${FABRIC_SAMPLES_PATH}/test-network/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem \
    --peerAddresses localhost:7051 \
    --tlsRootCertFiles ${FABRIC_SAMPLES_PATH}/test-network/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt \
    --peerAddresses localhost:9051 \
    --tlsRootCertFiles ${FABRIC_SAMPLES_PATH}/test-network/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt 2>&1)
  
  if [[ $result != *"Error"* ]]; then
    echo -e "${GREEN}✓ Commit Chaincode - SUCCESS${NC}"
    print_result "$result"
    
    # Verify the commit by querying committed chaincodes
    function_query_committed
  else
    echo -e "${RED}✗ Commit Chaincode - FAILED${NC}"
    print_result "$result"
  fi
}

# Function to check network and chaincode status
function_check_network_status() {
  echo -e "${BLUE}Checking network status...${NC}"
  
  echo -e "${YELLOW}=== NETWORK PEERS ===${NC}"
  peer node status --connTimeout 3s 2>&1 || echo -e "${RED}Failed to connect to local peer${NC}"
  
  echo -e "\n${YELLOW}=== CHANNEL LIST ===${NC}"
  peer channel list || echo -e "${RED}Failed to list channels${NC}"
  
  echo -e "\n${YELLOW}=== CHANNEL INFORMATION ===${NC}"
  peer channel getinfo -c ${CHANNEL_NAME} || echo -e "${RED}Failed to get channel info${NC}"
  
  echo -e "\n${YELLOW}=== INSTALLED CHAINCODES ===${NC}"
  peer lifecycle chaincode queryinstalled || echo -e "${RED}Failed to query installed chaincodes${NC}"
}

# Function to switch to Org2 peer
switch_to_org2() {
  echo -e "${BLUE}Switching to Org2 peer...${NC}"
  export CORE_PEER_LOCALMSPID="Org2MSP"
  export CORE_PEER_TLS_ROOTCERT_FILE=${FABRIC_SAMPLES_PATH}/test-network/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt
  export CORE_PEER_MSPCONFIGPATH=${FABRIC_SAMPLES_PATH}/test-network/organizations/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp
  export CORE_PEER_ADDRESS=localhost:9051
  
  echo -e "${GREEN}✓ Now using Org2 peer (localhost:9051)${NC}"
}

# Function to switch to Org1 peer
switch_to_org1() {
  echo -e "${BLUE}Switching to Org1 peer...${NC}"
  export CORE_PEER_LOCALMSPID="Org1MSP"
  export CORE_PEER_TLS_ROOTCERT_FILE=${FABRIC_SAMPLES_PATH}/test-network/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
  export CORE_PEER_MSPCONFIGPATH=${FABRIC_SAMPLES_PATH}/test-network/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
  export CORE_PEER_ADDRESS=localhost:7051
  
  echo -e "${GREEN}✓ Now using Org1 peer (localhost:7051)${NC}"
}

# Function to display the menu
show_menu() {
  echo -e "\n${YELLOW}=======================================${NC}"
  echo -e "${YELLOW}    CHAINCODE LIFECYCLE MANAGEMENT    ${NC}"
  echo -e "${YELLOW}=======================================${NC}"
  echo -e "${BLUE}Current Organization:${NC} ${CORE_PEER_LOCALMSPID}"
  echo -e "${BLUE}Current Peer:${NC} ${CORE_PEER_ADDRESS}"
  echo -e "${BLUE}Current Channel:${NC} ${CHANNEL_NAME}"
  echo -e "${BLUE}Current Chaincode:${NC} ${CC_NAME} (version: ${CC_VERSION}, sequence: ${CC_SEQUENCE})"
  echo -e "${YELLOW}=======================================${NC}\n"
  echo -e "${YELLOW}Chaincode Lifecycle Operations:${NC}"
  echo "1) Package Chaincode"
  echo "2) Install Chaincode"
  echo "3) Get Package ID"
  echo "4) Approve Chaincode for Organization"
  echo "5) Check Commit Readiness"
  echo "6) Commit Chaincode Definition"
  echo "7) Query Committed Chaincode"
  echo -e "\n${YELLOW}Organization Management:${NC}"
  echo "8) Switch to Org1 Peer"
  echo "9) Switch to Org2 Peer"
  echo -e "\n${YELLOW}Network Diagnostics:${NC}"
  echo "10) Check Network Status"
  echo -e "\n${YELLOW}Other Options:${NC}"
  echo "11) Exit"
  
  echo -e "\n${BLUE}Enter your choice [1-11]:${NC} "
  read choice
}

# Main function
main() {
  parse_options "$@"
  setup_environment
  
  while true; do
    show_menu
    
    case $choice in
      1) function_package_chaincode ;;
      2) function_install_chaincode ;;
      3) function_get_package_id ;;
      4) function_approve_chaincode ;;
      5) function_check_commit_readiness ;;
      6) function_commit_chaincode ;;
      7) function_query_committed ;;
      8) switch_to_org1 ;;
      9) switch_to_org2 ;;
      10) function_check_network_status ;;
      11) 
         echo -e "\n${GREEN}Exiting Chaincode Lifecycle Management. Goodbye!${NC}\n"
         exit 0
         ;;
      *) 
         echo -e "${RED}Invalid option. Please try again.${NC}"
         ;;
    esac
    
    echo -e "\n${BLUE}Press Enter to continue...${NC}"
    read
  done
}

# Execute main function
main "$@"
