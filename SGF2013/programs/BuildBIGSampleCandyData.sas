/*------------------------------------------------------------------------------------------
  PROGRAMMER   : Stephen Overton (SAS Institute Partner) (soverton@overtontechnologies.com)
  PURPOSE      : Build sample data for SGF13 
|-----------------------------------------------------------------------------------------*/
LIBNAME defiant POSTGRES  INSERTBUFF=1000  READBUFF=1000  DATABASE=dev 
   PRESERVE_COL_NAMES=YES  PRESERVE_TAB_NAMES=YES  DBCOMMIT=1000 
   SERVER=defiant  SCHEMA=public  USER=enterprise  PASSWORD="{SAS002}1D5793391C1104E20E3CF4CD2A793E2B" ;

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

data defiant.dim_sales_person;
  length sales_person_key 8 sales_person_name $40 sales_person_user_id $10;

  sales_person_key = 1;
  sales_person_name = 'Larry Page';
  sales_person_user_id = 'sas';
  output;

  sales_person_key = 2;
  sales_person_name = 'Sergey Brin';
  sales_person_user_id = 'sasdemo';
  output;

  sales_person_key = 3;
  sales_person_name = 'Bill Gates';
  sales_person_user_id = 'sastest';
  output;

run;

/** Manually add primary key for both dimensions in postgres **/

/** Define fact table in postgres and primary key and foreign keys **/

/**** Generate ~1 billion records of data ****/
%macro generate_sales_data;
%let last_key = 0;
%put Starting to loop through days;
/* Create data one day at a time for 1850 days */
%do x = 0 %to 1850;
  data stg_fact_candy_sales;
    length product_key customer_key units sale_amount 8;

    /* Create random data */
    do x = 1 to (round(rand("Uniform")*10000)+540000);
      product_key = round(rand("Uniform")*15) + 1;
      customer_key = round(rand("Uniform")*7) + 1;
      units = round(rand("Uniform")*100);
      sale_amount = round(rand("Uniform")*1000);

      output;
    end;
    drop x;
  run;

  %put Beginning Insertion into Fact Table;
  %put Last transaction key: &last_key;
  proc sql threads;
    insert into defiant.fact_candy_sales
      select
        monotonic() + &last_key as order_key,
        product_key,
        ('01JAN2005'd + &x) as order_date,
        customer_key,
        units,
        sale_amount
      from stg_fact_candy_sales
    ;

    select max(order_key) into :last_key from defiant.fact_candy_sales;

    %put Cleaning up workspace;
    drop table stg_fact_candy_sales;
  quit;

  %put Done with iteration for &x days from Jan 1, 2005;

%end;
%mend generate_sales_data;

%generate_sales_data;
