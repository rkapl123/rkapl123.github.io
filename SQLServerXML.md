# SQL Server XML queries

When I started writing XML queries for the ORE Database, following blog article was really helpful: [https://www.red-gate.com/simple-talk/sql/learn-sql-server/using-the-for-xml-clause-to-return-query-results-as-xml/](https://www.red-gate.com/simple-talk/sql/learn-sql-server/using-the-for-xml-clause-to-return-query-results-as-xml/)

Mainly using the PATH flavour, I was able to create following results (first the partial queries, then the xml query and finally the result) for the ORE input:

## TodaysMarket file
### TodaysMarketConfiguration

|id|YieldCurvesId|DiscountingCurvesId|...|...|
|---|---|---|---|---|
|collateral_eur|NULL|xois_eur|...|...|
|collateral_inccy|ois|ois|...|...|
|default|xois_eur|xois_eur|...|...|
|libor|inccy_swap|inccy_swap|...|...|

### TodaysMarketYieldCurves

|YieldCurve|name|id|
|---|---|---|
|Yield/EUR/BANK_EUR_BORROW|BANK_EUR_BORROW|default|
|Yield/EUR/BANK_EUR_BORROW|BANK_EUR_BORROW|inccy_swap|
|Yield/EUR/BANK_EUR_BORROW|BANK_EUR_BORROW|ois|
|Yield/EUR/BANK_EUR_BORROW|BANK_EUR_BORROW|xois_eur|
|Yield/EUR/BANK_EUR_LEND|BANK_EUR_LEND|default|
|Yield/EUR/BANK_EUR_LEND|BANK_EUR_LEND|inccy_swap|
|Yield/EUR/BANK_EUR_LEND|BANK_EUR_LEND|ois|
|Yield/EUR/BANK_EUR_LEND|BANK_EUR_LEND|xois_eur|
|Yield/EUR/BENCHMARK_EUR|BENCHMARK_EUR|inccy_swap|
|Yield/EUR/BENCHMARK_EUR|BENCHMARK_EUR|ois|
|Yield/EUR/BOND_YIELD_EUR|BOND_YIELD_EUR|default|
|Yield/EUR/BENCHMARK_EUR|BENCHMARK_EUR|xois_eur|
|Yield/EUR/BOND_YIELD_EUR|BOND_YIELD_EUR|inccy_swap|
|Yield/EUR/BOND_YIELD_EUR|BOND_YIELD_EUR|ois|
|Yield/EUR/BOND_YIELD_EUR|BOND_YIELD_EUR|xois_eur|
|Yield/EUR/EUR6M|EUR-EURIBOR-6M|inccy_swap|

.... The other tables are skipped here, as the principle is always the same, except for the SwapIndexCurves.
Usually, the Row's name is made of the inner PATH directive (e.g. ```PATH ('YieldCurve')```), the content is namelessly created with a ```[data()]``` directive and the name attribute is passed usin ```[@name]```. With SwapIndexCurves there is an inner element called Discounting, which needs to be separated, so it is not being passed with the ```[data()]``` directive but as a normally named field.

### TodaysMarketSwapIndexCurves

|Discounting|name|id|
|---|---|---|
|CHF-TOIS|CHF-CMS-1Y|default|
|CHF-TOIS|CHF-CMS-30Y|default|
|EUR-EONIA|EUR-CMS-1Y|default|
|EUR-EONIA|EUR-CMS-30Y|default|
|GBP-SONIA|GBP-CMS-1Y|default|
|GBP-SONIA|GBP-CMS-30Y|default|
|JPY-TONAR|JPY-CMS-1Y|default|
|JPY-TONAR|JPY-CMS-30Y|default|
|USD-FedFunds|USD-CMS-1Y|default|
|USD-FedFunds|USD-CMS-30Y|default|

.... Again the rest of the tables are skipped, except for the Securities, because this block and the BaseCorrelations are independent from the Configurations selected (all Securities and BaseCorrelations are available in TodaysMarket).

|Security|name|id|
|---|---|---|
|Security/SECURITY_1|SECURITY_1|collateral_eur|
|Security/SECURITY_1|SECURITY_1|default|

### FOR XML Query
```sql
SELECT DISTINCT tmc.GroupingId,
(SELECT
	(SELECT
		(SELECT
			id [@id],
			YieldCurvesId,
			DiscountingCurvesId,
			IndexForwardingCurvesId,
			SwapIndexCurvesId,
			ZeroInflationIndexCurvesId,
			YYInflationIndexCurvesId,
			FxSpotsId,
			FxVolatilitiesId,
			SwaptionVolatilitiesId,
			CapFloorVolatilitiesId,
			DefaultCurvesId,
			InflationCapFloorPriceSurfacesId,
			EquityCurvesId,
			EquityVolatilitiesId
		FROM TodaysMarketConfiguration WHERE GroupingId = tmc.GroupingId
		FOR XML PATH ('Configuration'), TYPE),
		(SELECT
			id [@id],
			(SELECT
				c.name [@name],
				c.YieldCurve [data()]
			FROM TodaysMarketYieldCurves c WHERE c.id = co.id
			FOR XML PATH ('YieldCurve'), TYPE)
		FROM (SELECT DISTINCT ISNULL(YieldCurvesId,'default') id FROM TodaysMarketConfiguration WHERE GroupingId = tmc.GroupingId) co
		FOR XML PATH ('YieldCurves'), TYPE),
		(SELECT
			id [@id],
			(SELECT
				c.currency [@currency],
				c.DiscountingCurve [data()]
			FROM TodaysMarketDiscountingCurves c WHERE c.id = co.id
			FOR XML PATH ('DiscountingCurve'), TYPE)
		FROM (SELECT DISTINCT ISNULL(DiscountingCurvesId,'default') id FROM TodaysMarketConfiguration WHERE GroupingId = tmc.GroupingId) co
		FOR XML PATH ('DiscountingCurves'), TYPE),
		(SELECT
			id [@id],
			(SELECT
				c.name [@name],
				c.IndexName [data()]
			FROM TodaysMarketIndexForwardingCurves c WHERE c.id = co.id
			FOR XML PATH ('Index'), TYPE)
		FROM (SELECT DISTINCT ISNULL(IndexForwardingCurvesId,'default') id FROM TodaysMarketConfiguration WHERE GroupingId = tmc.GroupingId) co
		FOR XML PATH ('IndexForwardingCurves'), TYPE),
		(SELECT
			id [@id],
			(SELECT
				c.name [@name],
				c.Discounting [Discounting]
			FROM TodaysMarketSwapIndexCurves c WHERE c.id = co.id
			FOR XML PATH ('SwapIndex'), TYPE)
		FROM (SELECT DISTINCT ISNULL(SwapIndexCurvesId,'default') id FROM TodaysMarketConfiguration WHERE GroupingId = tmc.GroupingId) co
		FOR XML PATH ('SwapIndexCurves'), TYPE),
		(SELECT
			id [@id],
			(SELECT
				c.name [@name],
				c.ZeroInflationIndexCurve [data()]
			FROM TodaysMarketZeroInflationIndexCurves c WHERE c.id = co.id
			FOR XML PATH ('ZeroInflationIndexCurve'), TYPE)
		FROM (SELECT DISTINCT ISNULL(ZeroInflationIndexCurvesId,'default') id FROM TodaysMarketConfiguration WHERE GroupingId = tmc.GroupingId) co
		FOR XML PATH ('ZeroInflationIndexCurves'), TYPE),
		(SELECT
			id [@id],
			(SELECT
				c.name [@name],
				c.YYInflationIndexCurve [data()]
			FROM TodaysMarketYYInflationIndexCurves c WHERE c.id = co.id
			FOR XML PATH ('YYInflationIndexCurve'), TYPE)
		FROM (SELECT DISTINCT ISNULL(YYInflationIndexCurvesId,'default') id FROM TodaysMarketConfiguration WHERE GroupingId = tmc.GroupingId) co
		FOR XML PATH ('YYInflationIndexCurves'), TYPE),
		(SELECT
			id [@id],
			(SELECT
				c.pair [@pair],
				c.FxSpot [data()]
			FROM TodaysMarketFxSpots c WHERE c.id = co.id
			FOR XML PATH ('FxSpot'), TYPE)
		FROM (SELECT DISTINCT ISNULL(FxSpotsId,'default') id FROM TodaysMarketConfiguration WHERE GroupingId = tmc.GroupingId) co
		FOR XML PATH ('FxSpots'), TYPE),
		(SELECT
			id [@id],
			(SELECT
				c.pair [@pair],
				c.FxVolatility [data()]
			FROM TodaysMarketFxVolatilities c WHERE c.id = co.id
			FOR XML PATH ('FxVolatility'), TYPE)
		FROM (SELECT DISTINCT ISNULL(FxVolatilitiesId,'default') id FROM TodaysMarketConfiguration WHERE GroupingId = tmc.GroupingId) co
		FOR XML PATH ('FxVolatilities'), TYPE),
		(SELECT
			id [@id],
			(SELECT
				c.currency [@currency],
				c.SwaptionVolatility [data()]
			FROM TodaysMarketSwaptionVolatilities c WHERE c.id = co.id
			FOR XML PATH ('SwaptionVolatility'), TYPE)
		FROM (SELECT DISTINCT ISNULL(SwaptionVolatilitiesId,'default') id FROM TodaysMarketConfiguration WHERE GroupingId = tmc.GroupingId) co
		FOR XML PATH ('SwaptionVolatilities'), TYPE),
		(SELECT
			id [@id],
			(SELECT
				c.currency [@currency],
				c.CapFloorVolatility [data()]
			FROM TodaysMarketCapFloorVolatilities c WHERE c.id = co.id
			FOR XML PATH ('CapFloorVolatility'), TYPE)
		FROM (SELECT DISTINCT ISNULL(CapFloorVolatilitiesId,'default') id FROM TodaysMarketConfiguration WHERE GroupingId = tmc.GroupingId) co
		FOR XML PATH ('CapFloorVolatilities'), TYPE),
		(SELECT
			id [@id],
			(SELECT
				c.name [@name],
				c.DefaultCurve [data()]
			FROM TodaysMarketDefaultCurves c WHERE c.id = co.id
			FOR XML PATH ('DefaultCurve'), TYPE)
		FROM (SELECT DISTINCT ISNULL(DefaultCurvesId,'default') id FROM TodaysMarketConfiguration WHERE GroupingId = tmc.GroupingId) co
		FOR XML PATH ('DefaultCurves'), TYPE),
		(SELECT
			id [@id],
			(SELECT
				c.name [@name],
				c.InflationCapFloorPriceSurface [data()]
			FROM TodaysMarketInflationCapFloorPriceSurfaces c WHERE c.id = co.id
			FOR XML PATH ('InflationCapFloorPriceSurface'), TYPE)
		FROM (SELECT DISTINCT ISNULL(InflationCapFloorPriceSurfacesId,'default') id FROM TodaysMarketConfiguration WHERE GroupingId = tmc.GroupingId) co
		FOR XML PATH ('InflationCapFloorPriceSurfaces'), TYPE),
		(SELECT
			id [@id],
			(SELECT
				c.name [@name],
				c.EquityCurve [data()]
			FROM TodaysMarketEquityCurves c WHERE c.id = co.id
			FOR XML PATH ('EquityCurve'), TYPE)
		FROM (SELECT DISTINCT ISNULL(EquityCurvesId,'default') id FROM TodaysMarketConfiguration WHERE GroupingId = tmc.GroupingId) co
		FOR XML PATH ('EquityCurves'), TYPE),
		(SELECT
			id [@id],
			(SELECT
				c.name [@name],
				c.EquityVolatility [data()]
			FROM TodaysMarketEquityVolatilities c WHERE c.id = co.id
			FOR XML PATH ('EquityVolatility'), TYPE)
		FROM (SELECT DISTINCT ISNULL(EquityVolatilitiesId,'default') id FROM TodaysMarketConfiguration WHERE GroupingId = tmc.GroupingId) co
		FOR XML PATH ('EquityVolatilities'), TYPE),
		(SELECT
			id [@id],
			(SELECT
				c.name [@name],
				c.Security [data()]
			FROM TodaysMarketSecurities c WHERE c.id = co.id
			FOR XML PATH ('Security'), TYPE)
		FROM (SELECT DISTINCT id FROM TodaysMarketSecurities) co
		FOR XML PATH ('Securities'), TYPE),
		(SELECT
			id [@id],
			(SELECT
				c.name [@name],
				c.BaseCorrelation [data()]
			FROM TodaysMarketBaseCorrelations c WHERE c.id = co.id
			FOR XML PATH ('BaseCorrelation'), TYPE)
		FROM (SELECT DISTINCT id FROM TodaysMarketBaseCorrelations) co
		FOR XML PATH ('BaseCorrelations'), TYPE)
	FOR XML PATH('TodaysMarket'))) XMLData
FROM TodaysMarketConfiguration tmc
```

### XML Result
```xml
<TodaysMarket>
	<Configuration id="collateral_eur">
		<DiscountingCurvesId>xois_eur</DiscountingCurvesId>
	</Configuration>
	<Configuration id="collateral_inccy">
		<YieldCurvesId>ois</YieldCurvesId>
		<DiscountingCurvesId>ois</DiscountingCurvesId>
	</Configuration>
	<Configuration id="default">
		<YieldCurvesId>xois_eur</YieldCurvesId>
		<DiscountingCurvesId>xois_eur</DiscountingCurvesId>
	</Configuration>
	<Configuration id="libor">
		<YieldCurvesId>inccy_swap</YieldCurvesId>
		<DiscountingCurvesId>inccy_swap</DiscountingCurvesId>
	</Configuration>
	<YieldCurves id="default">
		<YieldCurve name="BANK_EUR_BORROW">Yield/EUR/BANK_EUR_BORROW</YieldCurve>
		<YieldCurve name="BANK_EUR_LEND">Yield/EUR/BANK_EUR_LEND</YieldCurve>
		<YieldCurve name="BENCHMARK_EUR">Yield/EUR/BENCHMARK_EUR</YieldCurve>
		<YieldCurve name="BOND_YIELD_EUR">Yield/EUR/BOND_YIELD_EUR</YieldCurve>
	</YieldCurves>
	<YieldCurves id="inccy_swap">
		<YieldCurve name="BANK_EUR_BORROW">Yield/EUR/BANK_EUR_BORROW</YieldCurve>
		<YieldCurve name="BANK_EUR_LEND">Yield/EUR/BANK_EUR_LEND</YieldCurve>
		<YieldCurve name="BENCHMARK_EUR">Yield/EUR/BENCHMARK_EUR</YieldCurve>
		<YieldCurve name="BOND_YIELD_EUR">Yield/EUR/BOND_YIELD_EUR</YieldCurve>
		<YieldCurve name="EUR-EURIBOR-6M">Yield/EUR/EUR6M</YieldCurve>
	</YieldCurves>
	<YieldCurves id="ois">
		<YieldCurve name="BANK_EUR_BORROW">Yield/EUR/BANK_EUR_BORROW</YieldCurve>
		<YieldCurve name="BANK_EUR_LEND">Yield/EUR/BANK_EUR_LEND</YieldCurve>
		<YieldCurve name="BENCHMARK_EUR">Yield/EUR/BENCHMARK_EUR</YieldCurve>
		<YieldCurve name="BOND_YIELD_EUR">Yield/EUR/BOND_YIELD_EUR</YieldCurve>
	</YieldCurves>
	<YieldCurves id="xois_eur">
		<YieldCurve name="BANK_EUR_BORROW">Yield/EUR/BANK_EUR_BORROW</YieldCurve>
		<YieldCurve name="BANK_EUR_LEND">Yield/EUR/BANK_EUR_LEND</YieldCurve>
		<YieldCurve name="BENCHMARK_EUR">Yield/EUR/BENCHMARK_EUR</YieldCurve>
		<YieldCurve name="BOND_YIELD_EUR">Yield/EUR/BOND_YIELD_EUR</YieldCurve>
	</YieldCurves>
	<DiscountingCurves id="inccy_swap">
		<DiscountingCurve currency="CHF">Yield/CHF/CHF6M</DiscountingCurve>
		<DiscountingCurve currency="EUR">Yield/EUR/EUR6M</DiscountingCurve>
		<DiscountingCurve currency="GBP">Yield/GBP/GBP6M</DiscountingCurve>
		<DiscountingCurve currency="JPY">Yield/JPY/JPY6M</DiscountingCurve>
		<DiscountingCurve currency="USD">Yield/USD/USD3M</DiscountingCurve>
	</DiscountingCurves>
	<DiscountingCurves id="ois">
		<DiscountingCurve currency="CHF">Yield/CHF/CHF6M</DiscountingCurve>
		<DiscountingCurve currency="EUR">Yield/EUR/EUR1D</DiscountingCurve>
		<DiscountingCurve currency="GBP">Yield/GBP/GBP1D</DiscountingCurve>
		<DiscountingCurve currency="JPY">Yield/JPY/JPY6M</DiscountingCurve>
		<DiscountingCurve currency="USD">Yield/USD/USD1D</DiscountingCurve>
	</DiscountingCurves>
	<DiscountingCurves id="xois_eur">
		<DiscountingCurve currency="CHF">Yield/CHF/CHF6M</DiscountingCurve>
		<DiscountingCurve currency="EUR">Yield/EUR/EUR1D</DiscountingCurve>
		<DiscountingCurve currency="GBP">Yield/GBP/GBP-IN-EUR</DiscountingCurve>
		<DiscountingCurve currency="JPY">Yield/JPY/JPY6M</DiscountingCurve>
		<DiscountingCurve currency="USD">Yield/USD/USD-IN-EUR</DiscountingCurve>
	</DiscountingCurves>
	<IndexForwardingCurves id="default">
		<Index name="CHF-TOIS">Yield/CHF/CHF1D</Index>
		<Index name="CHF-LIBOR-3M">Yield/CHF/CHF3M</Index>
		<Index name="CHF-LIBOR-6M">Yield/CHF/CHF6M</Index>
		<Index name="EUR-EURIBOR-12M">Yield/EUR/EUR12M</Index>
		<Index name="EUR-EONIA">Yield/EUR/EUR1D</Index>
		<Index name="EUR-EURIBOR-1M">Yield/EUR/EUR1M</Index>
		<Index name="EUR-EURIBOR-3M">Yield/EUR/EUR3M</Index>
		<Index name="EUR-EURIBOR-6M">Yield/EUR/EUR6M</Index>
		<Index name="GBP-SONIA">Yield/GBP/GBP1D</Index>
		<Index name="GBP-LIBOR-3M">Yield/GBP/GBP3M</Index>
		<Index name="GBP-LIBOR-6M">Yield/GBP/GBP6M</Index>
		<Index name="JPY-TONAR">Yield/JPY/JPY1D</Index>
		<Index name="JPY-LIBOR-6M">Yield/JPY/JPY6M</Index>
		<Index name="USD-FedFunds">Yield/USD/USD1D</Index>
		<Index name="USD-LIBOR-3M">Yield/USD/USD3M</Index>
		<Index name="USD-LIBOR-6M">Yield/USD/USD6M</Index>
	</IndexForwardingCurves>
	<SwapIndexCurves id="default">
		<SwapIndex name="CHF-CMS-1Y">
			<Discounting>CHF-TOIS</Discounting>
		</SwapIndex>
		<SwapIndex name="CHF-CMS-30Y">
			<Discounting>CHF-TOIS</Discounting>
		</SwapIndex>
		<SwapIndex name="EUR-CMS-1Y">
			<Discounting>EUR-EONIA</Discounting>
		</SwapIndex>
		<SwapIndex name="EUR-CMS-30Y">
			<Discounting>EUR-EONIA</Discounting>
		</SwapIndex>
		<SwapIndex name="GBP-CMS-1Y">
			<Discounting>GBP-SONIA</Discounting>
		</SwapIndex>
		<SwapIndex name="GBP-CMS-30Y">
			<Discounting>GBP-SONIA</Discounting>
		</SwapIndex>
		<SwapIndex name="JPY-CMS-1Y">
			<Discounting>JPY-TONAR</Discounting>
		</SwapIndex>
		<SwapIndex name="JPY-CMS-30Y">
			<Discounting>JPY-TONAR</Discounting>
		</SwapIndex>
		<SwapIndex name="USD-CMS-1Y">
			<Discounting>USD-FedFunds</Discounting>
		</SwapIndex>
		<SwapIndex name="USD-CMS-30Y">
			<Discounting>USD-FedFunds</Discounting>
		</SwapIndex>
	</SwapIndexCurves>
	<ZeroInflationIndexCurves id="default">
		<ZeroInflationIndexCurve name="EUHICP">Inflation/EUHICP/EUHICP_ZC_Swaps</ZeroInflationIndexCurve>
		<ZeroInflationIndexCurve name="EUHICPXT">Inflation/EUHICPXT/EUHICPXT_ZC_Swaps</ZeroInflationIndexCurve>
		<ZeroInflationIndexCurve name="FRHICP">Inflation/FRHICP/FRHICP_ZC_Swaps</ZeroInflationIndexCurve>
		<ZeroInflationIndexCurve name="UKRPI">Inflation/UKRPI/UKRPI_ZC_Swaps</ZeroInflationIndexCurve>
		<ZeroInflationIndexCurve name="USCPI">Inflation/USCPI/USCPI_ZC_Swaps</ZeroInflationIndexCurve>
		<ZeroInflationIndexCurve name="ZACPI">Inflation/ZACPI/ZACPI_ZC_Swaps</ZeroInflationIndexCurve>
	</ZeroInflationIndexCurves>
	<YYInflationIndexCurves id="default">
		<YYInflationIndexCurve name="EUHICPXT">Inflation/EUHICPXT/EUHICPXT_YY_Swaps</YYInflationIndexCurve>
	</YYInflationIndexCurves>
	<FxSpots id="default">
		<FxSpot pair="EURCHF">FX/EUR/CHF</FxSpot>
		<FxSpot pair="EURGBP">FX/EUR/GBP</FxSpot>
		<FxSpot pair="EURJPY">FX/EUR/JPY</FxSpot>
		<FxSpot pair="EURUSD">FX/EUR/USD</FxSpot>
	</FxSpots>
	<FxVolatilities id="default">
		<FxVolatility pair="EURCHF">FXVolatility/EUR/CHF/EURCHF</FxVolatility>
		<FxVolatility pair="EURGBP">FXVolatility/EUR/GBP/EURGBP</FxVolatility>
		<FxVolatility pair="EURJPY">FXVolatility/EUR/JPY/EURJPY</FxVolatility>
		<FxVolatility pair="EURUSD">FXVolatility/EUR/USD/EURUSD</FxVolatility>
		<FxVolatility pair="GBPUSD">FXVolatility/GBP/USD/GBPUSD</FxVolatility>
	</FxVolatilities>
	<SwaptionVolatilities id="default">
		<SwaptionVolatility currency="CHF">SwaptionVolatility/CHF/CHF_SW_N</SwaptionVolatility>
		<SwaptionVolatility currency="JPY">SwaptionVolatility/CHF/JPY_SW_N</SwaptionVolatility>
		<SwaptionVolatility currency="EUR">SwaptionVolatility/EUR/EUR_SW_N</SwaptionVolatility>
		<SwaptionVolatility currency="GBP">SwaptionVolatility/GBP/GBP_SW_N</SwaptionVolatility>
		<SwaptionVolatility currency="USD">SwaptionVolatility/USD/USD_SW_N</SwaptionVolatility>
	</SwaptionVolatilities>
	<CapFloorVolatilities id="default">
		<CapFloorVolatility currency="EUR">CapFloorVolatility/EUR/EUR_CF_N</CapFloorVolatility>
		<CapFloorVolatility currency="GBP">CapFloorVolatility/GBP/GBP_CF_N</CapFloorVolatility>
		<CapFloorVolatility currency="USD">CapFloorVolatility/USD/USD_CF_N</CapFloorVolatility>
	</CapFloorVolatilities>
	<DefaultCurves id="default">
		<DefaultCurve name="BOND_YIELD_EUR_OVER_OIS">Default/EUR/BOND_YIELD_EUR_OVER_OIS</DefaultCurve>
		<DefaultCurve name="CPTY_C">Default/EUR/CPTY_C_SR_EUR</DefaultCurve>
		<DefaultCurve name="BANK">Default/USD/BANK_SR_USD</DefaultCurve>
		<DefaultCurve name="CPTY_A">Default/USD/CPTY_A_SR_USD</DefaultCurve>
		<DefaultCurve name="CPTY_B">Default/USD/CPTY_A_SR_USD</DefaultCurve>
	</DefaultCurves>
	<InflationCapFloorPriceSurfaces id="default">
		<InflationCapFloorPriceSurface name="EUHICPXT">InflationCapFloorPrice/EUHICPXT/EUHICPXT_ZC_CF</InflationCapFloorPriceSurface>
		<InflationCapFloorPriceSurface name="UKRPI">InflationCapFloorPrice/UKRPI/UKRPI_ZC_CF</InflationCapFloorPriceSurface>
		<InflationCapFloorPriceSurface name="USCPI">InflationCapFloorPrice/USCPI/USCPI_ZC_CF</InflationCapFloorPriceSurface>
	</InflationCapFloorPriceSurfaces>
	<EquityCurves id="default">
		<EquityCurve name="Lufthansa">Equity/EUR/Lufthansa</EquityCurve>
		<EquityCurve name="SP5">Equity/USD/SP5</EquityCurve>
	</EquityCurves>
	<EquityVolatilities id="default">
		<EquityVolatility name="Lufthansa">EquityVolatility/EUR/Lufthansa</EquityVolatility>
		<EquityVolatility name="SP5">EquityVolatility/USD/SP5</EquityVolatility>
	</EquityVolatilities>
	<Securities id="collateral_eur">
		<Security name="SECURITY_1">Security/SECURITY_1</Security>
	</Securities>
	<Securities id="default">
		<Security name="SECURITY_1">Security/SECURITY_1</Security>
	</Securities>
	<BaseCorrelations id="default"/>
</TodaysMarket>
```

Further interesting examples will follow soon...
