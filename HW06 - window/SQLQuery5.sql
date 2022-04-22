/*
�������� ������� �� ����� MS SQL Server Developer � OTUS.

������� "06 - ������� �������".

������� ����������� � �������������� ���� ������ WideWorldImporters.

����� �� ����� ������� ������:
https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0
����� WideWorldImporters-Full.bak

�������� WideWorldImporters �� Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- ������� - �������� ������� ��� ��������� ��������� ���� ������.
-- ---------------------------------------------------------------------------

USE WideWorldImporters
/*
1. ������� ������ ����� ������ ����������� ������ �� ������� � 2015 ���� 
(� ������ ������ ������ �� ����� ����������, ��������� ����� � ������� ������� �������).
��������: id �������, �������� �������, ���� �������, ����� �������, ����� ����������� ������

������:
-------------+----------------------------
���� ������� | ����������� ���� �� ������
-------------+----------------------------
 2015-01-29   | 4801725.31
 2015-01-30	 | 4801725.31
 2015-01-31	 | 4801725.31
 2015-02-01	 | 9626342.98
 2015-02-02	 | 9626342.98
 2015-02-03	 | 9626342.98
������� ����� ����� �� ������� Invoices.
����������� ���� ������ ���� ��� ������� �������.
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
2. �������� ������ ����� ����������� ������ � ���������� ������� � ������� ������� �������.
   �������� ������������������ �������� 1 � 2 � ������� set statistics time, io on
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
3. ������� ������ 2� ����� ���������� ��������� (�� ���������� ���������) 
� ������ ������ �� 2016 ��� (�� 2 ����� ���������� �������� � ������ ������).
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
4. ������� ����� ��������
���������� �� ������� ������� (� ����� ����� ������ ������� �� ������, ��������, ����� � ����):
* ������������ ������ �� �������� ������, ��� ����� ��� ��������� ����� �������� ��������� ���������� ������
* ���������� ����� ���������� ������� � �������� ����� � ���� �� �������
* ���������� ����� ���������� ������� � ����������� �� ������ ����� �������� ������
* ���������� ��������� id ������ ������ �� ����, ��� ������� ����������� ������� �� ����� 
* ���������� �� ������ � ��� �� �������� ����������� (�� �����)
* �������� ������ 2 ������ �����, � ������ ���� ���������� ������ ��� ����� ������� "No items"
* ����������� 30 ����� ������� �� ���� ��� ������ �� 1 ��

��� ���� ������ �� ����� ������ ������ ��� ������������� �������.
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
5. �� ������� ���������� �������� ���������� �������, �������� ��������� ���-�� ������.
   � ����������� ������ ���� �� � ������� ����������, �� � �������� �������, ���� �������, ����� ������.
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
6. �������� �� ������� ������� ��� ����� ������� ������, ������� �� �������.
� ����������� ������ ���� �� ������, ��� ��������, �� ������, ����, ���� �������.
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

����������� ������ ��� ������� ������� ��� ������� ������� ������� ������� �������� � �������� ��������� � �������� �� ������������������. 