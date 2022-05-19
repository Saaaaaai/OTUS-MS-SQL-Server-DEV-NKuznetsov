/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "08 - Выборки из XML и JSON полей".

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
Примечания к заданиям 1, 2:
* Если с выгрузкой в файл будут проблемы, то можно сделать просто SELECT c результатом в виде XML. 
* Если у вас в проекте предусмотрен экспорт/импорт в XML, то можете взять свой XML и свои таблицы.
* Если с этим XML вам будет скучно, то можете взять любые открытые данные и импортировать их в таблицы (например, с https://data.gov.ru).
* Пример экспорта/импорта в файл https://docs.microsoft.com/en-us/sql/relational-databases/import-export/examples-of-bulk-import-and-export-of-xml-documents-sql-server
*/


/*
1. В личном кабинете есть файл StockItems.xml.
Это данные из таблицы Warehouse.StockItems.
Преобразовать эти данные в плоскую таблицу с полями, аналогичными Warehouse.StockItems.
Поля: StockItemName, SupplierID, UnitPackageID, OuterPackageID, QuantityPerOuter, TypicalWeightPerUnit, LeadTimeDays, IsChillerStock, TaxRate, UnitPrice 

Загрузить эти данные в таблицу Warehouse.StockItems: 
существующие записи в таблице обновить, отсутствующие добавить (сопоставлять записи по полю StockItemName). 

Сделать два варианта: с помощью OPENXML и через XQuery.
*/
Declare @XmlDoc xml;

SELECT @XmlDoc = BulkColumn
FROM OPENROWSET
(BULK 'C:\Users\rinep\Desktop\Списания ЕГАИС ЖП\StockItems-188-1fb5df.xml',
SINGLE_CLOB)
as data

SELECT @XmlDoc as [@XmlDoc]

DECLARE @handle int
EXEC sp_xml_preparedocument @handle OUTPUT, @XmlDoc

SELECT @handle as handle

select 
c.value('@Name','varchar(50)'), 
c.value('SupplierID[1]', 'int'),
c.value('Package[1]/UnitPackageID[1]','int'),
c.value('Package[1]/OuterPackageID[1]', 'int'),
c.value('Package[1]/QuantityPerOuter[1]', 'int'),
c.value('Package[1]/TypicalWeightPerUnit[1]', 'float'),
c.value('LeadTimeDays[1]', 'int'),
c.value('IsChillerStock[1]', 'int'),
c.value('TaxRate[1]', 'float'),
c.value('UnitPrice[1]', 'float')
from
@XmlDoc.nodes('/StockItems/Item') t(c);


MERGE Warehouse.StockItems base
USING 
(
	SELECT *
	FROM OPENXML(@handle, '/StockItems/Item')
	WITH 
	(
		StockItemName varchar(50) '@Name',
		SupplierID int 'SupplierID',
		UnitPackageID int 'Package/UnitPackageID',
		OuterPackageID int 'Package/OuterPackageID',
		QuantityPerOuter int 'Package/QuantityPerOuter',
		TypicalWeightPerUnit float 'Package/TypicalWeightPerUnit',
		LeadTimeDays int 'LeadTimeDays',
		IsChillerStock int 'IsChillerStock',
		TaxRate float 'TaxRate',
		UnitPrice float 'UnitPrice'
	)
) AS source (StockItemName, SupplierID, UnitPackageID, OuterPackageID, QuantityPerOuter, TypicalWeightPerUnit, LeadTimeDays, IsChillerStock, TaxRate, UnitPrice)
ON (base.StockItemName = source.StockItemName)
WHEN MATCHED 
	THEN
	UPDATE
	SET
	base.StockItemName = source.StockItemName,
	base.SupplierID = source.SupplierID,
	base.UnitPackageID = source.UnitPackageID,
	base.OuterPackageID = source.OuterPackageID,
	base.QuantityPerOuter = source.QuantityPerOuter,
	base.TypicalWeightPerUnit = source.TypicalWeightPerUnit,
	base.LeadTimeDays = source.LeadTimeDays,
	base.IsChillerStock = source.IsChillerStock,
	base.TaxRate = source.TaxRate,
	base.UnitPrice = source.UnitPrice,
	base.LastEditedBy = 1
when not matched
	then insert (StockItemName, SupplierID, UnitPackageID, OuterPackageID, QuantityPerOuter, TypicalWeightPerUnit, LeadTimeDays, IsChillerStock, TaxRate, UnitPrice, LastEditedBy)
	values (source.StockItemName, source.SupplierID, source.UnitPackageID, source.OuterPackageID, source.QuantityPerOuter, source.TypicalWeightPerUnit, source.LeadTimeDays, 
			source.IsChillerStock, source.TaxRate, source.UnitPrice, 1)
	output inserted.*, $action;

-- XQuery

Declare @XmlDoc xml;

SELECT @XmlDoc = BulkColumn
FROM OPENROWSET
(BULK 'C:\Users\rinep\Desktop\Списания ЕГАИС ЖП\StockItems-188-1fb5df.xml',
SINGLE_CLOB)
as data

SELECT @XmlDoc as [@XmlDoc]

DECLARE @handle int
EXEC sp_xml_preparedocument @handle OUTPUT, @XmlDoc

SELECT @handle as handle

select 
c.value('@Name','varchar(50)'), 
c.value('SupplierID[1]', 'int'),
c.value('Package[1]/UnitPackageID[1]','int'),
c.value('Package[1]/OuterPackageID[1]', 'int'),
c.value('Package[1]/QuantityPerOuter[1]', 'int'),
c.value('Package[1]/TypicalWeightPerUnit[1]', 'float'),
c.value('LeadTimeDays[1]', 'int'),
c.value('IsChillerStock[1]', 'int'),
c.value('TaxRate[1]', 'float'),
c.value('UnitPrice[1]', 'float')
from
@XmlDoc.nodes('/StockItems/Item') t(c);

/*
2. Выгрузить данные из таблицы StockItems в такой же xml-файл, как StockItems.xml
*/


SELECT
ws.StockItemName "@Item",
ws.SupplierID,
(
	select 
	wsI.UnitPackageID,
	wsI.OuterPackageID,
	wsI.QuantityPerOuter,
	wsI.TypicalWeightPerUnit
	from Warehouse.StockItems wsI
	where wsI.StockItemID = ws.StockItemID
	for xml path (''), type
) as "Package",
ws.LeadTimeDays,
ws.IsChillerStock,
ws.TaxRate,
ws.UnitPrice
FROM Warehouse.StockItems ws
for xml path ('Item'), TYPE, ROOT ('StockItems');


/*
3. В таблице Warehouse.StockItems в колонке CustomFields есть данные в JSON.
Написать SELECT для вывода:
- StockItemID
- StockItemName
- CountryOfManufacture (из CustomFields)
- FirstTag (из поля CustomFields, первое значение из массива Tags)
*/


SELECT 
StockItemID,
StockItemName,
JSON_VALUE(CustomFields, '$.CountryOfManufacture') CountryOfManufacture,
JSON_VALUE(CustomFields, '$.Tags[0]') FirstTag
FROM Warehouse.StockItems


/*
4. Найти в StockItems строки, где есть тэг "Vintage".
Вывести: 
- StockItemID
- StockItemName
- (опционально) все теги (из CustomFields) через запятую в одном поле

Тэги искать в поле CustomFields, а не в Tags.
Запрос написать через функции работы с JSON.
Для поиска использовать равенство, использовать LIKE запрещено.

Должно быть в таком виде:
... where ... = 'Vintage'

Так принято не будет:
... where ... Tags like '%Vintage%'
... where ... CustomFields like '%Vintage%' 
*/

select customfields
from Warehouse.StockItems

SELECT
ws.StockItemID,
ws.StockItemName,
STRING_AGG(TagForRow.Value, ',') Tags 
FROM Warehouse.StockItems ws
CROSS APPLY OPENJSON(ws.CustomFields, '$.Tags') TagForSearch
CROSS APPLY OPENJSON(ws.CustomFields, '$.Tags') TagForRow
WHERE
TagForSearch.value = 'Vintage'
group by StockItemID, StockItemName, CustomFields, TagForSearch.value
