/**********************************************************/
/*   Code Written by:                                     */
/*      Stephen Overton  (stephen.overton@gmail.com       */
/*                                                        */
/**********************************************************/

/*
proc sql;
  connect to olap (host="localhost" port=5451 user="sasdemo" pass="Admin123");

    create table sample as select * from connection to olap
  (
     


  )
      

  ;

  disconnect from olap;
quit;
*/
options mprint mlogic symbolgen;
%let var=Total Sales;
proc sql;
  connect to olap (host="enterprise" port=5451 user="sasdemo" pass="Admin123");

    create table results as select * from connection to olap
  (
    WITH MEMBER [Measures].[% Change] AS
        %bquote('(([Measures].[&var.],[Time].[YM].CurrentMember) - 
          ([Measures].[&var.],[Time].[YM].CurrentMember.PrevMember)) / 
          ([Measures].[&var.],[Time].[YM].CurrentMember.PrevMember) , FORMAT_STRING = "PERCENT10.2" ')
      SELECT
        {[Measures].[Total Sales], 
         [Measures].[% Change] } ON COLUMNS,
        {[Time].[YM].[All YM].[2002].Children, 
         [Time].[YM].[All YM].[2001].Children, 
         [Time].[YM].[All YM].[2000].Children, 
         [Time].[YM].[All YM].[1999].Children, 
         [Time].[YM].[All YM].[1998].Children } ON ROWS
      FROM [SGF2011]
  )
  ;
  disconnect from olap;
quit;
