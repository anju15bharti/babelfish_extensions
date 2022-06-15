

#testing for all the datatypes of agrument#

#int, default value and nvarchar#
create procedure test_nvar(@a nvarchar , @b int = 8)
AS
BEGIN
        SELECT @b=8;
END
go

select tsql_get_functiondef(oid) from pg_proc where proname='test_nvar';
go

drop procedure test_nvar;
go

#SMALLINT and INT OUTPUT
create schema sc1;
go

create procedure sc1.test_si(@a SMALLINT ,@b INT OUTPUT)
AS
BEGIN
        SELECT @a=70;
	set @a=8;
	SELECT @a as a;
END;
go

select tsql_get_functiondef(oid) from pg_proc where proname='test_si';
go

drop procedure sc1.test_si;
go

drop schema sc1;
go

#decimal
CREATE FUNCTION test_dec(
    @quantity INT,
    @list_price DEC(10,2),
    @discount DEC(4,2)
)
RETURNS DEC(10,2)
AS
BEGIN
    RETURN @quantity * @list_price * (1 - @discount);
END;
go

select tsql_get_functiondef(oid) from pg_proc where proname='test_dec';
go

#char
create procedure test_char(@ch char)
AS
BEGIN
	set @ch ='c';
	SELECT @ch as 's';
END;
go

select tsql_get_functiondef(oid) from pg_proc where proname='test_char';
go

drop procedure test_char;
go

#tinyint, float and bigint
create procedure test_ti(@a tinyint OUTPUT, @b BIGINT, @c float )
AS
BEGIN
	set @a=79;
	select @b=19;
	SELECT @c * 20 +1000;
END;
go

select tsql_get_functiondef(oid) from pg_proc where proname='test_ti';
go

drop procedure test_ti;
go

#numeric
create procedure test_num(@a numeric(20,6) OUTPUT)
AS
BEGIN
	set @a = 65;
	SELECT test_dec(23,60.76,43.88);
	
END;
go

select tsql_get_functiondef(oid) from pg_proc where proname='test_num';
go

drop procedure test_num;
go

drop function test_dec;
go

#time and date
create procedure test_time(@a time(5) OUTPUT , @b date OUTPUT)
AS
BEGIN
	set @a='12:54';
	set @b='2022-06-11';
END;
go

select tsql_get_functiondef(oid) from pg_proc where proname='test_time';
go

drop procedure test_time;
go

#datetime
create procedure test_dt(@a datetime output)
AS
BEGIN
	set @a='2022 -06-12 12:43';
END;
go

select tsql_get_functiondef(oid) from pg_proc where proname='test_dt';
go

drop procedure test_dt;
go

#UID
create procedure test_uid(@a uniqueidentifier output)
AS
BEGIN
	set @a ='ce8af10a-2709-43b0-9e4e-a02753929d17';
	SELECT @a as a;
END;
go

select tsql_get_functiondef(oid) from pg_proc where proname='test_uid';
go

drop procedure test_uid;
go

#check with different sqlbody.#

CREATE TABLE customers
( customer_id int NOT NULL,
  customer_name char(50) NOT NULL,
  address char(50),
  city char(50),
  state char(25),
  zip_code char(10),
  CONSTRAINT customers_pk PRIMARY KEY (customer_id)
);
go

create procedure test_b1
AS
BEGIN
	select * from customers;
        select * from customers where customer_id = 25;
END;
go

select tsql_get_functiondef(oid) from pg_proc where proname='test_b1';
go

drop procedure test_b1;
go

create procedure test_b2(@id int)
AS
BEGIN
	select count(state) from customers;
	select * from customers where customer_id = @id;
END;
go

select tsql_get_functiondef(oid) from pg_proc where proname='test_b2';
go

drop procedure test_b2;
go

create procedure test_b3(@name char(255), @city char(255), @address char(255), @state char(255), @cust_id int)
AS
BEGIN
	INSERT INTO customers (customer_name,address,city,state,customer_id) VALUES (@name,@address,@city,@state,@cust_id);
END;
go

select tsql_get_functiondef(oid) from pg_proc where proname='test_b3';
go

drop procedure test_b3;
go

create procedure test_b4(@id int)
AS
BEGIN
	DELETE from customers where customer_id = @id;
	ALTER TABLE customers ADD email varchar(255);

END;
go

select tsql_get_functiondef(oid) from pg_proc where proname='test_b4';
go

drop procedure test_b4;
go

create procedure test_b5 @paramout varchar(20) out
AS
BEGIN
SELECT @paramout ='helloworld';
END;
go

select tsql_get_functiondef(oid) from pg_proc where proname='test_b5';
go

drop procedure test_b5;
go

create procedure test_b6(@id int)
AS
BEGIN
	select city,state,zip_code from customers where customer_id=@id;
	UPDATE customers SET city = 'RANCHI' where state = 'JHARKHAND';
END;
go

select tsql_get_functiondef(oid) from pg_proc where proname='test_b6';
go

drop procedure test_b6;
go

DROP  FUNCTION IF EXISTS test_bd7;
go

create function test_bd7 (@cost int)
RETURNS INT
AS
BEGIN
	set @cost = 100;
	RETURN @cost * 10;

END;
go

select tsql_get_functiondef(oid) from pg_proc where proname='test_bd7';
go

drop table customers;
go

create function test_b8(
    @a INT,
    @b DEC(10,2),
    @c DEC(4,2)
)
RETURNS DEC(10,2)
AS 
BEGIN
	RETURN test_bd7(199) * 79;
    RETURN @a * @b * (1 - @c);
END;
go

select tsql_get_functiondef(oid) from pg_proc where proname='test_b8';
go

drop function test_b8;
go

DROP  FUNCTION IF EXISTS test_bd9;
go

create function test_bd9(@x int, @y int)
RETURNS int
AS
BEGIN 
	RETURN test_bd7(4);
	RETURN 200+(@x * @y);
END;
go

select tsql_get_functiondef(oid) from pg_proc where proname='test_bd9';
go

create function test_b10(@k SMALLINT)
RETURNS SMALLINT
AS
BEGIN
	set @k =88;
	SELECT @k = 32;
	RETURN @k/27;
END;
go

select tsql_get_functiondef(oid) from pg_proc where proname='test_b10';
go

drop function test_b10;
go

create schema s1;
go

create function s1.test_b11 (@a varchar)
RETURNS varchar
AS
BEGIN
        RETURN test_bd9(2,6);
	set @a= 'smile please';
	RETURN test_bd7(65);
	RETURN @a;
END;
go

select tsql_get_functiondef(oid) from pg_proc where proname='test_b11';
go

DROP  FUNCTION IF EXISTS test_bd7;
go

DROP  FUNCTION IF EXISTS test_bd9;
go

drop function s1.test_b11;
go

drop schema s1;
go


