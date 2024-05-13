/**********************************************************/
/*   Code Written by:                                     */
/*      Stephen Overton  (stephen.overton@gmail.com)      */
/*                                                        */
/*   Builds a dataset for testing and demo purposes using */
/*   fake data in the SAS help library                    */
/**********************************************************/
libname sgf2012 base 'C:\SAS Projects\SGF2012\data';

/** Define and build fixed dimension table **/
proc sql;
  create table sgf2012.dim_location as
    select
      monotonic() as location_key,
      regionName,
      productLine,
      productName
    from(
      select distinct
        regionName,
        productLine,
        productName
      from
        sgf2012.stg_sales
      );
quit;

/** Get data prior to inserting into fact table **/
proc sql;
  /** Get last date extracted from source to join to incoming data **/
  create table last_key_date_extracted as
    select last_key_date_extracted
    from sgf2012.dim_source
    where source_desc = 'STG_SALES';

  create table fact_insert_sales as
    select
      location.location_key,
      stage.date as date_key,
      stage.sales
    from
      sgf2012.stg_sales stage
      /** Lookup location_key **/
      left join sgf2012.dim_location location on (
        trim(stage.regionName) = trim(location.regionName) and 
        trim(stage.productLine) = trim(location.productLine) and 
        trim(stage.productName) = trim(location.productName)
      )
      /** Merge Last Update to get timestamp to control flow of data **/
      ,last_key_date_extracted control
    where
      stage.last_update > control.last_key_date_extracted;

    /** Get count of incoming records for macro logic later **/
    select count(*) into :fact_sales_cnt from fact_insert_sales;

    /** Get last date in staging data to use for control table **/
    select max(last_update) format=datetime. into :last_key_date_extracted from sgf2012.stg_sales;
quit;

%macro load_data;
  /** If incoming data exists, add to target table and update control tables **/
  %if &fact_sales_cnt > 0 %then %do;
    /** Add data to staging table **/
    proc append base=sgf2012.fact_sales data=fact_insert_sales; run;

    /** Update Control Tables After Adding Data **/
    %update_control(STG_SALES,&last_key_date_extracted,SGF2012,FACT_SALES);
  %end;
%mend load_data;

%load_data;