drop table if exists Offices cascade;
drop table if exists Employees cascade;

---------- QUESTION 2 ----------
create table Offices (
	office_id int primary key,
	building text not null,
	level int not null,
	room_number int not null,
	area int,
	unique (building, level, room_number)
);

create table Employees (
	emp_id int primary key,
	name text not null,
	office_id int not null,
	manager_id int,
	foreign key (manager_id) references Employees (emp_id) on update cascade,
	foreign key (office_id) references Offices (office_id) on update cascade
);

---------- END QUESTION 2 ----------

---------- QUESTION 3(a) ----------
drop table if exists Books, Customers, Carts, Purchase, Purchased_items cascade;

create table Books (
	isbn text primary key,
	title text not null,
	authors text not null,
	year integer,
	edition text not null check (edition in ('paperback', 'hardcover', 'ebook')),
	publisher text,
	number_pages integer check (number_pages > 0),
	price numeric check (price > 0)
);

create table Customers (
	cust_id integer primary key,
	name text not null,
	email text not null
); 

create table Carts (
	cust_id integer,
	isbn text,
	primary key (cust_id, isbn),
	foreign key (cust_id) references Customers (cust_id),
	foreign key (isbn) references Books (isbn)
);

create table Purchase (
	pid integer primary key,
	purchase_date date not null,
	cust_id integer not null,
	foreign key (cust_id) references Customers (cust_id)
);

create table Purchased_items (
	pid integer,
	isbn text,
	primary key (pid, isbn),
	foreign key (pid) references Purchase (pid),
	foreign key (isbn) references Books (isbn)
);

---------- END QUESTION 3(a) ----------

---------- QUESTION 3(b) ----------

create table Purchase (
	pid integer primary key,
	purchase_timestamp timestamp,
	cust_id integer not null,
	unique (purchase_timestamp, cust_id),
	foreign key (cust_id) references Customers (cust_id)
);
---------- END QUESTION 3(b) ----------

---------- QUESTION 3(c) ----------
drop table if exists Books cascade;

create table Books (
	isbn text primary key,
	title text not null,
	authors text not null,
	year integer,
	edition text not null check (edition in ('paperback', 'hardcover', 'ebook')),
	publisher text,
	number_pages integer check (number_pages > 0),
	price numeric check (price > 0),
	check ((edition <> 'hardcover') or (price >= 30)),
	check ((number_pages <= 1000) or (edition = 'ebook' or price >= 100)),
	check (((publisher <> 'Acme') or (year < 2010)) or (edition = 'ebook'))
);

insert into Books values 
('1000', 'Book1', 'Author1', 2000, 'hardcover', 'Publisher1', 100, 40);

select * from Books;
---------- END QUESTION 3(c) ----------

---------- QUESTION 3(d) ----------
drop table if exists Books, Customers, Carts, Purchase, Purchased_items cascade;

create table Books (
	isbn text primary key,
	title text not null,
	authors text not null,
	year integer,
	edition text not null check (edition in ('paperback', 'hardcover', 'ebook')),
	publisher text,
	number_pages integer check (number_pages > 0),
	price numeric check (price > 0)
);

create table Customers (
	cust_id integer primary key,
	name text not null,
	email text not null
); 

create table Carts (
	cust_id integer,
	isbn text,
	primary key (cust_id, isbn),
	foreign key (cust_id) references Customers (cust_id) on delete cascade on update cascade,
	foreign key (isbn) references Books (isbn) on delete cascade on update cascade
);

create table Purchase (
	pid integer primary key,
	purchase_date date not null,
	cust_id integer not null,
	foreign key (cust_id) references Customers (cust_id) on delete cascade on update cascade
);

create table Purchased_items (
	pid integer,
	isbn text,
	primary key (pid, isbn),
	foreign key (pid) references Purchase (pid) on delete cascade on update cascade,
	foreign key (isbn) references Books (isbn) on delete set default on update cascade
);
---------- END QUESTION 3(d) ----------