/**********************************************************/
/*   Code Written by:                                     */
/*      Stephen Overton  (stephen.overton@gmail.com)      */
/*                                                        */
/*   Builds a cube using the divide and conquer technique */
/*   to load large volumes of data.  Cube is for testing  */
/*   and demo purposes using fake data in the EG Sample   */
/*   library.                                             */
/**********************************************************/
%let cube = /Projects/SGF2012/Cubes/Candy Sales;

%put ****** DIVIDE source data into segments to load ******;
proc sql;
  /* Years are used as segments to load cube. Get from fact table. */
  create table all_segments as
    select distinct year(date) as year from SGF2012.FACT_CANDY_SALES;
  /* select the max year to load initially */
  create table initial_segment as
    select * from all_segments where year = (select max(year) from all_segments) order by year;
  create table remaining_segments as
    select * from all_segments where year ^= (select max(year) from all_segments) order by year desc;
quit;
proc sql;
  /* define initial segment */
  select year into :initial_segment from initial_segment;
  /* insert segments into macro list to interate through */
  select year into :segment1 - :segment99999 from remaining_segments;
  /* get the number of records for a counter for loop */
  select count(year) into :segment_count from remaining_segments;
quit;
%put Segments to loop through &segment_count;

%put ****** DEFINE views of segments ******;
proc sql;
  create view SGF2012.FACT_CANDY_SALES_INITIAL_VIEW as
    select * from SGF2012.FACT_CANDY_SALES
    where year(date) = &initial_segment;
  create view SGF2012.FACT_CANDY_SALES_SEGMENT_VIEW as
    select * from SGF2012.FACT_CANDY_SALES
    where year(date) = &segment1;
quit;

/** Ensure segment views exist in metadata for OLAP server  **/
libname _temp meta repname="Foundation" library="SGF2012" metaout=data;
proc metalib;
  omr (library="SGF2012"
  metarepository="Foundation");
  select("FACT_CANDY_SALES_INITIAL_VIEW");
  update_rule=(delete);
  report;
run;
proc metalib;
  omr (library="SGF2012"
  metarepository="Foundation");
  select("FACT_CANDY_SALES_SEGMENT_VIEW");
  update_rule=(delete);
  report;
run;
libname _temp clear;

%put ****** START cube build process ******;
/** delete existing cube first **/
proc olap
   CUBE                   = "&cube"
   DELETE;

   METASVR
      HOST        = "&SYSHOSTNAME"
      PORT        = 8561
      OLAP_SCHEMA = "SASApp - OLAP Schema";

run;

%put ****** LOAD cube for snapshot = &initial_segment ******;
/** Build cube with initial segment of source data **/
proc olap
   CUBE                   = "&cube"
   PATH                   = 'D:\Projects\SGF2012\cubes'
   DESCRIPTION            = 'Candy sales demo cube for SGF2012'
   FACT                   = SGF2012.FACT_CANDY_SALES_INITIAL_VIEW
;

   METASVR
      HOST        = "&SYSHOSTNAME"
      PORT        = 8561
      OLAP_SCHEMA = "SASApp - OLAP Schema";

   DIMENSION Products
      CAPTION          = 'Product'
      SORT_ORDER       = ASCENDING
      DIMTBL           = SGF2012.DIM_CANDY_PRODUCTS
      DIMKEY           = ProdID
      FACTKEY          = ProdID
      HIERARCHIES      = ( FullProducts Products );

      HIERARCHY FullProducts 
         ALL_MEMBER = 'All Products'
         CAPTION    = 'Category > Subcategory > Product'
         LEVELS     = ( Category Subcategory Product )
         DEFAULT;

      HIERARCHY Products 
         ALL_MEMBER = 'All Products'
         CAPTION    = 'Products'
         LEVELS     = ( Product );

      LEVEL Category
         CAPTION        =  'Category'
         SORT_ORDER     =  ASCENDING;

      LEVEL Subcategory
         CAPTION        =  'Subcategory'
         SORT_ORDER     =  ASCENDING;

      LEVEL Product
         CAPTION        =  'Product'
         SORT_ORDER     =  ASCENDING;

    DIMENSION Time
      CAPTION          = 'Time'
      TYPE             = TIME
      SORT_ORDER       = ASCENDING
      HIERARCHIES      = ( YMD YQMD MonthYear );

      HIERARCHY YMD 
         ALL_MEMBER = 'All Years'
         CAPTION    = 'Year > Month > Date'
         LEVELS     = ( Year Month Date )
         DEFAULT;

      HIERARCHY YQMD 
         ALL_MEMBER = 'All Years'
         CAPTION    = 'Year > Qtr > Month > Date'
         LEVELS     = ( Year Quarter Month Date );

      HIERARCHY MonthYear 
         ALL_MEMBER = 'All Years'
         CAPTION    = 'Month Year'
         LEVELS     = ( 'Month Year'n );

      LEVEL Year
         COLUMN         =  Date
         FORMAT         =  YEAR4.
         TYPE           =  YEAR
         CAPTION        =  'Year'
         SORT_ORDER     =  ASCENDING;

      LEVEL Month
         COLUMN         =  Date
         FORMAT         =  MONNAME3.
         TYPE           =  MONTHS
         CAPTION        =  'Month'
         SORT_ORDER     =  ASCENDING;

      LEVEL Date
         FORMAT         =  mmddyy10.
         TYPE           =  DAYS
         CAPTION        =  'Date'
         SORT_ORDER     =  ASCENDING;

      LEVEL Quarter
         COLUMN         =  Date
         FORMAT         =  QTR1.
         TYPE           =  QUARTERS
         CAPTION        =  'Quarter'
         SORT_ORDER     =  ASCENDING;

      LEVEL 'Month Year'n
         COLUMN         =  Date
         FORMAT         =  MONYY7.
         TYPE           =  MONTHS
         CAPTION        =  'Month Year'
         SORT_ORDER     =  ASCENDING;

   DIMENSION Customer
      CAPTION          = 'Customer'
      SORT_ORDER       = ASCENDING
      DIMTBL           = SGF2012.DIM_CANDY_CUSTOMERS
      DIMKEY           = CustID
      FACTKEY          = CustID
      HIERARCHIES      = ( Customer CustomerTypes 'Org Structure'n  );

      HIERARCHY 'Org Structure'n 
         ALL_MEMBER = 'All Regional VPs'
         CAPTION    = 'Region VP > AM > Customers'
         LEVELS     = ( 'Region VP'n 'Account Manager'n Customers )
         DEFAULT;

      HIERARCHY Customer
         ALL_MEMBER = 'All Customers'
         CAPTION    = 'Customer > Region VP > AM'
         LEVELS     = ( Customers 'Region VP'n 'Account Manager'n );

      HIERARCHY CustomerTypes 
         ALL_MEMBER = 'All Customers'
         CAPTION    = 'Type > Customer'
         LEVELS     = ( Type Customers);

      LEVEL Customers
         CAPTION        =  'Customer'
         COLUMN         =  Customer
         SORT_ORDER     =  ASCENDING;

      LEVEL Type
         CAPTION        =  'Type'
         SORT_ORDER     =  ASCENDING;

      LEVEL 'Account Manager'n
         CAPTION        =  'Account Manager'
         COLUMN         =  Account_Manager
         SORT_ORDER     =  ASCENDING;

      LEVEL 'Region VP'n
         CAPTION        =  'Region VP'
         COLUMN         =  RegionVP
         SORT_ORDER     =  ASCENDING;

   DIMENSION Region
      CAPTION          = 'Region'
      SORT_ORDER       = ASCENDING
      DIMTBL           = SGF2012.DIM_CANDY_CUSTOMERS
      DIMKEY           = CustID
      FACTKEY          = CustID
      HIERARCHIES      = ( Region );

      HIERARCHY Region 
         ALL_MEMBER = 'All Regions'
         CAPTION    = 'Region'
         LEVELS     = ( Regions )
         DEFAULT;

      LEVEL Regions
         CAPTION        =  'Region'
         COLUMN         =  Region
         SORT_ORDER     =  ASCENDING;

   MEASURE 'Sales Amount'n
      STAT        = SUM
      COLUMN      = SalesAmt
      CAPTION     = 'Sales Amount'
      FORMAT      = DOLLAR22.
      DEFAULT;

   MEASURE 'Avg Sales'n
      STAT        = AVG
      COLUMN      = SalesAmt
      CAPTION     = 'Average Sales'
      FORMAT      = DOLLAR22.2;

   MEASURE 'Units Sold'n
      STAT        = SUM
      COLUMN      = Units
      CAPTION     = 'Units Sold'
      FORMAT      = comma18.;

   MEASURE 'Target Sales'n
      STAT        = SUM
      COLUMN      = Target
      CAPTION     = 'Target Sales'
      FORMAT      = DOLLAR22.;

   /* Rolling month sets */
   DEFINE SET "[Candy Sales].[Rolling 12 Months]" as "Tail([Time].[YM].[Month].AllMembers ,12)";
   DEFINE SET "[Candy Sales].[Rolling 24 Months]" as "Tail([Time].[YM].[Month].AllMembers ,24)";
   DEFINE SET "[Candy Sales].[Rolling 36 Months]" as "Tail([Time].[YM].[Month].AllMembers ,36)";

   /* Rolling time aggregate members */
   DEFINE MEMBER "[Candy Sales].[Time].[YM].[All Years].[Rolling 12 Months]" as 'Aggregate( Tail([Time].[YM].[Month].AllMembers ,12) )';
   DEFINE MEMBER "[Candy Sales].[Time].[YM].[All Years].[Rolling 24 Months]" as 'Aggregate( Tail([Time].[YM].[Month].AllMembers ,24) )';
   DEFINE MEMBER "[Candy Sales].[Time].[YM].[All Years].[Rolling 36 Months]" as 'Aggregate( Tail([Time].[YM].[Month].AllMembers ,36) )';

run;

/*** Macro to iterate through remaining segments and load cube ***/
%macro LoadSegmentsIntoCube;
/* incrementally load cube by updating a view in each step then incrementally adding data to the cube */
%do x=1 %to &segment_count;
  /* update view */
  %put ****** UPDATE View to Incrementally load cube for segment = &&segment&x ******;
  proc sql;
    create view SGF2012.FACT_CANDY_SALES_SEGMENT_VIEW as
      select * from SGF2012.FACT_CANDY_SALES
      where year(date) = &&segment&x
    ;
  quit;
 
  /* Incrementally update cube */
  %put ****** LOAD cube for snapshot = &&segment&x ******;
  proc olap
    CUBE                   = "&cube"
    DATA                   = SGF2012.FACT_CANDY_SALES_SEGMENT_VIEW
    ADD_DATA
    UPDATE_INPLACE
    IGNORE_MISSING_DIMKEYS = VERBOSE
    ;

   METASVR
      HOST        = "&SYSHOSTNAME"
      PORT        = 8561
      OLAP_SCHEMA = "SASApp - OLAP Schema";

    /*** IMPORTANT: Update this list if new dimensions are added ****/
    DIMENSION Products UPDATE_DIMENSION = MEMBERS;
    DIMENSION Time UPDATE_DIMENSION = MEMBERS;
    DIMENSION Customer UPDATE_DIMENSION = MEMBERS;
    DIMENSION Region UPDATE_DIMENSION = MEMBERS;

  run;

  %put ****** FINISH loading for snapshot = &&segment&x ******;
%end;
%mend LoadSegmentsIntoCube;

/** Execute macro **/
%LoadSegmentsIntoCube;

/*** Coalesce Aggregations ***/
proc olap
   CUBE                   = "&cube"
   COALESCE_AGGREGATIONS;

   METASVR
      HOST        = "&SYSHOSTNAME"
      PORT        = 8561
      OLAP_SCHEMA = "SASApp - OLAP Schema";

run;
