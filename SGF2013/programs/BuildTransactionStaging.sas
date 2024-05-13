LIBNAME postgres ODBC  DBCOMMIT=10000  READBUFF=10000  INSERTBUFF=10000  DATASRC=dev  SCHEMA=public CONNECTION=UNIQUE;

proc sql threads;
  create table accounts as
    select party_account_key from postgres.dim_party_account where ranuni(today()) between .3 and .7
  ;
quit; 

data postgres.stg_fact_transactions;
  length transaction_type_key party_account_key location_key transaction_date transaction_amount 8;
  set accounts;

  do transaction_date = '01JUN2011'd to '31DEC2012'd;

  /* Create a couple random transactions in a given day for each account */
  do t = 1 to (round(rand("Uniform")*4)+1);
    transaction_type_key = (round(rand("Uniform")*12) + 1);
    location_key = (round(rand("Uniform")*19999) + 1);
    transaction_amount = (round(rand("Uniform")*100) + round(rand("Uniform"),.01));
    output;
  end;
  /* Create a random set of suspicious high transactions 10% of the time each day */
  if rand('BERN',.1)=1 then do t = 1 to (round(rand("Uniform")*2)+1);
    transaction_type_key = (round(rand("Uniform")*12) + 1);
    location_key = (round(rand("Uniform")*19999) + 1);
    transaction_amount = ((round(rand("Uniform")*30000) + 10000) + round(rand("Uniform"),.01));
    output;
  end;
  /* Create suspicious very high transaction data 5 percent of the time each day */
  if rand('BERN',.05)=1 then do;
    transaction_type_key = (round(rand("Uniform")*12) + 1);
    location_key = (round(rand("Uniform")*19999) + 1);
    transaction_amount = ((round(rand("Uniform")*500000) + 50000) + round(rand("Uniform"),.01));
    output;
  end;

  end;
  drop t;
run;
