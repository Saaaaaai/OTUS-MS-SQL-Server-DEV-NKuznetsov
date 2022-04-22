/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "06 - Оконные функции"1

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
1. Сделать расчет суммы продаж нарастающим итогом по месяцам с 2015 года 
(в рамках одного месяца он будет одинаковый, нарастать будет в течение времени выборки).
Выведите: id продажи, название клиента, дату продажи, сумму продажи, сумму нарастающим итогом

Пример:
-------------+----------------------------
Дата продажи | Нарастающий итог по месяцу
-------------+----------------------------
 2015-01-29   | 4801725.31
 2015-01-30	 | 4801725.31
 2015-01-31	 | 4801725.31
 2015-02-01	 | 9626342.98
 2015-02-02	 | 9626342.98
 2015-02-03	 | 9626342.98
Продажи можно взять из таблицы Invoices.
Нарастающий итог должен быть без оконной функции.
*/

set statistics time, io on

select
si.InvoiceID,
sc.CustomerName,
si.InvoiceDate,
sum(sil.TaxAmount) monthSum,
(select
sum(silSub.TaxAmount)
from Sales.Invoices siSub 
left join Sales.InvoiceLines silSub
				on siSub.InvoiceID = silSub.InvoiceID
where
convert(varchar(7), siSub.InvoiceDate, 126) between '2015-01' and convert(varchar(7), si.InvoiceDate, 126)
) as Totals
from
sales.Invoices si
left join Sales.InvoiceLines sil
				on si.InvoiceID = sil.InvoiceID
left join Sales.Customers sc
				on si.CustomerID = sc.CustomerID
where convert(varchar(7), si.InvoiceDate, 126) >= '2015-01'
group by si.InvoiceID,sc.CustomerName,si.InvoiceDate
order by si.InvoiceDate;



/*
2. Сделайте расчет суммы нарастающим итогом в предыдущем запросе с помощью оконной функции.
   Сравните производительность запросов 1 и 2 с помощью set statistics time, io on
*/

select
si.InvoiceID,
sc.CustomerName,
si.InvoiceDate,
sil.TaxAmount,
sum(sil.TaxAmount) over (order by convert(varchar(7), si.invoicedate, 126))
from
sales.Invoices si
left join Sales.InvoiceLines sil
				on si.InvoiceID = sil.InvoiceID
left join Sales.Customers sc
				on si.CustomerID = sc.CustomerID
where 
convert(varchar(7), si.invoicedate, 126) >= '2015-01'
order by convert(varchar(7), si.invoicedate, 126);

/*
3. Вывести список 2х самых популярных продуктов (по количеству проданных) 
в каждом месяце за 2016 год (по 2 самых популярных продукта в каждом месяце).
*/

with monthTotalsCTE
AS
(
	select
	ws.StockItemName,
	MONTH(si.InvoiceDate) month,
	sum(sil.Quantity) totals
	from sales.Invoices si
	left join sales.InvoiceLines sil
					on si.InvoiceID = sil.InvoiceID
	left join Warehouse.StockItems ws
					on sil.StockItemID = ws.StockItemID
	where year(si.InvoiceDate) = 2016
	group by ws.StockItemName, MONTH(si.InvoiceDate)

),
numeredTotalsCTE
as
(
	select
	StockItemName,
	month,
	totals,
	ROW_NUMBER() over (partition by month order by month, totals desc) numeredTotals
	from monthTotalsCTE
)
select *
from numeredTotalsCTE
where numeredTotals <= 2
order by month


--with test
--as
--(
--select * from
--(
--select
--convert(varchar(7),si.InvoiceDate,126) myDate,
--sil.StockItemID,
--ROW_NUMBER() over (partition by convert(varchar(7),si.InvoiceDate,126), sil.StockItemID order by si.InvoiceDate) rn,
--sum(sil.Quantity) over (partition by convert(varchar(7),si.InvoiceDate,126),sil.stockitemid) sumQ
--from
--Sales.Invoices si
--left join Sales.InvoiceLines sil
--			on si.InvoiceID = sil.InvoiceID
--) x
--where
--(x.rn = 1 or x.rn = 2)
--and myDate like '2016%'
--group by myDate, StockItemID, rn, sumQ
--order by StockItemID
--)



--select myDate, max(sumQ) from
--(
--select distinct
--convert(varchar(7),si.InvoiceDate,126) myDate,
--sil.StockItemID,
--ROW_NUMBER() over (partition by convert(varchar(7),si.InvoiceDate,126), sil.StockItemID order by si.InvoiceDate) rn,
--sum(sil.Quantity) over (partition by convert(varchar(7),si.InvoiceDate,126),sil.stockitemid) sumQ
--from
--Sales.Invoices si
--left join Sales.InvoiceLines sil
--			on si.InvoiceID = sil.InvoiceID
--			where
--			convert(varchar(7),si.InvoiceDate,126) like '2016%'
--			order by convert(varchar(7),si.InvoiceDate,126), StockItemID, rn
--) x
--where
--myDate like '2016%'
--group by myDate
--order by myDate

/*
4. Функции одним запросом
Посчитайте по таблице товаров (в вывод также должен попасть ид товара, название, брэнд и цена):
* пронумеруйте записи по названию товара, так чтобы при изменении буквы алфавита нумерация начиналась заново
* посчитайте общее количество товаров и выведете полем в этом же запросе
* посчитайте общее количество товаров в зависимости от первой буквы названия товара
* отобразите следующий id товара исходя из того, что порядок отображения товаров по имени 
* предыдущий ид товара с тем же порядком отображения (по имени)
* названия товара 2 строки назад, в случае если предыдущей строки нет нужно вывести "No items"
* сформируйте 30 групп товаров по полю вес товара на 1 шт

Для этой задачи НЕ нужно писать аналог без аналитических функций.
*/

select
ws.StockItemID,
ws.StockItemName,
ws.Brand,
ws.UnitPrice,
row_number() over (partition by substring(ws.stockitemname,1,1) order by ws.stockitemname),
count(1) over (),
count(substring(ws.stockitemname,1,1)) over (partition by substring(ws.stockitemname,1,1)),
lead(ws.StockItemID) over (order by ws.stockItemName),
lag(ws.StockItemID) over (order by ws.stockItemName),
coalesce(lag(ws.stockItemName,2) over (order by ws.stockItemName),'No items'),
ntile(30) over (order by ws.TypicalWeightPerUnit)
from Warehouse.StockItems ws;
--group by ws.StockItemID, ws.StockItemName, ws.Brand, ws.UnitPrice

/*
5. По каждому сотруднику выведите последнего клиента, которому сотрудник что-то продал.
   В результатах должны быть ид и фамилия сотрудника, ид и название клиента, дата продажи, сумму сделки.
*/

with personsSales
as
(
	select
	si.SalespersonPersonID,
	ap.FullName,
	sc.CustomerID,
	sc.CustomerName,
	si.InvoiceDate,
	sum(sil.TaxAmount) saleSum
	from sales.Invoices si
	left join Application.People ap
				on si.SalespersonPersonID = ap.PersonID
	left join sales.Customers sc
				on si.CustomerID = sc.CustomerID
	left join sales.InvoiceLines sil
				on si.InvoiceID = sil.InvoiceID
	group by si.InvoiceDate, si.SalespersonPersonID, ap.FullName, sc.CustomerID, sc.CustomerName
),
lastPresonsSales
as
(
	select
	*,
	ROW_NUMBER() over (partition by SalespersonPersonID order by invoiceDate desc) rn
	from personsSales
)
select *
from lastPresonsSales
where rn = 1



/*
6. Выберите по каждому клиенту два самых дорогих товара, которые он покупал.
В результатах должно быть ид клиета, его название, ид товара, цена, дата покупки.
*/

with buyedItems
as
(
	select
	si.CustomerID,
	sc.CustomerName,
	sil.StockItemID,
	max(sil.UnitPrice) maxPrice,
	si.InvoiceDate
	from Sales.Invoices si
	left join sales.InvoiceLines sil
					on si.InvoiceID = sil.InvoiceID
	left join sales.Customers sc
					on si.CustomerID = sc.CustomerID
	group by si.CustomerID, sc.CustomerName, sil.StockItemID, si.InvoiceDate
),
last2MaxBuyedItems
as
(
	select
	*,
	ROW_NUMBER() over (partition by customerid order by maxPrice desc) rn
	from buyedItems
)
select *
from last2MaxBuyedItems
where rn <= 2

Опционально можете для каждого запроса без оконных функций сделать вариант запросов с оконными функциями и сравнить их производительность. 