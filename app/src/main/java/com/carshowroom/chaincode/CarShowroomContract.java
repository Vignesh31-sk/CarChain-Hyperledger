package com.carshowroom.chaincode;

import com.owlike.genson.Genson;
import org.hyperledger.fabric.contract.Context;
import org.hyperledger.fabric.contract.ContractInterface;
import org.hyperledger.fabric.contract.annotation.Contact;
import org.hyperledger.fabric.contract.annotation.Contract;
import org.hyperledger.fabric.contract.annotation.Default;
import org.hyperledger.fabric.contract.annotation.Info;
import org.hyperledger.fabric.contract.annotation.License;
import org.hyperledger.fabric.contract.annotation.Transaction;
import org.hyperledger.fabric.shim.ChaincodeException;
import org.hyperledger.fabric.shim.ChaincodeStub;
import org.hyperledger.fabric.shim.ledger.KeyValue;
import org.hyperledger.fabric.shim.ledger.QueryResultsIterator;

import java.util.ArrayList;
import java.util.List;

@Contract(
        name = "carshowroom",
        info = @Info(
                title = "Car Showroom Contract",
                description = "A chaincode contract for managing cars in a showroom",
                version = "1.0.0",
                contact = @Contact(
                        name = "Car Showroom",
                        email = "carshowroom@example.com"
                ),
                license = @License(
                        name = "Apache 2.0 License",
                        url = "http://www.apache.org/licenses/LICENSE-2.0.html"
                )
        )
)
@Default
public class CarShowroomContract implements ContractInterface {

    private final Genson genson = new Genson();

    private enum CarShowroomErrors {
        CAR_NOT_FOUND,
        CAR_ALREADY_EXISTS
    }

    /**
     * Initializes the ledger with sample cars.
     *
     * @param ctx the transaction context
     * @return success message
     */
    @Transaction(intent = Transaction.TYPE.SUBMIT)
    public String initLedger(final Context ctx) {
        ChaincodeStub stub = ctx.getStub();
        int carCount = 0;
        
        // Initial set of cars for demonstration - only create if they don't exist
        if (!carExists(ctx, "CAR001")) {
            createCar(ctx, "CAR001", "Toyota", "Corolla", "Blue", 2020, "John");
            carCount++;
        }
        
        if (!carExists(ctx, "CAR002")) {
            createCar(ctx, "CAR002", "Honda", "Civic", "Red", 2021, "Sarah");
            carCount++;
        }
        
        if (!carExists(ctx, "CAR003")) {
            createCar(ctx, "CAR003", "Ford", "Mustang", "Black", 2019, "Mike");
            carCount++;
        }
        
        if (!carExists(ctx, "CAR004")) {
            createCar(ctx, "CAR004", "BMW", "X5", "White", 2022, "Lisa");
            carCount++;
        }
        
        if (!carExists(ctx, "CAR005")) {
            createCar(ctx, "CAR005", "Tesla", "Model 3", "Silver", 2021, "David");
            carCount++;
        }
        
        return "Ledger initialized with " + carCount + " new sample cars";
    }

    /**
     * Creates a new car on the ledger.
     *
     * @param ctx the transaction context
     * @param id the ID of the car
     * @param make the make of the car
     * @param model the model of the car
     * @param color the color of the car
     * @param year the year of the car
     * @param owner the owner of the car
     * @return the created car
     */
    @Transaction(intent = Transaction.TYPE.SUBMIT)
    public Car createCar(final Context ctx, final String id, final String make, 
                         final String model, final String color, final int year, 
                         final String owner) {
        ChaincodeStub stub = ctx.getStub();

        // Check if car already exists
        if (carExists(ctx, id)) {
            String errorMessage = String.format("Car %s already exists", id);
            System.out.println(errorMessage);
            throw new ChaincodeException(errorMessage, CarShowroomErrors.CAR_ALREADY_EXISTS.toString());
        }

        Car car = new Car(id, make, model, color, year, owner);
        String carJSON = genson.serialize(car);
        stub.putStringState(id, carJSON);

        return car;
    }

    /**
     * Retrieves a car from the ledger.
     *
     * @param ctx the transaction context
     * @param id the ID of the car to retrieve
     * @return the car found on the ledger
     */
    @Transaction(intent = Transaction.TYPE.EVALUATE)
    public Car queryCar(final Context ctx, final String id) {
        ChaincodeStub stub = ctx.getStub();
        String carJSON = stub.getStringState(id);

        if (carJSON == null || carJSON.isEmpty()) {
            String errorMessage = String.format("Car %s does not exist", id);
            System.out.println(errorMessage);
            throw new ChaincodeException(errorMessage, CarShowroomErrors.CAR_NOT_FOUND.toString());
        }

        Car car = genson.deserialize(carJSON, Car.class);
        return car;
    }

    /**
     * Checks if a car exists in the ledger.
     *
     * @param ctx the transaction context
     * @param id the ID of the car
     * @return boolean indicating if the car exists
     */
    @Transaction(intent = Transaction.TYPE.EVALUATE)
    public boolean carExists(final Context ctx, final String id) {
        ChaincodeStub stub = ctx.getStub();
        String carJSON = stub.getStringState(id);
        return (carJSON != null && !carJSON.isEmpty());
    }

    /**
     * Changes the owner of a car in the ledger.
     *
     * @param ctx the transaction context
     * @param id the ID of the car to transfer
     * @param newOwner the new owner of the car
     * @return the updated car
     */
    @Transaction(intent = Transaction.TYPE.SUBMIT)
    public Car transferCarOwnership(final Context ctx, final String id, final String newOwner) {
        ChaincodeStub stub = ctx.getStub();
        String carJSON = stub.getStringState(id);

        if (carJSON == null || carJSON.isEmpty()) {
            String errorMessage = String.format("Car %s does not exist", id);
            System.out.println(errorMessage);
            throw new ChaincodeException(errorMessage, CarShowroomErrors.CAR_NOT_FOUND.toString());
        }

        Car car = genson.deserialize(carJSON, Car.class);
        car.setOwner(newOwner);
        
        // Update state on the ledger
        String updatedCarJSON = genson.serialize(car);
        stub.putStringState(id, updatedCarJSON);
        
        return car;
    }

    /**
     * Gets all cars from the ledger.
     *
     * @param ctx the transaction context
     * @return array of all cars found on the ledger
     */
    @Transaction(intent = Transaction.TYPE.EVALUATE)
    public Car[] queryAllCars(final Context ctx) {
        ChaincodeStub stub = ctx.getStub();
        List<Car> allCars = new ArrayList<>();
        
        // Get all cars from the ledger
        QueryResultsIterator<KeyValue> results = stub.getStateByRange("", "");
        
        for (KeyValue result : results) {
            Car car = genson.deserialize(result.getStringValue(), Car.class);
            allCars.add(car);
        }
        
        return allCars.toArray(new Car[0]);
    }
}