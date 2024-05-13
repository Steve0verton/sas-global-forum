/*------------------------------------------------------------------------------------------
  PROGRAMMER   : Stephen Overton (SAS Institute Partner) (soverton@overtontechnologies.com)
  PURPOSE      : Build fake bank transactions for SGF13 
|-----------------------------------------------------------------------------------------*/
LIBNAME defiant POSTGRES  INSERTBUFF=1000  READBUFF=1000  DATABASE=dev 
   PRESERVE_COL_NAMES=YES  PRESERVE_TAB_NAMES=YES  DBCOMMIT=1000 
   SERVER=defiant  SCHEMA=public  USER=enterprise  PASSWORD="{SAS002}1D5793391C1104E20E3CF4CD2A793E2B" ;
/* For bulk loading (without buffering) */
/*LIBNAME defiant POSTGRES  DATABASE=dev  AUTOCOMMIT=YES*/
/*   PRESERVE_COL_NAMES=YES  PRESERVE_TAB_NAMES=YES */
/*   SERVER=defiant  SCHEMA=public  USER=enterprise  PASSWORD="{SAS002}1D5793391C1104E20E3CF4CD2A793E2B" ;*/

%dbug(level=2);
proc options; run;

/** Build Dimension Tables **/
/* Generate a ton of fake parties ****/
data party;
  do x = 1 to 2711000;
    party_name = "Party " || strip(put(x,$12.0));
    party_number = x + 1000;

    if (round(rand("Uniform")) = 1) then do;
      party_type = "Individual";
      naics_code = .;
    end;
    else do;
      party_type = "Business";
      /* Only NAICS codes within a certain area to make demo work */
      naics_code = round(rand("Uniform")*100)+44000;
    end;
    output;
  end;
  drop x;
run;

/* Add rows for accounts */
/* generate 2-5 accounts per party */
data party_account;
  set party;
  do x = 1 to (round(rand("Uniform")*4)+1); 
    account_open_date = '01JAN2000'd + round(rand("Uniform")*4000);
    output;
  end;
  drop x;
run;

/* Requires list of random names before running. Contains column for 'party_name' in RandomNames. */
data party;
  set SGF2013.RandomNames;
  party_number = _N_ + 1000000;

  if (round(rand("Uniform")) = 1) then do;
    party_type = "Individual";
    naics_code = .;
  end;
  else do;
    party_type = "Business";
    /** Only NAICS codes within a certain area to make demo work */
    naics_code = round(rand("Uniform")*100)+44000;
  end;

  drop firstName lastName first_name last_name;
run;
/** Add rows for accounts */
data party_account;
  set party;
  do x = 1 to (round(rand("Uniform")*4)+1); /* generate 2-5 accounts per party */
    account_open_date = '01JAN2000'd + round(rand("Uniform")*4000);
    output;
  end;
  drop x;
run;

/* Subset data if needed depending on how many parties/accounts needed */
proc sql threads;
  create table party_account2 as
    select * from party_account where ranuni(today()) between .47 and .53
  ;
quit; 

/* Add specific account details */
data dim_party_account;
  party_account_key = _N_;
  set party_account2;
  account_number = _N_ + 100000; 
  account_name = "ACCT-" || strip(put(account_number,$12.0));
run;

/**** Define Tables manually in Postgres database ****/

/** Insert into dimension in postgres */
proc sql threads;
  insert into defiant.dim_party_account
    select
      party_account_key,
      party_name,
      party_number,
      party_type,
      naics_code,
      account_name,
      account_number,
      account_open_date
    from dim_party_account
  ;
quit;

proc sql;
/*  drop table defiant.dim_transaction_type;*/
  create table defiant.dim_transaction_type
  (
    transaction_type_key  NUM,
    transaction_type      CHAR(10),
    transaction_category  CHAR(50)
  );
/*  Manually add primary key **/
quit;

proc sql;
  insert into defiant.dim_transaction_type values (1,'Credit','Cash Over the Counter');
  insert into defiant.dim_transaction_type values (2,'Debit','Cash Withdrawal');
  insert into defiant.dim_transaction_type values (3,'Credit','Electronic/ACH');
  insert into defiant.dim_transaction_type values (4,'Debit','Electronic/ACH');
  insert into defiant.dim_transaction_type values (5,'Credit','Wire');
  insert into defiant.dim_transaction_type values (6,'Debit','Wire');
  insert into defiant.dim_transaction_type values (7,'Credit','ATM');
  insert into defiant.dim_transaction_type values (8,'Debit','ATM');
  insert into defiant.dim_transaction_type values (9,'Debit','Check');
  insert into defiant.dim_transaction_type values (10,'Credit','Check Deposit');
  insert into defiant.dim_transaction_type values (11,'Credit','Night Drop');
  insert into defiant.dim_transaction_type values (12,'Credit','Lockbox');
  insert into defiant.dim_transaction_type values (13,'Credit','Courier');
quit;

/*************** Define fact table manually in postgres **/

/**** Generate a ton of transactions from Jun 1, 2010 - Dec 31, 2012 ****/
/* Get initial keys to generate data for */
proc sql threads;
  create table accounts as
    select party_account_key from defiant.dim_party_account where ranuni(today()) between .25 and .75
  ;
quit; 

/* Set macro start and end date and initialize primary key variable. */
data _null_;
  call symput('start_date',19223);
  call symput('end_date',19723);
  call symput('last_key',0);
run;

%let syscc=0;

/* macro to loop through each date */
%macro iterate;

%do tran_date = &start_date %to &end_date;
%put %str(NOTE: Calculating date: &tran_date);

%errorcheck;

/** Build in stages to prevent loading problems. Inserts 1 day at a time ~2.1 million per insert. */
data stg_fact_transactions (bufsize=1M);
  length transaction_type_key party_account_key location_key transaction_date transaction_amount 8;
  set accounts;
  transaction_date = &tran_date; 
  /* Create a couple random transactions in a given day for each account */
  do t = 1 to (round(rand("Uniform")*6)+1);
    transaction_type_key = (round(rand("Uniform")*12) + 1);
    location_key = (round(rand("Uniform")*19999) + 1);
    transaction_amount = (round(rand("Uniform")*100) + round(rand("Uniform"),.01));
    output;
  end;
  /* Create a random set of suspicious high transactions 5% of the time each day */
  if rand('BERN',.05)=1 then do t = 1 to (round(rand("Uniform")*2)+1);
    transaction_type_key = (round(rand("Uniform")*12) + 1);
    location_key = (round(rand("Uniform")*19999) + 1);
    transaction_amount = ((round(rand("Uniform")*30000) + 10000) + round(rand("Uniform"),.01));
    output;
  end;
  /* Create suspicious very high transaction data 2 percent of the time each day */
  if rand('BERN',.02)=1 then do;
    transaction_type_key = (round(rand("Uniform")*12) + 1);
    location_key = (round(rand("Uniform")*19999) + 1);
    transaction_amount = ((round(rand("Uniform")*500000) + 50000) + round(rand("Uniform"),.01));
    output;
  end;
  drop t;
run;

/* Add PK */
data stg_fact_transactions;
  transaction_key = &last_key + _N_;
  set stg_fact_transactions;
run;

%errorcheck;

/* Insert into fact table */
proc append base=defiant.fact_transactions 
  ( bulkload=yes
    bl_datafile="/tmp/data" 
    bl_logfile="/tmp/bulkload_log" 
    BL_LOAD_METHOD=APPEND
  ) 
  data=stg_fact_transactions; 
run;

proc sql threads;
  select max(transaction_key) into :last_key from defiant.fact_transactions ;
  %put Last transaction_key: &last_key;

  drop table stg_fact_transactions;
  
  /** Regenerate account keys to use */
  drop table accounts;
  create table accounts as
    select party_account_key from defiant.dim_party_account where ranuni(today()) between .3 and .7
  ;
quit; 

%end;

%mend iterate;
%iterate;

