#!/bin/bash

# Test script for Car Showroom Chaincode
# This script tests all operations of the car showroom chaincode

set -e

# Colors for pretty output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default paths
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
  echo "  test_carshowroom.sh [options]"
  echo "    -f <path to fabric samples> - Path to fabric-samples directory (default \"${FABRIC_SAMPLES_PATH}\")"
  echo "    -c <channel name> - Name of channel (default \"${CHANNEL_NAME}\")"
  echo "    -n <chaincode name> - Chaincode name (default \"${CC_NAME}\")"
  echo "    -h - Print this help message"
}

# Display a test header
print_test_header() {
  local test_name=$1
  echo -e "\n${YELLOW}=======================================${NC}"
  echo -e "${YELLOW}TEST: ${test_name}${NC}"
  echo -e "${YELLOW}=======================================${NC}"
}

# Display test result
print_test_result() {
  local result=$1
  local expected=$2

  echo -e "${BLUE}Result:${NC}"
  echo "$result"
  
  if [ -n "$expected" ]; then
    echo -e "${BLUE}Expected:${NC}"
    echo "$expected"
  fi
}

# Test queryAllCars function
test_query_all_cars() {
  print_test_header "Query All Cars"
  echo -e "${BLUE}Querying all cars from the ledger...${NC}"

  local result=$(peer chaincode query -C ${CHANNEL_NAME} -n ${CC_NAME} -c '{"function":"queryAllCars","Args":[]}')
  local status=$?

  if [ $status -eq 0 ]; then
    echo -e "${GREEN}✓ Query All Cars - SUCCESS${NC}"
    print_test_result "$result"
  else
    echo -e "${RED}✗ Query All Cars - FAILED${NC}"
    print_test_result "$result"
    exit 1
  fi
}

# Test queryCar function for a specific car
test_query_car() {
  local car_id=$1
  print_test_header "Query Specific Car (${car_id})"
  echo -e "${BLUE}Querying car with ID ${car_id} from the ledger...${NC}"

  local result=$(peer chaincode query -C ${CHANNEL_NAME} -n ${CC_NAME} -c "{\"function\":\"queryCar\",\"Args\":[\"${car_id}\"]}")
  local status=$?

  if [ $status -eq 0 ]; then
    echo -e "${GREEN}✓ Query Car ${car_id} - SUCCESS${NC}"
    print_test_result "$result"
  else
    echo -e "${RED}✗ Query Car ${car_id} - FAILED${NC}"
    print_test_result "$result"
    exit 1
  fi
}

# Test createCar function
test_create_car() {
  local car_id=$1
  local make=$2
  local model=$3
  local color=$4
  local year=$5
  local owner=$6

  print_test_header "Create New Car (${car_id})"
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
    print_test_result "$result"
    
    # Verify the car was created by querying it
    echo -e "${BLUE}Verifying the car was created by querying it...${NC}"
    test_query_car ${car_id}
  else
    echo -e "${RED}✗ Create Car ${car_id} - FAILED${NC}"
    print_test_result "$result"
    exit 1
  fi
}

# Test transferCarOwnership function
test_transfer_car_ownership() {
  local car_id=$1
  local new_owner=$2

  print_test_header "Transfer Car Ownership (${car_id} to ${new_owner})"
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
    print_test_result "$result"
    
    # Verify the ownership was transferred by querying the car
    echo -e "${BLUE}Verifying the ownership was transferred by querying the car...${NC}"
    test_query_car ${car_id}
  else
    echo -e "${RED}✗ Transfer Car Ownership of ${car_id} to ${new_owner} - FAILED${NC}"
    print_test_result "$result"
    exit 1
  fi
}

# Function to add a delay between operations
add_delay() {
  local seconds=$1
  echo -e "${BLUE}Waiting for ${seconds} seconds to allow transaction to be committed...${NC}"
  sleep ${seconds}
}

# Run all tests
main() {
  parse_options "$@"
  setup_environment

  echo -e "${YELLOW}=====================================\n${NC}"
  echo -e "${YELLOW}Car Showroom Chaincode Test Suite${NC}"
  echo -e "\nTesting chaincode on channel: ${CHANNEL_NAME}"
  echo -e "Using chaincode: ${CC_NAME}"
  echo -e "${YELLOW}=====================================\n${NC}"

  # Test queryAllCars
  test_query_all_cars

  # Test queryCar for an existing car
  test_query_car "CAR001"

  # Test createCar
  test_create_car "CAR007" "Porsche" "911" "Silver" "2023" "Chris"
  add_delay 5  # Add 5 second delay after creation

  # Test transferCarOwnership
  test_transfer_car_ownership "CAR001" "Alex"
  add_delay 5  # Add 5 second delay after transfer

  # Final verification - query all cars again to see all changes
  echo -e "\n${YELLOW}Final Verification - Query All Cars${NC}"
  test_query_all_cars

  echo -e "\n${GREEN}All tests completed successfully!${NC}"
}

# Execute main function
main "$@"
