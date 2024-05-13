/*------------------------------------------------------------------------------------------
  PROGRAMMER   : Stephen Overton (SAS Institute Partner) (soverton@zencos.com)
  PURPOSE      : Build candy sales cube for SGF13 
|-----------------------------------------------------------------------------------------*/
/*LIBNAME pgdev POSTGRES  INSERTBUFF=1000  READBUFF=1000  DATABASE=dev */
/*   PRESERVE_COL_NAMES=YES  PRESERVE_TAB_NAMES=YES  DBCOMMIT=1000 conopts="UseDeclareFetch=1 Fetch=100000"*/
/*   SERVER=pgdev  SCHEMA=public  USER=pegasus  PASSWORD="{SAS002}1D5793391C1104E20E3CF4CD2A793E2B" ;*/

LIBNAME pgdev POSTGRES DATABASE="dev" SERVER=defiant SCHEMA=public 
  READBUFF=10000 USER=postgres  PASSWORD="{SAS002}1D5793391C1104E20E3CF4CD2A793E2B" ;
%let syscc=0;

proc olap
   CUBE                   = "/Projects/SGF2013/Cubes/Candy Sales Advanced"
   DELETE;

   METASVR
      HOST        = "pegasus"
      PORT        = 8561
      OLAP_SCHEMA = "SASApp - OLAP Schema";

run;

options fullstimer fmterr;
options SASTRACE=',,,ds' sastraceloc=saslog nostsuffix;
%let syssumtrace=3;

proc options group=performance; run;

proc olap
   CUBE                   = "/Projects/SGF2013/Cubes/Candy Sales Advanced"
   PATH                   = '/projects/SGF2013/cubes'
   DESCRIPTION            = 'Candy sales demo cube for SGF2013'
   FACT                   = pgdev.fact_candy_sales
   CONCURRENT             = 4
   ASYNCINDEXLIMIT        = 4
   MAXTHREADS             = 4
   TEST_LEVEL             = 26
;

   METASVR
      HOST        = "pegasus"
      PORT        = 8561
      OLAP_SCHEMA = "SASApp - OLAP Schema";

   DIMENSION Products
      CAPTION          = 'Product'
      SORT_ORDER       = ASCENDING
      DIMTBL           = pgdev.dim_candy_products
      DIMKEY           = product_key
      FACTKEY          = product_key
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
         COLUMN         =  order_date
         FORMAT         =  YEAR4.
         TYPE           =  YEAR
         CAPTION        =  'Year'
         SORT_ORDER     =  ASCENDING;

      LEVEL Month
         COLUMN         =  order_date
         FORMAT         =  MONNAME3.
         TYPE           =  MONTHS
         CAPTION        =  'Month'
         SORT_ORDER     =  ASCENDING;

      LEVEL Date
         column         =  order_date
         FORMAT         =  mmddyy10.
         TYPE           =  DAYS
         CAPTION        =  'Date'
         SORT_ORDER     =  ASCENDING;

      LEVEL Quarter
         COLUMN         =  order_date
         FORMAT         =  QTR1.
         TYPE           =  QUARTERS
         CAPTION        =  'Quarter'
         SORT_ORDER     =  ASCENDING;

      LEVEL 'Month Year'n
         COLUMN         =  order_date
         FORMAT         =  MONYY7.
         TYPE           =  MONTHS
         CAPTION        =  'Month Year'
         SORT_ORDER     =  ASCENDING;

   DIMENSION Customer
      CAPTION          = 'Customer'
      SORT_ORDER       = ASCENDING
      DIMTBL           = pgdev.dim_candy_customers
      DIMKEY           = customer_key
      FACTKEY          = customer_key
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
      DIMTBL           = pgdev.dim_candy_customers
      DIMKEY           = customer_key
      FACTKEY          = customer_key
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

   DIMENSION 'Sales Person'n
      CAPTION          = 'Sales Person'
      SORT_ORDER       = ASCENDING
      DIMTBL           = pgdev.dim_sales_person
      DIMKEY           = sales_person_key
      FACTKEY          = sales_person_key
      HIERARCHIES      = ( 'Sales Person Name'n  'Sales Person User ID'n  );

      HIERARCHY 'Sales Person Name'n 
         ALL_MEMBER = 'All Sales People'
         CAPTION    = 'Sales Person Name'
         LEVELS     = ( 'Person Name'n )
         DEFAULT;

      HIERARCHY 'Sales Person User ID'n 
         ALL_MEMBER = 'All Sales People'
         CAPTION    = 'Sales Person User ID'
         LEVELS     = ( 'User ID'n );

      LEVEL 'Person Name'n
         CAPTION        =  'Person Name'
         COLUMN         =  sales_person_name
         SORT_ORDER     =  ASCENDING;

      LEVEL 'User ID'n
         CAPTION        =  'User ID'
         COLUMN         =  sales_person_user_id
         SORT_ORDER     =  ASCENDING;

   PROPERTY 'Gross Margin'n
      level=Product
      column=GrssMrgn
      hierarchy=(Products FullProducts)
      caption='Gross Margin'
      description='Gross Margin'
   ;

   PROPERTY 'Retail Price'n
      level=Product
      column=Retail_Price
      hierarchy=(Products FullProducts)
      caption='Retail Price'
      description='Retail Price'
   ;

   MEASURE 'Sales Amount'n
      STAT        = SUM
      COLUMN      = sale_amount
      CAPTION     = 'Sales Amount'
      FORMAT      = DOLLAR22.
      DEFAULT;

   MEASURE 'Avg Sales'n
      STAT        = AVG
      COLUMN      = sale_amount
      CAPTION     = 'Average Sales'
      FORMAT      = DOLLAR22.2;

   MEASURE 'Units Sold'n
      STAT        = SUM
      COLUMN      = units
      CAPTION     = 'Units Sold'
      FORMAT      = comma18.;
run;
%errorcheck;
proc olap;
   METASVR
      HOST        = "pegasus"
      PORT        = 8561
      OLAP_SCHEMA = "SASApp - OLAP Schema";

   /* Rolling month sets */
   DEFINE SET '[Candy Sales Advanced].[Rolling 12 Months]' as 'tail([Time].[YMD].[Month].members,12)';
   DEFINE SET '[Candy Sales Advanced].[Rolling 24 Months]' as 'tail([Time].[YMD].[Month].members,24)';
   DEFINE SET '[Candy Sales Advanced].[Rolling 36 Months]' as 'tail([Time].[YMD].[Month].members,36)';
   DEFINE SET '[Candy Sales Advanced].[Rolling 7 Days]' as 'tail({[Time].[YMD].[Date].members},7)';

   /* Rolling time aggregate members */
   DEFINE MEMBER '[Candy Sales Advanced].[Time].[YMD].[All Years].[Rolling 12 Months]' as 'aggregate( tail([Time].[YMD].[Month].members ,12) )';
   DEFINE MEMBER '[Candy Sales Advanced].[Time].[YMD].[All Years].[Rolling 24 Months]' as 'aggregate( tail([Time].[YMD].[Month].members ,24) )';
   DEFINE MEMBER '[Candy Sales Advanced].[Time].[YMD].[All Years].[Rolling 36 Months]' as 'aggregate( tail([Time].[YMD].[Month].members ,36) )';
   
   /* Ratio */
   DEFINE MEMBER '[Candy Sales Advanced].[Measures].[Sales Price Per Unit]' AS
    '([Measures].[Sales Amount] / [Measures].[Units Sold]), format_string="dollar20.0"';

   /* Rolling Average */
   DEFINE MEMBER '[Candy Sales Advanced].[Measures].[Sales 3M Rolling]' AS
        'Avg(LastPeriods(3,[Time].[MonthYear].CurrentMember),[Measures].[Sales Amount])';
   DEFINE MEMBER '[Candy Sales Advanced].[Measures].[Sales 6M Rolling]' AS
        'Avg(LastPeriods(6,[Time].[MonthYear].CurrentMember),[Measures].[Sales Amount])';

   /* Percent Change - Sales Growth */
   DEFINE MEMBER '[Candy Sales Advanced].[Measures].[Sales Growth]' AS
     '(([Time].[YMD].CurrentMember,[Measures].[Sales Amount])-([Time].[YMD].CurrentMember.PrevMember,[Measures].[Sales Amount]))/([Time].[YMD].CurrentMember.PrevMember,[Measures].[Sales Amount]), format_string="percent14.2"';

   /** Measures to compare account managers performance to their peer group (team)**/
   DEFINE MEMBER '[Candy Sales Advanced].[Measures].[Team AVG Sales]' AS
    '([Customer].[Org Structure].CurrentMember.Parent,[Measures].[Avg Sales]), SOLVE_ORDER=0, format_string="dollar20.0"';

   DEFINE MEMBER '[Candy Sales Advanced].[Measures].[Team AVG 3M Sales]' AS
    'Avg(LastPeriods(3,[Time].[MonthYear].CurrentMember),([Customer].[Org Structure].CurrentMember.Parent,[Measures].[Sales Amount])), SOLVE_ORDER=1, format_string="dollar20.0"';

   DEFINE MEMBER '[Candy Sales Advanced].[Measures].[Diff Team AVG Sales]' AS
    '([Measures].[Avg Sales] - [Measures].[Team AVG Sales]), SOLVE_ORDER=1, format_string="dollar20.0"';

   DEFINE MEMBER '[Candy Sales Advanced].[Measures].[Diff Team AVG 3M Sales]' AS
    '([Measures].[Avg Sales] - [Measures].[Team AVG 3M Sales]), SOLVE_ORDER=1, format_string="dollar20.0"';

   DEFINE MEMBER '[Candy Sales Advanced].[Measures].[%Diff Team AVG Sales]' AS
    '([Measures].[Diff Team AVG Sales] / [Measures].[Team AVG Sales]), SOLVE_ORDER=2, format_string="NLPCT10.2"';

   DEFINE MEMBER '[Candy Sales Advanced].[Measures].[%Diff Team AVG 3M Sales]' AS
    '([Measures].[Diff Team AVG 3M Sales] / [Measures].[Team AVG 3M Sales]), SOLVE_ORDER=2, format_string="NLPCT10.2"';

run;

%errorcheck;
/* Aggregates */
proc olap 
   CUBE="/Projects/SGF2013/Cubes/Candy Sales Advanced"
   CONCURRENT             = 4
   ASYNCINDEXLIMIT        = 2
   MAXTHREADS             = 2
   TEST_LEVEL             = 26;

   METASVR
      HOST        = "pegasus"
      PORT        = 8561
      OLAP_SCHEMA = "SASApp - OLAP Schema";

   AGGREGATION 'Region VP'n  
      / NAME      = 'Region VP';
   AGGREGATION Year Month 'Region VP'n
      / NAME      = 'Year Month Region VP';
   AGGREGATION Year Month
      /  NAME     = 'Year Month';
   AGGREGATION Year
      /  NAME     = 'Year';

run;
%errorcheck;
proc olap 
   CUBE="/Projects/SGF2013/Cubes/Candy Sales Advanced"
   CONCURRENT             = 4
   ASYNCINDEXLIMIT        = 2
   MAXTHREADS             = 2
   TEST_LEVEL             = 26;

   METASVR
      HOST        = "pegasus"
      PORT        = 8561
      OLAP_SCHEMA = "SASApp - OLAP Schema";

   AGGREGATION 'Month Year'n 'Region VP'n
      / NAME      = 'Month Year Region VP';
   AGGREGATION 'Month Year'n
      /  NAME     = 'Month Year';

run;
