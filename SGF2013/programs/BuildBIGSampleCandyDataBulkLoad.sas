/*------------------------------------------------------------------------------------------
  PROGRAMMER   : Stephen Overton (SAS Institute Partner) (soverton@overtontechnologies.com)
  PURPOSE      : Build sample data for SGF13 
|-----------------------------------------------------------------------------------------*/
LIBNAME defiant POSTGRES  INSERTBUFF=1000  READBUFF=1000  DATABASE=dev 
   PRESERVE_COL_NAMES=YES  PRESERVE_TAB_NAMES=YES  DBCOMMIT=1000 
   SERVER=defiant  SCHEMA=public  USER=enterprise  PASSWORD="{SAS002}1D5793391C1104E20E3CF4CD2A793E2B" ;

%let syscc=0;

/**** Build dimension tables ****/
data defiant.dim_candy_customers;
  set egdata.candy_customers(rename=(Name=Customer));

  /* Add Regional VPs */
  if Region = 'Central' then RegionVP = 'Smedley Snodgrass';
  else if Region = 'East' then RegionVP = 'Chuck Norris';
  else if Region = 'West' then RegionVP = 'Wesley Snipes';

  /* Add Account Managers */
  if Customer = 'Bulls Eye Emporium' then Account_Manager = 'Geordi La Forge';
  else if Customer = 'Floor Mart' then Account_Manager = 'William Riker';
  else if Customer = 'Wholesalers R Us' then Account_Manager = 'Tasha Yar';
  else if Customer = 'Harry Koger' then Account_Manager = 'Beverly Crusher';
  else if Customer = 'Land of Fun' then Account_Manager = 'Jean-Luc Picard';
  else if Customer = 'Super Low Wholesaler' then Account_Manager = 'Worf';
  else if Customer = 'Toys 4 U' then Account_Manager = 'Data';
  else if Customer = 'Nile Online' then Account_Manager = 'Deanna Troi';
run;

data defiant.dim_candy_products;
  set egdata.candy_products;
  Plant = PrimPlnt;
  drop PrimPlnt;
run;

/** Manually add primary key for both dimensions in postgres **/
/** Define fact table in postgres and primary key and foreign keys **/

data stg_fact_candy_sales (bufsize=256K);
  length product_key order_date customer_key sales_person_key units sale_amount 8;

  /* Create random data */
  do order_date = '01JAN2005'd to '31DEC2010'd;
    do x = 1 to (round(rand("Uniform")*1000)+700);
      product_key = round(rand("Uniform")*15) + 1;
      customer_key = round(rand("Uniform")*7) + 1;
      sales_person_key = round(rand("Uniform")*2) + 1;
      units = round(rand("Uniform")*100);
      sale_amount = round(rand("Uniform")*1000);
      output;
    end;
  end;
  drop x;
run;

/* Add PK */
data stg_fact_candy_sales (bufsize=256K);
  order_key = _N_;
  set stg_fact_candy_sales;
run;

%errorcheck;
/* Insert into fact table */
proc append base=defiant.fact_candy_sales
  ( bulkload=yes
    bl_datafile="/tmp/data" 
    bl_logfile="/tmp/bulkload_log" 
    BL_LOAD_METHOD=APPEND
  ) 
  data=stg_fact_candy_sales; 
run;

/*proc sql buffersize=1M;*/
/*  insert into defiant.fact_candy_sales*/
/*    select * from stg_fact_candy_sales;*/
/*quit;*/
