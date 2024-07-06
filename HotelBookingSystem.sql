--Hotel Booking System

CREATE DATABASE HotelBookingSystem;
USE HotelBookingSystem;

--Hotels Table
CREATE TABLE Hotels (
  HotelID INT IDENTITY(1,1) PRIMARY KEY,
  HotelName VARCHAR(255) NOT NULL,
  Address VARCHAR(255) NOT NULL,
  City VARCHAR(100) NOT NULL,
  State VARCHAR(100) NOT NULL,
  Country VARCHAR(100) NOT NULL,
  ZipCode VARCHAR(10) NOT NULL
);

--Rooms Table
CREATE TABLE Rooms (
  RoomID INT IDENTITY(1,1) PRIMARY KEY,
  HotelID INT NOT NULL,
  RoomNumber INT NOT NULL,
  RoomType VARCHAR(100) NOT NULL,
  Price DECIMAL(10,2) NOT NULL,
  FOREIGN KEY (HotelID) REFERENCES Hotels(HotelID)
);

--Customers Table
CREATE TABLE Customers (
  CustomerID INT IDENTITY(1,1) PRIMARY KEY,
  FirstName VARCHAR(100) NOT NULL,
  LastName VARCHAR(100) NOT NULL,
  Email VARCHAR(255) NOT NULL UNIQUE,
  PhoneNumber VARCHAR(20) NOT NULL UNIQUE,
  CHECK (PhoneNumber LIKE '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'),
  CHECK (Email LIKE '%_@__%.__%')
);

--Booking Table
CREATE TABLE Booking (
  BookingID INT IDENTITY(1,1) PRIMARY KEY,
  RoomID INT NOT NULL,
  CustomerID INT NOT NULL,
  Checkin DATE NOT NULL,
  Checkout DATE NOT NULL,
  FOREIGN KEY (RoomID) REFERENCES Rooms(RoomID),
  FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID)
);
--Small correction in Booking table
ALTER TABLE Booking

ADD HotelID INT

ALTER TABLE Booking
ADD CONSTRAINT FK_Booking_Hotel
FOREIGN KEY (HotelID)
REFERENCES Hotels(HotelID);


--Payments Table
CREATE TABLE Payments (
  PaymentID INT IDENTITY(1,1) PRIMARY KEY,
  BookingID INT NOT NULL,
  Amount DECIMAL(10,2) NOT NULL,
  PaymentDate DATE NOT NULL,
  FOREIGN KEY (BookingID) REFERENCES Booking(BookingID)
);

--To Display hotles and rooms
CREATE PROCEDURE display_hotels_and_rooms
AS
BEGIN
  SELECT h.HotelName, r.RoomNumber, r.Price
  FROM Hotels h
  JOIN Rooms r ON h.HotelID = r.HotelID
  ORDER BY h.HotelName, r.RoomNumber;
END;

--To Display available rooms
CREATE PROCEDURE display_available_rooms 
    @p_hotel_name NVARCHAR(255)
AS
BEGIN
    SELECT h.HotelName,h.HotelID,r.RoomID, r.RoomNumber, r.Price
    FROM Rooms r
    JOIN Hotels h ON r.HotelID = h.HotelID
    WHERE h.HotelName = @p_hotel_name
    AND NOT EXISTS (
        SELECT 1
        FROM Booking b
        WHERE b.RoomID = r.RoomID
    )
END;

--Booking Stored Procedure
CREATE PROCEDURE book_room
    @HotelID int,
	@RoomID int,
    @CustomerFirstName nvarchar(50),
    @CustomerLastName nvarchar(50),
    @CustomerEmail nvarchar(100),
    @CustomerPhoneNumber nvarchar(20),
    @BookingDate datetime,
    @CheckoutDate datetime
AS
BEGIN
    -- Checking if the room exists
    IF NOT EXISTS (
        SELECT 1
        FROM Rooms r
        WHERE r.RoomID = @RoomID
        AND r.HotelID = @HotelID
    )
    BEGIN
        RAISERROR ('Room does not exist', 16, 1);
        RETURN;
    END

    -- Checking if the room is available or not
    IF EXISTS (
        SELECT 1
        FROM Booking b
        WHERE b.RoomID = @RoomID
        AND ((@BookingDate BETWEEN b.Checkin AND b.Checkout) OR (@CheckoutDate BETWEEN b.Checkin AND b.Checkout))
    )
    BEGIN
        RAISERROR ('Room is not available for the specified dates', 16, 1);
        RETURN;
    END

    -- Adding customer data
    DECLARE @CustomerID int
    INSERT INTO Customers (FirstName, LastName, Email, PhoneNumber)
    VALUES (@CustomerFirstName, @CustomerLastName, @CustomerEmail, @CustomerPhoneNumber)
    SET @CustomerID = SCOPE_IDENTITY()

    -- Get the room price
    DECLARE @RoomPrice decimal(10,2)
    SELECT @RoomPrice = r.Price FROM Rooms r WHERE r.RoomID = @RoomID AND r.HotelID = @HotelID

    -- Calculateing the amount
    DECLARE @Amount decimal(10,2)
    SET @Amount = @RoomPrice * DATEDIFF(DAY, @BookingDate, @CheckoutDate)

    -- Checking if the amount is valid
    IF @Amount IS NULL OR @Amount <= 0
    BEGIN
        RAISERROR ('Invalid amount', 16, 1);
        RETURN;
    END

    -- Booking the room
    DECLARE @BookingID int
    INSERT INTO Booking (RoomID, CustomerID, Checkin, Checkout, HotelID)
    VALUES (@RoomID, @CustomerID, @BookingDate, @CheckoutDate, @HotelID)
    SET @BookingID = SCOPE_IDENTITY()

    -- Adding payment details
    INSERT INTO Payments (BookingID, Amount, PaymentDate)
    VALUES (@BookingID, @Amount, GETDATE())
END

--Displaying the details of booking
CREATE PROCEDURE display_booking_details
    @p_BookingID int
AS
BEGIN
    SELECT 
        h.HotelName,
        r.RoomNumber,
        c.FirstName,
        c.LastName,
        c.Email,
        c.PhoneNumber,
        b.Checkin,
        b.Checkout
    FROM 
        Booking b
    JOIN 
        Rooms r ON b.RoomID = r.RoomID
    JOIN 
        Hotels h ON b.HotelID = h.HotelID
    JOIN 
        Customers c ON b.CustomerID = c.CustomerID
    WHERE 
        b.BookingID = @p_BookingID;
END;

-- Inserting data for Hotels
INSERT INTO Hotels (HotelName, Address, City, State, Country, ZipCode)
VALUES
('Hotel Taj', 'Banjara Hills', 'Hyderabad', 'Telangana', 'India', '500034'),
('Hotel Novotel', 'Vijayawada', 'Vijayawada', 'Andhra Pradesh', 'India', '520010'),
('Hotel Leela', 'Connaught Place', 'Delhi', 'Delhi', 'India', '110001'),
('Hotel JW Marriott', 'Senapati Bapat Marg', 'Mumbai', 'Maharashtra', 'India', '400013'),
('Hotel Hyatt', 'Weikfield IT Park', 'Pune', 'Maharashtra', 'India', '411014');

-- Inserting data for Rooms
INSERT INTO Rooms (HotelID, RoomNumber, RoomType, Price)
VALUES
(1, 101, 'Deluxe', 5000.00),
(1, 102, 'Premium', 7000.00),
(2, 201, 'Deluxe', 4000.00),
(2, 202, 'Premium', 6000.00),
(3, 301, 'Deluxe', 6000.00),
(3, 302, 'Premium', 8000.00),
(4, 401, 'Deluxe', 7000.00),
(4, 402, 'Premium', 9000.00),
(5, 501, 'Deluxe', 5000.00),
(5, 502, 'Premium', 7000.00);

--Booking Rooms
--Displaying Hotles and rooms
EXEC display_hotels_and_rooms

--Displaying Avalable rooms
EXEC display_available_rooms 'Hotel Hyatt';

--RoomBooking
EXEC book_room 1, 1, 'Kurup', 'Reddy', 'kurupreddy@gmail.com', '1234567890', '2022-01-01', '2022-01-03'

EXEC book_room 2, 3, 'Arjun', 'Das', 'das@gmail.com', '0987654321', '2022-01-01', '2022-01-03'

EXEC book_room 3, 5, 'Alex', 'Smith', 'alexsmith@gmail.com', '5551234567', '2022-01-01', '2022-01-03'

EXEC book_room 4, 7, 'Virat', 'John', 'viratjohnson@gmail.com', '5559876543', '2022-01-01', '2022-01-03';

EXEC book_room 5, 9, 'Manish', 'pandey', 'manish@gmail.com', '6282567652', '2022-01-01', '2022-01-03';

--Displaying Booking Details
EXEC display_booking_details 14

--Payments
select*from Payments
