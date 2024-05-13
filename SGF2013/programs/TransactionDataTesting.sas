LIBNAME postgres ODBC  READBUFF=30000 DATASRC=dev  SCHEMA=public;

proc sql;
  create table out as
    select
      transaction_date as date,
      count(transaction_key)
    from postgres.fact_transactions
    group by monthyear
  ;
quit;

data test;
 set out;
 run;
