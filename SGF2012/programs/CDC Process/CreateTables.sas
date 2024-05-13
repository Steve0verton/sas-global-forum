/***********************************************************/
/*   Code Written by:                                      */
/*      Stephen Overton  (stephen.overton@gmail.com)       */
/*                                                         */
/*   Builds datasets for demonstrating change data capture */
/*   process at SAS Global Forum 2012.                     */
/***********************************************************/
libname sgf2012 base 'C:\SAS Projects\SGF2012\data';

/** Define table dimension with sample data **/
data sgf2012.dim_table;
  length
    table_key 8
    dw_location
    libref
    physical_table_name
    table_name $50
    last_update 8
    data_retention_days 8
  ;
  format
    table_key 16.0
    dw_location
    libref
    physical_table_name
    table_name $50.
    last_update datetime22.
    data_retention_days 16.0
  ;

  /** Initialize Values **/
  table_key = 0;
  dw_location = 'Data Warehouse';
  libref = 'SGF2012';
  physical_table_name = 'FACT_SALES';
  table_name = 'Sales Fact Table';
  output;

  table_key = 1;
  dw_location = 'Staging';
  libref = 'SGF2012';
  physical_table_name = 'STG_SALES';
  table_name = 'Sales Staging Table';
  data_retention_days = 90;
  output;

run;

/** Define source dimension with sample data **/
data sgf2012.dim_source;
  length
    source_key 8
    source_type
    source_library
    source_desc
    key_date_column $50
    last_key_date_extracted
    last_extraction 8
  ;
  format
    source_key 16.0
    source_type
    source_library
    source_desc
    key_date_column $50.
    last_key_date_extracted
    last_extraction datetime22.
  ;

  /** Initialize Values **/
  source_key = 0;
  source_type = 'SAS Dataset';
  source_library = 'WORK';
  source_desc = 'SOURCE_SALES';
  key_date_column = 'date';
  output;

  source_key = 1;
  source_type = 'SAS Dataset';
  source_library = 'SGF2012';
  source_desc = 'STG_SALES';
  key_date_column = 'last_update';
  output;

run;

proc sql;
  /** Define fact table **/
  create table sgf2012.fact_sales (
    location_key num,
    date_key date format=mmddyy10.,
    sales num format=dollar22.2
  );

  /** Define staging table **/
  create table sgf2012.stg_sales (
    date date format=mmddyy10.,
    regionName char(20),
    productLine char(20),
    productName char(20),
    sales num format=dollar22.2,
    last_update date format=datetime22.
  );
quit;

/** Macro to Update Control Tables After Adding Data **/
%macro update_control(source,last_key_date_extracted,target_library,target);
/* source = Data source extracted                               */
/* last_key_date_extracted = Last identifying date extracted    */
/* target = Target data source                                  */
/* target_library = Target library of data source updated       */
proc sql;
  update sgf2012.dim_source
  set last_key_date_extracted=round("&last_key_date_extracted"dt,'0:00:01'T)
  where source_desc = "&source";

  update sgf2012.dim_source
  set last_extraction=round(datetime(),'0:00:01'T)
  where source_desc = "&source";

  update sgf2012.dim_table
  set last_update=datetime()
  where physical_table_name = "&target" and libref = "&target_library";
quit;
%mend update_control;