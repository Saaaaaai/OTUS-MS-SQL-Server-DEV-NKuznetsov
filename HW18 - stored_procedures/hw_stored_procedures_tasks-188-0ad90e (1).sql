/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "12 - Хранимые процедуры, функции, триггеры, курсоры".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0
Нужен WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

USE WideWorldImporters

/*
Во всех заданиях написать хранимую процедуру / функцию и продемонстрировать ее использование.
*/

/*
1) Написать функцию возвращающую Клиента с наибольшей суммой покупки.
*/

CREATE FUNCTION getMaxCliPurchase()
RETURNS TABLE  
AS  
RETURN   
(
	SELECT SO.CustomerID
	FROM Sales.Orders SO
	WHERE SO.OrderID = (SELECT TOP 1 OrderID
						FROM Sales.OrderLines
						GROUP BY OrderID
						ORDER BY SUM(UnitPrice) DESC)
);

SELECT * FROM getMaxCliPurchase();

/*
2) Написать хранимую процедуру с входящим параметром СustomerID, выводящую сумму покупки по этому клиенту.
Использовать таблицы :
Sales.Customers
Sales.Invoices
Sales.InvoiceLines
*/

CREATE PROCEDURE getTotalSumOfCliPurchase @CustomerID int
AS
	SELECT SUM(SIL.UNITPRICE)
	FROM Sales.Invoices SI
	LEFT JOIN Sales.InvoiceLines SIL
		ON SI.InvoiceID = SIL.InvoiceID
	WHERE SI.CustomerID = @CustomerID

	EXEC getTotalSumOfCliPurchase @CustomerID=39

/*
3) Создать одинаковую функцию и хранимую процедуру, посмотреть в чем разница в производительности и почему.
*/


CREATE FUNCTION getTotalSumOfCliPurchaseTest(@CustomerID int)
RETURNS TABLE
AS RETURN
(
		SELECT SUM(SIL.UNITPRICE) TotalSum
	FROM Sales.Invoices SI
	LEFT JOIN Sales.InvoiceLines SIL
		ON SI.InvoiceID = SIL.InvoiceID
	WHERE SI.CustomerID = @CustomerID
)

	SET STATISTICS TIME ON
	EXEC getTotalSumOfCliPurchase @CustomerID=39;
	SELECT * FROM getTotalSumOfCliPurchaseTest(39)

	--судя по плану запроса процедура тратит процессорное время на собственный вызов, в то время как функция этого не делает

/*
4) Создайте табличную функцию покажите как ее можно вызвать для каждой строки result set'а без использования цикла. 
*/

CREATE FUNCTION getTotalSumOfALLCliPurchase()
RETURNS TABLE
AS RETURN
(
		SELECT SI.CustomerID, SUM(SIL.UNITPRICE) TotalSum
	FROM Sales.Invoices SI
	LEFT JOIN Sales.InvoiceLines SIL
		ON SI.InvoiceID = SIL.InvoiceID
	GROUP BY SI.CustomerID
)

SET STATISTICS TIME OFF

declare MyCursor cursor
for select * from getTotalSumOfALLCliPurchase()
open MyCursor
declare @Client int,
		@Sum int,
		@String varchar(100)
fetch next from MyCursor INTO @Client, @Sum
while @@FETCH_STATUS = 0
begin
	SET @String = CAST(@Client as varchar) + ' - ' + CAST(@Sum as varchar);
	print @String;
	fetch next from MyCursor INTO  @Client, @Sum
end
close MyCursor
deallocate MyCursor


/*
5) Опционально. Во всех процедурах укажите какой уровень изоляции транзакций вы бы использовали и почему. 
*/
