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
1. Посчитать среднюю цену товара, общую сумму продажи по месяцам
Вывести:
* Год продажи (например, 2015)
* Месяц продажи (например, 4)
* Средняя цена за месяц по всем товарам
* Общая сумма продаж за месяц

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

TODO: 

select
year(si.InvoiceDate),
month(si.InvoiceDate),
avg(sil.unitPrice),
sum(sil.unitPrice)
from
	Sales.Invoices si 
join sales.InvoiceLines sil
			on si.InvoiceID = sil.InvoiceID
group by year(si.InvoiceDate), month(si.InvoiceDate)
order by year(si.InvoiceDate), month(si.InvoiceDate)

/*
2. Отобразить все месяцы, где общая сумма продаж превысила 10 000

Вывести:
* Год продажи (например, 2015)
* Месяц продажи (например, 4)
* Общая сумма продаж

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

TODO:

select
year(si.InvoiceDate),
month(si.InvoiceDate),
sum(sil.unitPrice)
from
	Sales.Invoices si 
join sales.InvoiceLines sil
			on si.InvoiceID = sil.InvoiceID
group by year(si.InvoiceDate), month(si.InvoiceDate)
having sum(sil.UnitPrice) > 10000
order by year(si.InvoiceDate), month(si.InvoiceDate)

/*
3. Вывести сумму продаж, дату первой продажи
и количество проданного по месяцам, по товарам,
продажи которых менее 50 ед в месяц.
Группировка должна быть по году,  месяцу, товару.

Вывести:
* Год продажи
* Месяц продажи
* Наименование товара
* Сумма продаж
* Дата первой продажи
* Количество проданного

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

TODO:

select
year(si.InvoiceDate) year,
month(si.InvoiceDate) month,
ws.StockItemName,
sum(sil.ExtendedPrice) totalPrice,
min(si.InvoiceDate) firstSale,
sum(sil.Quantity) TotalQuantity
from
	Sales.Invoices si 
join sales.InvoiceLines sil
			on si.InvoiceID = sil.InvoiceID
join Warehouse.StockItems ws
			on sil.StockItemID = ws.StockItemID
group by year(si.InvoiceDate), month(si.InvoiceDate), ws.StockItemName
having sum(sil.Quantity) < 50
order by year(si.InvoiceDate), month(si.InvoiceDate)


-- ---------------------------------------------------------------------------
-- Опционально
-- ---------------------------------------------------------------------------
/*
Написать запросы 2-3 так, чтобы если в каком-то месяце не было продаж,
то этот месяц также отображался бы в результатах, но там были нули.
*/
/*
select
year(si.InvoiceDate) year,
month(si.invoiceDate) month,
ws.StockItemName,
sil.ExtendedPrice,
si.InvoiceDate,
sil.Quantity,
1
from
Sales.Invoices si 
join sales.InvoiceLines sil
			on si.InvoiceID = sil.InvoiceID
join Warehouse.StockItems ws
			on sil.StockItemID = ws.StockItemID

union

select distinct
null,
null,
null,
null,
null,
null,
month(si.invoiceDate)
from sales.Invoices si
*/

