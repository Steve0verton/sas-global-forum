%dbug(level=2);

LIBNAME defiant ODBC READBUFF=1000 DATASRC=defiant SCHEMA=public;

data out;
  set defiant.fact_transactions;
run;
