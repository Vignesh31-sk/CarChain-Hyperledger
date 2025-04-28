package com.carshowroom.chaincode;

import org.hyperledger.fabric.contract.ContractRouter;

public class CarShowroomChaincode {
    
    public static void main(String[] args) {
        // Start the chaincode contract using the ContractRouter
        // The ContractRouter will automatically discover and register contracts
        // in the same package or subpackages as this class
        ContractRouter router = new ContractRouter(args);
        router.start(args);
    }
}