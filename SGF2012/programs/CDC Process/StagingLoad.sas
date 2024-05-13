/**************************************************************/
/*   Code Written by:                                         */
/*      Stephen Overton  (stephen.overton@gmail.com)          */
/*                                                            */
/*   Loads staging table and normalizes time for CDC process. */
/*   Updates control table after adding data.                 */
/**************************************************************/
libname sgf2012 base 'C:\SAS Projects\SGF2012\data'; 

/** Add last_key_date_extracted timestamp on the staging data to normalize time for CDC **/
proc sql;
  /** Get last date extracted from source to join to incoming data **/
  create table last_key_date_extracted as
    select last_key_date_extracted
    from sgf2012.dim_source
    where source_desc = 'SOURCE_SALES';

  /** Create temporary table with incoming data to append in next step **/
  create table stg_insert_sales as
    select
      source.*,
      datetime() as last_update format datetime22.
    from
      source_sales source,
      last_key_date_extracted control
    where
      dhms(source.date,0,0,0) > control.last_key_date_extracted;

  /** Get count of incoming records for macro logic later **/
  select count(*) into :stg_sales_cnt from stg_insert_sales;

  /** Get last date in source data to use for control table **/
  select dhms(max(date),0,0,0) format=datetime. into :last_key_date_extracted from stg_insert_sales;
quit;

%macro load_data;
  /** If incoming data exists, add to target table and update control tables **/
  %if &stg_sales_cnt > 0 %then %do;
    /** Add data to staging table **/
    proc append base=sgf2012.stg_sales data=stg_insert_sales; run;

    /** Update Control Tables After Adding Data **/
    %update_control(SOURCE_SALES,&last_key_date_extracted,SGF2012,STG_SALES);
  %end;
%mend load_data;

%load_data;