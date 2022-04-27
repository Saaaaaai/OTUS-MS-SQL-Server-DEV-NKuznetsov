/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "10 - Операторы изменения данных".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0
Нужен WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- Задание - написать выборки для получения указанных ниже данных.
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Довставлять в базу пять записей используя insert в таблицу Customers или Suppliers 
*/

select * from Sales.Customers;
select * from Purchasing.Suppliers;

insert into sales.Customers 
(CustomerName, BillToCustomerID, CustomerCategoryID, BuyingGroupID, PrimaryContactPersonID, AlternateContactPersonID,
DeliveryCityID, PostalCityID, CreditLimit, AccountOpenedDate, StandardDiscountPercentage, IsStatementSent, IsOnCreditHold,
PaymentDays, PhoneNumber, FaxNumber, DeliveryRun, RunPosition, WebsiteURL, DeliveryAddressLine1, DeliveryAddressLine2,
DeliveryPostalCode, DeliveryLocation, PostalAddressLine1, PostalAddressLine2, PostalPostalCode, LastEditedBy, DeliveryMethodID)
select top 5
CustomerName+' NEW', BillToCustomerID, CustomerCategoryID, BuyingGroupID, PrimaryContactPersonID, AlternateContactPersonID,
DeliveryCityID, PostalCityID, CreditLimit, AccountOpenedDate, StandardDiscountPercentage, IsStatementSent, IsOnCreditHold,
PaymentDays, PhoneNumber, FaxNumber, DeliveryRun, RunPosition, WebsiteURL, DeliveryAddressLine1, DeliveryAddressLine2,
DeliveryPostalCode, DeliveryLocation, PostalAddressLine1, PostalAddressLine2, PostalPostalCode, LastEditedBy, DeliveryMethodID
from sales.Customers;

/*
2. Удалите одну запись из Customers, которая была вами добавлена
*/

delete from Sales.Customers
where CustomerID = (select top 1 customerID
					from Sales.Customers
					order by CustomerID desc)



/*
3. Изменить одну запись, из добавленных через UPDATE
*/

update sales.Customers
set
CustomerName = 'NEW Customer'
where
CustomerID = (select top 1 CustomerID
			  from Sales.Customers
			  order by CustomerID desc)

/*
4. Написать MERGE, который вставит вставит запись в клиенты, если ее там нет, и изменит если она уже есть
*/

MERGE sales.customers as TARGET
using (
select top 5
customerID + 10000, CustomerName+' NEW MERGE', BillToCustomerID, CustomerCategoryID, BuyingGroupID, PrimaryContactPersonID, AlternateContactPersonID,
DeliveryCityID, PostalCityID, CreditLimit, AccountOpenedDate, StandardDiscountPercentage, IsStatementSent, IsOnCreditHold,
PaymentDays, PhoneNumber, FaxNumber, DeliveryRun, RunPosition, WebsiteURL, DeliveryAddressLine1, DeliveryAddressLine2,
DeliveryPostalCode, DeliveryLocation, PostalAddressLine1, PostalAddressLine2, PostalPostalCode, LastEditedBy, DeliveryMethodID
from sales.Customers)
AS SOURCE (customerID,CustomerName, BillToCustomerID, CustomerCategoryID, BuyingGroupID, PrimaryContactPersonID, AlternateContactPersonID,
DeliveryCityID, PostalCityID, CreditLimit, AccountOpenedDate, StandardDiscountPercentage, IsStatementSent, IsOnCreditHold,
PaymentDays, PhoneNumber, FaxNumber, DeliveryRun, RunPosition, WebsiteURL, DeliveryAddressLine1, DeliveryAddressLine2,
DeliveryPostalCode, DeliveryLocation, PostalAddressLine1, PostalAddressLine2, PostalPostalCode, LastEditedBy, DeliveryMethodID)
ON (target.customerid = source.customerid)
when matched
	then update set customerName = target.CustomerName + 'Updated MERGE'
when not matched
	then insert (CustomerName, BillToCustomerID, CustomerCategoryID, BuyingGroupID, PrimaryContactPersonID, AlternateContactPersonID,
DeliveryCityID, PostalCityID, CreditLimit, AccountOpenedDate, StandardDiscountPercentage, IsStatementSent, IsOnCreditHold,
PaymentDays, PhoneNumber, FaxNumber, DeliveryRun, RunPosition, WebsiteURL, DeliveryAddressLine1, DeliveryAddressLine2,
DeliveryPostalCode, DeliveryLocation, PostalAddressLine1, PostalAddressLine2, PostalPostalCode, LastEditedBy, DeliveryMethodID)
	values (source.CustomerName, source.BillToCustomerID, source.CustomerCategoryID, source.BuyingGroupID, 
	source.PrimaryContactPersonID, source.AlternateContactPersonID, source.DeliveryCityID, 
	source.PostalCityID, source.CreditLimit, source.AccountOpenedDate, source.StandardDiscountPercentage, 
	source.IsStatementSent, source.IsOnCreditHold, source.PaymentDays, source.PhoneNumber, source.FaxNumber, 
	source.DeliveryRun, source.RunPosition, source.WebsiteURL, source.DeliveryAddressLine1, source.DeliveryAddressLine2,
	source.DeliveryPostalCode, source.DeliveryLocation, source.PostalAddressLine1, source.PostalAddressLine2, 
	source.PostalPostalCode, source.LastEditedBy, source.DeliveryMethodID)
output inserted.*, $action;


/*
5. Напишите запрос, который выгрузит данные через bcp out и загрузить через bulk insert
*/

select @@SERVERNAME

exec sp_configure 'show advanced options', 1;
go

reconfigure;
go

exec sp_configure 'xp_cmdshell',1;
go

reconfigure;
go

exec..xp_cmdshell 'bcp "[WideWorldImporters].Sales.Customers" out "D:\bcp.txt" -T -w -t";" -S DESKTOP-6182RB5\SQL2017';


select * into new_bulk_tab from Sales.Customers
where 1=2;

select * from new_bulk_tab;

BULK INSERT [new_bulk_tab]
			from "D:\bcp.txt"
			with
			(
				BATCHSIZE = 1000, 
				DATAFILETYPE = 'widechar',
				FIELDTERMINATOR = ';',
				ROWTERMINATOR ='\n',
				KEEPNULLS,
				TABLOCK    
			);

select * from new_bulk_tab;




