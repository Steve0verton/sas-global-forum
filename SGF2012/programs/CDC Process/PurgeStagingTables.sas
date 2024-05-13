/***********************************************************/
/*   Code Written by:                                      */
/*      Stephen Overton  (stephen.overton@gmail.com)       */
/*                                                         */
/*   Purges staging tables using data retention period in  */
/*   DIM_TABLE control table.                              */
/***********************************************************/
libname sgf2012 base 'C:\SAS Projects\SGF2012\data';

proc sql;
  /** Get a list of all tables in a specified library using the SAS dictionary tables **/
  create table table_list as
    select
      tables.libname,
      tables.memname as tablename,
      control.data_retention_days,
      control.libref
    from dictionary.tables tables
    left join sgf2012.dim_table control on
      trim(tables.memname) = trim(control.physical_table_name) and
      trim(tables.LIBNAME) = trim(control.libref)
    where
      control.dw_location = 'Staging'
  ;

  /** Get list of tables from desired schema or library **/
  select tablename into :table1-:table99999 from table_list;

  /** Get data retention thresholds from same list of tables **/
  select data_retention_days into :retention1-:retention99999 from table_list;

  /** Get how many tables are in the list to loop through **/
  select count(*) into :table_count from table_list;
quit;

/**Macro to loop through a single information map at a time and return all data fields and key data about the field**/
%macro PurgeTables;
	%do x=1 %to &table_count;
		proc sql;
      delete from sgf2012.&&table&x
      where last_update < intnx('dtday',datetime(),-&&retention&x);
    quit;
	%end;
%mend;

%PurgeTables;
