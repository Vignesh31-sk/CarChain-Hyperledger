package com.carshowroom.chaincode;

import com.owlike.genson.annotation.JsonProperty;
import org.hyperledger.fabric.contract.annotation.DataType;
import org.hyperledger.fabric.contract.annotation.Property;

import java.util.Objects;

@DataType()
public final class Car {

    @Property()
    private final String id;

    @Property()
    private final String make;

    @Property()
    private final String model;

    @Property()
    private final String color;

    @Property()
    private final int year;

    @Property()
    private String owner;

    public Car(@JsonProperty("id") final String id,
               @JsonProperty("make") final String make,
               @JsonProperty("model") final String model,
               @JsonProperty("color") final String color,
               @JsonProperty("year") final int year,
               @JsonProperty("owner") final String owner) {
        this.id = id;
        this.make = make;
        this.model = model;
        this.color = color;
        this.year = year;
        this.owner = owner;
    }

    public String getId() {
        return id;
    }

    public String getMake() {
        return make;
    }

    public String getModel() {
        return model;
    }

    public String getColor() {
        return color;
    }

    public int getYear() {
        return year;
    }

    public String getOwner() {
        return owner;
    }

    public void setOwner(String owner) {
        this.owner = owner;
    }

    @Override
    public boolean equals(final Object obj) {
        if (this == obj) {
            return true;
        }
        if (obj == null || getClass() != obj.getClass()) {
            return false;
        }
        Car other = (Car) obj;
        return Objects.equals(id, other.id) &&
               Objects.equals(make, other.make) &&
               Objects.equals(model, other.model) &&
               Objects.equals(color, other.color) &&
               year == other.year &&
               Objects.equals(owner, other.owner);
    }

    @Override
    public int hashCode() {
        return Objects.hash(id, make, model, color, year, owner);
    }

    @Override
    public String toString() {
        return "Car{" +
                "id='" + id + '\'' +
                ", make='" + make + '\'' +
                ", model='" + model + '\'' +
                ", color='" + color + '\'' +
                ", year=" + year +
                ", owner='" + owner + '\'' +
                '}';
    }
}