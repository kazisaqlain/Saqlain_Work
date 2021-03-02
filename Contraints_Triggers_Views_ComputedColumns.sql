
/*Customer will give the details while he registers and Create Date and Processing Date will be updated with the Current Timestamp.
  Whenever the customer updates his details, the Processing_Date will be automatically update with the Current Timestamp*/

 CREATE TRIGGER  Customer.Update_Date
ON Customer.Customer_Base
after INSERT, UPDATE 
AS
BEGIN
   UPDATE Customer.Customer_Base
    set  Processing_Date = CURRENT_TIMESTAMP
       FROM Customer.Customer_Base cb 
       FULL  JOIN  Inserted i ON cb.Customer_ID = i.Customer_ID  
       FULL JOIN Deleted d ON cb.Customer_ID = d.Customer_ID  
       where ((cb.Customer_ID = i.Customer_ID  or cb.Customer_ID = d.Customer_ID) 
		and (i.Customer_ID IN (select Customer_ID from Deleted d))
   UPDATE Customer.Customer_Base
    set  Processing_Date = CURRENT_TIMESTAMP,Create_Date = CURRENT_TIMESTAMP
       FROM Customer.Customer_Base cb 
       FULL  JOIN  Inserted i ON cb.Customer_ID = i.Customer_ID  
       FULL JOIN Deleted d ON cb.Customer_ID = d.Customer_ID  
        where ((cb.Customer_ID = i.Customer_ID  or cb.Customer_ID = d.Customer_ID)
		and i.Customer_ID NOT IN (select Customer_ID from Deleted d))
END;


/*The below trigger is based on Customer_Base table. Whenever customer  withdraws from the business, it will automatically delete
  the corresponding customer address and card details from Customer_Address and Customer_Card_Details respectively*/


CREATE TRIGGER Address_Card_Delete
       ON Customer.Customer_Base
	   AFTER DELETE
AS
BEGIN
     DELETE CD
	 FROM Customer.Customer_Card_Detail CD
	 FULL JOIN Inserted i ON CD.Customer_ID = i.Customer_ID
	 FULL JOIN Deleted d ON CD.Customer_ID = d.Customer_ID
	 WHERE CD.Customer_ID IN (Select d.Customer_ID FROM Deleted d) AND 
	       CD.Customer_ID NOT IN (Select i.Customer_ID FROM Inserted i) AND
		   (CD.Customer_ID = i.Customer_ID or CD.Customer_ID = d.Customer_ID)  
     
	 DELETE AD
	 FROM Customer.Customer_Address AD
	 FULL JOIN Inserted i ON AD.Customer_ID = i.Customer_ID
	 FULL JOIN Deleted d ON AD.Customer_ID = d.Customer_ID
	 WHERE AD.Customer_ID IN (Select d.Customer_ID FROM Deleted d) AND 
	       AD.Customer_ID NOT IN (Select i.Customer_ID FROM Inserted i) AND
		   (AD.Customer_ID = i.Customer_ID or AD.Customer_ID = d.Customer_ID)  

END;




/*Whenever the Invoice_Status will be updated in the Invoice_Master table, This trigger will automatically update the 
 Invoice_Status of the order in Order_Details*/


CREATE TRIGGER  Invoice_Status_Update
ON Invoice.Invoice_Master
after  UPDATE
AS
BEGIN
UPDATE Orders.Order_Details
set Invoice_Status  = (select Invoice_Status from Invoice.Invoice_Master im where Order_ID = od.Order_ID)
FROM Orders.Order_Details od  
  FULL  JOIN  Inserted i ON od.Order_ID = i.Order_ID   
  FULL JOIN Deleted d ON od.Order_ID = d.Order_ID    
  where (od.Order_ID = d.Order_ID or od.Order_ID = i.Order_ID)
END;


/*The below function is created for the table check constriant. The scenario is for any Pharmaceutical Order then there must be 
 Prescription ID as mandatory. We check if the order consistes any Pharma order and will not be shipped if there is no prescription Available*/

DROP Function CheckPrescription
Create function CheckPrescription(@OrderID int)
RETURNS smallint
AS
  BEGIN	
     DECLARE @Flag smallint = 0;
	 Declare @ProductID int;
	 Declare @Prescription  int =  0;
	 Select  @Prescription = Prescription_ID from Orders.Order_Master om INNER JOIN Orders.Order_Details od ON om.Order_ID = od.Order_ID
	  where om.Order_ID = @OrderID and 
	   od.Product_ID  IN (Select Product_ID from Commodity.Commodity_Master where Product_Category = 'pharmaceutical');
	 
	 IF @Prescription is null SET @Flag = 1;
	 Return @Flag;
  END;



 ALTER Table Shipment.Order_Shipment_Master
ADD CONSTRAINT  PrescriptionCheck CHECK (dbo.CheckPrescription(Order_ID) = 0) 



/*The below view will generate the retail order report of every customer*/


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


/*The below view will generate the Pharma order report of every customer*/

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
/*The below function is to calculate total price of particular order id and product id generated under Total_Price of 
  Order_Details table*/

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






