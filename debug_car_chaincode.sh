#!/bin/bash

# Debug Car Showroom Chaincode Script
# This script allows for individual invocation of car showroom chaincode functions for debugging purposes
# It provides a simple menu-driven interface to invoke different chaincode functions

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
}

# Function to parse command-line options
parse_options() {
  while getopts "f:c:n:h" opt; do
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
    esac
  done
}

# Print help message
print_help() {
  echo "Usage: "
  echo "  debug_car_chaincode.sh [options]"
  echo "    -f <path to fabric samples> - Path to fabric-samples directory (default \"${FABRIC_SAMPLES_PATH}\")"
  echo "    -c <channel name> - Name of channel (default \"${CHANNEL_NAME}\")"
  echo "    -n <chaincode name> - Chaincode name (default \"${CC_NAME}\")"
  echo "    -h - Print this help message"
}

# Function to print the result of a chaincode invocation
print_result() {
  local result=$1
  
  echo -e "\n${YELLOW}=== RESULT ====${NC}"
  echo "$result"
  echo -e "${YELLOW}==============${NC}\n"
}

# Function to add a delay between operations
add_delay() {
  local seconds=$1
  echo -e "${BLUE}Waiting for ${seconds} seconds to allow transaction to be committed...${NC}"
  sleep ${seconds}
}

# Function to query all cars
function_query_all_cars() {
  echo -e "${BLUE}Querying all cars from the ledger...${NC}"

  local result=$(peer chaincode query -C ${CHANNEL_NAME} -n ${CC_NAME} -c '{"function":"queryAllCars","Args":[]}')
  local status=$?

  if [ $status -eq 0 ]; then
    echo -e "${GREEN}✓ Query All Cars - SUCCESS${NC}"
    print_result "$result"
  else
    echo -e "${RED}✗ Query All Cars - FAILED${NC}"
    print_result "$result"
  fi
}

# Function to query a specific car
function_query_car() {
  echo -e "${BLUE}Enter the car ID to query:${NC}"
  read car_id
  
  echo -e "${BLUE}Querying car with ID ${car_id} from the ledger...${NC}"

  local result=$(peer chaincode query -C ${CHANNEL_NAME} -n ${CC_NAME} -c "{\"function\":\"queryCar\",\"Args\":[\"${car_id}\"]}")
  local status=$?

  if [ $status -eq 0 ]; then
    echo -e "${GREEN}✓ Query Car ${car_id} - SUCCESS${NC}"
    print_result "$result"
  else
    echo -e "${RED}✗ Query Car ${car_id} - FAILED${NC}"
    print_result "$result"
  fi
}

# Function to check if a car exists
function_car_exists() {
  echo -e "${BLUE}Enter the car ID to check if it exists:${NC}"
  read car_id
  
  echo -e "${BLUE}Checking if car with ID ${car_id} exists in the ledger...${NC}"

  local result=$(peer chaincode query -C ${CHANNEL_NAME} -n ${CC_NAME} -c "{\"function\":\"carExists\",\"Args\":[\"${car_id}\"]}")
  local status=$?

  if [ $status -eq 0 ]; then
    echo -e "${GREEN}✓ Check Car Existence ${car_id} - SUCCESS${NC}"
    print_result "$result"
  else
    echo -e "${RED}✗ Check Car Existence ${car_id} - FAILED${NC}"
    print_result "$result"
  fi
}

# Function to create a new car
function_create_car() {
  echo -e "${BLUE}Enter the details of the car to create:${NC}"
  echo -e "${BLUE}Car ID:${NC}"
  read car_id
  echo -e "${BLUE}Make:${NC}"
  read make
  echo -e "${BLUE}Model:${NC}"
  read model
  echo -e "${BLUE}Color:${NC}"
  read color
  echo -e "${BLUE}Year:${NC}"
  read year
  echo -e "${BLUE}Owner:${NC}"
  read owner
  
  echo -e "${BLUE}Creating a new car with ID ${car_id}...${NC}"
  
  local result=$(peer chaincode invoke -o localhost:7050 \
    --ordererTLSHostnameOverride orderer.example.com \
    --tls \
    --cafile ${FABRIC_SAMPLES_PATH}/test-network/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem \
    --peerAddresses localhost:7051 \
    --tlsRootCertFiles ${FABRIC_SAMPLES_PATH}/test-network/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt \
    --peerAddresses localhost:9051 \
    --tlsRootCertFiles ${FABRIC_SAMPLES_PATH}/test-network/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt \
    -C ${CHANNEL_NAME} \
    -n ${CC_NAME} \
    -c "{\"function\":\"createCar\",\"Args\":[\"${car_id}\",\"${make}\",\"${model}\",\"${color}\",\"${year}\",\"${owner}\"]}")

  local status=$?

  if [ $status -eq 0 ]; then
    echo -e "${GREEN}✓ Create Car ${car_id} - SUCCESS${NC}"
    print_result "$result"
    add_delay 3
  else
    echo -e "${RED}✗ Create Car ${car_id} - FAILED${NC}"
    print_result "$result"
  fi
}

# Function to transfer car ownership
function_transfer_car_ownership() {
  echo -e "${BLUE}Enter the details for transferring car ownership:${NC}"
  echo -e "${BLUE}Car ID:${NC}"
  read car_id
  echo -e "${BLUE}New Owner:${NC}"
  read new_owner
  
  echo -e "${BLUE}Transferring ownership of car ${car_id} to ${new_owner}...${NC}"

  local result=$(peer chaincode invoke -o localhost:7050 \
    --ordererTLSHostnameOverride orderer.example.com \
    --tls \
    --cafile ${FABRIC_SAMPLES_PATH}/test-network/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem \
    --peerAddresses localhost:7051 \
    --tlsRootCertFiles ${FABRIC_SAMPLES_PATH}/test-network/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt \
    --peerAddresses localhost:9051 \
    --tlsRootCertFiles ${FABRIC_SAMPLES_PATH}/test-network/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt \
    -C ${CHANNEL_NAME} \
    -n ${CC_NAME} \
    -c "{\"function\":\"transferCarOwnership\",\"Args\":[\"${car_id}\",\"${new_owner}\"]}")

  local status=$?

  if [ $status -eq 0 ]; then
    echo -e "${GREEN}✓ Transfer Car Ownership of ${car_id} to ${new_owner} - SUCCESS${NC}"
    print_result "$result"
    add_delay 3
  else
    echo -e "${RED}✗ Transfer Car Ownership of ${car_id} to ${new_owner} - FAILED${NC}"
    print_result "$result"
  fi
}

# Function to initialize the ledger
function_init_ledger() {
  echo -e "${BLUE}Initializing the ledger with sample cars...${NC}"
  
  # Ask if initialization should use --isInit flag
  echo -e "${BLUE}Use --isInit flag? (required for first deployment) [y/n]:${NC}"
  read use_init_flag
  
  local init_cmd=""
  if [[ "$use_init_flag" == "y" || "$use_init_flag" == "Y" ]]; then
    init_cmd="--isInit"
  fi
  
  local result=$(peer chaincode invoke -o localhost:7050 \
    --ordererTLSHostnameOverride orderer.example.com \
    --tls \
    --cafile ${FABRIC_SAMPLES_PATH}/test-network/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem \
    --peerAddresses localhost:7051 \
    --tlsRootCertFiles ${FABRIC_SAMPLES_PATH}/test-network/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt \
    --peerAddresses localhost:9051 \
    --tlsRootCertFiles ${FABRIC_SAMPLES_PATH}/test-network/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt \
    -C ${CHANNEL_NAME} \
    -n ${CC_NAME} \
    $init_cmd \
    -c '{"function":"initLedger","Args":[]}')

  local status=$?

  if [ $status -eq 0 ]; then
    echo -e "${GREEN}✓ Initialize Ledger - SUCCESS${NC}"
    print_result "$result"
    add_delay 5
  else
    echo -e "${RED}✗ Initialize Ledger - FAILED${NC}"
    print_result "$result"
  fi
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

# Function to check network and chaincode status
function_check_network_status() {
  echo -e "${BLUE}Checking network status...${NC}"
  
#   echo -e "${YELLOW}=== NETWORK PEERS ===${NC}"
#   peer node status 2>&1 || echo -e "${RED}Failed to connect to local peer${NC}"
  
  echo -e "\n${YELLOW}=== CHANNEL LIST ===${NC}"
  peer channel list || echo -e "${RED}Failed to list channels${NC}"
  
  echo -e "\n${YELLOW}=== CHANNEL INFORMATION ===${NC}"
  peer channel getinfo -c ${CHANNEL_NAME} || echo -e "${RED}Failed to get channel info${NC}"
  
  echo -e "\n${YELLOW}=== INSTALLED CHAINCODES ===${NC}"
  peer lifecycle chaincode queryinstalled || echo -e "${RED}Failed to query installed chaincodes${NC}"
  
  echo -e "\n${YELLOW}=== INSTANTIATED CHAINCODES ===${NC}"
  peer chaincode list --instantiated -C ${CHANNEL_NAME} || echo -e "${RED}Failed to list instantiated chaincodes${NC}"
}

# Function to display the menu
show_menu() {
  echo -e "\n${YELLOW}=======================================${NC}"
  echo -e "${YELLOW}    CAR SHOWROOM CHAINCODE DEBUGGER    ${NC}"
  echo -e "${YELLOW}=======================================${NC}"
  echo -e "${BLUE}Current Organization:${NC} ${CORE_PEER_LOCALMSPID}"
  echo -e "${BLUE}Current Peer:${NC} ${CORE_PEER_ADDRESS}"
  echo -e "${BLUE}Current Channel:${NC} ${CHANNEL_NAME}"
  echo -e "${BLUE}Current Chaincode:${NC} ${CC_NAME}"
  echo -e "${YELLOW}=======================================${NC}\n"
  echo -e "${YELLOW}Chaincode Invocation:${NC}"
  echo "1) Query All Cars"
  echo "2) Query Specific Car"
  echo "3) Check if Car Exists"
  echo "4) Create New Car"
  echo "5) Transfer Car Ownership"
  echo "6) Initialize Ledger"
  echo -e "\n${YELLOW}Organization Management:${NC}"
  echo "7) Switch to Org1 Peer"
  echo "8) Switch to Org2 Peer"
  echo -e "\n${YELLOW}Network Diagnostics:${NC}"
  echo "9) Check Network Status"
  echo -e "\n${YELLOW}Other Options:${NC}"
  echo "10) Exit"
  
  echo -e "\n${BLUE}Enter your choice [1-10]:${NC} "
  read choice
}

# Main function
main() {
  parse_options "$@"
  setup_environment
  
  while true; do
    show_menu
    
    case $choice in
      1) function_query_all_cars ;;
      2) function_query_car ;;
      3) function_car_exists ;;
      4) function_create_car ;;
      5) function_transfer_car_ownership ;;
      6) function_init_ledger ;;
      7) switch_to_org1 ;;
      8) switch_to_org2 ;;
      9) function_check_network_status ;;
      10) 
         echo -e "\n${GREEN}Exiting Car Showroom Chaincode Debugger. Goodbye!${NC}\n"
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
