LIBNAME defiant POSTGRES  INSERTBUFF=1000  READBUFF=1000  DATABASE=dev 
   PRESERVE_COL_NAMES=YES  PRESERVE_TAB_NAMES=YES  DBCOMMIT=1000 
   SERVER=defiant  SCHEMA=public  USER=enterprise  PASSWORD="{SAS002}1D5793391C1104E20E3CF4CD2A793E2B" ;

proc sql threads;
  create table SGF2013.fact_candy_sales_segment as
    select * from defiant.fact_candy_sales where ranuni(today()) between .45 and .55
  ;
quit; 
