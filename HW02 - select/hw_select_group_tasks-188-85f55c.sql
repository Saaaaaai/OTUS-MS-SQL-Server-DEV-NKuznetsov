/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.
Занятие "02 - Оператор SELECT и простые фильтры, GROUP BY, HAVING".

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
1. Все товары, в названии которых есть "urgent" или название начинается с "Animal".
Вывести: ИД товара (StockItemID), наименование товара (StockItemName).
Таблицы: Warehouse.StockItems.
*/

TODO: 
select StockItemID, StockItemName
from Warehouse.StockItems
where
StockItemName like '%urgent%'
or StockItemName like 'Animal%';

/*
2. Поставщиков (Suppliers), у которых не было сделано ни одного заказа (PurchaseOrders).
Сделать через JOIN, с подзапросом задание принято не будет.
Вывести: ИД поставщика (SupplierID), наименование поставщика (SupplierName).
Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders.
По каким колонкам делать JOIN подумайте самостоятельно.
*/

TODO:
select s.SupplierID, s.SupplierName
from Purchasing.Suppliers s
left join Purchasing.PurchaseOrders o
					on s.SupplierID = o.SupplierID
where 
o.SupplierID is null; 


/*
3. Заказы (Orders) с ценой товара (UnitPrice) более 100$ 
либо количеством единиц (Quantity) товара более 20 штук
и присутствующей датой комплектации всего заказа (PickingCompletedWhen).
Вывести:
* OrderID
* дату заказа (OrderDate) в формате ДД.ММ.ГГГГ
* название месяца, в котором был сделан заказ
* номер квартала, в котором был сделан заказ
* треть года, к которой относится дата заказа (каждая треть по 4 месяца)
* имя заказчика (Customer)
Добавьте вариант этого запроса с постраничной выборкой,
пропустив первую 1000 и отобразив следующие 100 записей.

Сортировка должна быть по номеру квартала, трети года, дате заказа (везде по возрастанию).

Таблицы: Sales.Orders, Sales.OrderLines, Sales.Customers.
*/

TODO:

select distinct 
so.orderID,
format(so.orderdate,'dd.MM.yyyy') orderDate,
datename(month,so.orderdate),
datepart(quarter,so.orderdate) quarter,
case 
	when month(so.orderdate) <= 4 then 1
	when month(so.orderdate) between 5 and 8 then 2
	when month(so.orderdate) > 8 then 3
end thridYear,
sc.CustomerName
from sales.Orders so
join Sales.Customers sc
			on so.CustomerID = sc.CustomerID 
join Sales.OrderLines sol
			on so.OrderID = sol.OrderID
where 1=1
and sol.UnitPrice > 100
and sol.Quantity > 20
and so.PickingCompletedWhen is not null
order by quarter, thridYear, orderDate;

--Вариант 2

select distinct 
so.orderID,
format(so.orderdate,'dd.MM.yyyy') orderDate,
datename(month,so.orderdate),
datepart(quarter,so.orderdate) quarter,
case 
	when month(so.orderdate) <= 4 then 1
	when month(so.orderdate) between 5 and 8 then 2
	when month(so.orderdate) > 8 then 3
end thridYear,
sc.CustomerName
from sales.Orders so
join Sales.Customers sc
			on so.CustomerID = sc.CustomerID 
join Sales.OrderLines sol
			on so.OrderID = sol.OrderID
where 1=1
and sol.UnitPrice > 100
and sol.Quantity > 20
and so.PickingCompletedWhen is not null
order by quarter, thridYear, orderDate
OFFSET 1000 ROWS FETCH NEXT 100 ROWS ONLY;

/*
4. Заказы поставщикам (Purchasing.Suppliers),
которые должны быть исполнены (ExpectedDeliveryDate) в январе 2013 года
с доставкой "Air Freight" или "Refrigerated Air Freight" (DeliveryMethodName)
и которые исполнены (IsOrderFinalized).
Вывести:
* способ доставки (DeliveryMethodName)
* дата доставки (ExpectedDeliveryDate)
* имя поставщика
* имя контактного лица принимавшего заказ (ContactPerson)

Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders, Application.DeliveryMethods, Application.People.
*/

TODO: 

select
ad.DeliveryMethodName,
ppo.ExpectedDeliveryDate,
ps.SupplierName,
ap.FullName
from
Purchasing.PurchaseOrders ppo
join Application.DeliveryMethods ad
					on ppo.DeliveryMethodID = ad.DeliveryMethodID
join Purchasing.Suppliers ps
					on ppo.SupplierID = ps.SupplierID
join Application.People ap
					on ppo.ContactPersonID = ap.PersonID
where
ppo.ExpectedDeliveryDate between '2013-01-01' and '2013-01-31 23:59:59'
and (ad.DeliveryMethodName = 'Air Freight' or ad.DeliveryMethodName = 'Refrigerated Air Freight')
and ppo.IsOrderFinalized = 1
/*
5. Десять последних продаж (по дате продажи) с именем клиента и именем сотрудника,
который оформил заказ (SalespersonPerson).
Сделать без подзапросов.
*/

TODO:
select top 10
so.OrderID,
sc.CustomerName,
ap.FullName,
so.OrderDate
from 
Sales.Orders so
join sales.Customers sc
			on so.CustomerID = sc.CustomerID
join Application.People ap
			on so.SalespersonPersonID = ap.PersonID 
order by so.OrderDate desc
/*
6. Все ид и имена клиентов и их контактные телефоны,
которые покупали товар "Chocolate frogs 250g".
Имя товара смотреть в таблице Warehouse.StockItems.
*/

TODO: 
select * from Sales.OrderLines
select * from Warehouse.StockItems

select 
sc.CustomerID,
sc.CustomerName,
sc.PhoneNumber
from Sales.OrderLines sol
join Sales.Orders so 
			on sol.OrderID = so.OrderID
join sales.Customers sc
			on so.CustomerID = sc.CustomerID
join Warehouse.StockItems ws
			on sol.StockItemID = ws.StockItemID
where 
ws.StockItemName = 'Chocolate frogs 250g'
