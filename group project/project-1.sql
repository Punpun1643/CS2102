CREATE TABLE Users(
    email VARCHAR(100) PRIMARY KEY,
    uname VARCHAR(100) NOT NULL,
    verified BOOLEAN NOT NULL DEFAULT FALSE,
    date_of_verification DATE,
    credit_card_number_1 INTEGER NOT NULL,
    credit_card_number_2 INTEGER,
    CHECK (credit_card_number_1 IS DISTINCT FROM credit_card_number_2),
    CHECK (CASE WHEN verified IS TRUE THEN date_of_verification IS NOT NULL END)
);

CREATE TABLE Backers(
    email VARCHAR(100) PRIMARY KEY REFERENCES Users ON DELETE CASCADE,
    country_name VARCHAR(100) NOT NULL,
    street_name VARCHAR(100) NOT NULL,
    house_number VARCHAR(100) NOT NULL,
    zip_code INTEGER NOT NULL
);

CREATE TABLE Creators(
    email VARCHAR(100) PRIMARY KEY REFERENCES Users ON DELETE CASCADE,
    country_of_origin VARCHAR(100) NOT NULL
);

CREATE TABLE Projects(
    pid SERIAL PRIMARY KEY,
    email VARCHAR(100) NOT NULL REFERENCES Creators,
    pname VARCHAR(100) NOT NULL,
    deadline DATE NOT NULL,
    funding_goal NUMERIC NOT NULL,
    UNIQUE (pid, deadline)
);

CREATE TABLE Reward_levels(
    rname VARCHAR(100),
    pid SERIAL REFERENCES Projects ON DELETE CASCADE,
    amount_required NUMERIC NOT NULL,
    PRIMARY KEY (rname, pid),
    UNIQUE (rname, pid, amount_required),
    CHECK (amount_required > 0)
);

CREATE TABLE Creates(
    date_created DATE NOT NULL,
    pid SERIAL PRIMARY KEY REFERENCES Projects,
    email VARCHAR(100) NOT NULL REFERENCES Creators
);

CREATE TABLE Updates(
    datetime_updated TIMESTAMP,
    content TEXT NOT NULL,
    pid SERIAL REFERENCES Projects,
    email VARCHAR(100) NOT NULL REFERENCES Backers,
    PRIMARY KEY (pid, datetime_updated)
);

CREATE TABLE Funds(
    amount_funded NUMERIC NOT NULL,
    date_funded DATE NOT NULL,
    email VARCHAR(100) REFERENCES Backers,
    pid SERIAL,
    rname VARCHAR(100) NOT NULL,
    amount_required NUMERIC NOT NULL,
    deadline DATE NOT NULL,
    FOREIGN KEY (pid, deadline) REFERENCES Projects (pid, deadline),
    FOREIGN KEY (rname, pid, amount_required) REFERENCES Reward_levels (rname, pid, amount_required) ON DELETE CASCADE,
    PRIMARY KEY (email, pid),
    UNIQUE (email, pid, amount_funded),
    CHECK (amount_funded >= amount_required),
    CHECK (date_funded < deadline)
);

CREATE TABLE Employees(
    eid SERIAL PRIMARY KEY,
    ename VARCHAR(100) NOT NULL,
    monthly_salary NUMERIC NOT NULL,
    CHECK (monthly_salary > 0)
);

CREATE TABLE Refunds(
    amount_refunded NUMERIC NOT NULL,
    email VARCHAR(100) REFERENCES Backers,
    pid SERIAL NOT NULL,
    deadline DATE NOT NULL,
    eid SERIAL REFERENCES Employees,
    date_of_request DATE NOT NULL,
    status VARCHAR(8),
    date_finish_processing DATE,
    amount_funded NUMERIC NOT NULL,
    FOREIGN KEY (email, pid, amount_funded) REFERENCES Funds (email, pid, amount_funded),
    FOREIGN KEY (pid, deadline) REFERENCES Projects (pid, deadline),
    PRIMARY KEY (email, pid), 
    CHECK ((status IN ('Approved', 'Rejected') AND date_finish_processing IS NOT NULL AND eid IS NOT NULL) OR
        (status IS NULL AND date_finish_processing IS NULL)
    ),
    CHECK (amount_refunded = amount_funded),
    CHECK (CASE WHEN date_of_request > deadline + 90 THEN status = 'Rejected' END)
);

--DROP SCHEMA public CASCADE;