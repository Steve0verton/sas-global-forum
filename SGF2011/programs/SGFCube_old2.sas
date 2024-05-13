OPTIONS VALIDVARNAME=ANY;
LIBNAME sgf BASE "C:\Projects\SGF\data";

PROC OLAP
   CUBE                   = "/Shared Data/SGF/Cubes"
   DELETE;


   METASVR
      HOST        = "zendev05.zencos.com"
      PORT        = 8561
      OLAP_SCHEMA = "SASApp - OLAP Schema";

RUN;

PROC OLAP
   CUBE                   = "/Shared Data/SGF/Cubes"
   DATA                   = sgf.CUBEBASE
   PATH                   = 'C:\Projects\SGF\cubes'
   DESCRIPTION            = 'SGF'
;

   METASVR
      HOST        = "zendev05.zencos.com"
      PORT        = 8561
      OLAP_SCHEMA = "SASApp - OLAP Schema";

   DIMENSION Time
      CAPTION          = 'Time'
      TYPE             = TIME
      SORT_ORDER       = ASCENDING
      HIERARCHIES      = (
         YM YQM 
         ) /* HIERARCHIES */;

      HIERARCHY YM 
         ALL_MEMBER = 'All YM'
         CAPTION    = 'YM'
         LEVELS     = (
            Year Month 
            ) /* LEVELS */
         DEFAULT;

      HIERARCHY YQM 
         ALL_MEMBER = 'All YQM'
         CAPTION    = 'YQM'
         LEVELS     = (
            Year Quarter Month 
            ) /* LEVELS */;

      LEVEL Year
         COLUMN         =  date
         FORMAT         =  YEAR4.
         TYPE           =  YEAR
         CAPTION        =  'Year'
         SORT_ORDER     =  ASCENDING;

      LEVEL Month
         COLUMN         =  date
         FORMAT         =  MONNAME9.
         TYPE           =  MONTHS
         CAPTION        =  'Month'
         SORT_ORDER     =  ASCENDING;

      LEVEL Quarter
         COLUMN         =  date
         FORMAT         =  QTR1.
         TYPE           =  QUARTERS
         CAPTION        =  'Quarter'
         SORT_ORDER     =  ASCENDING;

   DIMENSION Product
      CAPTION          = 'Product'
      SORT_ORDER       = ASCENDING
      HIERARCHIES      = (
         Product 
         ) /* HIERARCHIES */;

      HIERARCHY Product 
         ALL_MEMBER = 'All Product'
         CAPTION    = 'Product'
         LEVELS     = (
            productLine productName 
            ) /* LEVELS */
         DEFAULT;

      LEVEL productLine
         CAPTION        =  'Product Line'
         SORT_ORDER     =  ASCENDING;

      LEVEL productName
         CAPTION        =  'Product Name'
         SORT_ORDER     =  ASCENDING;

   DIMENSION Location
      CAPTION          = 'Location'
      SORT_ORDER       = ASCENDING
      HIERARCHIES      = (
         Location 
         ) /* HIERARCHIES */;

      HIERARCHY Location 
         ALL_MEMBER = 'All Location'
         CAPTION    = 'Location'
         LEVELS     = (
            regionName 
            ) /* LEVELS */
         DEFAULT;

      LEVEL regionName
         CAPTION        =  'Sales Region'
         SORT_ORDER     =  ASCENDING;

   DIMENSION ValueType 
      CAPTION          = 'Type'
      SORT_ORDER       = ASCENDING
      HIERARCHIES      = (
         ValueType 
         ) /* HIERARCHIES */;

      HIERARCHY ValueType 
         ALL_MEMBER = 'All Type'
         CAPTION    = 'Type'
         LEVELS     = (
            Type 
            ) /* LEVELS */
         DEFAULT;


   MEASURE salesSUM
   formats=dollar20.
      STAT        = SUM
      COLUMN      = price
      CAPTION     = 'Sales Sum';



   MEASURE salesMIN
      STAT        = MIN
      COLUMN      = price
      CAPTION     = 'Sales Min'
      DEFAULT;

   MEASURE salesMAX
   formats=dollar20.
      STAT        = MAX
      COLUMN      = price
      CAPTION     = 'Sales Max';



   MEASURE SalesAVG
   formats=dollar20.
      STAT        = AVG
      COLUMN      = price
      CAPTION     = 'Sales Average';

   MEASURE discountSUM
   formats=dollar20.
      STAT        = SUM
      COLUMN      = discount
      CAPTION     = 'Discount Sum';

   MEASURE costSUM
      STAT        = SUM
	  formats=dollar20.
      COLUMN      = cost
      CAPTION     = 'Cost Sum';

   MEASURE monthdays
      STAT        = max
	  formats=comma8.
      COLUMN      = monthdays
      CAPTION     = 'monthdays';

	MEASURE yeardays
      STAT        = max
	  formats=comma8.
      COLUMN      = yeardays
      CAPTION     = 'yeardays';

   MEASURE employee
      STAT        = max
	  formats=comma8.
      COLUMN      = employee
      CAPTION     = 'Employee';

	DEFINE Member "[SGF].[Measures].[TimeLevel]" AS 
     'iif([Time].[YQM].currentmember.level.Ordinal > 0, "YQM",
				iif([Time].[YM].currentmember.level.Ordinal > 0, "YM",
					"UNKNOWN" ))';

	DEFINE Member "[SGF].[Measures].[Employee Count]" AS
		'iif(isleaf([Time].[YM].CurrentMember) OR isleaf([Time].[YQM].CurrentMember),[Measures].[employee] , 
  iif([Time].[YQM].CurrentMember.Level.Name = "Quarter", iif([Measures].[TimeLevel] = "YQM", ([Time].[YQM].LastChild, [Measures].[employee]), null),
    iif([Time].[YQM].CurrentMember.Level.Name = "Year" OR [Time].[YM].CurrentMember.Level.Name = "Year",
    	iif([Measures].[TimeLevel] = "YM", ([Time].[YM].LastChild, [Measures].[employee]), iif([Measures].[TimeLevel] = "YQM", ([Time].[YQM].LastChild.LastChild, [Measures].[employee]), null)), null))
)';

	


   AGGREGATION /* Default */
      /* levels */
      Month productLine productName 
      Quarter regionName Year 
      / /* options */
      NAME      = 'Default';

RUN;
