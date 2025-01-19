---
title: SQL Server yield to maturity function
description: a yield to maturity function for annual bullet bonds with act/act pricing convention
---

Looking for a YTM function, I found this article the most promising: [https://www.insidesql.org/blogs/frankkalis/2006/01/25/yield-to-maturity](https://www.insidesql.org/blogs/frankkalis/2006/01/25/yield-to-maturity).
However, even with a nice explanation, the code was only rudimentary (on purpose by the author), so I decided to publish a usable version for bonds with act/act pricing convention (most European bonds, except Bulgaria, Croatia, Malta, UK and Italy).

The function returns -999.9 in case of obvious input errors, no checking is done for arithmetic overflows in the used newton method for finding the root.

```sql
CREATE FUNCTION yield_to_maturity(@price_date DATETIME, @maturity DATETIME, @coupon decimal(9,6), @price decimal(9,6))
RETURNS float
AS
BEGIN
 DECLARE @ytm_prev float
 DECLARE @ytm float
 DECLARE @pv_prev float
 DECLARE @pv float
 DECLARE @accrued float
 DECLARE @cash_flows TABLE (cashflow decimal(9,6), value_date datetime)
 DECLARE @cf_date datetime
 
 -- sanity checks, return "impossible value"
 IF @maturity < @price_date
  RETURN -999.9
 IF @price IS NULL OR @maturity IS NULL OR @price_date IS NULL OR @coupon IS NULL
  RETURN -999.9

 -- set up cashflows, first add the bond coupons, backdated from maturity
 SET @cf_date = @maturity
 WHILE @cf_date > @price_date
 BEGIN
  INSERT INTO @cash_flows (cashflow, value_date) VALUES (@coupon, @cf_date)
  SET @cf_date = DATEADD(year,-1,@cf_date)
 END

 -- @cf_date is now the last coupon date, used to calculate accrued from coupon to determine dirty price
 SET @accrued = @coupon * cast(DATEDIFF(day, @cf_date, @price_date) as float)/DATEDIFF(day,DATEADD(year,-1,@price_date),@price_date)
 -- bond redemption: final cashflow
 INSERT INTO @cash_flows (cashflow, value_date) VALUES (100.0, @maturity)
 -- bond purchase: first cashflow
 INSERT INTO @cash_flows (cashflow, value_date) VALUES (-(@price+@accrued), @price_date)

 -- initialize newton method, initial ytm set to 1%
 SET @ytm_prev = 0
 SET @ytm = 0.01
 SELECT @pv_prev = SUM(cashflow) FROM @cash_flows
 -- calculate pv using initial ytm as total discounted sum of cashflows using act/act daycount
 SET @pv = (SELECT SUM(cashflow/POWER(1+@ytm,cast(DATEDIFF(day,@price_date, value_date) as float)/DATEDIFF(day,DATEADD(year,-1,value_date),value_date))) FROM @cash_flows)

 -- iterate with newton method until either accuracy goal reached or x- differential zero (would lead to div/0 otherwise)
 WHILE ABS(@pv) >= 0.000001 AND (@pv - @pv_prev) <> 0
 BEGIN
  DECLARE @t float
  SET @t = @ytm_prev
  SET @ytm_prev = @ytm
  SET @ytm = @ytm + (@t-@ytm)*@pv/(@pv - @pv_prev)
  SET @pv_prev = @pv
  SET @pv = (SELECT SUM(cashflow/POWER(1+@ytm,cast(DATEDIFF(day,@price_date, value_date) as float)/DATEDIFF(day,DATEADD(year,-1,value_date),value_date))) FROM @cash_flows)
 END

 RETURN @ytm
END
GO
```