/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "03 - Подзапросы, CTE, временные таблицы".

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
-- Для всех заданий, где возможно, сделайте два варианта запросов:
--  1) через вложенный запрос
--  2) через WITH (для производных таблиц)
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Выберите сотрудников (Application.People), которые являются продажниками (IsSalesPerson), 
и не сделали ни одной продажи 04 июля 2015 года. 
Вывести ИД сотрудника и его полное имя. 
Продажи смотреть в таблице Sales.Invoices.
*/

TODO: 

--Вариант 1
select ap.PersonID, ap.FullName
from application.People ap
where ap.PersonID not in (select distinct si1.SalespersonPersonID 
							from sales.Invoices si1
							where
							si1.InvoiceDate = cast('04-07-2015' as date))
and ap.IsSalesperson = 1;

--Вариант 2
with si (SalepersonPersonID)
as
(
	select distinct si1.SalespersonPersonID 
	from sales.Invoices si1
	where
	si1.InvoiceDate = cast('04-07-2015' as date)
)
select ap.PersonID, ap.fullname
from Application.People ap
left join si on ap.PersonID = si.SalepersonPersonID
where ap.IsSalesperson = 1
and si.SalepersonPersonID is null;

/*
2. Выберите товары с минимальной ценой (подзапросом). Сделайте два варианта подзапроса. 
Вывести: ИД товара, наименование товара, цена.
*/

TODO: 
--Вариант 1
select ws.StockItemID, ws.StockItemName, ws.UnitPrice
from
Warehouse.StockItems ws
where 
ws.StockItemID = (select top 1 StockItemID from Warehouse.StockItems where StockItemID = ws.StockItemID
					order by UnitPrice)
group by ws.StockItemID, ws.StockItemName, ws.UnitPrice;

--Вариант 2
with wsCTE (stockitemID)
AS
(
	select top 1 stockitemid
	from Warehouse.StockItems
	order by UnitPrice
)
select ws.StockItemID, ws.StockItemName, ws.UnitPrice
from
Warehouse.StockItems ws
left join wsCTE
			on ws.StockItemID = wsCTE.stockitemID;


/*
3. Выберите информацию по клиентам, которые перевели компании пять максимальных платежей 
из Sales.CustomerTransactions. 
Представьте несколько способов (в том числе с CTE). 
*/

TODO:

select top 5 sc.CustomerID, sc2.CustomerName, max(sc.TransactionAmount)
from Sales.CustomerTransactions sc
left join sales.Customers sc2
			on sc.CustomerID = sc2.CustomerID
group by sc.CustomerID, sc2.CustomerName;

with scCTE
as
(
	select top 5 CustomerID, max(TransactionAmount) ta
	from Sales.CustomerTransactions
	group by CustomerID
)
select sc.CustomerID, scCTE.ta
from Sales.CustomerTransactions sc
join scCTE
			on sc.CustomerID = scCTE.CustomerID
group by sc.CustomerID, scCTE.ta;



/*
4. Выберите города (ид и название), в которые были доставлены товары, 
входящие в тройку самых дорогих товаров, а также имя сотрудника, 
который осуществлял упаковку заказов (PackedByPersonID).
*/

TODO: 

with wsCTE
as
(
select top 3 ws.StockItemID, ws.StockItemName, ws.UnitPrice
from Warehouse.StockItems ws
order by ws.UnitPrice desc
)
select distinct ac.CityID, ac.CityName, ap.FullName
from 
sales.Invoices si
left join Sales.InvoiceLines sil
			on si.OrderID = sil.InvoiceID
left join wsCTE
			on sil.StockItemID = wsCTE.StockItemID
			and wsCTE.StockItemID is not null
left join Sales.Customers sc
			on si.CustomerID = sc.CustomerID
left join Application.People ap
			on si.PackedByPersonID = ap.PersonID
left join Application.Cities ac
			on sc.DeliveryCityID = ac.CityID



-- ---------------------------------------------------------------------------
-- Опциональное задание
-- ---------------------------------------------------------------------------
-- Можно двигаться как в сторону улучшения читабельности запроса, 
-- так и в сторону упрощения плана\ускорения. 
-- Сравнить производительность запросов можно через SET STATISTICS IO, TIME ON. 
-- Если знакомы с планами запросов, то используйте их (тогда к решению также приложите планы). 
-- Напишите ваши рассуждения по поводу оптимизации. 

-- 5. Объясните, что делает и оптимизируйте запрос

/*Используя CTE мне удалось уменьшить число физических чтений, а также читабельность запроса.
Я вижу, что в плане запроса самая большая стоимость у Clustered index SCAN у таблицы invoices по первичному ключу, но не понимаю как здесь можно что-то оптимизировать.
Можно будет посмотреть решения других студентов?*/

SET STATISTICS IO, TIME ON
SELECT 
	Invoices.InvoiceID, 
	Invoices.InvoiceDate,
	(SELECT People.FullName
		FROM Application.People
		WHERE People.PersonID = Invoices.SalespersonPersonID
	) AS SalesPersonName,
	SalesTotals.TotalSumm AS TotalSummByInvoice, 
	(SELECT SUM(OrderLines.PickedQuantity*OrderLines.UnitPrice)
		FROM Sales.OrderLines
		WHERE OrderLines.OrderId = (SELECT Orders.OrderId 
			FROM Sales.Orders
			WHERE Orders.PickingCompletedWhen IS NOT NULL	
				AND Orders.OrderId = Invoices.OrderId)	
	) AS TotalSummForPickedItems
FROM Sales.Invoices 
	JOIN
	(SELECT InvoiceId, SUM(Quantity*UnitPrice) AS TotalSumm
	FROM Sales.InvoiceLines
	GROUP BY InvoiceId
	HAVING SUM(Quantity*UnitPrice) > 27000) AS SalesTotals
		ON Invoices.InvoiceID = SalesTotals.InvoiceID
ORDER BY TotalSumm DESC;

-- --

TODO: 
with pnameCTE as
(
	SELECT People.PersonID, People.FullName
		FROM Application.People
),
TotalsCTE as
(
	SELECT InvoiceId, SUM(Quantity*UnitPrice) AS TotalSumm
		FROM Sales.InvoiceLines
		GROUP BY InvoiceId
		HAVING SUM(Quantity*UnitPrice) > 27000
),
orders2 as
(
	SELECT Orders.OrderId as ord
			FROM Sales.Orders
			WHERE Orders.PickingCompletedWhen IS NOT NULL
),
totalsForPicked as
(
	SELECT OrderID, SUM(OrderLines.PickedQuantity*OrderLines.UnitPrice)  AS TotalSummForPickedItems
		FROM Sales.OrderLines
		group by orderID
)

SELECT 
	Invoices.InvoiceID, 
	Invoices.InvoiceDate,
	pnameCTE.FullName,
	TotalsCTE.TotalSumm AS TotalSummByInvoice, 
	totalsForPicked.TotalSummForPickedItems
FROM Sales.Invoices 
	JOIN TotalsCTE
		ON Invoices.InvoiceID = TotalsCTE.InvoiceID
	left join pnameCTE
		on pnameCTE.PersonID = Invoices.SalespersonPersonID
	left join orders2
		on Invoices.OrderID = orders2.ord
	left join totalsForPicked
		on orders2.ord = totalsForPicked.OrderID
ORDER BY TotalSumm DESC


