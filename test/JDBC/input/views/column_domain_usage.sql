##tests for column_domain_usage##
CREATE TYPE typ1 FROM char(32) NOT NULL;
go

CREATE TABLE tb1(a int, b char, c varchar, d typ1);
go

SELECT * FROM information_schema.COLUMN_DOMAIN_USAGE WHERE TABLE_NAME NOT LIKE 'sys%' ORDER BY COLUMN_NAME;
go

CREATE DATABASE db_column_domain_usage;
go

USE db_column_domain_usage;
go

SELECT * FROM information_schema.COLUMN_DOMAIN_USAGE WHERE TABLE_NAME NOT LIKE 'sys%' ORDER BY COLUMN_NAME;
go

CREATE TYPE NTYP FROM varchar(11) NOT NULL;
go

create table col_test( s int, t nvarchar(8), r NTYP);
go

SELECT * FROM information_schema.COLUMN_DOMAIN_USAGE WHERE TABLE_NAME NOT LIKE 'sys%' ORDER BY COLUMN_NAME;
go

drop table col_test;
go

drop type NTYP;
go

use master;
go

drop table tb1;
go

drop type typ1;
go

drop database db_column_domain_usage;
go

create schema sch;
go

create type sch.ty4 from varchar(4) NOT NULL;
go

create table sch.tb4(m char, n int, o sch.ty4);
go

SELECT * FROM information_schema.COLUMN_DOMAIN_USAGE WHERE TABLE_NAME NOT LIKE 'sys%' ORDER BY COLUMN_NAME;
go

drop table sch.tb4;
go

drop type sch.ty4;
go

drop schema sch;
go
