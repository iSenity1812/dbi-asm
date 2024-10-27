
-- Create table Customers
CREATE TABLE Customers (
	CustomerID VARCHAR(10) PRIMARY KEY,
	Username NVARCHAR(45) NOT NULL,
	[FirstName] NVARCHAR(45) NOT NULL,
	[LastName] NVARCHAR(45) NOT NULL,
	Gender CHAR(1) NOT NULL,
	Phone CHAR(10) UNIQUE,
	Email VARCHAR(255) UNIQUE,
	City NVARCHAR(50),
	[Address] NVARCHAR(50),
	MembershipType VARCHAR(50) --Regular/CFRIEND/CVIP
);


-- Create table Movies
CREATE TABLE Movies (
	MovieID INT PRIMARY KEY,
	Title NVARCHAR(255),
	Duration INT,
	Subtitle BIT,
	Director VARCHAR(50),
	[Description] NVARCHAR(500),
	[Language] NVARCHAR(50),
	ReleaseDate DATETIME,
	TrailerURL VARCHAR(255),
	AgeRestriction VARCHAR(3),
	Genre NVARCHAR(50),
);



-- Create table Cinemas
CREATE TABLE Cinemas (
	CinemaID INT PRIMARY KEY,
	[Name] NVARCHAR(255) NOT NULL,
	[Location] NVARCHAR(255) NOT NULL,
	TotalScreens INT NOT NULL,
);

-- Create table Discounts
CREATE TABLE Discounts (
	DiscountID VARCHAR(10) PRIMARY KEY,
	[Description] NVARCHAR(255),
	DiscountValue DECIMAL(10, 2),
);

-- Create table PaymentMethods
CREATE TABLE PaymentMethods (
	PaymentMethodID INT PRIMARY KEY,
	MethodName VARCHAR(50),
	[Description] NVARCHAR(255)
);

-- Create table Booking
CREATE TABLE Booking (
	BookingID VARCHAR(30) PRIMARY KEY,
	CustomerID VARCHAR(10) NOT NULL,
	TransactionDate DATETIME, -- automatic current date
	BookingDate DATETIME DEFAULT CURRENT_TIMESTAMP,
	FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID)
);


-- Create table Transactions
CREATE TABLE Transactions (
	TransactionID VARCHAR(10) PRIMARY KEY,
	BookingID VARCHAR(30) NOT NULL,
	FinalAmount DECIMAL(10, 2) NULL,
	DiscountID VARCHAR(10) NULL,
	PaymentMethodID INT,
	CustomerID VARCHAR(10),

	FOREIGN KEY (BookingID) REFERENCES Booking(BookingID),
	FOREIGN KEY (DiscountID) REFERENCES Discounts(DiscountID),
	FOREIGN KEY (PaymentMethodID) REFERENCES PaymentMethods(PaymentMethodID),
	FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID)
);

-- Create table TicketPrice
CREATE TABLE TicketPrice (
	PriceID INT PRIMARY KEY,
	CinemaID INT,
	BasePrice DECIMAL(10, 2),
	AgeGroup INT,
	SeatType INT,
	FOREIGN KEY (CinemaID) REFERENCES Cinemas(CinemaID)
);


-- Create table Rooms
CREATE TABLE Rooms (
	RoomID VARCHAR(10) PRIMARY KEY,
	CinemaID INT,
	Capacity INT,

	FOREIGN KEY (CinemaID) REFERENCES Cinemas(CinemaID)
);



	-- Create table Seats
CREATE TABLE Seats (
	SeatID VARCHAR(20) PRIMARY KEY,
	RoomID VARCHAR(10) NOT NULL,
	SeatNumber INT NOT NULL,
	[Row] CHAR(1),
	[Status] BIT,
	[Type] CHAR(1),

	CONSTRAINT FK_Room FOREIGN KEY (RoomID) REFERENCES Rooms(RoomID),
	CONSTRAINT UQ_Room_Seat UNIQUE (RoomID, SeatNumber, [Row]) --  dam bao cac ghe la duy nhat cho moi roomID
);



-- Create table ShowTimes
CREATE TABLE ShowTimes (
	ShowTimeID INT PRIMARY KEY, 
	MovieID INT NOT NULL,
	StartTime VARCHAR(10),

	FOREIGN KEY (MovieID) REFERENCES Movies(MovieID)
);

-- Create table DetailBooking
CREATE TABLE DetailBooking (
	DetailBookingID INT PRIMARY KEY,
	BookingID VARCHAR(30) NOT NULL,
	TicketID VARCHAR(30) NULL, -- Nullable
	FoodID VARCHAR(30) NULL, -- Nullable
	PricePerUnit DECIMAL(10, 2),
	Quantity INT,
	ProductType VARCHAR(20) NOT NULL, -- Values 'Ticket' or 'Food'


	-- Foreign key
	FOREIGN KEY (BookingID) REFERENCES Booking(BookingID),
	FOREIGN KEY (TicketID) REFERENCES Ticket(TicketID),
	FOREIGN KEY (FoodID) REFERENCES FoodAndBeverages(FoodID), -- reference to either FoodAndBeverages or Ticket

	-- 1 of them is not null
	CONSTRAINT CHK_TicketOrFood CHECK (TicketID IS NOT NULL OR FoodID IS NOT NULL),

	-- Ensure ProductType aligns with either TicketID or FoodID
	CONSTRAINT CHK_ProductType CHECK (
	    (ProductType = 'Ticket' AND TicketID IS NOT NULL AND FoodID IS NULL) OR 
	    (ProductType = 'Food' AND FoodID IS NOT NULL AND TicketID IS NULL)
	),

	CONSTRAINT UQ_Booking_TicketFood UNIQUE (BookingID, TicketID, FoodID)

	--CONSTRAINT UQ_Booking_Ticket UNIQUE (BookingID, TicketID),
    --CONSTRAINT UQ_Booking_Food UNIQUE (BookingID, FoodID), -- Unique composite key -- Trong truong hop co nhieu phan loai hang

);


-- Create table Ticket
CREATE TABLE Ticket (
	TicketID VARCHAR(30) PRIMARY KEY,
	PriceID INT NOT NULL,
	SeatID VARCHAR(20) NOT NULL,
	MovieID INT NOT NULL,
	ShowTimeID INT NOT NULL,


	FOREIGN KEY (PriceID) REFERENCES TicketPrice(PriceID),
	FOREIGN KEY (SeatID) REFERENCES Seats(SeatID),
	FOREIGN KEY (MovieID) REFERENCES Movies(MovieID),
	FOREIGN KEY (ShowTimeID) REFERENCES ShowTimes(ShowTimeID)
);


-- Create table FoodAndBeverages
CREATE TABLE FoodAndBeverages (
	FoodID VARCHAR(30) PRIMARY KEY,
	CinemaID INT NOT NULL,
	ProductName NVARCHAR(255),
	Category VARCHAR(255),
	Price DECIMAL(10, 2),

	FOREIGN KEY (CinemaID) REFERENCES Cinemas(CinemaID)
);


--================ TRIGGERS AND PROCEDURES ================--
-- Kiem tra seatnumber
CREATE TRIGGER CheckSeatNumber
ON Seats
AFTER INSERT, UPDATE
AS
BEGIN
	DECLARE @RoomID VARCHAR(10);
	DECLARE @SeatNum INT;
	DECLARE @Capacity INT;

	-- Lay RoomID va SeatNum
	SELECT @RoomID = RoomID, @SeatNum = SeatNumber
	FROM inserted;

	SELECT @Capacity = Capacity
	FROM Rooms
	WHERE RoomID = @RoomID;

	-- Kiem tra seatnumber
	IF @SeatNum > @Capacity AND @SeatNum <= 0
	BEGIN
		RAISERROR('SeatNumber cannot be greater than the room capacity.', 16, 1)
		ROLLBACK TRANSACTION;
	END
END;


-- Tu dong  tao ticketID
CREATE TRIGGER GenerateTicketID
ON Ticket
INSTEAD OF INSERT
AS
BEGIN
	DECLARE @CinemaID INT,
			@TicketID VARCHAR(30),
			@SeatID VARCHAR(20),
			@MovieID INT,
			@PriceID INT,
			@ShowTimeID INT,
			@Sequence INT,
			@GUID VARCHAR(8);

	-- Khai bao con tro de duyet qua tung bang ghi
	DECLARE cur CURSOR FOR
	SELECT PriceID, SeatID, MovieID, ShowTimeID
	FROM inserted;

	OPEN cur;
	FETCH NEXT FROM cur INTO @PriceID, @SeatID, @MovieID, @ShowTimeID;

	WHILE @@FETCH_STATUS = 0
	BEGIN
		-- Lay CinemaID tu Seats thong qua Rooms
		SELECT @CinemaID = CinemaID --FROM TicketPrice WHERE PriceID = @PriceID;
		FROM Seats
		INNER JOIN Rooms ON Rooms.RoomID = Seats.RoomID 
		WHERE @SeatID = SeatID
		-- Tao ID
		SET @GUID = SUBSTRING(CONVERT(VARCHAR(36), NEWID()), 1, 8);
		SET @TicketID = CONCAT('TC', @CinemaID, 'M' , @MovieID, 'S', @ShowTimeID, '-', @GUID);

		-- Insert
		INSERT INTO Ticket(TicketID, PriceID, SeatID, MovieID, ShowTimeID)
		VALUES (@TicketID, @PriceID, @SeatID, @MovieID, @ShowTimeID);

		FETCH NEXT FROM cur INTO @PriceID, @SeatID, @MovieID, @ShowTimeID;

	END

	CLOSE cur;
	DEALLOCATE cur;
END;




-- Tu dong tao foodID
CREATE TRIGGER GenerateFoodID
ON FoodAndBeverages
INSTEAD OF INSERT
AS
BEGIN
	DECLARE @FoodID VARCHAR(30),
			@GUID VARCHAR(8), -- Lay 8 ky tu dau cua GUID
			@ProductName VARCHAR(255),
			@Price DECIMAL(10, 2),
			@Category VARCHAR(255),
			@CinemaID INT;
	
	DECLARE cur CURSOR FOR
	SELECT ProductName, CinemaID, Category, Price
	FROM inserted

	OPEN cur;
	FETCH NEXT FROM cur INTO @ProductName, @CinemaID, @Category, @Price;

	WHILE @@FETCH_STATUS = 0
	BEGIN
		SET @GUID = SUBSTRING(CONVERT(VARCHAR(36), NEWID()), 1, 8);
		SET @FoodID = CONCAT('FOOD-', @GUID);

		INSERT INTO FoodAndBeverages(FoodID, ProductName, CinemaID, Category, Price)
		VALUES (@FoodID, @ProductName, @CinemaID, @Category, @Price );

		FETCH NEXT FROM cur INTO @ProductName, @CinemaID, @Category, @Price;
		
	END
	CLOSE cur;
	DEALLOCATE cur;
END;

-- Tao RoomID
CREATE TRIGGER GenerateRoomID
ON Rooms
INSTEAD OF INSERT
AS
BEGIN
	DECLARE @CinemaID INT,
			@TotalScreens INT,
			@RoomID VARCHAR(10),
			@NewRoomID VARCHAR(10),
			@CurRoomCount INT;
	
	DECLARE cur CURSOR FOR
	SELECT CinemaID FROM inserted

	OPEN cur;
	FETCH NEXT FROM cur INTO @CinemaID

	WHILE @@FETCH_STATUS = 0
	BEGIN
		SELECT @TotalScreens = TotalScreens FROM Cinemas WHERE CinemaID = @CinemaID

		SELECT @CurRoomCount = COUNT(*) FROM Rooms WHERE CinemaID = @CinemaID
		PRINT 'Count: ' + CAST(@CurRoomCount as VARCHAR)

		-- Tao roomID
		DECLARE @i INT = 1;
		WHILE @i <= @TotalScreens
		BEGIN
			-- ID mau: CinemaID: 1, TotalScreens: 2
			-- --> RoomID: C1R1, C1R2
			SET @NewRoomID = @i + @CurRoomCount;
			SET @RoomID = CONCAT('C', @CinemaID, 'R', @NewRoomID);

			INSERT INTO Rooms(RoomID, CinemaID, Capacity)
			VALUES (@RoomID, @CinemaID, 100) -- cho suc chua mac dinh la 100

			SET @i += 1;
		END

		FETCH NEXT FROM cur INTO @CinemaID
	END
	CLOSE cur;
	DEALLOCATE cur;
END;



-- Tao SeatID
CREATE TRIGGER GenerateSeatID
ON Seats
INSTEAD OF INSERT
AS
BEGIN
	DECLARE @SeatID VARCHAR(20),
			@RoomID VARCHAR(10),
			@SeatNumber INT,
			@Row CHAR(1),
			@Type CHAR(1);

	DECLARE cur CURSOR FOR
	SELECT RoomID, SeatNumber, [Row], COALESCE([Type], 'S') AS [Type]
	-- Type: Single (S) / Double (D)
	-- Colaesce de kiem tra xem cai type co phai null ko neu ma co thi cho no la S(Single)
	FROM inserted

	OPEN cur
	FETCH NEXT FROM cur INTO @RoomID, @SeatNumber, @Row, @Type; 

	WHILE @@FETCH_STATUS = 0
	BEGIN
		-- SeatID: [RoomID][Row][SeatNum]
		-- Vd: RoomID: C1R1; Row: A; SeatNum: 1
		-- --> SeatID: C1R1A1
		SET @SeatID = CONCAT(@RoomID, @Row ,@SeatNumber)

		-- Insert
		-- Status: available: 1; not available: 0
		-- Type: Single: 0, Double: 1
		INSERT INTO Seats(SeatID, RoomID, SeatNumber, [Row], [Status], [Type])
		VALUES (@SeatID, @RoomID, @SeatNumber, @Row, 0, @Type)

		FETCH NEXT FROM cur INTO @RoomID, @SeatNumber, @Row, @Type;
	END
	CLOSE cur;
	DEALLOCATE cur;
END;



-- Trigger tu dong cap nhat PricePerUnit
CREATE TRIGGER SetPricePerUnit
ON DetailBooking
AFTER INSERT
AS
BEGIN
	-- Ticket
	UPDATE db
	SET db.PricePerUnit = tkp.BasePrice
	FROM DetailBooking db
	LEFT JOIN Ticket tk ON tk.TicketID = db.TicketID
	left join TicketPrice tkp ON tkp.PriceID = tk.PriceID
	JOIN inserted i ON i.DetailBookingID = db.DetailBookingID
	WHERE i.ProductType = 'Ticket';

	-- Food
	UPDATE db
	SET db.PricePerUnit = f.Price
	FROM DetailBooking db
	JOIN FoodAndBeverages f ON f.FoodID = db.FoodID
	JOIN inserted i ON i.DetailBookingID = db.DetailBookingID
	WHERE i.ProductType = 'Food';
END;

-- Set Ticket Quantity
CREATE TRIGGER SetTicketQuantity
ON DetailBooking
AFTER INSERT
AS
BEGIN
	UPDATE db
	SET db.Quantity = 1
	FROM DetailBooking db
	JOIN inserted i ON i.DetailBookingID = db.DetailBookingID
	WHERE i.ProductType = 'Ticket';

END;

-- Trigger tu  dong ktra va set DiscountID

CREATE TRIGGER SetDiscount
ON Transactions
AFTER INSERT
AS
BEGIN
	UPDATE t
	SET t.DiscountID = 'DISC00001'
	FROM Transactions t
	JOIN Customers c ON c.CustomerID = t.CustomerID
	JOIN inserted i ON i.TransactionID = t.TransactionID
	WHERE c.MembershipType = 'CVIP';

	UPDATE t
	SET t.DiscountID = 'DISC00002'
	FROM Transactions t
	JOIN Customers c ON c.CustomerID = t.CustomerID
	JOIN inserted i ON i.TransactionID = t.TransactionID
	WHERE c.MembershipType = 'CFRIEND';
END;
GO

-- Trigger tu dong cap nhat CustomerID dua vao BookingID cho Transactions
CREATE TRIGGER SetCustomer
ON Transactions
AFTER INSERT
AS
BEGIN
	UPDATE t
	SET t.CustomerID = b.CustomerID
	FROM Transactions t
	INNER JOIN Booking b ON t.BookingID = b.BookingID
	JOIN inserted i ON i.TransactionID = t.TransactionID
END;
GO


-- Calculate FinalAmount
ALTER PROCEDURE CalculateFinalAmount(@BookingID VARCHAR(30))
AS
BEGIN
	DECLARE @TicketID VARCHAR(30),
			@FoodID VARCHAR(30),
			@TicketPrice DECIMAL(10, 2) = 0,
			@FoodPrice DECIMAL(10, 2) = 0,
			@FinalAmount DECIMAL(10, 2),
			@FoodQuantity INT = 0,
			--@TicketQuantity INT = 0,
			@TotalFoodPrice DECIMAL(10, 2),

			@CustomerID VARCHAR(10),
			@MembershipType VARCHAR(50),
			@DiscountValue DECIMAL(10,2) = 0,
			@DiscountID VARCHAR(10),
			
			@BookingDate DATETIME,
			@Date VARCHAR(20),
			@CurHour INT;

	-- Lay CustomerID tu BookingID
	SELECT @CustomerID = CustomerID, @BookingDate = BookingDate
	FROM Booking
	WHERE BookingID = @BookingID;

	-- Lay MembershipType
	SELECT @MembershipType = MembershipType
	FROM Customers
	WHERE @CustomerID = CustomerID;

	-- Lay Discount Value
	SET @DiscountValue = dbo.GetDiscountValue(@CustomerID);

	-- Check ngay
	-- T2: ai cung giam (gia ve), ko ap dung giam gia cua membership
	-- T4: giam gia ve cua membership (45), giam gia tri bap nuoc theo discount value
	Set @CurHour = DATEPART(HOUR, @BookingDate);
	Set @Date = DATENAME(WEEKDAY, @BookingDate);

	-- Tao bang temp
	WITH Details AS (
		SELECT * 
		FROM DetailBooking db
		WHERE @BookingID = db.BookingID
	)
	--Lay ticket quantity va price
	SELECT
		--@TicketQuantity = MAX(CASE WHEN d.ProductType = 'Ticket' THEN d.Quantity ELSE 0 END),
		@TicketPrice = SUM (CASE WHEN d.ProductType = 'Ticket' THEN d.PricePerUnit END),
		@TotalFoodPrice = SUM(CASE WHEN d.ProductType = 'Food' THEN d.PricePerUnit * d.Quantity  END),
		@FoodQuantity = MAX(CASE WHEN d.ProductType = 'Food' THEN d.Quantity ELSE 0 END)
	FROM Details d;

	select * from Customers
	-- Dieu chinh gia ve
	IF (@CurHour < 10 OR @CurHour >= 22)
		SET @TicketPrice = 45000;
	ELSE IF (@Date = 'Monday')
		SET @TicketPrice = 45000;
	ELSE IF (@Date = 'Wednesday' AND (@MembershipType = 'CFRIEND' OR @MembershipType = 'CVIP'))
		BEGIN
			SET @TicketPrice = 45000;
			SET @TotalFoodPrice = @TotalFoodPrice * (1 - @DiscountValue)
		END
	-- Calculate Final Amount
	SET @FinalAmount = @TotalFoodPrice + @TicketPrice

	-- Lay discount ID
	SELECT @DiscountID = 
		CASE
			WHEN @MembershipType = 'CVIP' THEN 'DISC00001'
			WHEN @MembershipType = 'CFRIEND' THEN 'DISC00002'
			ELSE NULL
		END

	-- Update vao bang Transaction
	UPDATE Transactions
	SET FinalAmount = @FinalAmount, DiscountID = @DiscountID
	WHERE BookingID = @BookingID
	
	-- Update TransactionDate trong Booking
	UPDATE Booking
	SET TransactionDate = GETDATE()
	WHERE BookingID = @BookingID

END;


-- Lay ti le giam gia
CREATE FUNCTION GetDiscountValue(@CustomerID VARCHAR(10))
RETURNS DECIMAL(10, 2)
AS
BEGIN
	DECLARE @DiscountID VARCHAR(10),
			@DiscountValue DECIMAL(10, 2) = 0;

	-- Lay DiscountValue tu Discount dua tren MembershipType
	SELECT @DiscountID = 
		CASE
			WHEN MembershipType = 'CVIP' THEN 'DISC00001'
			WHEN MembershipType = 'CFRIEND' THEN 'DISC00002'
			ELSE NULL
		END
	FROM Customers
	WHERE CustomerID = @CustomerID;

	-- Neu co DiscountID thi lay value cua no
	IF @DiscountID IS NOT NULL
	BEGIN
		SELECT @DiscountValue = DiscountValue
		FROM Discounts
		WHERE DiscountID = @DiscountID
	END

	RETURN @DiscountValue;
END;


-- Trigger for insertion on Customers table
-- Phone format: 10 digits
-- CustomerID format: CUSTXXXXX
-- MembershipType: Regular/CFRIEND/CVIP
CREATE TRIGGER CheckCustomerInsertion ON Customers
AFTER INSERT, UPDATE
AS BEGIN
    IF EXISTS (SELECT 1 FROM inserted
    WHERE Phone NOT LIKE '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'
    OR CustomerID NOT LIKE 'C[0-9][0-9][0-9][0-9][0-9]'
    OR Gender NOT IN ('M', 'F')
    OR MembershipType NOT IN ('Regular', 'CFRIEND', 'CVIP'))
    BEGIN
        PRINT('Error! Insertion canceled!');
        ROLLBACK TRANSACTION;
    END
END;
GO

-- Trigger for insertion on Cinemas table
-- TotalScreen > 0
CREATE TRIGGER CheckCinemaInsertion ON Cinemas
AFTER INSERT, UPDATE
AS BEGIN
    IF EXISTS (SELECT 1 FROM inserted
    WHERE TotalScreens <= 0)
    BEGIN
        PRINT('Error! Insertion canceled!');
        ROLLBACK TRANSACTION;
    END
END;
GO

-- Trigger for insertion on Rooms table
-- Capacity > 0
CREATE TRIGGER CheckRoomInsertion ON Rooms
AFTER INSERT, UPDATE
AS BEGIN
    IF EXISTS (SELECT 1 FROM inserted
    WHERE Capacity <= 0)
    BEGIN
        PRINT('Error! Insertion canceled!');
        ROLLBACK TRANSACTION;
    END
END;
GO

-- Trigger for insertion on Seats table
-- Type: 0/1
CREATE TRIGGER CheckSeatInsertion ON Seats
AFTER INSERT, UPDATE
AS BEGIN
    IF EXISTS (SELECT 1 FROM inserted
    WHERE Type NOT IN ('0', '1'))
    BEGIN
        PRINT('Error! Insertion canceled!');
        ROLLBACK TRANSACTION;
    END
END;
GO

-- Trigger for insertion on TicketPrice table
-- BasePrice > 0
-- AgeGroup: 1/2
-- SeatType: 0/1 (based on Type(Seats))
CREATE TRIGGER CheckTicketPriceInsertion ON TicketPrice
AFTER INSERT, UPDATE
AS BEGIN
    IF EXISTS (SELECT 1 FROM inserted
    WHERE BasePrice <= 0
    OR AgeGroup NOT IN (1, 2)
    OR SeatType NOT IN (0, 1))
    BEGIN
        PRINT('Error! Insertion canceled!');
        ROLLBACK TRANSACTION;
    END
END;
GO

-- Trigger for insertion on FoodAndBeverages table
-- Price > 0
CREATE TRIGGER CheckFoodAndBeveragesInsertion ON FoodAndBeverages
AFTER INSERT, UPDATE
AS BEGIN
    IF EXISTS (SELECT 1 FROM inserted
    WHERE Price <= 0)
    BEGIN
        PRINT('Error! Insertion canceled!');
        ROLLBACK TRANSACTION;
    END
END;
GO

-- Trigger for insertion on DetailBooking table
-- Quantity > 0
-- ProductType: Ticket/Food
CREATE TRIGGER CheckDetailBookingInsertion ON DetailBooking
AFTER INSERT, UPDATE
AS BEGIN
    IF EXISTS (SELECT 1 FROM inserted
    WHERE Quantity <= 0
    OR ProductType NOT IN ('Ticket', 'Food'))
    BEGIN
        PRINT('Error! Insertion canceled!');
        ROLLBACK TRANSACTION;
    END
END;
GO

-- Trigger for insertion on Booking table
-- BookingID format: BOOKXXXXX
CREATE TRIGGER CheckBookingInsertion ON Booking
AFTER INSERT
AS BEGIN
    IF EXISTS (SELECT 1 FROM inserted
    WHERE BookingID NOT LIKE 'BOOK[0-9][0-9][0-9][0-9][0-9]')
    BEGIN
        PRINT('Error! Insertion canceled!');
        ROLLBACK TRANSACTION;
    END
END;
GO

-- Trigger for insertion on Movies table
-- Duration > 0
-- AgeRestriction: T18/T16/T13/K/P
CREATE TRIGGER CheckMovieInsertion ON Movies
AFTER INSERT, UPDATE
AS BEGIN
    IF EXISTS (SELECT 1 FROM inserted
    WHERE Duration <= 0
    OR AgeRestriction NOT IN ('T18', 'T16', 'T13', 'K', 'P'))
    BEGIN
        PRINT('Error! Insertion canceled!');
        ROLLBACK TRANSACTION;
    END
END;
GO

-- Trigger for insertion on Transactions table
-- TransactionID format: TRANSXXXXX
CREATE TRIGGER CheckTransactionInsertion ON Transactions
AFTER INSERT
AS BEGIN
    IF EXISTS (SELECT 1 FROM inserted
    WHERE TransactionID NOT LIKE 'TRANS[0-9][0-9][0-9][0-9][0-9]')
    BEGIN
        PRINT('Error! Insertion canceled!');
        ROLLBACK TRANSACTION;
    END
END;
GO

-- Trigger for insertion on Discounts table
-- DiscountID format: DISCXXXXX
-- DiscountValue > 0
CREATE TRIGGER CheckDiscountInsertion ON Discounts
AFTER INSERT, UPDATE
AS BEGIN
    IF EXISTS (SELECT 1 FROM inserted
    WHERE DiscountID NOT LIKE 'DISC[0-9][0-9][0-9][0-9][0-9]'
    OR DiscountValue <= 0)
    BEGIN
        PRINT('Error! Insertion canceled!');
        ROLLBACK TRANSACTION;
    END
END;
GO


-- ============ INSERT DATA ============ --
-- Food
INSERT INTO FoodAndBeverages (ProductName, Category, Price, CinemaID) VALUES
('Popcorn', 'Snack', 5.00, 1), -- CinemaID 1
('Soda', 'Drink', 3.00, 1),
('Candy', 'Snack', 2.50, 1),
('Nachos', 'Snack', 4.50, 2), -- CinemaID 2
('Water', 'Drink', 1.00, 2);

-- Cinema
INSERT INTO Cinemas (CinemaID, Name, Location, TotalScreens) VALUES
(1, 'Cinema One', 'Location A', 5),
(2, 'Cinema Two', 'Location B', 6);

-- Thêm phòng cho Cinema 
-- Rooms
INSERT INTO Rooms (CinemaID, Capacity) 
VALUES 
(1, 100),  -- Room 1
(2, 100);

-- Seats (S)
INSERT INTO Seats(RoomID, SeatNumber, [Row])
VALUES
('C1R1', 1, 'A'),
('C1R1', 2, 'A'),
('C1R1', 3, 'A'),
('C1R1', 4, 'A'),
('C1R1', 5, 'A'),
('C1R1', 6, 'A'),
('C1R1', 7, 'A'),
('C1R1', 8, 'A'),


('C1R2', 1, 'A'),
('C1R2', 2, 'A'),
('C1R2', 3, 'A'),
('C1R2', 4, 'A'),

('C1R2', 1, 'B'),
('C1R2', 2, 'B'),
('C1R2', 3, 'B'),
('C1R2', 4, 'B');

-- Seats (D)
INSERT INTO Seats(RoomID, SeatNumber, [Row], [Type])
VALUES 
('C1R2', 5, 'B', 'D'),
('C1R2', 6, 'B', 'D'),
('C1R2', 7, 'B', 'D'),
('C1R2', 8, 'B', 'D');	



INSERT INTO Seats(RoomID, SeatNumber, [Row])
VALUES
('C2R1', 1, 'A'),
('C2R1', 2, 'A'),
('C2R1', 3, 'A'),
('C2R1', 4, 'A'),
('C2R1', 5, 'A'),
('C2R1', 6, 'A'),
('C2R1', 7, 'A'),
('C2R1', 8, 'A'),

('C2R2', 1, 'A'),
('C2R2', 2, 'A'),
('C2R2', 3, 'A'),
('C2R2', 4, 'A'),

('C2R2', 1, 'B'),
('C2R2', 2, 'B'),
('C2R2', 3, 'B'),
('C2R2', 4, 'B');

-- Seats (D) - Cinema2
INSERT INTO Seats(RoomID, SeatNumber, [Row], [Type])
VALUES 
('C2R2', 5, 'B', 'D'),
('C2R2', 6, 'B', 'D'),
('C2R2', 7, 'B', 'D'),
('C2R2', 8, 'B', 'D');


--BasePrice:
-- AgeGroup: 1; SeatType: 0 --> BasePrice: 65000
-- AgeGroup: 2; SeatType: 0 --> BasePrice: 45000
-- AgeGroup: 1; SeatType: 1 --> BasePrice: 135000

-- SeatType: 0 - single; 1 - double
INSERT INTO TicketPrice(PriceID, CinemaID, BasePrice, AgeGroup, SeatType)
VALUES
(1, 1, 65000, 1, 0),
(2, 1, 45000, 2, 0),
(3, 1, 135000, 1, 1); 


-- ShowTimes
INSERT INTO ShowTimes (ShowTimeID, MovieID, StartTime)
VALUES 
(1, 1, '08:00:00'),
(2, 1, '11:00:00'),
(3, 1, '14:00:00'),
(4, 1, '17:00:00'),
(5, 1, '20:00:00'),
(6, 1, '23:00:00'),
(7, 2, '08:30:00'),
(8, 2, '11:30:00'),
(9, 2, '14:30:00'),
(10, 2, '17:30:00'),
(11, 2, '20:30:00'),
(12, 2, '23:30:00'),
(13, 3, '09:00:00'),
(14, 3, '12:00:00'),
(15, 3, '15:00:00'),
(16, 3, '18:00:00'),
(17, 3, '21:00:00'),
(18, 3, '24:00:00'),
(19, 4, '08:00:00'),
(20, 4, '11:00:00'),
(21, 4, '14:00:00'),
(22, 4, '17:00:00'),
(23, 4, '20:00:00'),
(24, 4, '23:00:00'),
(25, 5, '09:00:00'),
(26, 5, '12:00:00'),
(27, 5, '15:00:00'),
(28, 5, '18:00:00'),
(29, 5, '21:00:00'),
(30, 5, '24:00:00'),
(31, 6, '08:30:00'),
(32, 6, '11:30:00'),
(33, 6, '14:30:00'),
(34, 6, '17:30:00'),
(35, 6, '20:30:00'),
(36, 6, '23:30:00'),
(37, 7, '09:00:00'),
(38, 7, '12:00:00'),
(39, 7, '15:00:00'),
(40, 7, '18:00:00'),
(41, 7, '21:00:00'),
(42, 7, '24:00:00'),
(43, 8, '08:00:00'),
(44, 8, '11:00:00'),
(45, 8, '14:00:00'),
(46, 8, '17:00:00'),
(47, 8, '20:00:00'),
(48, 8, '23:00:00');


-- Ticket
INSERT INTO Ticket(PriceID, SeatID, MovieID, ShowTimeID)
VALUES
(1, 'C1R1A1', 1, 1),  -- PriceID 1, Seat C1R1A1, Movie Inception, ShowTime 08:00
(2, 'C1R1A2', 1, 1),  -- PriceID 2, Seat C1R1A2, Movie Inception, ShowTime 08:00
(3, 'C1R1A3', 1, 7);  -- PriceID 3, Seat C1R1A3, Movie Shawshank Redemption, ShowTime 08:30

INSERT INTO Ticket(PriceID, SeatID, MovieID, ShowTimeID)
VALUES
(1, 'C1R1A4', 1, 7), -- PriceID 1, Seat C1R1A4, Movie The Dark Knight, ShowTime 09:00
(2, 'C1R1A5', 4, 19), -- PriceID 2, Seat C1R1A5, Movie Pulp Fiction, ShowTime 08:00
(3, 'C1R1A6', 5, 25), -- PriceID 3, Seat C1R1A6, Movie Forrest Gump, ShowTime 09:00
(1, 'C1R1A7', 6, 31), -- PriceID 1, Seat C1R1A7, Movie The Matrix, ShowTime 08:30
(2, 'C1R1A8', 7, 37), -- PriceID 2, Seat C1R1A8, Movie Interstellar, ShowTime 09:00
(3, 'C1R2A1', 8, 43), -- PriceID 3, Seat C1R2A1, Movie Silence of the Lambs, ShowTime 08:00
(1, 'C1R2A2', 1, 3),  -- PriceID 1, Seat C1R2A2, Movie Inception, ShowTime 14:00
(2, 'C1R2A3', 2, 4),  -- PriceID 2, Seat C1R2A3, Movie Shawshank Redemption, ShowTime 17:00
(3, 'C1R2A4', 3, 5);  -- PriceID 3, Seat C1R2A4, Movie The Dark Knight, ShowTime 20:00

INSERT INTO Ticket(PriceID, SeatID, MovieID, ShowTimeID)
VALUES
(1, 'C2R1A1', 1, 1),  
(2, 'C2R1A2', 1, 1),  
(3, 'C2R1A3', 1, 7),
(1, 'C2R1A4', 1, 7), 
(2, 'C2R1A5', 4, 19), 
(3, 'C2R1A6', 5, 25);


-- =========== Movies =========== --
select * from Movies
-- Movies
INSERT INTO Movies (MovieID, Title, Duration, Subtitle, Director, [Description], [Language], ReleaseDate, TrailerURL, AgeRestriction, Genre)
VALUES 
(1, 'Inception', 148, 1, 'Christopher Nolan', 'A thief who steals corporate secrets through dream-sharing technology.', 'English', '2010-07-16', 'https://www.youtube.com/watch?v=YoHD9XEInc0', 'T13', 'Sci-Fi'),
(2, 'The Shawshank Redemption', 142, 0, 'Frank Darabont', 'Two imprisoned men bond over a number of years.', 'English', '1994-09-23', 'https://www.youtube.com/watch?v=6hB3S9bIaco', 'T18', 'Drama'),
(3, 'The Dark Knight', 152, 1, 'Christopher Nolan', 'The Joker emerges from his mysterious past.', 'English', '2008-07-18', 'https://www.youtube.com/watch?v=EXeTwQWrcwY', 'T13', 'Action'),
(4, 'Pulp Fiction', 154, 0, 'Quentin Tarantino', 'The lives of two mob hitmen, a boxer, a gangsters wife', 'English', '1994-10-14', 'https://www.youtube.com/watch?v=s7EdQ4FqBHs', 'T18', 'Crime'),
(5, 'Forrest Gump', 142, 0, 'Robert Zemeckis', 'The presidencies of Kennedy and Johnson, the Vietnam War, the Watergate scandal, and other historical events unfold through the perspective of an Alabama man.', 'English', '1994-07-06', 'https://www.youtube.com/watch?v=bLvqoHBptjg', 'T13', 'Drama'),
(6, 'The Matrix', 136, 1, 'The Wachowskis', 'A computer hacker learns about the true nature of his reality.', 'English', '1999-03-31', 'https://www.youtube.com/watch?v=vKQi0pVi908', 'T13', 'Sci-Fi'),
(7, 'Interstellar', 169, 1, 'Christopher Nolan', 'A team of explorers travel through a wormhole in space.', 'English', '2014-11-07', 'https://www.youtube.com/watch?v=zSWdZVtXT7E', 'T18', 'Adventure'),
(8, 'The Silence of the Lambs', 118, 0, 'Jonathan Demme', 'A young FBI cadet must confide in an incarcerated and manipulative killer to catch another serial killer.', 'English', '1991-02-14', 'https://www.youtube.com/watch?v=4Nf1_KhAs0Y', 'T18', 'Thriller');


-- ========== DETAIL BOOKING ========== --
INSERT INTO DetailBooking (DetailBookingID, BookingID, TicketID, ProductType)
VALUES (1, 'B00001', 'TC1M1S1-2EAB3A13', 'Ticket');

-- Insert for Food (without specifying PricePerUnit)
INSERT INTO DetailBooking (DetailBookingID, BookingID, FoodID, Quantity, ProductType)
VALUES (2, 'B00001', 'FOOD-25702CE0', 1, 'Food');


INSERT INTO DetailBooking (DetailBookingID, BookingID, FoodID, Quantity, ProductType)
VALUES (3, 'B00002', 'FOOD-25702CE0', 2, 'Food')

INSERT INTO DetailBooking (DetailBookingID, BookingID, TicketID, ProductType)
VALUES (4, 'B00003', 'TC1M1S1-B93F4D6D', 'Ticket')

INSERT INTO DetailBooking (DetailBookingID, BookingID, TicketID, ProductType)
VALUES (5, 'B00004', 'TC1M5S25-EB92AC39', 'Ticket');

INSERT INTO DetailBooking (DetailBookingID, BookingID, FoodID, Quantity, ProductType)
VALUES (6, 'B00004', 'FOOD-5C5F15A5', 3, 'Food');

INSERT INTO DetailBooking (DetailBookingID, BookingID, FoodID, Quantity, ProductType)
VALUES (7, 'B00004', 'FOOD-AD8D8F00', 1, 'Food');

INSERT INTO DetailBooking (DetailBookingID, BookingID, FoodID, Quantity, ProductType)
VALUES (8, 'B00004', 'FOOD-25702CE0', 3, 'Food');

INSERT INTO DetailBooking (DetailBookingID, BookingID, FoodID, Quantity, ProductType)
VALUES (9, 'B00006', 'FOOD-25702CE0', 2, 'Food');

INSERT INTO DetailBooking (DetailBookingID, BookingID, FoodID, Quantity, ProductType)
VALUES (10, 'B00007', 'FOOD-25702CE0', 3, 'Food');

INSERT INTO DetailBooking (DetailBookingID, BookingID, TicketID, ProductType)
VALUES (11, 'B00008', 'TC1M3S5-687D0BEA', 'Ticket');

INSERT INTO DetailBooking (DetailBookingID, BookingID, FoodID, Quantity, ProductType)
VALUES 
(12, 'B00008', 'FOOD-25702CE0', 2, 'Food'),
(13, 'B00009', 'FOOD-25702CE0', 4, 'Food');

INSERT INTO DetailBooking (DetailBookingID, BookingID, TicketID, ProductType)
VALUES (14, 'B00009', 'TC1M7S37-2FA21465', 'Ticket');


-- ========== Booking ========== --
INSERT INTO Booking(BookingID, CustomerID, TransactionDate)
VALUES
('B00001', 'C00001', NULL),
('B00002', 'C00002', NULL),
('B00003', 'C00003', NULL),
('B00004', 'C00004', NULL),
('B00005', 'C00005', NULL);

-- Test cac truong hop co ngay giam gia
INSERT INTO Booking(BookingID, CustomerID, TransactionDate, BookingDate)
VALUES
('B00006', 'C00005', NULL, '2024-10-28 20:20:41.683'),
('B00007', 'C00005', NULL, '2024-10-30 20:20:41.683'),
('B00008', 'C00005', NULL, '2024-10-30 20:20:41.683'),
('B00009', 'C00003', NULL, '2024-10-27 20:20:41.683');


-- ========== Customers ========== --
-- Thêm dữ liệu vào bảng Customers
INSERT INTO Customers (CustomerID, Username, FirstName, LastName, Gender, Phone, Email, City, Address, MembershipType)
VALUES 
('C00001', 'john_doe', 'John', 'Doe', 'M', '1234567890', 'john.doe@example.com', 'New York', '123 Main St', 'Regular'),
('C00002', 'jane_smith', 'Jane', 'Smith', 'F', '0987654321', 'jane.smith@example.com', 'Los Angeles', '456 Elm St', 'CFRIEND'),
('C00003', 'alice_johnson', 'Alice', 'Johnson', 'F', '2345678901', 'alice.johnson@example.com', 'Chicago', '789 Oak St', 'CVIP'),
('C00004', 'bob_brown', 'Bob', 'Brown', 'M', '3456789012', 'bob.brown@example.com', 'Houston', '321 Pine St', 'Regular'),
('C00005', 'charlie_wilson', 'Charlie', 'Wilson', 'M', '4567890123', 'charlie.wilson@example.com', 'Miami', '654 Cedar St', 'CFRIEND');

-- ========== Discounts ========== --
INSERT INTO Discounts (DiscountID, DiscountValue, [Description])
VALUES
('DISC00001', 0.15, 'For C''VIP'),
('DISC00002', 0.1, 'For C''FRIEND');

-- ========== Payment Methods ========== --
INSERT INTO PaymentMethods (PaymentMethodID, MethodName, [Description])
VALUES
(1, 'MBBank', 'ngan hang mb'),
(2, 'VCBank', 'vietcombank'),
(3, 'Momo', 'Vi Momo');


INSERT INTO Transactions(TransactionID, BookingID, PaymentMethodID)
VALUES
('TRANS00001', 'B00001', 1),
('TRANS00002', 'B00002', 1),
('TRANS00003', 'B00003', 1),
('TRANS00004', 'B00004', 1),
('TRANS00005', 'B00005', 1),
('TRANS00006', 'B00006', 1),
('TRANS00007', 'B00007', 1),
('TRANS00008', 'B00008', 1),
('TRANS00009', 'B00009', 1);

select * from Discounts
select * from DetailBooking
select * from Booking

EXEC CalculateFinalAmount @BookingID = 'B00001'
EXEC CalculateFinalAmount @BookingID = 'B00002'
EXEC CalculateFinalAmount @BookingID = 'B00004'
EXEC CalculateFinalAmount @BookingID = 'B00006'
EXEC CalculateFinalAmount @BookingID = 'B00007'
EXEC CalculateFinalAmount @BookingID = 'B00008'
EXEC CalculateFinalAmount @BookingID = 'B00009'

drop trigger if exists GenerateRoomID;
drop trigger if exists GenerateTicketID;
drop trigger if exists GenerateRoomID;
drop trigger if exists GenerateSeatID;
SELECT * FROM SYS.triggers;

select * from FoodAndBeverages
select * from Cinemas
select * from Rooms
select * from Seats
select * from TicketPrice
select * from Ticket
select * from Movies
select * from ShowTimes
select * from Booking
select * from Transactions
select * from Customers
select * from Discounts
select * from PaymentMethods
select * from DetailBooking





delete from FoodAndBeverages
delete from Cinemas
delete from Rooms
delete from Seats
delete from TicketPrice
delete from Ticket
delete from Movies
delete from ShowTimes
delete from Booking
delete from Transactions
delete from Customers
delete from Discounts
delete from PaymentMethods
delete from DetailBooking


drop procedure CalculateFinalAmount