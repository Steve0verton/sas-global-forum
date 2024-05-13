/**********************************************************/
/*   Code Written by:                                     */
/*      Stephen Overton  (stephen.overton@gmail.com       */
/*      Bryan Stines     (btstines@gmail.com)             */
/*                                                        */
/*   Builds a dataset for testing and demo purposes using */
/*   fake data in the SAS help library                    */
/**********************************************************/
libname sgf2011 base '/projects/SGF2011/data'; 

data sgf2011.cubebase;
  set sashelp.pricedata(keep=date price regionname productline productname region line product ) ;
  where date < '05Oct2002'd;
  format date date9. price sales dollar20.2; 

  /** Sales conversion to higher numbers - uses 'Price' column **/
  multiply = (mod((_n_*11) / (3 * ranuni(_n_)),ranuni(_n_))*10) +100 ;
  if year(date) = 2002 then sales = (price * multiply )* 9.4 + 110;
  else if year(date) = 2001 then sales = (price * multiply )* 7.98 + 110;
  else if year(date) = 2000 then sales = (price * multiply )* 11.4 + 110;
  else if year(date) = 1999 then sales = (price * multiply )* 10+ 107;
  else if year(date) = 1998 then sales = (price * multiply )* 10.2 + 109;
  else if year(date) = 1997 then sales = (price * multiply )* 8 + 104;
  else if year(date) = 1996 then sales = (price * multiply )* 9 + 101;

  /** Annualization measures **/
  monthdays = intnx('month',date,0,'e') - intnx('month',date,0,'b') + 1 ;
  yeardays = intnx('year',date,0,'e') - intnx('year',date,0,'b') + 1 ;
  quarterdays = intnx('quarter',date,0,'e') - intnx('quarter',date,0,'b') + 1 ;

  if date => '01Jan2002'd then type = 'Forecast';
  else type = 'Actual' ;

  /** Employee simulation **/
  Employee = 102;
  if date = '01JAN1999'd then employee = 44;
  if date = '01JUN2000'd then employee = 60;
  if date = '01DEC2000'd then employee = 50;
  if date = '01MAY2001'd then employee = 80;
  if date = '01MAR2002'd then employee = 130;
  if date > '01MAR2002'd then employee = 135;
run;  




