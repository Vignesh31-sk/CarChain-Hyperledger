# Car Showroom Blockchain Application

This project implements a car showroom management system using Hyperledger Fabric blockchain. The system allows for tracking cars in a showroom, including creating new cars, querying cars, and transferring ownership.

## Prerequisites

- Java 11 or later
- Gradle 7.x or later
- Docker and Docker Compose
- Hyperledger Fabric v2.4.x binaries, Docker images, and samples

## Project Structure

```
/car-showroom-chaincode/
├── src/
│   └── main/
│       └── java/
│           └── org/
│               └── example/
│                   ├── CarContract.java      # Main chaincode implementation
│                   ├── Car.java              # Car asset definition
│                   └── CarQueryResult.java   # Query result wrapper class
├── build.gradle                              # Gradle build configuration
├── settings.gradle                           # Gradle settings
├── package_chaincode.sh                      # Script to package the chaincode
├── test_chaincode.sh                         # Script to test the chaincode
└── deploy_chaincode.sh                       # Script to deploy chaincode to network
```

## Setup Instructions

### 1. Start the Fabric Test Network

```bash
cd fabric-samples/test-network

# Make sure to replace above path with your path to fabric-samples
# export PATH=${PWD}/../bin:$PATH
# export FABRIC_CFG_PATH=$PWD/../config/

./network.sh down
./network.sh up createChannel -c mychannel -ca
```

### 2. Deploy the Chaincode

Before deploying the chaincode, you need to update the scripts with your local Fabric samples path:

```bash
# IMPORTANT: Edit the script files to update the FABRIC_SAMPLES_PATH variable to match your fabric samples actual path before running these commands

# Once path is updated, run:

./package_chaincode.sh
./deploy_chaincode.sh -i
```

The `-i` flag initializes the ledger with sample data.

### 3. Test the Chaincode

```bash
./test_chaincode.sh
```

This will run through all the core functions of the chaincode:

- Query all cars
- Query a specific car
- Create a new car
- Transfer car ownership

#### Test Script Options

```bash
./test_carshowroom.sh [options]
```

Available options:

- `-f <path>`: Path to fabric-samples directory (default: "/home/viki/Programming/Projects/BCT-Mini/fabric-samples")
- `-c <channel>`: Channel name (default: "mychannel")
- `-n <name>`: Chaincode name (default: "carshowroom")
- `-h`: Print help message

## Chaincode Functions

The chaincode provides the following functions:

1. **initLedger** - Initialize the ledger with sample cars
2. **createCar** - Create a new car on the ledger
3. **queryCar** - Query details of a specific car
4. **transferCarOwnership** - Transfer ownership of a car to a new owner
5. **queryAllCars** - List all cars in the ledger
6. **carExists** - Check if a car exists in the ledger

## Cleanup

To stop the Fabric network and clean up:

```bash
cd /path/to/fabric-samples/test-network
./network.sh down
```
