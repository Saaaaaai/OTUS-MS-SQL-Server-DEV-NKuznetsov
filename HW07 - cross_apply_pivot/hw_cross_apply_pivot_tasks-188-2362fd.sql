/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "05 - Операторы CROSS APPLY, PIVOT, UNPIVOT".

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
1. Требуется написать запрос, который в результате своего выполнения 
формирует сводку по количеству покупок в разрезе клиентов и месяцев.
В строках должны быть месяцы (дата начала месяца), в столбцах - клиенты.

Клиентов взять с ID 2-6, это все подразделение Tailspin Toys.
Имя клиента нужно поменять так чтобы осталось только уточнение.
Например, исходное значение "Tailspin Toys (Gasport, NY)" - вы выводите только "Gasport, NY".
Дата должна иметь формат dd.mm.yyyy, например, 25.12.2019.

Пример, как должны выглядеть результаты:
-------------+--------------------+--------------------+-------------+--------------+------------
InvoiceMonth | Peeples Valley, AZ | Medicine Lodge, KS | Gasport, NY | Sylvanite, MT | Jessie, ND
-------------+--------------------+--------------------+-------------+--------------+------------
01.01.2013   |      3             |        1           |      4      |      2        |     2
01.02.2013   |      7             |        3           |      4      |      2        |     1
-------------+--------------------+--------------------+-------------+--------------+------------
*/

select * from
(
select 
dateadd(month,datediff(month,0,si.InvoiceDate),0) month,
si.InvoiceID,
substring(sc.CustomerName,15,50) [subName] 
from sales.Invoices si
left join sales.Customers sc
				on si.CustomerID = sc.CustomerID
where sc.CustomerID in (2,3,4,5,6)
) as s
pivot (
count(invoiceID) 
for [subName]  in ("(Sylvanite, MT)","(Peeples Valley, AZ)", "(Medicine Lodge, KS)", "(Gasport, NY)", "(Jessie, ND)")
) as pvt;


/*
2. Для всех клиентов с именем, в котором есть "Tailspin Toys"
вывести все адреса, которые есть в таблице, в одной колонке.

Пример результата:
----------------------------+--------------------
CustomerName                | AddressLine
----------------------------+--------------------
Tailspin Toys (Head Office) | Shop 38
Tailspin Toys (Head Office) | 1877 Mittal Road
Tailspin Toys (Head Office) | PO Box 8975
Tailspin Toys (Head Office) | Ribeiroville
----------------------------+--------------------
*/

select 
sc.CustomerName,
sc.DeliveryAddressLine1
from
Sales.Customers sc
where
substring(sc.customerName,1,14) = 'Tailspin Toys'

union 

select 
sc.CustomerName,
sc.DeliveryAddressLine2
from
Sales.Customers sc
where
substring(sc.customerName,1,14) = 'Tailspin Toys'

union

select 
sc.CustomerName,
sc.PostalAddressLine1
from
Sales.Customers sc
where
substring(sc.customerName,1,14) = 'Tailspin Toys'

union

select 
sc.CustomerName,
sc.PostalAddressLine2
from
Sales.Customers sc
where
substring(sc.customerName,1,14) = 'Tailspin Toys'


/*
3. В таблице стран (Application.Countries) есть поля с цифровым кодом страны и с буквенным.
Сделайте выборку ИД страны, названия и ее кода так, 
чтобы в поле с кодом был либо цифровой либо буквенный код.

Пример результата:
--------------------------------
CountryId | CountryName | Code
----------+-------------+-------
1         | Afghanistan | AFG
1         | Afghanistan | 4
3         | Albania     | ALB
3         | Albania     | 8
----------+-------------+-------
*/

select * from Application.Countries

select
ac.CountryName,
caac.*
from
Application.Countries ac
cross apply (
select
acAPLY.IsoAlpha3Code
from Application.Countries acAPLY
where
ac.CountryID = acAPLY.CountryID

union

select
cast(acAPLY.IsoNumericCode as varchar)
from Application.Countries acAPLY
where
ac.CountryID = acAPLY.CountryID
) caac





/*
4. Выберите по каждому клиенту два самых дорогих товара, которые он покупал.
В результатах должно быть ид клиета, его название, ид товара, цена, дата покупки.
*/

select 
sc.CustomerID,
sc.CustomerName,
aply.StockItemID,
aply.UnitPrice,
aply.InvoiceDate
from Sales.Customers sc
cross apply
(
select top 2
si.InvoiceDate,
sil.*
from Sales.Invoices si
left join Sales.InvoiceLines sil
				on si.InvoiceID = sil.InvoiceID
where 
sc.CustomerID = si.CustomerID
order by sil.UnitPrice desc
) aply
