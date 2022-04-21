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

with test
as
(
select * from
(
select
convert(varchar(7),si.InvoiceDate,126) myDate,
sil.StockItemID,
ROW_NUMBER() over (partition by convert(varchar(7),si.InvoiceDate,126), sil.StockItemID order by si.InvoiceDate) rn,
sum(sil.Quantity) over (partition by convert(varchar(7),si.InvoiceDate,126),sil.stockitemid) sumQ
from
Sales.Invoices si
left join Sales.InvoiceLines sil
			on si.InvoiceID = sil.InvoiceID
) x
where
(x.rn = 1 or x.rn = 2)
and myDate like '2016%'
group by myDate, StockItemID, rn, sumQ
order by StockItemID
)



select myDate, max(sumQ) from
(
select distinct
convert(varchar(7),si.InvoiceDate,126) myDate,
sil.StockItemID,
ROW_NUMBER() over (partition by convert(varchar(7),si.InvoiceDate,126), sil.StockItemID order by si.InvoiceDate) rn,
sum(sil.Quantity) over (partition by convert(varchar(7),si.InvoiceDate,126),sil.stockitemid) sumQ
from
Sales.Invoices si
left join Sales.InvoiceLines sil
			on si.InvoiceID = sil.InvoiceID
			where
			convert(varchar(7),si.InvoiceDate,126) like '2016%'
			order by convert(varchar(7),si.InvoiceDate,126), StockItemID, rn
) x
where
myDate like '2016%'
group by myDate
order by myDate

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

�������� ����� ���� �������

/*
5. �� ������� ���������� �������� ���������� �������, �������� ��������� ���-�� ������.
   � ����������� ������ ���� �� � ������� ����������, �� � �������� �������, ���� �������, ����� ������.
*/

�������� ����� ���� �������

/*
6. �������� �� ������� ������� ��� ����� ������� ������, ������� �� �������.
� ����������� ������ ���� �� ������, ��� ��������, �� ������, ����, ���� �������.
*/

�������� ����� ���� �������

����������� ������ ��� ������� ������� ��� ������� ������� ������� ������� �������� � �������� ��������� � �������� �� ������������������. 