LIBNAME defiant ODBC  DBCOMMIT=20000  READBUFF=20000  INSERTBUFF=20000  DATASRC=defiant  SCHEMA=public ;

/* Load data for locations */
proc sql;
  create table dim_location as
    select
      monotonic() as location_key,
      statecode as state,
      county,
      upcase(city) as city,
      pop as population
    from maps.uscity
  ;
quit;

filename transfer '/tmp/dim_location.cport';
proc cport data=dim_location file=transfer;
run;

proc cimport infile=transfer library=defiant memtype=data;
run;
