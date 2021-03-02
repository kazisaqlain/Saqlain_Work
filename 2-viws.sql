use Ecommerce_Solution_Group19
create view Retail_Order_Report
as 
select c.Customer_ID,Customer_First_Name,Customer_Last_Name,m.Product_ID,o.Order_ID,Product_Description,i.Invoice_ID,Payment_Amount
from Customer.Customer_Base c
inner join Orders.Cart_Master m 
on c.Customer_ID = m.Customer_ID
inner join Orders.Order_Master o
on o.Customer_ID = m.Customer_ID
inner join Commodity.Commodity_Details d
on d.Product_ID = m.Product_ID
inner join Invoice.Invoice_Master i
on i.Order_ID = o.Order_ID
inner join Invoice.Payment_Master p
on p.Invoice_ID = i.Invoice_ID

select * from Retail_Order_Report


create view Pharmaceutical_Order_Report
as 
select c.Customer_ID,Customer_First_Name,Customer_Last_Name,o.Order_ID,l.Prescription_ID,h.Appointment_ID,r.Product_ID,Total_Price,Tax_Amount,r.Create_Date,r.Processing_Date
from Customer.Customer_Base c
inner join Orders.Order_Master o
on o.Customer_ID = c.Customer_ID
inner join Healthcare.Appointment_Details h
on h.Customer_ID = c.Customer_ID
inner join Healthcare.Prescription_Master l
on l.Customer_ID = c.Customer_ID
inner join Orders.Order_Details r
on r.Order_ID = r.Order_ID
inner join Commodity.Commodity_Master m
on m.Product_ID = r.Product_ID
where Product_Category = 'Pharmaceutical'


select * from Pharmaceutical_Order_Report




-------------Computed Column------------------

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



