# Makersbnb

![alt text](http://i.imgur.com/ViVhjND.png)

We followed this [specification](SPECIFICATION.md).

---
### Running the app

In your terminal:
```terminal
npm install
```

Install mongo db
create database `makersBnB`
create table `adverts`
In the terminal run:
```m
mongod
```
create a new terminal window, `cd` to project directory
```n
node app
```

---
### User Stories
*Landlord*
```landlord
As a landlord
So that I can list a space as myself
I want to be able to sign up

As a landlord
So that I can advertise a space
I want to be able to create a property listing

As a landlord
So that I can maximise my revenue
I want to list multiple spaces

As a landlord
So that customers can view details of my spaces
I want to describe my space with a name, short description and price per night

As a landlord
So that customers can book days/Nights
I want to offer a range of available dates

As a landlord
So that I let out my property
I want to approve a customer's request to book my property

As a landlord
So that I can have multiple requests
I want my space to be available until I have confirmed the booking
```

*Customer*
```customer
As a customer
So I can book a space
I want to be able to sign up

As a customer
So I can see spaces to book
I want to be able to view available spaces

As a customer
So I can get plan my trip
I want to be able to request a space for a night

As a customer
So that I don't book an already booked space and date
I want to only be able to book available nights
```

---
#### Minimum Viable Product
*Requirements*
##### List a space
Create a page that allows you to enter details for a property advert.

##### View a space
Display the property advert on a page.

##### Request a booking
Interact with the page to request a booking.

##### Confirm a booking
Have a page that allows you to confirm a booking
---
