--Query 1:
-- Show the list of transaction history of customer with phone number '0987654321'
-- Display: customerID, customerName (firstname + lastname), transactionID, bookingID, FinalAmount, PaymentMethodID
SELECT c.CustomerID, CONCAT(c.FirstName, ' ', c.LastName) AS CustomerName, 
   b.BookingID, t.FinalAmount, t.PaymentMethodID FROM Customers c
JOIN Booking b ON c.CustomerID = b.CustomerID
LEFT JOIN Transactions t ON b.BookingID = t.BookingID
WHERE c.Phone = '0956344676';


--Query 2:
-- Find the movie that a customer watched the most in October
-- Display: MovieID, Title, Duration, Genre, amount of views
SELECT TOP 1 WITH TIES m.MovieID, m.Title, m.Duration, m.Genre, COUNT(b.BookingID) AS AmountOfViews
FROM  Movies m
JOIN ShowTimes st ON m.MovieID = st.MovieID
JOIN Ticket t ON st.ShowTimeID = t.ShowTimeID
JOIN DetailBooking db ON t.TicketID = db.TicketID
JOIN Booking b ON db.BookingID = b.BookingID
WHERE MONTH(b.BookingDate) = 10
GROUP BY m.MovieID, m.Title, m.Duration, m.Genre
ORDER BY AmountOfViews DESC;


-- Query 3:
-- Show the list of booking details that have not yet been paid for
-- Display: BookingID, booking date, customerName (firstname + lastname), PhoneNumber
SELECT b.BookingID, b.BookingDate, CONCAT(c.FirstName, ' ', c.LastName) AS CustomerName, c.Phone AS PhoneNumber
FROM Booking b
JOIN Customers c ON b.CustomerID = c.CustomerID
LEFT JOIN Transactions t ON b.BookingID = t.BookingID
WHERE b.TransactionDate IS NULL;  -- No transaction date means unpaid


-- Query 4:
-- List all showtimes for movie 'KÈO CUỐI'
-- Display: MovieName, ShowtimeID, StartTime
SELECT m.Title AS MovieName, st.ShowTimeID, st.StartTime
FROM Movies m
JOIN ShowTimes st ON m.MovieID = st.MovieID
WHERE m.Title = N'KÈO CUỐI';


-- Query 5:
-- Display food information with the most purchases of customers who do not register for membership (regular type)
-- Display: FoodID, ProductName, Category, Price, amount of purchases
SELECT TOP 1 WITH TIES fb.FoodID, fb.ProductName, fb.Category, fb.Price, COUNT(db.FoodID) AS AmountOfPurchases
FROM FoodAndBeverages fb
JOIN DetailBooking db ON fb.FoodID = db.FoodID
JOIN Booking b ON db.BookingID = b.BookingID
JOIN Customers c ON b.CustomerID = c.CustomerID
WHERE c.MembershipType = 'Regular'
GROUP BY fb.FoodID, fb.ProductName, fb.Category, fb.Price
ORDER BY AmountOfPurchases DESC;


-- Query 6:
-- Show total amount of revenue of each month
-- Display: Year, Month, TotalRevenue
SELECT YEAR(b.BookingDate) AS [Year], MONTH(b.BookingDate) AS [Month], SUM(t.FinalAmount) AS TotalRevenue
FROM Booking b
JOIN Transactions AS t ON b.BookingID = t.BookingID
GROUP BY YEAR(b.BookingDate), MONTH(b.BookingDate)
ORDER BY [Year], [Month];


-- Query 7:
-- List the details of all tickets sold for movies that are rated with "T18" age restriction
SELECT t.TicketID, t.PriceID, t.SeatID, t.MovieID, t.ShowTimeID, m.Title, m.AgeRestriction
FROM Ticket t
JOIN Movies AS m ON t.MovieID = m.MovieID
WHERE m.AgeRestriction = 'T18';


-- Query 8:
-- List all the information of foodandBeverages which are bought by the CFRIEND customer
SELECT DISTINCT fb.* FROM FoodAndBeverages fb
JOIN DetailBooking db ON fb.FoodID = db.FoodID
JOIN Booking b ON db.BookingID = b.BookingID
JOIN Customers c ON b.CustomerID = c.CustomerID
WHERE c.MembershipType = 'CFRIEND';
