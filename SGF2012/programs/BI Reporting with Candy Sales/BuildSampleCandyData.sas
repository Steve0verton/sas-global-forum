/**********************************************************/
/*   Code Written by:                                     */
/*      Stephen Overton  (stephen.overton@gmail.com)      */
/*                                                        */
/*   Builds a dataset for testing and demo purposes using */
/*   fake data in the EG Sample library                   */
/**********************************************************/
libname source base '/projects/SampleData/eg_data';
libname sgf2012 base '/projects/SGF2012/data'; 

/** Drop integrity constraints and tables first **/
proc datasets library=SGF2012 nowarn;
  modify fact_candy_sales;
  ic delete _all_;
  modify dim_candy_customers;
  ic delete _all_;
  modify dim_candy_products;
  ic delete _all_;
  delete dim_candy_customers dim_candy_products fact_candy_sales;
quit;

/** Build dimension tables **/
data sgf2012.dim_candy_customers;
  set source.candy_customers(rename=(Name=Customer));

  /* Add Regional VPs */
  if Region = 'Central' then RegionVP = 'Smedley Snodgrass';
  else if Region = 'East' then RegionVP = 'Chuck Norris';
  else if Region = 'West' then RegionVP = 'Wesley Snipes';

  /* Add Account Managers */
  if Customer = 'Bulls Eye Emporium' then Account_Manager = 'Geordi La Forge';
  else if Customer = 'Floor Mart' then Account_Manager = 'William Riker';
  else if Customer = 'Wholesalers R Us' then Account_Manager = 'Tasha Yar';
  else if Customer = 'Harry Koger' then Account_Manager = 'Beverly Crusher';
  else if Customer = 'Land of Fun' then Account_Manager = 'Jean-Luc Picard';
  else if Customer = 'Super Low Wholesaler' then Account_Manager = 'Worf';
  else if Customer = 'Toys 4 U' then Account_Manager = 'Data';
  else if Customer = 'Nile Online' then Account_Manager = 'Deanna Troi';
run;

data sgf2012.dim_candy_products;
  set source.candy_products;
  Plant = PrimPlnt;
  drop PrimPlnt;
run;

/** Build fact table **/
data sgf2012.fact_candy_sales;
  set source.candy_sales_history(rename=(Customer=CustID));
  format SalesAmt Target dollar22.0;
  label SalesAmt='Sales Amount';
  SalesAmt = 7.77 * units;
  Date = intnx('year',Date,8,'same');
  Target = SalesAmt * 1.1 ;
run;

/** Define primary keys **/
proc datasets library=sgf2012;
  modify fact_candy_sales;
  ic create fact_pk = primary key(OrderID);
  index create date / nomiss;

  modify dim_candy_products;
  ic create dim_candy_product_pk = primary key(ProdID);

  modify dim_candy_customers;
  ic create dim_candy_customer_pk = primary key(CustID);
run;

/** Define referntial integrity **/
proc sql;
  alter table SGF2012.fact_candy_sales add constraint refdim_custID                                                                                                                                                                                                   
  foreign key (CustID)                                                                                                                                                                                                                                       
  references SGF2012.dim_candy_customers(CustID);

  alter table SGF2012.fact_candy_sales add constraint refdim_prodID                                                                                                                                                                                                   
  foreign key (ProdID)                                                                                                                                                                                                                                       
  references SGF2012.dim_candy_products(ProdID);
quit;

/** Create view for sample wide report **/
proc sql;
  create view sgf2012.candy_flat_view as
    select
      product.Product,
      product.Category,
      product.Subcategory,
      product.GrssMrgn,
      product.Retail_Price,
      product.Plant,
      customer.Customer,
      customer.Region,
      customer.RegionVP,
      customer.Account_Manager,
      customer.Type,
      fact.SalesAmt,
      fact.Units,
      year(fact.date) as Year,
      qtr(fact.date) as Quarter,
      month(fact.date) as Month,
      fact.date
    from
      sgf2012.fact_candy_sales fact
      inner join dim_candy_products product on (fact.ProdID = product.ProdID)
      inner join dim_candy_customers customer on (fact.CustID = customer.CustID)
    ;
quit;
