#!/bin/bash

# Package Car Showroom Chaincode for Hyperledger Fabric
# This script packages the chaincode and prepares it for deployment

set -e

echo "===== Car Showroom Chaincode Packaging Tool ====="

echo "Cleaning up any previous packaging..."
rm -rf chaincode-package/src/main/java
mkdir -p chaincode-package/src/main/java

echo "Building the chaincode with Gradle..."
./gradlew clean build shadowJar

echo "Copying Java source files to chaincode package..."
cp -r app/src/main/java/com chaincode-package/src/main/java/

echo "Creating simplified build.gradle file in chaincode package..."
cat > chaincode-package/build.gradle << EOF
plugins {
    id 'com.github.johnrengelman.shadow' version '7.1.2'
    id 'java'
}

repositories {
    mavenCentral()
    maven {
        url 'https://jitpack.io'
    }
}

dependencies {
    implementation 'org.hyperledger.fabric-chaincode-java:fabric-chaincode-shim:2.4.1'
    implementation 'com.github.everit-org.json-schema:org.everit.json.schema:1.12.1'
    implementation 'com.owlike:genson:1.6'
}

sourceCompatibility = 1.8
targetCompatibility = 1.8

shadowJar {
    archiveBaseName = 'chaincode'
    archiveClassifier = ''
    archiveVersion = ''
    manifest {
        attributes 'Main-Class': 'org.hyperledger.fabric.contract.ContractRouter'
    }
}
EOF

echo "Copying pre-built JAR to chaincode package..."
cp app/build/libs/carshowroom-chaincode-1.0.0-all.jar chaincode-package/chaincode.jar

echo "Creating chaincode metadata files..."
cat > chaincode-package/metadata.json << EOF
{
    "type": "java",
    "label": "carshowroom"
}
EOF

cat > chaincode-package/connection.json << EOF
{
    "address": "carshowroom-chaincode:9999",
    "dial_timeout": "10s",
    "tls_required": false
}
EOF

cat > chaincode-package/connection.yaml << EOF
address: carshowroom-chaincode:9999
dial_timeout: 10s
tls_required: false
EOF

echo "Creating simplified Dockerfile..."
cat > chaincode-package/Dockerfile << EOF
FROM openjdk:8-jre

COPY chaincode.jar /chaincode/input/chaincode.jar
WORKDIR /chaincode/input
CMD ["java", "-jar", "chaincode.jar"]
EOF

echo "Packaging complete. Files are in the chaincode-package directory."
echo "Use the following command to build the chaincode Docker image:"
echo "    docker build -t carshowroom-chaincode:1.0 ./chaincode-package"
echo ""
echo "Use the following command to package the chaincode for Fabric:"
echo "    cd \${FABRIC_SAMPLES_DIR}/test-network"
echo "    export PATH=\${PWD}/../bin:\$PATH"
echo "    export FABRIC_CFG_PATH=\${PWD}/../config/"
echo "    peer lifecycle chaincode package carshowroom.tar.gz --path /path/to/chaincode-package --lang java --label carshowroom_1.0"
echo ""