# Enhancing ORE

Following is an overview on enhancing ORE with new instruments using the example of CMS Spread Structured Swaps with three market variables.
We start bottom up (thinking in the libraries architecture), starting with Quantlib and ORE's Quantlib extension (QLE), 
then enhancing the Data level (Market Data and Trade/Leg/Engine Representation) and ending with the Analytics layer.

ORE can usually be enhanced by adding separate code files, however in following instances an addition is required in existing code:

0. extend CrossAssetModel (for XVA simulation) in qle/models/crossassetmodel.?pp
1. registering the new Coupon in PricerSetter, extending qle/cashflows/couponpricer.cpp
2. add MarketDatum, extend MarketDatumParser, extending ored/marketdata/marketdatum.?pp and marketdatumparser.?pp (not in this example)
3. add a CurveType and CurveSpec, extending ored/marketdata/curvespec.?pp and ored/marketdata/curvespecparser.cpp (not in this example)
4. extend Market, MarketImpl in ored/marketdata/market.?pp and marketimpl.?pp (not in this example)
5. extend TodaysMarket, TodaysMarketParameters in ored/marketdata/todaysmarket.?pp and todaysmarketparameters.?pp (not in this example)
6. extend Index Parser in ored/utilities/indexparser.?pp (not in this example)
7. add TradeBuilder in ored/portfolio/tradefactory.?pp (not in this example)
8. registered the LegBuilder with the engine factory in ored/portfolio/enginefactory.cpp
9. and all parts of the analytic layer, so
 - extend Scenario in orea/scenario/scenario.?pp (not in this example)
 - extend ScenarioSimMarket + Parameters in orea/scenario/scenariosimmarket.?pp and scenariosimmarketparameters.?pp (not in this example)
 - extend CAM Scenario Generator (Data, Builder) in orea/scenario/crossassetmodelscenariogenerator.?pp (not in this example)
 - extend SensitivityScenarioGenerator + Data in orea/scenario/sensitivityscenariogenerator.?pp, sensitivityscenariodata.?pp (not in this example)
 - extend StressScenarioGenerator + Data in orea/scenario/stressscenariogenerator.?pp, stressscenariodata.?pp (not in this example)
 - extend FixingManager in orea/simulation/fixingmanager.cpp (not in this example)


- First Steps (QL, QLE)
  1. add Instrument / Index / Coupon
  2. add PricingEngine / CouponPricer
  3. add TermStructure
  4. extend CrossAssetModel (for XVA sim)

- Second Steps (ORED: Market Data)
  1. add MarketDatum, extend MarketDatumParser
  2. add CurveSpec, CurveConfig, Wrapper
  3. extend Market interface, MarketImpl
  4. extend TodaysMarket / TodaysMarketParameters
  5. extend index parser

- Third Steps (ORED: Portfolio)
  1. extend LegData
  2. add Trade
  3. add EngineBuilder, TradeBuilder, LegBuilder

- Fourth Steps (OREA: Simulation, Sensitivities)
  1. extend Scenario
  2. extend ScenarioSimMarket / ScenarioSimMarketParameters
  3. extend CrossAssetModelScenarioGenerator (Data, Builder)
  4. extend SensitivityScenarioGenerator, SensitivityScenarioData
  5. extend StressScenarioGenerator, StressScenarioData
  6. extend FixingManager

- Fifth Steps (Miscellaneous)
  1. extend Curve Ordering

# First Steps (QL, QLE)

## QL: add Instrument / Index / Coupon
  either use an existing instrument (e.g. Swap instrument), an existing Index (e.g. SwapSpreadIndex) and an existing Coupon (e.g. CmsSpreadCoupon) from QuantLib
  or ...

### add your own Instrument:
  using existing Swap instrument here.
  
### add your own Index: qle/indexes/swapspread3index.hpp and .cpp:

```cpp
#include <ql/indexes/swapindex.hpp>
using namespace QuantLib;

namespace QuantExt {

    //! class for swap-rate spread indexes
    class SwapSpread3Index : public InterestRateIndex {
      public:
        SwapSpread3Index(const std::string& familyName,
                        const boost::shared_ptr<SwapIndex>& swapIndex1,
                        const boost::shared_ptr<SwapIndex>& swapIndex2,
                        const boost::shared_ptr<SwapIndex>& swapIndex3,
                        const Real gearing1 = 1.0,
                        const Real gearing2 = -1.0,
                        const Real gearing3 = 1.0,
                        const Real strike = 0.005,
                        const Real cap = 0.01,
                        const Real elseconstant = 0.01);

        //! \name InterestRateIndex interface
        //@{
        Date maturityDate(const Date& valueDate) const {
            QL_FAIL("SwapSpreadIndex does not provide a single maturity date");
        }
        Rate forecastFixing(const Date& fixingDate) const;
        Rate pastFixing(const Date& fixingDate) const;
        bool allowsNativeFixings() { return false; }
        //@}

        //! \name Inspectors
        //@{
        boost::shared_ptr<SwapIndex> swapIndex1() { return swapIndex1_; }
        boost::shared_ptr<SwapIndex> swapIndex2() { return swapIndex2_; }
        boost::shared_ptr<SwapIndex> swapIndex3() { return swapIndex3_; }
        Real gearing1() { return gearing1_; }
        Real gearing2() { return gearing2_; }
        Real gearing3() { return gearing3_; }
        //@}

    private:
        boost::shared_ptr<SwapIndex> swapIndex1_, swapIndex2_, swapIndex3_;
        Real gearing1_, gearing2_, gearing3_, strike_, elseconstant_, cap_;
    };

    inline Rate SwapSpread3Index::forecastFixing(const Date& fixingDate) const {
        // this also handles the case when one of indices has
        // a historic fixing on the evaluation date
        return (gearing1_ * swapIndex1_->fixing(fixingDate, false) + 
        gearing2_ * swapIndex2_->fixing(fixingDate, false) > strike_ ? 
        std::max(gearing3_ * swapIndex3_->fixing(fixingDate, false), cap_)
        : elseconstant_ );
    }

    inline Rate SwapSpread3Index::pastFixing(const Date& fixingDate) const {

        Real f1 = swapIndex1_->pastFixing(fixingDate);
        Real f2 = swapIndex2_->pastFixing(fixingDate);
        Real f3 = swapIndex3_->pastFixing(fixingDate);
        // if one of the fixings is missing we return null, indicating
        // a missing fixing for the spread index
        if(f1 == Null<Real>() || f2 == Null<Real>() || f3 == Null<Real>())
            return Null<Real>();
        else
            return (gearing1_ * f1 + gearing2_ * f2 > strike_ ? 
            std::max(gearing3_ * f3, cap_) : elseconstant_);
    }
}

// ***************  .cpp  ****************
#include <qle/indexes/swapspread3index.hpp>

#include <sstream>
#include <iomanip>

using boost::shared_ptr;

namespace QuantExt {

    SwapSpread3Index::SwapSpread3Index(
        const std::string &familyName,
        const boost::shared_ptr<SwapIndex> &swapIndex1,
        const boost::shared_ptr<SwapIndex> &swapIndex2, 
        const boost::shared_ptr<SwapIndex> &swapIndex3,
        const Real gearing1,
        const Real gearing2,
        const Real gearing3,
        const Real strike,
        const Real cap,
        const Real elseconstant)
        : InterestRateIndex(
              familyName,
              swapIndex1->tenor(), // does not make sense, but have to provide
              swapIndex1->fixingDays(),
              swapIndex1->currency(), swapIndex1->fixingCalendar(),
              swapIndex1->dayCounter()),
          swapIndex1_(swapIndex1), swapIndex2_(swapIndex2),
           swapIndex3_(swapIndex3), gearing1_(gearing1),
          gearing2_(gearing2), gearing3_(gearing3), 
          strike_(strike), cap_(cap), elseconstant_(elseconstant) {

        registerWith(swapIndex1_);
        registerWith(swapIndex2_);
        registerWith(swapIndex3_);

        std::ostringstream name;
        name << std::setprecision(4) << std::fixed << "SwapSpread3:" 
            << swapIndex1_->name() << "("
            << gearing1 << ") + " << swapIndex2_->name() 
            << "(" << gearing2 << ")" << swapIndex3_->name() 
            << "(" << gearing3 << ")";
        name_ = name.str();

        QL_REQUIRE(swapIndex1_->fixingDays() == swapIndex2_->fixingDays(),
                   "index1 fixing days ("
                       << swapIndex1_->fixingDays() << ")"
                       << "must be equal to index2 fixing days ("
                       << swapIndex2_->fixingDays() << ")");

.... lots of further QL_REQUIRES to assure sane parameters ...

    }
}
```

### add your own Coupon: qle/cashflows/CmsSpread3coupon.hpp and .cpp:

```cpp
#include <ql/cashflows/floatingratecoupon.hpp>
#include <ql/cashflows/capflooredcoupon.hpp>
#include <ql/cashflows/couponpricer.hpp>
#include <qle/indexes/swapspread3index.hpp>
#include <ql/time/schedule.hpp>

using namespace QuantLib;

namespace QuantLib {
    class SwapIndex;
}

namespace QuantExt {

    //! CMS spread coupon class
    class CmsSpread3Coupon : public FloatingRateCoupon {
      public:
        CmsSpread3Coupon(const Date& paymentDate,
                  Real nominal,
                  const Date& startDate,
                  const Date& endDate,
                  Natural fixingDays,
                  const boost::shared_ptr<SwapSpread3Index>& index,
                  Real gearing = 1.0,
                  Spread spread = 0.0,
                  const Date& refPeriodStart = Date(),
                  const Date& refPeriodEnd = Date(),
                  const DayCounter& dayCounter = DayCounter(),
                  bool isInArrears = false);
        //! \name Inspectors
        //@{
        const boost::shared_ptr<SwapSpread3Index>& swapSpreadIndex() const {
            return index_;
        }
        //@}
        //! \name Visitability
        //@{
        virtual void accept(AcyclicVisitor&);
        //@}
      private:
        boost::shared_ptr<SwapSpread3Index> index_;
    };

    // need to provide this if index is specific to coupon (see .cpp below)!
    class CappedFlooredCmsSpread3Coupon : public CappedFlooredCoupon {
    public:
        CappedFlooredCmsSpread3Coupon(
            const Date& paymentDate,
            Real nominal,
            const Date& startDate,
            const Date& endDate,
            Natural fixingDays,
            const boost::shared_ptr<SwapSpread3Index>& index,
            Real gearing = 1.0,
            Spread spread = 0.0,
            const Rate cap = Null<Rate>(),
            const Rate floor = Null<Rate>(),
            const Date& refPeriodStart = Date(),
            const Date& refPeriodEnd = Date(),
            const DayCounter& dayCounter = DayCounter(),
            bool isInArrears = false)
            : CappedFlooredCoupon(boost::shared_ptr<FloatingRateCoupon>(new
                CmsSpread3Coupon(paymentDate, nominal, startDate, endDate, 
                fixingDays, index, gearing, spread, refPeriodStart, 
                refPeriodEnd, dayCounter, isInArrears))
                , cap, floor) {}

        virtual void accept(AcyclicVisitor& v) {
            Visitor<CappedFlooredCmsSpread3Coupon>* v1 =
                dynamic_cast<Visitor<CappedFlooredCmsSpread3Coupon>*>(&v);
            if (v1 != 0)
                v1->visit(*this);
            else
                CappedFlooredCoupon::accept(v);
        }
    };

    //! helper class building a sequence of cms-spread-rate coupons
    class CmsSpread3Leg {
      public:
        CmsSpread3Leg(const Schedule& schedule,
               const boost::shared_ptr<SwapSpread3Index>& swapSpreadIndex);
        CmsSpread3Leg& withNotionals(Real notional);
... lots of other decorators ...
        operator Leg() const;
      private:
        Schedule schedule_;
        boost::shared_ptr<SwapSpread3Index> swapSpread3Index_;
        std::vector<Real> notionals_;
        DayCounter paymentDayCounter_;
        BusinessDayConvention paymentAdjustment_;
        std::vector<Natural> fixingDays_;
        std::vector<Real> gearings_;
        std::vector<Spread> spreads_;
        bool inArrears_, zeroPayments_;
    };

    //! base pricer for vanilla CMS spread coupons
    class CmsSpread3CouponPricer : public FloatingRateCouponPricer {
      public:
        explicit CmsSpread3CouponPricer(
                           const Handle<Quote> &correlation = Handle<Quote>())
        : correlation_(correlation) {
            registerWith(correlation_);
        }

        Handle<Quote> correlation() const{ return correlation_; }

        void setCorrelation(const Handle<Quote> &correlation = Handle<Quote>()) {
            unregisterWith(correlation_);
            correlation_ = correlation;
            registerWith(correlation_);
            update();
        }
      private:
        Handle<Quote> correlation_;
    };
}

// ***************  .cpp  ****************
#include <qle/cashflows/cmsspread3coupon.hpp>
#include <ql/cashflows/cashflowvectors.hpp>
#include <ql/cashflows/capflooredcoupon.hpp>

namespace QuantExt {
    CmsSpread3Coupon::CmsSpread3Coupon(
        const Date &paymentDate, Real nominal, const Date &startDate,
        const Date &endDate, Natural fixingDays,
        const boost::shared_ptr<SwapSpread3Index> &index, Real gearing,
        Spread spread, const Date &refPeriodStart,
        const Date &refPeriodEnd,
        const DayCounter &dayCounter, bool isInArrears)
        : FloatingRateCoupon(paymentDate, nominal, startDate, endDate,
                             fixingDays, index, gearing, spread,
                             refPeriodStart, refPeriodEnd, dayCounter,
                             isInArrears),
          index_(index) {}

    void CmsSpread3Coupon::accept(AcyclicVisitor &v) {
        Visitor<CmsSpread3Coupon> *v1 = 
          dynamic_cast<Visitor<CmsSpread3Coupon> *>(&v);
        if (v1 != 0)
            v1->visit(*this);
        else
            FloatingRateCoupon::accept(v);
    }

    CmsSpread3Leg::CmsSpread3Leg(const Schedule &schedule,
                               const boost::shared_ptr<SwapSpread3Index> &index)
        : schedule_(schedule), swapSpread3Index_(index),
          paymentAdjustment_(Following), inArrears_(false),
          zeroPayments_(false) {}

    CmsSpread3Leg &CmsSpread3Leg::withNotionals(Real notional) {
        notionals_ = std::vector<Real>(1, notional);
        return *this;
    }

.... lots of further decorators to allow easier making of Leg ... 

    // important: CappedFloored coupon was done separately 
    // (although it was not needed), 
    // because it has the same index as the uncapped coupon 
    // and the index is only given once here:
    CmsSpread3Leg::operator Leg() const {
        return FloatingLeg<SwapSpread3Index, CmsSpread3Coupon,
            CappedFlooredCmsSpread3Coupon>(
            schedule_, notionals_, swapSpread3Index_, paymentDayCounter_,
            paymentAdjustment_, fixingDays_, gearings_, spreads_, 
            std::vector<Real>(1,Null<Real>()),
            std::vector<Real>(1, Null<Real>()), inArrears_, zeroPayments_);
    }
}
```

## QL: add PricingEngine / CouponPricer
  Either use an existing, matching coupon pricer from QuantLib (LognormalCmsSpreadPricer, requires a single implied correlation parameter)  
  or ...
  
### add your own CouponPricer: qle/cashflows/lognormalcmsspreadpricerGen.hpp and .cpp:

```cpp
#include <ql/cashflows/cmscoupon.hpp>
#include <qle/cashflows/cmsspread3coupon.hpp>
#include <qle/indexes/swapspread3index.hpp>
#include <ql/math/integrals/gaussianquadratures.hpp>
#include <ql/math/distributions/normaldistribution.hpp>

namespace QuantLib {
    class CmsSpread3Coupon;
    class YieldTermStructure;
}

using namespace QuantLib;

namespace QuantExt {

    //! CMS spread - coupon pricer
    /*! This is a Zero Vol pricer not actually pricing,
     but just resetting the coupons for future fixings
     by returning the fixing in swapletRate()
    */

    class LognormalCmsSpreadPricerGen : public CmsSpread3CouponPricer {

      public:
          LognormalCmsSpreadPricerGen(
            const boost::shared_ptr<CmsCouponPricer> cmsPricer,
            const Handle<Quote> &correlation,
            const Handle<YieldTermStructure> &couponDiscountCurve =
                Handle<YieldTermStructure>(),
            const Size IntegrationPoints = 16,
            const boost::optional<VolatilityType> volatilityType= boost::none,
            const Real shift1 = Null<Real>(), const Real shift2 = Null<Real>());

        /*     */
        virtual Real swapletPrice() const {QL_FAIL("Not implemented");}
        virtual Rate swapletRate() const;
        virtual Real capletPrice(Rate effectiveCap) 
        		const { QL_FAIL("Not implemented"); }
        virtual Rate capletRate(Rate effectiveCap) 
        		const { QL_FAIL("Not implemented"); }
        virtual Real floorletPrice(Rate effectiveFloor) 
        		const { QL_FAIL("Not implemented"); }
        virtual Rate floorletRate(Rate effectiveFloor) 
        		const { QL_FAIL("Not implemented"); }
        /* */
        void flushCache();

      private:
        class PrivateObserver : public Observer {
          public:
            explicit PrivateObserver(LognormalCmsSpreadPricerGen *t) : t_(t) {}
            void update() { t_->flushCache(); }

          private:
              LognormalCmsSpreadPricerGen *t_;
        };

        boost::shared_ptr<PrivateObserver> privateObserver_;

        typedef std::map<std::pair<std::string, Date>, std::pair<Real, Real> >
        CacheType;

        void initialize(const FloatingRateCoupon &coupon);
        Real optionletPrice(Option::Type optionType, Real strike) const;

        Real integrand(const Real) const;
        Real integrand_normal(const Real) const;

        boost::shared_ptr<CmsCouponPricer> cmsPricer_;

        Handle<YieldTermStructure> couponDiscountCurve_;

        const CmsSpread3Coupon *coupon_;

        Date today_, fixingDate_, paymentDate_;

        Real fixingTime_;

        Real gearing_, spread_;
        Real spreadLegValue_;
        Real discount_;

        boost::shared_ptr<SwapSpread3Index> index_;

        boost::shared_ptr<CumulativeNormalDistribution> cnd_;
        boost::shared_ptr<GaussianQuadrature> integrator_;

        Real swapRate1_, swapRate2_, gearing1_, gearing2_;
        Real adjustedRate1_, adjustedRate2_;
        Real vol1_, vol2_;
        Real mu1_, mu2_;
        Real rho_;

        bool inheritedVolatilityType_;
        VolatilityType volType_;
        Real shift1_, shift2_;

        mutable Real phi_, a_, b_, s1_, s2_, m1_, m2_, v1_, v2_, k_;
        mutable Real alpha_, psi_;
        mutable Option::Type optionType_;

        boost::shared_ptr<CmsCoupon> c1_, c2_;

        CacheType cache_;
    };
}

// ***************  .cpp  ****************
#include <qle/cashflows/lognormalcmsspreadpricerGen.hpp>
#include <qle/cashflows/cmsspread3coupon.hpp>
#include <ql/math/integrals/kronrodintegral.hpp>
#include <ql/termstructures/volatility/swaption/swaptionvolcube.hpp>
#include <ql/pricingengines/blackformula.hpp>

#include <boost/make_shared.hpp>
using namespace QuantLib;

using std::sqrt;

namespace QuantExt {

    LognormalCmsSpreadPricerGen::LognormalCmsSpreadPricerGen(
        const boost::shared_ptr<CmsCouponPricer> cmsPricer,
        const Handle<Quote> &correlation,
        const Handle<YieldTermStructure> &couponDiscountCurve,
        const Size integrationPoints,
        const boost::optional<VolatilityType> volatilityType,
        const Real shift1, const Real shift2)
        : CmsSpread3CouponPricer(correlation), cmsPricer_(cmsPricer),
          couponDiscountCurve_(couponDiscountCurve) {

        registerWith(correlation);
        if (!couponDiscountCurve_.empty())
            registerWith(couponDiscountCurve_);

        QL_REQUIRE(integrationPoints >= 4,
                   "at least 4 integration points should be used ("
                       << integrationPoints << ")");
        integrator_ =
            boost::make_shared<GaussHermiteIntegration>(integrationPoints);

        cnd_ = boost::make_shared<CumulativeNormalDistribution>(0.0, 1.0);

        privateObserver_ = boost::make_shared<PrivateObserver>(this);
        privateObserver_->registerWith(cmsPricer_);

        if(volatilityType == boost::none) {
            QL_REQUIRE(shift1 == Null<Real>() && shift2 == Null<Real>(),
                       "if volatility type is inherited, no shifts should be "
                       "specified");
            inheritedVolatilityType_ = true;
            volType_ = cmsPricer->swaptionVolatility()->volatilityType();
        } else {
            shift1_ = shift1 == Null<Real>() ? 0.0 : shift1;
            shift2_ = shift2 == Null<Real>() ? 0.0 : shift2;
            inheritedVolatilityType_ = false;
            volType_ = *volatilityType;
        }
    }

    Real LognormalCmsSpreadPricerGen::integrand(const Real x) const {
... calculation details not used ...
    }

    Real LognormalCmsSpreadPricerGen::integrand_normal(const Real x) const {
... calculation details not used ...
    }

    void LognormalCmsSpreadPricerGen::flushCache() { cache_.clear(); }

    void
    LognormalCmsSpreadPricerGen::initialize(const FloatingRateCoupon &coupon) {

        coupon_ = dynamic_cast<const CmsSpread3Coupon *>(&coupon);
        QL_REQUIRE(coupon_, "CMS spread 3 coupon needed");
        index_ = coupon_->swapSpreadIndex();
        gearing_ = coupon_->gearing();
        spread_ = coupon_->spread();

        fixingDate_ = coupon_->fixingDate();
        paymentDate_ = coupon_->date();

        // if no coupon discount curve is given just use the discounting curve
        // from the _first_ swap index.
        // for rate calculation this curve cancels out in the computation, so
        // e.g. the discounting
        // swap engine will produce correct results, even if the
        // couponDiscountCurve is not set here.
        // only the price member function in this class will be dependent on the
        // coupon discount curve.

        today_ = QuantLib::Settings::instance().evaluationDate();

        if (couponDiscountCurve_.empty())
            couponDiscountCurve_ =
                index_->swapIndex1()->exogenousDiscount()
                    ? index_->swapIndex1()->discountingTermStructure()
                    : index_->swapIndex1()->forwardingTermStructure();

        discount_ = paymentDate_ > couponDiscountCurve_->referenceDate()
                        ? couponDiscountCurve_->discount(paymentDate_)
                        : 1.0;

        spreadLegValue_ = spread_ * coupon_->accrualPeriod() * discount_;

        gearing1_ = index_->gearing1();
        gearing2_ = index_->gearing2();

        QL_REQUIRE(gearing1_ > 0.0 && gearing2_ < 0.0,
                   "gearing1 (" << gearing1_
                                << ") should be positive while gearing2 ("
                                << gearing2_ << ") should be negative");

        c1_ = boost::shared_ptr<CmsCoupon>(new CmsCoupon(
            coupon_->date(), coupon_->nominal(), coupon_->accrualStartDate(),
            coupon_->accrualEndDate(), coupon_->fixingDays(),
            index_->swapIndex1(), 1.0, 0.0, coupon_->referencePeriodStart(),
            coupon_->referencePeriodEnd(), coupon_->dayCounter(),
            coupon_->isInArrears()));

        c2_ = boost::shared_ptr<CmsCoupon>(new CmsCoupon(
            coupon_->date(), coupon_->nominal(), coupon_->accrualStartDate(),
            coupon_->accrualEndDate(), coupon_->fixingDays(),
            index_->swapIndex2(), 1.0, 0.0, coupon_->referencePeriodStart(),
            coupon_->referencePeriodEnd(), coupon_->dayCounter(),
            coupon_->isInArrears()));

        c1_->setPricer(cmsPricer_);
        c2_->setPricer(cmsPricer_);

        if (fixingDate_ > today_) {

            fixingTime_ = cmsPricer_->swaptionVolatility()->timeFromReference(
                fixingDate_);

            swapRate1_ = c1_->indexFixing();
            swapRate2_ = c2_->indexFixing();

            // costly part, look up in cache first
            std::pair<std::string, Date> key =
                std::make_pair(index_->name(), fixingDate_);
            CacheType::const_iterator k = cache_.find(key);
            if (k != cache_.end()) {
                adjustedRate1_ = k->second.first;
                adjustedRate2_ = k->second.second;
            } else {
                adjustedRate1_ = c1_->adjustedFixing();
                adjustedRate2_ = c2_->adjustedFixing();
                cache_.insert(std::make_pair(
                    key, std::make_pair(adjustedRate1_, adjustedRate2_)));
            }

            boost::shared_ptr<SwaptionVolatilityStructure> swvol =
                *cmsPricer_->swaptionVolatility();
            boost::shared_ptr<SwaptionVolatilityCube> swcub =
                boost::dynamic_pointer_cast<SwaptionVolatilityCube>(swvol);

            if(inheritedVolatilityType_ && volType_ == ShiftedLognormal) {
                shift1_ =
                    swvol->shift(fixingDate_, index_->swapIndex1()->tenor());
                shift2_ =
                    swvol->shift(fixingDate_, index_->swapIndex2()->tenor());
            }

            if (swcub == NULL) {
                // not a cube, just an atm surface given, so we can
                // not easily convert volatilities and just forbid it
                QL_REQUIRE(inheritedVolatilityType_,
                           "if only an atm surface is given, the volatility "
                           "type must be inherited");
                vol1_ = swvol->volatility(
                    fixingDate_, index_->swapIndex1()->tenor(), swapRate1_);
                vol2_ = swvol->volatility(
                    fixingDate_, index_->swapIndex2()->tenor(), swapRate2_);
            } else {
                vol1_ = swcub->smileSection(fixingDate_,
                                            index_->swapIndex1()->tenor())
                            ->volatility(swapRate1_, volType_, shift1_);
                vol2_ = swcub->smileSection(fixingDate_,
                                            index_->swapIndex2()->tenor())
                            ->volatility(swapRate2_, volType_, shift2_);
            }

            if(volType_ == ShiftedLognormal) {
                mu1_ = 1.0 / fixingTime_ * 
                     std::log((adjustedRate1_ + shift1_) /
                                                    (swapRate1_ + shift1_));
                mu2_ = 1.0 / fixingTime_ * 
                     std::log((adjustedRate2_ + shift2_) /
                                                    (swapRate2_ + shift2_));
            }
            // for the normal volatility case we do not need the drifts
            // but rather use adjusted rates directly in the integrand

            rho_ = std::max(std::min(correlation()->value(), 0.9999),
                            -0.9999); // avoid division by zero in integrand
        } else {
            // fixing is in the past or today
            adjustedRate1_ = c1_->indexFixing();
            adjustedRate2_ = c2_->indexFixing();
        }
    }

    Real LognormalCmsSpreadPricerGen::optionletPrice(Option::Type optionType,
                                                  Real strike) const {
... calculation details of optionlet pricing not used ......
    }

    Rate LognormalCmsSpreadPricerGen::swapletRate() const {
        return coupon_->swapSpreadIndex()->fixing(fixingDate_);
    }
}
```

### and register the Coupon in PricerSetter, extending qle/cashflows/couponpricer.cpp:

```cpp
#include <qle/cashflows/couponpricer.hpp>

namespace QuantExt {

namespace {

class PricerSetter : public AcyclicVisitor,
                     public Visitor<CashFlow>,
                     public Visitor<Coupon>,
                     public Visitor<AverageONIndexedCoupon>,
                     public Visitor<SubPeriodsCoupon>,
                     public Visitor<CmsSpread3Coupon> {
private:
    const boost::shared_ptr<FloatingRateCouponPricer> pricer_;

public:
    PricerSetter(const boost::shared_ptr<FloatingRateCouponPricer>& pricer) : 
                                     pricer_(pricer) {}
    void visit(CashFlow& c);
    void visit(Coupon& c);
    void visit(AverageONIndexedCoupon& c);
    void visit(SubPeriodsCoupon& c);
    void visit(CmsSpread3Coupon& c);
};

void PricerSetter::visit(CashFlow&) {
    // nothing to do
}

void PricerSetter::visit(Coupon&) {
    // nothing to do
}

... other visit implementations ...

void PricerSetter::visit(CmsSpread3Coupon& c) {
    const boost::shared_ptr<CmsSpread3CouponPricer> cmsSpread3CouponPricer =
        boost::dynamic_pointer_cast<CmsSpread3CouponPricer>(pricer_);
    QL_REQUIRE(cmsSpread3CouponPricer, 
               "Pricer not compatible with cmsSpread3 coupon");
    c.setPricer(cmsSpread3CouponPricer);
}

} // namespace
} // namespace QuantExt
```

## QL: add TermStructure
Ideally we should have a correlation term structure, this should support maturity and strike dimensions.
Straightforward to implement, but for the time being we will treat the implied correlation as a model parameter, thus no term structure is  required.

## QL: extend CrossAssetModel (for XVA simulation)
The existing cross asset model implies perfect correlation between CMS rates, we could possibly extend the IR component in qle\models\crossassetmodel.?pp so that it can be calibrated to market prices 
for cms spread options, but for the moment we skip this and use our fixed, external implied correlation for simulation.
Notice that this is inconsistent to a certain degree!

# Second Steps (ORED: Market Data)

## ORED: add MarketDatum, extend MarketDatumParser

Describes a single market datum, corresponds to one line in marketdata.txt in ored/marketdata/marketdatum.?pp and marketdatumparser.?pp
We don't do anything right now, but we could
  - ...add an InstrumentType `CMS_SPREAD_OPTION`
  - ...add a QuoteType `IMPLIED_CORRELATION`
  - ...add a CmsSpreadOptionQuote with maturity, strike dimensions, ccy, for types `IMPLIED_CORRELATION` and `PRICE`
  - ...extend `parseMarketDatum()` in ored/marketdata/marketdatumparser.cpp so that it recognises the new quotes

## ORED: add CurveSpec
Defines the "label" for a curve, e.g. `CmsCorrelation/EUR/EUR_Impl_Corr(type/ccy/curveID)` in ored/marketdata/curvespec.?pp
We don't do anything right now, but we could
  - ...add a CurveType CmsCorrelation
  - ...add a CurveSpec CmsCorrelationSpec
  - ...extend `parseCurveSpec()` in ored/marketdata/curvespecparser.cpp to handle the new curve type

## ORED: add CurveConfig
Holds the details of the curve configuration, reads it from and writes to XML, provides the quotes used for the curve in ored/configuration/<>curveconfig.?pp
We don't do anything right now, but we could
  - ...add a CmsCorrelationCurveConfig

## ORED: add Wrapper
Takes the spec, config, market data and builds the actual QL term structure in ored/marketdata/<>curve.?pp
We don't do anything right now, but we could ... 
  - ...add a CmsCorrelationCurve

## ORED: extend Market, MarketImpl
Interface to retrieve QL term structures, plus "standard" implementation in ored/marketdata/market.?pp and marketimpl.?pp.
We don't do anything right now, but we could ... 
  - ...add `cmsCorrelation(const string\& ccy, const string\& config)`
  - ...add a lookup implementation to MarketImpl

## ORED: extend TodaysMarket, TodaysMarketParameters
Builds a T0 market, based on TodaysMarketParameters that reflects todaysmarket.xml in ored/marketdata/todaysmarket.?pp and todaysmarketparameters.?pp.
We don't do anything right now, but we could ... 
  - ...add the building of CMS Correlation Termstructures and
  - ...the corresponding todays market parameters

## ORED: extend Index Parser
Builds QL indices from strings in ored/utilities/indexparser.?pp.
We don't need that for cms spread indices, because we will build them from CMS indices on the fly, but in general ... 
  - ... new "native" (i.e. not composed) index types require support by an index parser 
  - ... the index parser is called from the fixings loader
  - ... indices are either directly available via the market interface (Ibor, CMS, ZeroInflation), or constructed on the fly (FX, Equity)

# Third Steps (ORED: Portfolio)

![Image of screenshot1](https://raw.githubusercontent.com/rkapl123/rkapl123.github.io/master/ORED_Portfolio.png)

## ORED: extend LegData
Legs are reusable in Swaps, Bonds, etc., so there is no need for an instrument.
This should be preferred over an own Instrument / Trade, whenever possible.

### Done in ored/portfolio/legdata.hpp and .cpp (or extending those as separate files):

```cpp
#include <qle/indexes/swapspread3index.hpp>
....
//! Serializable CMS Spread 3 Leg Data
class CMSSpread3LegData : public LegAdditionalData {
public:
    //! Default constructor
    CMSSpread3LegData() : LegAdditionalData("CMSSpread3"), fixingDays_(0), 
                            isInArrears_(true), nakedOption_(false) {}
    //! Constructor
    CMSSpread3LegData(const string& swapIndex1, const string& swapIndex2, 
        const string& swapIndex3, int fixingDays, bool isInArrears,
        const vector<double>& spreads, 
        const vector<string>& spreadDates = vector<string>(),
        const vector<double>& gearings = vector<double>(),
        const vector<string>& gearingDates = vector<string>(), 
        bool nakedOption = false)
        : LegAdditionalData("CMSSpread3"), swapIndex1_(swapIndex1), 
        swapIndex2_(swapIndex2), swapIndex3_(swapIndex3), 
        fixingDays_(fixingDays), isInArrears_(isInArrears), 
        spreads_(spreads), spreadDates_(spreadDates), gearings_(gearings), 
        gearingDates_(gearingDates), nakedOption_(nakedOption) {}

    //! \name Inspectors
    //@{
    const string& swapIndex1() const { return swapIndex1_; }
    const string& swapIndex2() const { return swapIndex2_; }
    const string& swapIndex3() const { return swapIndex3_; }
    int fixingDays() const { return fixingDays_; }
    bool isInArrears() const { return isInArrears_; }
    const vector<double>& spreads() const { return spreads_; }
    const vector<string>& spreadDates() const { return spreadDates_; }
    const vector<double>& gearings() const { return gearings_; }
    const vector<string>& gearingDates() const { return gearingDates_; }
    bool nakedOption() const { return nakedOption_; }
    //@}

    //! \name Serialisation
    //@{
    virtual void fromXML(XMLNode* node);
    virtual XMLNode* toXML(XMLDocument& doc);
    //@}
private:
    string swapIndex1_;
    string swapIndex2_;
    string swapIndex3_;
    int fixingDays_;
    bool isInArrears_;
    vector<double> spreads_;
    vector<string> spreadDates_;
    vector<double> gearings_;
    vector<string> gearingDates_;
    bool nakedOption_;
};
....
Leg makeCMSSpread3Leg(const LegData& data, 
    const boost::shared_ptr<QuantExt::SwapSpread3Index>& swapSpreadIndex,
    const boost::shared_ptr<EngineFactory>& engineFactory, 
    const bool attachPricer = true);

// ***************  .cpp  ****************
#include <qle/cashflows/cmsspread3coupon.hpp>

XMLNode* CMSSpread3LegData::toXML(XMLDocument& doc) {
    XMLNode* node = doc.allocNode(legNodeName());
    XMLUtils::addChild(doc, node, "Index1", swapIndex1_);
    XMLUtils::addChild(doc, node, "Index2", swapIndex2_);
    XMLUtils::addChild(doc, node, "Index3", swapIndex3_);
    XMLUtils::addChild(doc, node, "IsInArrears", isInArrears_);
    XMLUtils::addChild(doc, node, "FixingDays", fixingDays_);
    addChildrenWithOptionalAttributes(doc, node, "Gearings", 
                         "Gearing", gearings_, "startDate", gearingDates_);
    addChildrenWithOptionalAttributes(doc, node, "Spreads", 
                         "Spread", spreads_, "startDate", spreadDates_);
    XMLUtils::addChild(doc, node, "NakedOption", nakedOption_);
    return node;
}

void CMSSpread3LegData::fromXML(XMLNode* node) {
    XMLUtils::checkNode(node, legNodeName());
    swapIndex1_ = XMLUtils::getChildValue(node, "Index1", true);
    swapIndex2_ = XMLUtils::getChildValue(node, "Index2", true);
    swapIndex3_ = XMLUtils::getChildValue(node, "Index3", true);
    spreads_ =
        XMLUtils::getChildrenValuesAsDoublesWithAttributes(node, "Spreads", 
                     "Spread", "startDate", spreadDates_, true);
    // These are all optional
    XMLNode* arrNode = XMLUtils::getChildNode(node, "IsInArrears");
    if (arrNode)
        isInArrears_ = XMLUtils::getChildValueAsBool(node, "IsInArrears", true);
    else
        isInArrears_ = false;  // default to fixing-in-advance
    fixingDays_ = 
        XMLUtils::getChildValueAsInt(node, "FixingDays"); // defaults to 0
    gearings_ =
        XMLUtils::getChildrenValuesAsDoublesWithAttributes(node, "Gearings", 
                      "Gearing", "startDate", gearingDates_);
    if (XMLUtils::getChildNode(node, "NakedOption"))
        nakedOption_ = XMLUtils::getChildValueAsBool(node, "NakedOption", false);
    else
        nakedOption_ = false;
}
....
boost::shared_ptr<LegAdditionalData> 
LegData::initialiseConcreteLegData(const string& legType) {
    if (legType == "Fixed") {
.... other LegTypes ....
    } else if (legType == "CMSSpread3") {
        return boost::make_shared<CMSSpread3LegData>();
    } else {
        QL_FAIL("Unkown leg type " << legType);
    }
}
....
Leg makeCMSSpread3Leg(const LegData& data, 
    const boost::shared_ptr<QuantExt::SwapSpread3Index>& swapSpreadIndex,
    const boost::shared_ptr<EngineFactory>& engineFactory, 
        const bool attachPricer) {

        boost::shared_ptr<CMSSpread3LegData> cmsSpread3Data =
        boost::dynamic_pointer_cast<CMSSpread3LegData>(data.concreteLegData());
    QL_REQUIRE(cmsSpread3Data, 
              "Wrong LegType, expected CMSSpread3, got " << data.legType());

    Schedule schedule = makeSchedule(data.schedule());
    DayCounter dc = parseDayCounter(data.dayCounter());
    BusinessDayConvention bdc = 
            parseBusinessDayConvention(data.paymentConvention());
    vector<double> spreads =
        ore::data::buildScheduledVector(cmsSpread3Data->spreads(), 
       			cmsSpread3Data->spreadDates(), schedule);
    QuantExt::CmsSpread3Leg cmsSpreadLeg = 
       QuantExt::CmsSpread3Leg(schedule, swapSpreadIndex)
        .withNotionals(data.notionals())
        .withSpreads(spreads)
        .withPaymentDayCounter(dc)
        .withPaymentAdjustment(bdc)
        .withFixingDays(cmsSpread3Data->fixingDays())
        .inArrears(cmsSpread3Data->isInArrears());

    if (cmsSpread3Data->gearings().size() > 0)
        cmsSpreadLeg.withGearings(
            buildScheduledVector(cmsSpread3Data->gearings(), 
                             cmsSpread3Data->gearingDates(), schedule));

    if (!attachPricer)
        return cmsSpreadLeg;

    // Get a coupon pricer for the leg
    auto builder1 = engineFactory->builder("CMS");
    QL_REQUIRE(builder1, "No CMS builder found for CmsSpreadLeg");
    auto cmsBuilder = boost::dynamic_pointer_cast<CmsCouponPricerBuilder>(
                  builder1);
    auto cmsPricer = boost::dynamic_pointer_cast<CmsCouponPricer>(
                  cmsBuilder->engine(swapSpreadIndex->currency()));
    QL_REQUIRE(cmsPricer, "Expected CMS Pricer");
    auto builder2 = engineFactory->builder("CMSSpread3");
    QL_REQUIRE(builder2, "No CMS Spread 3 builder found for CmsSpreadLeg");
    auto cmsSpreadBuilder = 
        boost::dynamic_pointer_cast<CmsSpread3CouponPricerBuilder>(builder2);
    auto cmsSpreadPricer = 
        cmsSpreadBuilder->engine(swapSpreadIndex->currency(), cmsPricer);
    QL_REQUIRE(cmsSpreadPricer, "Expected CMS Spread Pricer");

    // Loop over the coupons in the leg and set pricer
    Leg tmpLeg = cmsSpreadLeg;
    QuantExt::setCouponPricer(tmpLeg, cmsSpreadPricer);

    // build naked option leg if required
    if (cmsSpread3Data->nakedOption()) {
        tmpLeg = StrippedCappedFlooredCouponLeg(tmpLeg);
    }
    return tmpLeg;
}
```

## ORED: CMSSpreadLegData, makeCMSSpreadLeg
CMSSpreadData describes the leg, as it is specified in XML, makeCMSSpreadLeg builds the actual QL Leg, this is called from the leg builder (see below).

## ORED: add Trade
Done in ored/portfolio/
This is only needed if a new Trade Type should be added, i.e. we can skip it as we just extend legs.
Represents the trade as specified in XML and uses Components like Envelope, LegData, TradeActions etc., and own data.
It builds the actual ORE instrument that wraps the QL trade using an engine builder

## ORED: add TradeBuilder
Done in ored/portfolio/tradefactory.?pp
builds a `boost::shared_ptr` to a trade and is registered with the TradeFactory with the trade type string, 
either in `TradeFactory::TradeFactory()` or `OREApp::getExtraTradeBuilders()`
Pure Boilerplate Code, no business logic whatsoever present.

## ORED: add LegBuilder
Builds the actual QL Leg given the specific LegData for a leg type and an engine builder, typically calls `make*Type*Leg()` in legdata.?pp, here `makeCMSSpreadLeg()`.
Here, the cms spread index is also created on the fly.

### Done in ored/portfolio/legbuilders.hpp and .cpp (or extending those as separate files):

```cpp
....
class CMSSpread3LegBuilder : public LegBuilder {
public:
    CMSSpread3LegBuilder() : LegBuilder("CMSSpread3") {}
    Leg buildLeg(const LegData& data, 
       const boost::shared_ptr<EngineFactory>& engineFactory,
       const string& configuration) const override;
};

// ***************  .cpp  ****************
#include <qle/indexes/swapspread3index.hpp>
....
Leg CMSSpread3LegBuilder::buildLeg(const LegData& data, 
    const boost::shared_ptr<EngineFactory>& engineFactory,
    const string& configuration) const {
    auto cmsSpreadData =
       boost::dynamic_pointer_cast<CMSSpread3LegData>(data.concreteLegData());
    QL_REQUIRE(cmsSpreadData, "Wrong LegType, expected CMSSpread");
    auto index1 = 
      *engineFactory->market()->swapIndex(cmsSpreadData->swapIndex1(), 
         configuration);
    auto index2 = 
      *engineFactory->market()->swapIndex(cmsSpreadData->swapIndex2(), 
         configuration);
    auto index3 = 
      *engineFactory->market()->swapIndex(cmsSpreadData->swapIndex3(), 
         configuration);
    return makeCMSSpread3Leg(data,
        boost::make_shared<QuantExt::SwapSpread3Index>(
            "CMSSpread3_" + index1->familyName() + "_" 
            + index2->familyName() + "_" + index3->familyName(), 
            index1, index2, index3), engineFactory);
}
```

### The LegBuilder is registered with the engine factory in ored/portfolio/enginefactory.cpp

```cpp
void EngineFactory::addDefaultBuilders() {
....
    registerBuilder(boost::make_shared<CmsSpread3CouponPricerBuilder>());

....
    registerLegBuilder(boost::make_shared<CMSSpread3LegBuilder>());
}
```

## ORED: add EngineBuilder
Builds a QL pricing engine or a QL coupon pricer (typically).
Uses model and engine parameters from pricingengine.xml and is registered with the engine factory (as shown above).

### Done in ored/portfolio/builders/cmsspread.hpp and .cpp (or extending those as separate files):

```cpp
#include <qle/cashflows/lognormalcmsspreadpricerGen.hpp>

using namespace ore::data;

namespace ore {
namespace data {
....
//! CouponPricer Builder for CmsSpread3Leg
/*! The coupon pricers are cached by currency */
class CmsSpread3CouponPricerBuilder
    : public CachingCouponPricerBuilder<string, const Currency&, 
            const boost::shared_ptr<QuantLib::CmsCouponPricer>&> {
public:
    CmsSpread3CouponPricerBuilder() : CachingEngineBuilder("ZeroVol", 
           "Analytic", { "CMSSpread3" }) {}

protected:
    string keyImpl(const Currency& ccy, 
      const boost::shared_ptr<QuantLib::CmsCouponPricer>& cmsPricer) override {
        return ccy.code();
    }
    boost::shared_ptr<FloatingRateCouponPricer>
        engineImpl(const Currency& ccy, 
      const boost::shared_ptr<QuantLib::CmsCouponPricer>& cmsPricer) override;
};

} // namespace data
} // namespace ore

// ***************  .cpp  ****************
#include <ored/portfolio/builders/cmsspread.hpp>
#include <ored/utilities/log.hpp>
#include <ored/utilities/parsers.hpp>

#include <boost/make_shared.hpp>

using namespace QuantLib;

namespace ore {
namespace data {
....
boost::shared_ptr<FloatingRateCouponPricer>
CmsSpread3CouponPricerBuilder::engineImpl(const Currency& ccy, 
             const boost::shared_ptr<CmsCouponPricer>& cmsPricer) {

    const string& ccyCode = ccy.code();
    Real correlation;
    if (modelParameters_.find("Correlation_" + ccyCode) 
    	!= modelParameters_.end()) {
        correlation = parseReal(modelParameters_.at("Correlation_" + ccyCode));
    }
    else if (modelParameters_.find("Correlation") != modelParameters_.end()) {
        correlation = parseReal(modelParameters_.at("Correlation"));
    }
    else {
        QL_FAIL("CmsSpreadCouponPricerBuilder(" << ccy 
                   << "): correlation parameter required");
    }

    return boost::make_shared<QuantExt::LognormalCmsSpreadPricerGen>(
        cmsPricer, Handle<Quote>(boost::make_shared<SimpleQuote>(correlation)),
        market_->discountCurve(ccyCode, configuration(MarketContext::pricing)),
        parseInteger(engineParameters_.at("IntegrationPoints")));
}
} // namespace data
} // namespace ore
```

# Fourth Steps (OREA: Simulation, Sensitivities)

###  OREA: extend Scenario
Holds a market data scenario (RiskFactorKey &#8594; Real)
Done in orea/scenario/scenario.?pp
Needed for sensitivities / stress and xva simulation
We don't do anything right now, but when CMS Correlation is a market datum we should add it to the RiskFactorKey KeyType.

## OREA: ScenarioSimMarket + Parameters
Holds a simulation market used for XVA and sensitivities / stress.
Done in orea/scenario/scenariosimmarket.?pp and scenariosimmarketparameters.?pp
Initially takes a copy from today's market, then applies scenarios.
Distinguishes non-simulated (xva) and simulated (xva, sensitivity/stress) factors.
Non-simulated means, there are no scenario required to evolve a factor, it's done on the fly.
Not needed now, but CMS Correlation should be added later and for CMS the whole cube should be simulated (only ATM slice currently)!
ScenarioSimMarketParameters correspond to simulation.xml, Market section.

## OREA: extend CAM Scenario Generator (Data, Builder)
Generates scenarios using the Cross Asset Model.
Done in orea/scenario/crossassetmodelscenariogenerator.?pp
Is required for simulate-able factors only and in general will generate model implied scenarios.
Not really interesting for CMS Correlation unless we add a multifactor IR model to the CAM, then we need to extend ored/model/crossassetmodeldata.?pp 
and crossassetmodelbuilder.?pp as well.
CAM Data corresponds to simulation.xml, CrossAssetModel section.

## OREA: extend SensitivityScenarioGenerator + Data
Generates scenarios for scenario analysis.
Done in orea/scenario/sensitivityscenariogenerator.?pp, sensitivityscenariodata.?pp
Requires simulate-able factors and would be required if we want to compute sensitivites w.r.t. CMS correlations (later)

## OREA: extend StressScenarioGenerator + Data
Generates scenarios for stress analysis.
Done in orea/scenario/stressscenariogenerator.?pp, stressscenariodata.?pp
Requires simulate-able factors and would be required if we want to compute stress scenarios w.r.t. CMS correlations (later)
  
##  OREA: extend FixingManager
Generates historical fixings during XVA simulation.
Sometimes needs to be extended, if new coupon types are added (but not always).
For CMS Spread Coupons we actually need to extend it, because the fixings of the underlying swap indices have to be generated.
  
### Done in orea/simulation/fixingmanager.cpp:

```cpp
#include <qle/cashflows/cmsspread3coupon.hpp>
.....
using namespace std;
using namespace QuantLib;
using namespace QuantExt;
using namespace ore::data;

namespace ore {
namespace analytics {

//! Initialise the manager-

void FixingManager::initialise(const boost::shared_ptr<Portfolio>& portfolio) {

    // loop over all cashflows, populate index map

    for (auto trade : portfolio->trades()) {
        for (auto leg : trade->legs()) {
            for (auto cf : leg) {
                // For any coupon type that requires fixings, 
                // it must be handled here
                // Most coupons are based off a floating rate coupon 
                // and their single index
                // will be captured in section A.
                //
                // Other more exotic coupons (inflation, CMS spreads, etc) 
                // are captured on a
                // case by case basis in section B.
                //
                // In all cases we want to add dates to the fixingMap_ map.

                // A floating rate coupons

                // extract underlying from cap/floored coupons
                boost::shared_ptr<FloatingRateCoupon> frc;
                auto cfCpn = 
                    boost::dynamic_pointer_cast<CappedFlooredCoupon>(cf);
                if (cfCpn)
                    frc = cfCpn->underlying();
                else
                    frc = boost::dynamic_pointer_cast<FloatingRateCoupon>(cf);

                if (frc) {
...
                    auto cmssp3 = 
                    	boost::dynamic_pointer_cast<CmsSpread3Coupon>(frc);
                    if (cmssp3) {
                        fixingMap_[cmssp3->swapSpreadIndex()->swapIndex1()]
                        	.insert(frc->fixingDate());
                        fixingMap_[cmssp3->swapSpreadIndex()->swapIndex2()]
                        	.insert(frc->fixingDate());
                        fixingMap_[cmssp3->swapSpreadIndex()->swapIndex3()]
                        	.insert(frc->fixingDate());
                        continue;
                    }
....
                    fixingMap_[frc->index()].insert(frc->fixingDate());
                }
...
            }
        }
    }

    // Now cache the original fixings so we can re-write on reset()
    for (auto m : fixingMap_) {
        fixingCache_[m.first] = 
           IndexManager::instance().getHistory(m.first->name());
    }
}
```

# Fifth Steps (Miscellaneous)

## Curve Ordering

  - builds a dependency graph between term structures to be built
  - currently only for yield curves, all other curve types are sorted "blockwise"
  - if more complicated dependencies are introduced, this would need generalisation
  - not relevant here, just mentioned for completeness
