CREATE DATABASE [BookStore]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'BookStore', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL14.SQL2017\MSSQL\DATA\BookStore.mdf' , SIZE = 8192KB , FILEGROWTH = 65536KB )
 LOG ON 
( NAME = N'BookStore_log', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL14.SQL2017\MSSQL\DATA\BookStore_log.ldf' , SIZE = 8192KB , FILEGROWTH = 65536KB );

USE BookStore;

CREATE TABLE Authors
(
	Author_id int PRIMARY KEY,
	First_Name varchar(50),
	Last_Name varchar(50)
);

CREATE TABLE Publishing
(
	Publishing_id int PRIMARY KEY,
	Publishing_name varchar(50)
);

CREATE TABLE BOOKS
(
	Book_id int PRIMARY KEY,
	Titile varchar(100) NOT NULL,
	Author_id int foreign key references Authors(Author_id),
	Publishing_id int foreign key references Publishing(Publishing_id),
	Price money NOT NULL
);

CREATE TABLE BOOKSALES
(
	SALEID int PRIMARY KEY,
	Book_id int foreign key references BOOKS(Book_id),
	Quantity int not null,
	Price money,
	TotalPrice as Quantity * Price
)

USE [BookStore]

GO

CREATE NONCLUSTERED INDEX [NonClusteredIndex-Author_id] ON [dbo].[BOOKS]
(
	[Author_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)

GO
