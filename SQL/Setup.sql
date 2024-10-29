
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
	Director NVARCHAR(50),
	[Description] NVARCHAR(500),
	[Language] NVARCHAR(50),
	ReleaseDate DATETIME,
	TrailerURL VARCHAR(255),
	AgeRestriction VARCHAR(3),
	Genre NVARCHAR(50),
);

alter table Movies
alter column Genre nvarchar(50);


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




-- Trigger for insertion on Customers table
-- Phone format: 10 digits
-- CustomerID format: CXXXXX
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

-- Trigger for insertion on FoodAndBeverages table
CREATE TRIGGER CheckFoodID ON FoodAndBeverages
AFTER INSERT, UPDATE
AS BEGIN
    IF EXISTS (SELECT 1 FROM inserted
    WHERE FoodID NOT LIKE 'F[0-9][0-9][0-9][0-9][0-9]')
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
-- Type: D/S
drop trigger if exists CheckSeatInsertion
CREATE TRIGGER CheckSeatInsertion ON Seats
AFTER INSERT, UPDATE
AS BEGIN
    IF EXISTS (SELECT 1 FROM inserted
    WHERE Type NOT IN ('D', 'S'))
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
-- BookingID format: BXXXXX
CREATE TRIGGER CheckBookingInsertion ON Booking
AFTER INSERT
AS BEGIN
    IF EXISTS (SELECT 1 FROM inserted
    WHERE BookingID NOT LIKE 'B[0-9][0-9][0-9][0-9][0-9]')
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
GO

-- Tu dong  tao ticketID
/*
	TicketID: TC{CinemaID}M{MovieID}S{ShowTimeID}-{GUID}(8 ky tu dau)
	Lay cac thong tin can thiet, Check xem seat co dc dat hay ko thi moi tao TicketID
*/

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
			--@GUID VARCHAR(8),
			@SeatStatus BIT;

	-- Khai bao con tro de duyet qua tung bang ghi trong inserted
	DECLARE cur CURSOR FOR
	SELECT PriceID, SeatID, MovieID, ShowTimeID
	FROM inserted;

	OPEN cur;
	FETCH NEXT FROM cur INTO @PriceID, @SeatID, @MovieID, @ShowTimeID;

	WHILE @@FETCH_STATUS = 0
	BEGIN
		-- Lay CinemaID tu Seats thong qua Rooms, va lay seat status
		SELECT @SeatStatus = [Status], @CinemaID = r.CinemaID
		FROM Seats s
		INNER JOIN Rooms r ON r.RoomID = s.RoomID 
		WHERE s.SeatID = @SeatID;

		-- Kiem tra status cua seat
		IF @SeatStatus = 1
		BEGIN
			-- Neu ghe da dc dat (1)
			RAISERROR('Ghế đã được đặt, không thể tạo vé mới.', 16, 1);
			ROLLBACK TRANSACTION;
			RETURN;
		END

		-- Neu ghe trong thi tao ticket
		--SET @GUID = SUBSTRING(CONVERT(VARCHAR(36), NEWID()), 1, 8);
		SET @TicketID = CONCAT('TC', @CinemaID, 'M' , @MovieID, 'S', @ShowTimeID, '-', @SeatID);

		-- Insert
		INSERT INTO Ticket(TicketID, PriceID, SeatID, MovieID, ShowTimeID)
		VALUES (@TicketID, @PriceID, @SeatID, @MovieID, @ShowTimeID);

		-- Cap nhat status -> (1)
		UPDATE Seats
		SET [Status] = 1
		WHERE SeatID = @SeatID;

		-- Lay bang ghi tiep theo
		FETCH NEXT FROM cur INTO @PriceID, @SeatID, @MovieID, @ShowTimeID;

	END

	CLOSE cur;
	DEALLOCATE cur;
END;
GO





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
GO


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
	-- Colaesce de kiem tra xem cai type co phai null ko neu ma co thi gan gia tri la S(Single)
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
GO

-- Ktra sea, cap nhat khi ve dc dat
CREATE TRIGGER UpdateSeatStatus
ON Ticket
AFTER INSERT
AS
BEGIN
	DECLARE @SeatID VARCHAR(20);

	-- Lay seatID vua dc dat
	SELECT @SeatID = i.SeatID FROM inserted i

	-- Cap nhat status 
	UPDATE Seats
	SET [Status] = 1
	WHERE @SeatID = SeatID;

END;
GO


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
GO

-- Set Ticket Quantity
CREATE TRIGGER SetTicketQuantity
ON DetailBooking
AFTER INSERT
AS
BEGIN
	-- Dat so luong ticket la 1 cho cac record moi
	UPDATE db
	SET db.Quantity = 1
	FROM DetailBooking db
	JOIN inserted i ON i.DetailBookingID = db.DetailBookingID
	WHERE i.ProductType = 'Ticket';

END;
GO

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

	-- Cap nhat DiscountID la DISC
	UPDATE t
	SET t.DiscountID = 'DISC00002'
	FROM Transactions t
	JOIN Customers c ON c.CustomerID = t.CustomerID
	JOIN inserted i ON i.TransactionID = t.TransactionID
	WHERE c.MembershipType = 'CFRIEND';
END;
GO

-- Trigger tu dong cap nhat CustomerID thong qua BookingID cho Transactions
CREATE TRIGGER SetCustomer
ON Transactions
AFTER INSERT
AS
BEGIN
	-- Cap nhat CustomerID trong bang Transactions tu bang Booking
	UPDATE t
	SET t.CustomerID = b.CustomerID
	FROM Transactions t
	INNER JOIN Booking b ON t.BookingID = b.BookingID
	JOIN inserted i ON i.TransactionID = t.TransactionID
END;
GO

-- param: CustomerID
CREATE FUNCTION GetDiscountValue(@CustomerID VARCHAR(10))
RETURNS DECIMAL(10, 2)
AS
BEGIN
	DECLARE @DiscountID VARCHAR(10),
			@DiscountValue DECIMAL(10, 2) = 0;

	-- Lay DiscountValue dua tren MembershipType
	SELECT @DiscountID = 
		CASE
			WHEN MembershipType = 'CVIP' THEN 'DISC00001'
			WHEN MembershipType = 'CFRIEND' THEN 'DISC00002'
			ELSE NULL
		END
	FROM Customers
	WHERE CustomerID = @CustomerID;

	-- Neu co DiscountID thi lay value tuong ung
	IF @DiscountID IS NOT NULL
	BEGIN
		SELECT @DiscountValue = DiscountValue
		FROM Discounts
		WHERE DiscountID = @DiscountID
	END

	RETURN @DiscountValue;
END;
GO

-- Tinh toan FinalAmount dua tren BookingID
CREATE PROCEDURE CalculateFinalAmount(@BookingID VARCHAR(30))
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

	-- Ktra gio va ngay de dieu chinh gia ve
	-- T2: ai cung giam (gia ve), ko ap dung giam gia cua membership
	-- T4: giam gia ve cua membership (45), giam gia tri bap nuoc theo discount value
	Set @CurHour = DATEPART(HOUR, @BookingDate);
	Set @Date = DATENAME(WEEKDAY, @BookingDate);

	-- Tao bang tam thoi de lay chi tiet dat cho
	WITH Details AS (
		SELECT * 
		FROM DetailBooking db
		WHERE @BookingID = db.BookingID
	)
	--Lay ticket, food quantity va price
	SELECT
		@TicketPrice = COALESCE(SUM(CASE WHEN d.ProductType = 'Ticket' THEN d.PricePerUnit END), 0),
		@TotalFoodPrice = COALESCE(SUM(CASE WHEN d.ProductType = 'Food' THEN d.PricePerUnit * d.Quantity END), 0),
		@FoodQuantity = COALESCE(MAX(CASE WHEN d.ProductType = 'Food' THEN d.Quantity ELSE 0 END), 0)
	FROM Details d;



	-- Dieu chinh gia ve theo gio va ngay
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

	-- Lay discount ID de cap nhat cho Transactions
	SELECT @DiscountID = 
		CASE
			WHEN @MembershipType = 'CVIP' THEN 'DISC00001'
			WHEN @MembershipType = 'CFRIEND' THEN 'DISC00002'
			ELSE NULL
		END

	-- Cap nhat FinalAmount va DiscountID vao bang Transaction
	UPDATE Transactions
	SET FinalAmount = @FinalAmount, DiscountID = @DiscountID
	WHERE BookingID = @BookingID
	
	-- Update TransactionDate trong Booking
	UPDATE Booking
	SET TransactionDate = GETDATE()
	WHERE BookingID = @BookingID


    SELECT  
        @BookingID AS BookingID,
        @CustomerID AS CustomerID,
        @MembershipType AS MembershipType,
        @DiscountValue AS DiscountValue,
        @TicketPrice AS TicketPrice,
        @TotalFoodPrice AS TotalFoodPrice,
        @Date AS BookingDate,
        @CurHour AS CurrentHour,
        @FinalAmount AS FinalAmount,
        @DiscountID AS DiscountID,
        N'Thanh toán đã hoàn tất!' AS Message;  -- Thông báo
END;
GO

-- SELECTION
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
GO

-- DELETION
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
GO



-- Cinema
INSERT INTO Cinemas (CinemaID, Name, Location, TotalScreens) VALUES
(1, 'Cinestar DL', N'Đà Lạt', 5),
(2, 'Cinestar BD', N'Bình Dương', 4);
GO

-- Food
INSERT INTO FoodAndBeverages (FoodID, ProductName, Category, Price, CinemaID) VALUES
('F00001', N'Combo Party', 'Combo', 210000, 1),
('F00002', N'Combo Solo', 'Combo', 94000, 1),
('F00003', N'Combo Couple', 'Combo', 115000, 1),
('F00004', N'Combo Nha Gau', 'Combo2', 259000, 1),
('F00005', N'Combo Gau', 'Combo2', 119000, 1),
('F00006', N'Combo Co Gau', 'Combo2', 129000, 1),
('F00007', N'Nuoc cam Teppy 327ml', 'Drink', 28000, 1),
('F00008', N'Nuoc suoi Dasani', 'Drink', 20000, 1),
('F00009', N'Nuoc trai cay Nutriboost 297ml', 'Drink', 28000, 1),
('F00010', N'Fanta 32oz', 'Drink', 37000, 1),
('F00011', N'Coke Zero 32oz', 'Drink', 37000, 1),
('F00012', N'Coke 32oz', 'Drink', 37000, 1),
('F00013', N'Sprite 32oz', 'Drink', 37000, 1),
('F00014', N'Snack Thai', 'Snack', 25000, 1),
('F00015', N'Khoai Tay Lay''s Stax 100g', 'Poca', 59000, 1),
('F00016', N'Poca Khoai Tay 54gr', 'Poca', 28000, 1),
('F00017', N'Poca Wavy 54gr', 'Poca', 28000, 1);
GO



-- Thêm phòng cho Cinema 
-- Rooms
INSERT INTO Rooms (CinemaID, Capacity) 
VALUES 
(1, 100),  -- Room 1
(2, 100);
GO

-- Seats (S)
INSERT INTO Seats(RoomID, SeatNumber, [Row])
VALUES
-- CinemaID: 1 Room: 1
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
GO

-- Seats (D)
INSERT INTO Seats(RoomID, SeatNumber, [Row], [Type])
VALUES 
('C1R2', 5, 'B', 'D'),
('C1R2', 6, 'B', 'D'),
('C1R2', 7, 'B', 'D'),
('C1R2', 8, 'B', 'D');
GO

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
GO

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
GO

INSERT INTO Movies (MovieID, Title, Duration, Subtitle, Director, [Description], [Language], ReleaseDate, TrailerURL, AgeRestriction, Genre)
VALUES 
(1, N'KÈO CUỐI ', 109, 1, 'Kelly Marcel', N'Tom Hardy sẽ tái xuất trong bom tấn Venom: The Last Dance và phải đối mặt với toàn bộ chủng tộc Symbiote', 'Other', '2024-09-25', 'https://youtu.be/6yCMRxGI4RA', 'T13', N'Hành Động'),
(2, N'NGÀY XƯA CÓ MỘT CHUYỆN TÌNH', 135, 1, N'Trịnh Đình Lê Minh' ,N'Ngày Xưa Có Một Chuyện Tình xoay quanh câu chuyện tình bạn, tình yêu giữa hai chàng trai và một cô gái từ thuở ấu thơ ...', 'VietNam', '2024-01-10', 'https://youtu.be/4Y2q2tx1Ee8', 'T16', N'Tình Cảm'),
(3, N'CÔ DÂU HÀO MÔN', 114, 1, N'Vũ Ngọc Đãng', N'Bộ phim xoay quanh câu chuyện làm dâu nhà hào môn dưới góc nhìn hài hước và châm biếm, hé lộ những câu chuyện kén dâu chọn rể trong giới thượng lưu...', 'VietNam', '2024-10-18', 'https://youtu.be/OP5X4Bp-g78', 'T18', N'Tâm Lý'),
(4, N'VÂY HÃM TẠI ĐÀI BẮC', 100, 1, N'George Huang', N'Theo chân John Lawlor là một đặc vụ DEA cừ khôi bất khả chiến bại, anh sẽ không tiếc hi sinh bất cứ điều gì để hoàn thành nhiệm vụ được giao.Trong khi đó, Joey Kwang là "người vận chuyển" hàng đầu ở Đài Bắc..', 'Other', '2024-01-11', NULL, 'T18', N'Hồi Hộp'),
(5, N'ELLI VÀ BÍ ẨN CHIẾC TÀU MA', 86, 1, N'Piet De Rycker', N'Một hồn ma nhỏ vô gia cư gõ cửa nhà những cư dân lập dị của Chuyến tàu ma để tìm kiếm một nơi thuộc về, cô bé vô tình thu hút sự chú ý từ "thế giới bên ngoài", ...', 'Other', '2024-10-25', 'https://youtu.be/j_rApVdDV-E', 'P', N'Hoạt hình'),
(6, N'TIẾNG GỌI CỦA OÁN HỒN', 108, 1, N'Takashi Shimizu', N'Năm 1992, một cô gái rơi từ mái của trường trung học cơ sở. Bên cạnh thi thể của cô ấy là một máy ghi âm cassette vẫn đang ghi lại...', 'Other', '2024-01-11', 'https://youtu.be/fBubjidz0vw', 'T18', N'Kinh Dị'),
(7, N'VÙNG ĐẤT BỊ NGUYỀN RỦA', 117, 1, N'Panu Aree', N'Sau cái chết của vợ, để trốn tránh quá khứ, Mit và cô con gái May chuyển đến một ngôi nhà mới ở khu phố ngoại ô. Trong lúc chuẩn bị xây dựng một miếu thờ thiên trước nhà mới,...', 'Other', '2024-01-11', 'https://youtu.be/4X-hI7qCJ98', 'T18', N'Kinh Dị'),
(8, N'QUỶ ĂN TẠNG 2', 120, 1, N'Taweewat Wantha', 'Khi họ đuổi theo linh hồn mặc áo choàng đen, tiếng kêu đầy ám ảnh của Tee Yod sắp quay trở lại một lần nữa...', 'Other', '2024-10-18', 'https://youtu.be/3ghi6ffcfAI', 'T18', N'Kinh Dị');
GO

INSERT INTO Ticket(PriceID, SeatID, MovieID, ShowTimeID)
VALUES
(1, 'C1R1A1', 1, 1), 
(2, 'C1R1A2', 1, 1),  
(3, 'C1R1A3', 1, 7),
(1, 'C1R1A4', 1, 7), 
(2, 'C1R1A5', 4, 19), 
(3, 'C1R1A6', 5, 25), 
(1, 'C1R1A7', 6, 31), 
(2, 'C1R1A8', 7, 37), 
(3, 'C1R2A1', 8, 43), 
(1, 'C1R2A2', 1, 3),  
(2, 'C1R2A3', 2, 4), 
(3, 'C1R2A4', 3, 5); 
GO

-- Discounts
INSERT INTO Discounts (DiscountID, DiscountValue, [Description])
VALUES
('DISC00001', 0.15, 'For C''VIP'),
('DISC00002', 0.1, 'For C''FRIEND');
GO

-- insert data for PaymentMethods table
INSERT INTO PaymentMethods (PaymentMethodID, MethodName, Description)
VALUES 
(1, 'Credit Card', 'Payments made via major credit cards like Visa, MasterCard, and American Express'),
(2, 'Debit Card', 'Payments made directly from a bank account using a debit card'),
(3, 'MoMo', 'Online payments made through MoMo'),
(4, 'Bank Transfer', 'Direct transfer of funds from bank account to bank account'),
(5, 'Cash', 'Payments made with physical cash'),
(6, 'Mobile Payment', 'Payments made via mobile wallets such as Apple Pay or Google Wallet');
GO

-- Booking
INSERT INTO Booking(BookingID, CustomerID, TransactionDate)
VALUES
('B00001', 'C00001', NULL),
('B00002', 'C00002', NULL),
('B00003', 'C00003', NULL),
('B00004', 'C00004', NULL),
('B00005', 'C00005', NULL);
GO

INSERT INTO Booking(BookingID, CustomerID, TransactionDate, BookingDate)
VALUES
('B00006', 'C00005', NULL, '2024-10-30 20:20:41.683'),
('B00007', 'C00003', NULL, '2024-10-27 20:20:41.683'),
('B00008', 'C00002', NULL, '2024-10-27 20:20:42.683'),
('B00009', 'C00003', NULL, '2024-10-26 23:20:21.243');
GO

-- Customer
INSERT INTO Customers (CustomerID, Username, FirstName, LastName, Gender, Phone, Email, City, Address, MembershipType)
VALUES 
('C00001', 'thang_pham12', N'Thắng', N'Phạm', 'M', '0956344676', 'thangtruongvo@gmail.com', N'Lâm Đồng', N'45 Võ Thị Sáu', 'Regular'),
('C00002', 'nghi_mint', N'Nghi', N'Võ', 'F', '0987654321', 'bichnghi1302@gmail.com', N'Cần Thơ', N'403/12 Phạm Văn Đồng', 'CFRIEND'),
('C00003', 'alice_truong', N'Vy', N'Trương', 'F', '0919199453', 'mendytruongcvl@gmail.com', N'Sóc Trăng', N'03/4/6 Ngô Hữu Hạnh', 'CVIP'),
('C00004', 'phamtan', N'Tân', N'Phạm', 'M', '0656664592', 'pnnhuttan2005@gmail.com', N'Bình Dương', N'321 Ngô Quyền', 'Regular'),
('C00005', 'jennykim', N'Kim', N'Thiên', 'F', '0456789012', 'thienkimpham32@gmail.com', N'Bạc Liêu', N'65/4 Hai Bà Trưng', 'CFRIEND'); 
GO

-- DetailBooking
select * from DetailBooking
select * from Ticket
delete from DetailBooking
INSERT INTO DetailBooking (DetailBookingID, BookingID, TicketID, ProductType)
VALUES 
(1, 'B00001', 'TC1M1S1-C1R1A1', 'Ticket'),
(3, 'B00002', 'TC1M1S1-C1R1A2', 'Ticket'),
(6, 'B00003', 'TC1M1S3-C1R2A2', 'Ticket'),
(10, 'B00005', 'TC1M1S7-C1R1A3', 'Ticket'),
(11, 'B00006', 'TC1M1S7-C1R1A4', 'Ticket'),
(14, 'B00008', 'TC1M3S5-C1R2A4', 'Ticket'),
(15, 'B00009', 'TC1M6S31-C1R1A7', 'Ticket');

GO

INSERT INTO DetailBooking (DetailBookingID, BookingID, FoodID, Quantity, ProductType)
VALUES 
(2, 'B00001', 'F00001', 2, 'Food'),
(4, 'B00002', 'F00002', 4, 'Food'),
(5, 'B00002', 'F00003', 3, 'Food'),
(7, 'B00003', 'F00005', 2, 'Food'),
(8, 'B00004', 'F00001', 2, 'Food'),
(9, 'B00004', 'F00004', 1, 'Food'),
(12, 'B00006', 'F00006', 1, 'Food'),
(13, 'B00007', 'F00010', 2, 'Food');
GO

-- Transaction
INSERT INTO Transactions(TransactionID, BookingID, PaymentMethodID)
VALUES
('TRANS00001', 'B00001', 1),
('TRANS00002', 'B00002', 2),
('TRANS00003', 'B00003', 3),
('TRANS00004', 'B00004', 4),
('TRANS00005', 'B00005', 1),
('TRANS00006', 'B00006', 3),
('TRANS00007', 'B00007', 5),
('TRANS00008', 'B00008', 6),
('TRANS00009', 'B00009', 3);
GO



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
GO


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
GO


EXEC CalculateFinalAmount @BookingID = 'B00001'
EXEC CalculateFinalAmount @BookingID = 'B00002'
EXEC CalculateFinalAmount @BookingID = 'B00003'
EXEC CalculateFinalAmount @BookingID = 'B00004'
EXEC CalculateFinalAmount @BookingID = 'B00005'
EXEC CalculateFinalAmount @BookingID = 'B00006'
EXEC CalculateFinalAmount @BookingID = 'B00007'
GO

delete from Transactions

select * from sys.triggers
