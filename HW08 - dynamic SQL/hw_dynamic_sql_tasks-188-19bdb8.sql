/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "07 - Динамический SQL".

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

Это задание из занятия "Операторы CROSS APPLY, PIVOT, UNPIVOT."
Нужно для него написать динамический PIVOT, отображающий результаты по всем клиентам.
Имя клиента указывать полностью из поля CustomerName.

Требуется написать запрос, который в результате своего выполнения 
формирует сводку по количеству покупок в разрезе клиентов и месяцев.
В строках должны быть месяцы (дата начала месяца), в столбцах - клиенты.

Дата должна иметь формат dd.mm.yyyy, например, 25.12.2019.

Пример, как должны выглядеть результаты:
-------------+--------------------+--------------------+----------------+----------------------
InvoiceMonth | Aakriti Byrraju    | Abel Spirlea       | Abel Tatarescu | ... (другие клиенты)
-------------+--------------------+--------------------+----------------+----------------------
01.01.2013   |      3             |        1           |      4         | ...
01.02.2013   |      7             |        3           |      4         | ...
-------------+--------------------+--------------------+----------------+----------------------
*/


--select * from sales.Customers

declare
@CustomersName varchar(max),
@SqlQuery nvarchar(max);


select @CustomersName = isnull(@CustomersName,',') + QUOTENAME(test.CustomerName) + ','
from
( 
select  distinct top (select distinct count(CustomerName) from Sales.customers )
sc.CustomerName
from Sales.Customers sc
) as test ;

set @CustomersName = SUBSTRING(@CustomersName,2,len(@CustomersName)-2);

--select @CustomersName as Customers

set @SqlQuery = '
select *
from
(
select
si.InvoiceID,
convert(date,dateadd(month,datediff(month,0,si.InvoiceDate),0),103) mnth,
sc.CustomerName
from
sales.Invoices si
left join Sales.Customers sc
			on si.CustomerID = sc.CustomerID
) as CustomersOrders
pivot 
(
count(invoiceID) for CustomerName in ('+ @CustomersName +')) as pivotTable
order by mnth'


EXEC sp_executesql @SqlQuery
