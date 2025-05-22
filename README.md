# Car Showroom Blockchain Application

This project implements a car showroom management system using Hyperledger Fabric blockchain. The system allows for tracking cars in a showroom, including creating new cars, querying cars, and transferring ownership.

## Prerequisites

- Java 11 or later
- Gradle 7.x or later
- Docker and Docker Compose
- Hyperledger Fabric v2.4.x binaries, Docker images, and samples

## Project Structure

```
/CarChain-Hyperledger/

├──app/
│   └── src/
│       └── main/
│           └── java/
│               └── org/
│                   └── example/
│                       ├── CarShowroomChaincode.java  # Main chaincode implementation
│                       ├── Car.java                   # Car asset definition
│                       └── CarShowroomContract.java   # Main contract
├── gradle/                                   # Gradle configuration files
├── build.gradle                              # Gradle build configuration
├── settings.gradle                           # Gradle settings
├── package_chaincode.sh                      # Script to package the chaincode
├── chaincode_lifecycle.sh                    # Script to manage chaincode lifecycle.
├── debug_car_chaincode.sh                    # Script to manage chaincode functions.
├── test_chaincode.sh                         # Script to test the chaincode
└── deploy_chaincode.sh                       # Script to deploy chaincode to network.

```

## Setup Instructions

> :warning: Edit the script files to update the variables before running these commands or pass the required variables as arguments

### 1. Start the Fabric Test Network

```bash
cd /path/to/fabric-samples/test-network

# Make sure to replace above path with your path to fabric-samples

./network.sh down
./network.sh up createChannel -c mychannel -ca
```

### 2. Package the Chaincode

```bash
./package_chaincode.sh
```

### 3. Deploy the Chaincode

```bash
./deploy_chaincode.sh -i
```

The `-i` flag initializes the ledger with sample data.

Available options:

- `-f <path>`: Path to fabric-samples directory (default: "/home/viki/Programming/Projects/BCT-Mini/fabric-samples")
- `-c <channel>`: Channel name (default: "mychannel")
- `-n <name>`: Chaincode name (default: "carshowroom")
- `-i`: Initialize the ledger with sample data after deployment
- `-h`: Print help message

### 4. Test the Chaincode

```bash
./test_chaincode.sh
```

This will run through all the core functions of the chaincode:

- Query all cars
- Query a specific car
- Create a new car
- Transfer car ownership

Available options:

- `-f <path>`: Path to fabric-samples directory (default: "/home/viki/BCT_Mini/fabric-samples")
- `-c <channel>`: Channel name (default: "mychannel")
- `-n <name>`: Chaincode name (default: "carshowroom")
- `-h`: Print help message

### 4. Chaincode Lifecycle Management

This script provides tools to manage the chaincode lifecycle in Hyperledger Fabric.

It handles packaging, installing, approving, and committing chaincode definitions

- Package Chaincode
- Install Chaincode
- Get Package ID
- Approve Chaincode for Organization
- Check Commit Readiness
- Commit Chaincode Definition
- Query Committed Chaincode
- Check Peer Status

```bash
./chaincode_lifecycle.sh 
```

Available options:

- `-f <path>`: Path to fabric-samples directory (default "/home/viki/BCT_Mini/fabric-samples")
- `-c <channel name>`: Name of channel (default "mychannel")
- `-n <chaincode name>`: Chaincode name (default "carshowroom")
- `-v <chaincode version>`: Chaincode version (default "1.0.0")
- `-s <sequence>`: Version sequence (default 1)
- `-h`: Print this help message

## Chaincode Functions

This script allows for individual invocation of car showroom chaincode functions for testing and debugging purposes

It provides a simple menu-driven interface to invoke different chaincode functions

```bash
./debug_car_chaincode.sh 
```

Available options:

- `-f <path>`: Path to fabric-samples directory (default "/home/viki/BCT_Mini/fabric-samples")
- `-c <channel name>`: Name of channel (default "mychannel")
- `-n <chaincode name>`: Chaincode name (default "carshowroom")
- `-h`: Print this help message

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
