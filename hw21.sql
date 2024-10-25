--1
drop function hello_user;

create or replace function hello_user(n text)
returns text 
language plpgsql as 
$$
	begin 		
		return concat('Hello ', n , ' ', current_timestamp);
	end;
$$;


--2
create or replace function arithmetics(x float, y float, 
out summ float, out mult float, out dif float, out divv float)
language plpgsql as 
$$
	begin 
		select x+y, x*y, x/y, x-y
		into summ, mult, dif, divv;
	end;
$$;

--3
create or replace function smaller(x integer, y integer)
returns integer
language plpgsql as $$
	begin
		if x > y then
			return y;
		else
			return x;
		end if;
	end;
$$;

--4
create or replace function smallest(x int, y int, z int)
returns int
language plpgsql as $$
	begin 
		return least(x, y, z);
	end;
$$;

--5
create or replace function ran(big int, small int)
returns float
language plpgsql as $$
	BEGIN
		return random() * (big - small) + small;
	END;
$$;

--6
create or replace function stats()
returns setof books
language plpgsql as $$
begin
    return query
    with 
        cheapest as (
            select * from books where price = (select min(price) from books)
        ),
        expensive as (
            select * from books where price = (select max(price) from books)
        ),
        average as (
            select * from books where price = (select avg(price) from books)
        )
    select * from cheapest
    union all
    select * from expensive
    union all
    select * from average;
--Didnt understand how to return the total count
end;
$$;

--7
create or replace function most()
returns table(name text, count int8)
language plpgsql as $$
	begin
		return query
		with combined as
			(select a.name, count(*) from authors a join books b on a.id = b.author_id group by a.name)
		select * from combined c where c.count = (select max(c.count) from combined c);
		
	end;
$$;

--8
create or replace function cheapest()
returns table(cheap text)
language plpgsql as $$
	begin 
		return query select title from books where price = (select min(price) from books);
	end;
$$;

--9
create or replace function avg_rows()
returns float
language plpgsql as $$
	declare 
		b_rows int:= (select count(*) from books);
		a_rows int := (select count(*) from authors);
	begin 
		return (a_rows + b_rows) / 2::float; 
	end;
$$;

--10
create or replace function add_book(_title text, _release_date timestamp, _price float, _author_id int8)
returns int8
language plpgsql as $$
	declare
		new_id int8 := 0;
	begin 
		insert into books(title, release_date, price, author_id)
		values (_title, _release_date, _price, _author_id)
		returning id into new_id;
		return new_id;
	end;
$$;

--bonus
--11
create or replace function author_add(_name text)
returns int8
language plpgsql as $$
	declare
		new_id int8 := 0;
	begin 
		insert into authors(name)
		values(_name)
		returning id into new_id;
		return new_id;
	end;
$$;

--12
create or replace function avg_books()
returns table(name text, avg float)
language plpgsql as $$
	declare 
		average float:= 0;
	begin 
		return query
		with combined as
		(select count(*) from authors a join books b on a.id = b.author_id group by a.name)
		select avg(count) from combined;
	
	end;
$$;

--13
create or replace procedure book_update(_id int8, _title text, _release_date timestamp, _price float)
language plpgsql as $$
	begin 
		update books set title = _title, release_date = _release_date,
		price = _price
		where id = _id;
	end;
$$;

call book_update(27, 'Harry and Hagrid', cast('2034-01-01' as timestamp), 45)

--14
create or replace procedure author_update(_id int8, _name text)
language plpgsql as $$
	begin 
		update authors
		set name = _name
		where id = _id;
	end;
$$;
call author_update(11, 'Benji')

--15
create or replace function in_between(_max float, _min float)
returns table(_title text, _price float)
language plpgsql as $$
	begin
		return query
		select title, price from books where price <= _max and price >= _min;
	end;
$$;

--16
create or replace function double_authors(name1 text, name2 text)
returns table(_title text)
language plpgsql as $$ 
	begin
		return query
		with combined as
		(select b.title, a.name from books b join authors a on b.author_id = a.id)
		
		select title from combined where name not in (name1,name2);
-- There is no need for BOOKS_AUTH 1 and 2, this is way more simple
end;
$$;


--17
CREATE OR REPLACE FUNCTION upsert(_title text, _release_date timestamp, _price float, _name text)
RETURNS int8
LANGUAGE plpgsql AS $$
DECLARE
    the_id int8 := 0;
    _author_id int8;
BEGIN
    SELECT id INTO _author_id FROM authors WHERE name = _name;
    
    SELECT b.id INTO the_id
    FROM books b
    JOIN authors a ON b.author_id = a.id
    WHERE b.title = _title AND a.name = _name;
    
    IF NOT FOUND THEN
        INSERT INTO books (title, release_date, price, author_id)
        VALUES (_title, _release_date, _price, _author_id)
        RETURNING id INTO the_id;
    ELSE
        UPDATE books
        SET title = _title, release_date = _release_date, price = _price, author_id = _author_id
        WHERE id = the_id;
    END IF;

    RETURN the_id;

END;
$$;

--18
create or replace function if_d(x text)
returns table(id int8, title text, t text)
language plpgsql as $$
	begin
		if x = 'D' then
			return query
			select b.id, b.title, release_date::text as t from books b;	
		else
			return query
			select b.id, b.title, a.name::text as t from books b join authors a on b.author_id = a.id;
		end if;
	end;
$$;

--19 bonus
create or replace function discount(_title text, _discount bool ,_percent int)
returns float 
language plpgsql as $$
	declare 
		_price float;
	begin 
		select price into _price from books where title = _title;
		if _discount then
			return _price - (_price * _percent / 100);
		elsif not _discount and _percent = 0 then
			return _price;
		else 
			raise NOTICE 'this is an error';

		end if;
end;
$$;


--20
create or replace function book_exists(book_name text)
returns int
language plpgsql as $$
	declare
		_id int8 = 0;
	begin 
		for i in 1..(select max(id) from books)
			loop
				if (select title from books where id = i) = book_name then
					_id = i;
				end if;
			end loop;
		return _id;
	end;
$$;
