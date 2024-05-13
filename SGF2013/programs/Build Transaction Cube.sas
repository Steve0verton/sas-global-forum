/*************************************************************/
/*   Code Written by:                                        */
/*      Stephen Overton  (soverton@overtontechnologies.com)  */
/*                                                           */
/*   Builds a cube for testing and demo purposes using       */
/*   fake transaction data                                   */
/*************************************************************/
LIBNAME postgres ODBC  DBCOMMIT=10000  READBUFF=20000  INSERTBUFF=20000  DATASRC=dev  SCHEMA=public ;

proc olap
   CUBE                   = "/Projects/SGF2013/Cubes/Transaction Summary"
   DELETE;

   METASVR
      HOST        = "vSAS"
      PORT        = 8561
      OLAP_SCHEMA = "SASApp - OLAP Schema";

RUN;

PROC OLAP
   CUBE                   = "/Projects/SGF2013/Cubes/Transaction Summary"
   PATH                   = '/projects/SGF2013/cubes'
   DESCRIPTION            = 'Candy sales demo cube for SGF2013'
   FACT                   = postgres.fact_transactions
;

   METASVR
      HOST        = "vSAS"
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

   PROPERTY 'Gross Margin'n
      level=Product
      column=GrssMrgn
      hierarchy=(Products)
      caption='Gross Margin'
      description='Gross Margin'
   ;

   PROPERTY 'Retail Price'n
      level=Product
      column=Retail_Price
      hierarchy=(Products)
      caption='Retail Price'
      description='Retail Price'
   ;

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
   DEFINE SET "[Candy Sales].[Rolling 12 Months]" as "Tail([Time].[YMD].[Month].AllMembers ,12)";
   DEFINE SET "[Candy Sales].[Rolling 24 Months]" as "Tail([Time].[YMD].[Month].AllMembers ,24)";
   DEFINE SET "[Candy Sales].[Rolling 36 Months]" as "Tail([Time].[YMD].[Month].AllMembers ,36)";

   /* Rolling time aggregate members */
   DEFINE MEMBER "[Candy Sales].[Time].[YMD].[All Years].[Rolling 12 Months]" as 'Aggregate( Tail([Time].[YMD].[Month].AllMembers ,12) )';
   DEFINE MEMBER "[Candy Sales].[Time].[YMD].[All Years].[Rolling 24 Months]" as 'Aggregate( Tail([Time].[YMD].[Month].AllMembers ,24) )';
   DEFINE MEMBER "[Candy Sales].[Time].[YMD].[All Years].[Rolling 36 Months]" as 'Aggregate( Tail([Time].[YMD].[Month].AllMembers ,36) )';

run;
