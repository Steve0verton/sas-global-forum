/**********************************************************/
/*   Code Written by:                                     */
/*      Stephen Overton  (stephen.overton@gmail.com)      */
/*                                                        */
/*   Builds a dataset for testing and demo purposes using */
/*   fake data in the SAS help library                    */
/**********************************************************/
libname sgf2012 base 'C:\SAS Projects\SGF2012\data'; 

data source_sales;
  set sashelp.pricedata(keep=date price regionname productline productname) ;
  format date mmddyy10. sales dollar22.2; 

  /** Make data more recent **/
  date = intnx('year',date,8);

  /** Sales conversion to higher numbers - uses 'Price' column **/
  multiply = (mod((_n_*11) / (3 * ranuni(_n_)),ranuni(_n_))*10) +100 ;
  if year(date) = 2010 then sales = (price * multiply )* 9.4 + 110;
  else if year(date) = 2009 then sales = (price * multiply )* 7.98 + 110;
  else if year(date) = 2008 then sales = (price * multiply )* 11.4 + 110;
  else if year(date) = 2007 then sales = (price * multiply )* 10+ 107;
  else if year(date) = 2006 then sales = (price * multiply )* 10.2 + 109;
  else if year(date) = 2005 then sales = (price * multiply )* 8 + 104;

  /** Cleanup variables **/
  drop multiply price;

run;  

/** Sort Data to add months properly **/
proc sort data=source_sales;
  by date productName;
run;

/** Load months using first. processing **/
data source_sales;
  set source_sales;
  by date productName;

  /** add in months **/
  month_num + 1;
  if month_num = 13 then month_num = 1;
  date = mdy(month_num,1,year(date));
  drop month_num;

run;

/** Sort again by date **/
proc sort data=source_sales;
  by date;
run;

/** Move data around for demo purposes **/
proc sql;
  /** Copy last month of data for test incremental month **/
  create table source_incoming_sales as
    select *
    from source_sales
    where date = (select max(date) from source_sales);

  /** Remove Last month from test data **/
  delete from source_sales
  where date = (select max(date) from source_sales);
quit;
