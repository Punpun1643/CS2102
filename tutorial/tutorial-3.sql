---------- QUESTION 1(b) DESIGN A ----------
drop table if exists Parts, Projects, Suppliers, Supplies cascade;

create table Parts (
	pid integer primary key,
	pname text
);

create table Projects (
	jid integer primary key,
	jname text
);

create table Suppliers (
	sid integer primary key,
	sname text
);

create table Supplies (
	pid integer,
	jid integer,
	sid integer,
	qty integer,
	price numeric,
	t_date date,
	primary key (pid, jid, sid),
	foreign key (pid) references Parts (pid),
	foreign key (jid) references Projects (jid), 
	foreign key (sid) references Suppliers (sid)
);

---------- END QUESTION 1(b) DESIGN A ----------

---------- QUESTION 1(b) DESIGN B ----------
drop table if exists Parts, Projects, Suppliers, Uses, Sells, Supplies cascade;

create table Parts (
	pid integer primary key,
	pname text
);

create table Projects (
	jid integer primary key,
	jname text
);

create table Suppliers (
	sid integer primary key,
	sname text
);

create table Uses (
	pid integer,
	jid integer,
	qty numeric,
	primary key (pid, jid),
	foreign key (pid) references Parts (pid),
	foreign key (jid) references Projects (jid)
);

create table Sells (
	pid integer,
	sid integer,
	price numeric,
	primary key (pid, sid),
	foreign key (pid) references Parts (pid),
	foreign key (sid) references Suppliers (sid)
);

create table Supplies (
	jid integer,
	sid integer,
	s_date date,
	primary key (jid, sid),
	foreign key (jid) references Projects (jid),
	foreign key (sid) references Suppliers (sid)
);
---------- END QUESTION 1(b) DESIGN B ----------

---------- QUESTION 1(b) DESIGN C ----------
drop table if exists Parts, Projects, Suppliers, Uses, Supplies cascade;

create table Parts (
	pid integer primary key,
	pname text
);

create table Projects (
	jid integer primary key,
	jname text
);

create table Suppliers (
	sid integer primary key,
	sname text
);

create table Uses (
	pid integer,
	jid integer,
	primary key (pid, jid),
	foreign key (pid) references Parts (pid),
	foreign key (jid) references Projects (jid)
);

create table Supplies (
	pid integer,
	jid integer,
	sid integer,
	s_date date,
	qty integer,
	price numeric,
	primary key (pid, jid, sid),
	foreign key (pid, jid) references Uses (pid, jid),
	foreign key (sid) references Suppliers (sid)
);
---------- END QUESTION 1(b) DESIGN C ----------

---------- QUESTION 2(a) ----------
drop table if exists A, B, C, D, T, S, R cascade;

create table A (
	a1 integer primary key,
	a2 integer
);

create table B (
	b1 integer primary key,
	b2 integer
);

create table C (
	c1 integer primary key,
	c2 integer
);

create table D (
	d1 integer primary key,
	d2 integer
);

create table R (
	a1 integer,
	b1 integer,
	r1 integer,
	primary key (a1, b1),
	foreign key (a1) references A,
	foreign key (b1) references B
);

create table S (
	a1 integer,
	b1 integer,
	c1 integer,
	s1 integer,
	primary key (a1, b1, c1),
	foreign key (c1) references C,
	foreign key (a1, b1) references R
);

create table T (
	a1 integer,
	b1 integer,
	c1 integer,
	d1 integer,
	t1 integer,
	primary key (a1, b1, c1, d1, t1),
	foreign key (a1, b1, c1) references S,
	foreign key (d1) references D
);
---------- END QUESTION 2(a) ----------

---------- QUESTION 2(b) ----------
drop table if exists A, B, C, D, E, F cascade;

create table A (
	a1 integer primary key,
	a2 integer
);

create table B (
	a1 integer primary key,
	b1 integer,
	foreign key (a1) references A on delete cascade
);

create table C (
	a1 integer primary key,
	c1 integer,
	foreign key (a1) references A on delete cascade
);

create table D (
	a1 integer primary key,
	d1 integer,
	foreign key (a1) references B on delete cascade,
	foreign key (a1) references C on delete cascade
);

create table E (
	a1 integer primary key,
	e1 integer,
	foreign key (a1) references C on delete cascade
);

create table F (
	a1 integer primary key,
	f1 integer,
	foreign key (a1) references C on delete cascade
);
---------- END QUESTION 2(b) ----------
---------- QUESTION 2(c) ----------
create table A (
	a1 integer primary key,
	a2 integer
);

create table B (
	a1 integer,
	b1 integer,
	b2 integer,
	primary key (a1, b1),
	foreign key (a1) references A on delete cascade
);

create table C (
	a1 integer,
	b1 integer,
	c1 integer,
	c2 integer,
	primary key (a1, b1, c1),
	foreign key (a1, b1) references B on delete cascade
);
---------- END QUESTION 2(c) ----------