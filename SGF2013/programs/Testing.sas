LIBNAME postgres ODBC  DBCOMMIT=100000  READBUFF=30000  INSERTBUFF=30000  DATASRC=dev  SCHEMA=public ;

proc sql;
  create table countsbydate as
    select
      transaction_date format=mmddyy10. as date,
      count(transaction_key) as count
    from postgres.fact_transactions
  ;
quit;

proc options; run;
