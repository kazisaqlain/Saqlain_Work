use Ecommerce_Solution_Group19
CREATE FUNCTION fn_Calc_Total_Price(@OrdID INT,@PrdID INT)
RETURNS MONEY
AS
   BEGIN
      DECLARE @total MONEY =
         (SELECT SUM((Price_Per_Unit * Quantity)+Tax_Amount)
          FROM Orders.Order_Details
          WHERE Order_ID =@OrdID and Product_ID =@PrdID );
		
      SET @total = ISNULL(@total, 0);
      RETURN @total;
END

-- Add a computed column to the Orders.Order_Details

ALTER TABLE Orders.Order_Details
add Total_Price AS (dbo.fn_Calc_Total_Price(Order_ID,Product_ID));

select * from Orders.Order_Details





