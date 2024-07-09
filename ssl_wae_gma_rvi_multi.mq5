//+------------------------------------------------------------------+
//|                                             mql5_ssl_1.mq5 |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//|                                                  Version Notes 1 |
//| Introduction into MQL5. Expert Advisor demonstrates OnInit (),   |
//| OnDeinit () & OnTick () functions. Advisor adds in key Global    |
//| functions which are commonly used. This can be commonly used as  |
//| a template file.                                                 |
//+------------------------------------------------------------------+
//|                                                    Patch Notes 2 |
//|Trailing Stop Loss  05.30.2024                                    |
//|  Process of adding Indicators:
//|      Declare Variables (Inputs), Set up Handle In OnInit
//|      Find Indicator Values Using Copy Buffer
//|      Store Indicator Values Into Variables
//|      Confirm Indicator Long and Short Position                                                                
//|                                                                  
//|Trade Any MT5 Indicator w/ Chart indicator get
//|   youtube.com/watch?v=DMCYVVNKC4M 
//|   Add EA to the chart 
//|   View => Add Data Window 
//|   F1 to reference the documentation of the function 
//|                                                   Patch Notes 3
//| Looking for continuation trades algorithm the NNFX way
//| Determine which indicator will be applying the continuation
//| If the exit indicator has not triggered.
//| *Ignore No trading if price goes past 1x ATR of your baseline for continuation trades
//| *Ignore Volume indicator for continuation trades  
//| Price must never have crossed the other way on the baseline
//| Add a Volume Indicator and Baseline and Exit
//| Waddah Attar Explosion Indicator Find MACD and Signal line index.
//|
//| Strategy Tester does not use the ChartIndicatorGet directly because it runs
//| in a different environment.
//|                                                Patch Notes 4
//| SSL implemented Confirmation
//| Waddah Attar Implemented Volume 
//| Adjust Stop Loss ATR

//|                                                Patch Notes 5
//| Baseline Geometric Mean Moving Average https://www.mql5.com/en/code/49485
//| Change all syntax
//|      - MAX_BUFFER_SIZE is a macro constant in all uppercase
//|      - g_global_counter is a global variable with 'g_' prefix
//|      - local_variable is a local variable in snake_case
//|      - User is a struct in PascalCase
//|      - user_id and user_name are struct members in snake_case
//|      - printMessage is a function in camelCase
//| Geometric Mean Moving average is not displaying correctly in the strategy tester
//| I am going to try to set the date back another year to see if the moving average requires a certain number of bars.
//|                                                Patch Notes 6
//| Changed Geometric Mean Average Indicator to another one YGMA on mql5
//| Still not profitable so I need to look at the continutation to get into more trades
//| Continuation Trades:  
//|      Before adding Continutation need the exit indicator
//|      - Exit Indicator Try WAE our volatility. Even though this goes agains the no nonsense rules because I see opportunity here
//|      - No stick to the rules damn it. RVI Relative Vigor Index. Cross overs
//|      - if RVI crosses from under while in a BEAR move then exit
//|      - if RVI crosses over while in a BULL move then exit 
//|      - Using the video: Introduction - Write your own expert for MT5 - MA Cross
//|      - Adding IsTradeAllowed for safety precautions 
//|                                                Patch Notes 7
//| Finally in the profit zone. 
//| But not enough. So Continuation trades.
//| Price can not be RVI and Price can not be on the opposite side of the baseline to enter new trade
//| Can ignore Volume.

//| Possibly add enter a trade if and only if price is within 1 ATR from the baseline. 
//| Searching for optimizations fro 2.4% annually 
//| Added GMA > YGMA and vice versa
//| Place a pending order   
//|                                                Patch Notes 8
//| Set order types to both market and stops
//| Added RVI Exit as  Confirmation as well  
//| Continuation: If the exit indicator has not triggered.
//| *Ignore No trading if price goes past 1x ATR of your baseline for continuation trades
//| *Ignore Volume indicator for continuation trades  
//| Price must never have crossed the other way on the baseline  

//| Bridge too far
//| Price must cross and close past your baseline
//| Confirmation indicator crossed long 7+ candle ago. NO TRADE.
//| 06.18.2024 Line 345 looping through open trade bars to determine continuation.
//|
//| Patch Notes 9
//| Fixed Partial Take profit at ATR
//| Fixed Adjust Stop Loss
//|   Had to start using PositionGetTickets instead of the Global Variable TicketNumber
//|   I believe this is an improvement to Dillon Grechs' method.
//| Error: Placing orders when orders are already open\
//| Added RVI exit on pending orders 
//| Why didn't 12/21/2022 enter a long trade 
//|   Flipping on and off the currentGMA < priorGMA Baseline.  
//| Why didn't 02.22.2023 not partially close.
//|   Fails with Invalid Volume
//|   Work on adding volume broker requirements  

//| Patch Notes 10
//| I would like to identify big news days and not trade for those first 4 hours and 4 hours prior.
//| Set this up for multi currency if the algorithm produces a profit over 2 year back test. 
//| Exclude news that affects broad market impacts and the pair itself.
//| Anything Federal Reserve do not trad 4 days prior or 4 days after.
//| RBNXZ entered a trade 5 days prior and resulted in a loss.
//|   Check trade state every day. Therefore with this NNFX check on each bar.
//|   Saturday set trade wait  

//| Patch Notes 11
//| No Trade periods around major news events especially when these periods overlap.
//|   Solution create array no trading periods and merge the overlapping no trade periods
//|   Combines them into continuous no-trade periods
//|   Then just check if the current date falls within the no trade periods
//| Complications arose from the 5 days before and 5 days after
//| And overlapping dates
//| AI Code Mentor helped pseudo code       
//| Patch Notes 12
//|  Playing with the amount of no trade days. Increased the number to 6.
//|  Changed to market order & left at 2.0 to 4.0
//|  Implementing multiple currencies.
//|  An Array of symbols and Handles array
//|  Trade on all 27 currency pairs while ensuring that you are only risking 2% of the entire
//|  account balance at any given time.  

//|   will need to check the brokers
//|   Margin Requirements, Minimum Trade Size, Risk management rules, Broker-Specific Restrictions
//|   Starting at line 481 to change TicketNumber because with Multiple currencies there
//|   There is a possibility there will be multiple trades at a time. 

//| Patch notes 13
//|   I want to clean up the different currency pair data into structs clean up OnTick into multiple functions
//|   It is a more flexible and robust way to handle this. 
//+------------------------------------------------------------------+
#property copyright "Cody McKeon"
#property link      "https://www.mql5.com"
#property version   "1.01"

//Include Functions
#include <Trade\Trade.mqh> //Include MQL trade object functions
CTrade   *Trade;           //Declaire Trade as pointer to CTrade class



//+------------------------------------+
// No trade periods |
//+------------------------------------+
struct DateRange {
  datetime start;
  datetime end; 
};

//+------------------------------------------------------+
//| Structure to hold indicator data for a currency pair +
//+------------------------------------------------------+
struct currencyData {
   string symbol;
   int atr_handle[]; // ATR
   double g_current_atr;
   
   int g_handle_ssl[]; // SSL
   string open_signal_ssl;
   
   int g_wae_handle[];// WAE
   string open_signal_gma;
   
   int g_handle_gma[];// GMA
   string open_signal_gma;
   
   int g_handle_rvi[];// RVI
   string open_confirmation_rvi;
   
   int g_order_type; // The Order Type
   bool g_continuation = true; // For Continuation Trades
   string g_continuation_trade = "na";
}

currencyData all_currency_data[];


//Setup Variables
input int                InpMagicNumber  = 2000001;     //Unique identifier for this expert advisor
input string             InpTradeComment = __FILE__;    //Optional comment for trades
input ENUM_APPLIED_PRICE InpAppliedPrice = PRICE_CLOSE; //Applied price for indicators
//Setting Up Order Type
input bool g_stop_order = false;
input bool g_market_order = true;

//Store Position Ticket Number for Trailing Stop Loss
ulong TicketNumber = 0;

//Global Variables
string          IndicatorMetrics    = "";
int             TicksReceivedCount  = 0; //Counts the number of ticks from oninit function
int             TicksProcessedCount = 0; //Counts the number of ticks proceeded from oninit function based off candle opens only
static datetime TimeLastTickProcessed;   //Stores the last time a tick was processed based off candle opens only
int          g_partial_close = 0;
MqlRates    g_bar[];


//Continuation Trades
int g_continuation_trade_direction;
  
int g_continuation_candle_count = 0;

int g_continuation_start_candle = 0; 

//Scaling out variables
double g_open_price;    
double g_buy_current_price;
double g_sell_current_price; 
double g_stop_loss;     
double g_take_profit;   
double g_volume;        
int    g_direction; //0 = Buy 1 = Sell
double g_min_volume;
double g_profit_target;
//DEBUG
double g_buy_difference;
double g_sell_difference;
  
//close half of the position
double g_close_volume;

//Confirmation Ssl Handle and Variables

string g_ssl_name = ""; 

//Volume Wae Handle and Variables

string g_wae_name = "";

//Baseline GMA Handle and Variables

string g_gma_name = "";

//Exit RVI Handle and Variables

string g_rvi_name = "";
input bool g_rvi_exit = true; //Use the exit?

//ATR Handle and Variables

int atr_period  = 10;
 

//Risk Metrics
input double AtrLossMulti      = 1.0;    //ATR Loss Multiple
input double AtrProfitMulti    = 2.0;    //ATR Profit Multiple
input bool   TslCheck          = true;   //Use Trailing Stop Loss?
input bool   RiskCompounding   = false;  //Use Compounded Risk Method?
double       StartingEquity    = 0.0;    //Starting Equity
double       CurrentEquityRisk = 0.0;    //Equity that will be risked per trade
input double MaxLossPrc        = 0.02;   //Percent Risk Per Trade

// List of major news event dates for AUD / NZD and global economics
datetime g_major_news_dates[] = {
   D'2022.06.15 00:00',  // Fed interest rate decision
   D'2022.06.21 00:00',  // RBA meeting minutes
   D'2022.06.29 00:00',  // U.S. GDP data release
   D'2022.07.06 00:00',  // RBA interest rate decision
   D'2022.07.08 00:00',  // U.S. Non-farm payrolls
   D'2022.07.13 00:00',  // U.S. CPI data
   D'2022.07.27 00:00',  // Fed interest rate decision
   D'2022.08.02 00:00',  // RBA interest rate decision
   D'2022.08.05 00:00',  // U.S. Non-farm payrolls
   D'2022.08.10 00:00',  // U.S. CPI data
   D'2022.08.17 00:00',  // RBA meeting minutes
   D'2022.09.02 00:00',  // U.S. Non-farm payrolls
   D'2022.09.06 00:00',  // RBA interest rate decision
   D'2022.09.21 00:00',  // Fed interest rate decision
   D'2022.09.28 00:00',  // U.S. GDP data release
   D'2022.10.04 00:00',  // RBA interest rate decision
   D'2022.10.07 00:00',  // U.S. Non-farm payrolls
   D'2022.10.12 00:00',  // U.S. CPI data
   D'2022.11.01 00:00',  // RBA interest rate decision
   D'2022.11.02 00:00',  // Fed interest rate decision
   D'2022.11.04 00:00',  // U.S. Non-farm payrolls
   D'2022.11.09 00:00',  // U.S. CPI data
   D'2022.11.23 00:00',  // RBA meeting minutes
   D'2022.12.02 00:00',  // U.S. Non-farm payrolls
   D'2022.12.06 00:00',  // RBA interest rate decision
   D'2022.12.14 00:00',  // Fed interest rate decision
   D'2022.12.28 00:00',  // U.S. GDP data release

   D'2023.01.03 00:00',  // RBA interest rate decision
   D'2023.01.06 00:00',  // U.S. Non-farm payrolls
   D'2023.01.11 00:00',  // U.S. CPI data
   D'2023.01.31 00:00',  // Fed interest rate decision
   D'2023.02.01 00:00',  // RBA interest rate decision
   D'2023.02.03 00:00',  // U.S. Non-farm payrolls
   D'2023.02.10 00:00',  // U.S. CPI data
   D'2023.03.07 00:00',  // RBA interest rate decision
   D'2023.03.10 00:00',  // U.S. Non-farm payrolls
   D'2023.03.22 00:00',  // Fed interest rate decision
   D'2023.04.04 00:00',  // RBA interest rate decision
   D'2023.04.07 00:00',  // U.S. Non-farm payrolls
   D'2023.04.12 00:00',  // U.S. CPI data
   D'2023.05.02 00:00',  // RBA interest rate decision
   D'2023.05.05 00:00',  // U.S. Non-farm payrolls
   D'2023.05.10 00:00',  // U.S. CPI data
   D'2023.05.24 00:00',  // RBNZ monetary policy announcement
   D'2023.06.06 00:00',  // RBA interest rate decision
   D'2023.06.07 00:00',  // RBA meeting minutes
   D'2023.06.09 00:00',  // U.S. Non-farm payrolls
   D'2023.06.14 00:00',  // Fed interest rate decision
   D'2023.07.04 00:00',  // RBA interest rate decision
   D'2023.07.07 00:00',  // U.S. Non-farm payrolls
   D'2023.07.12 00:00',  // U.S. CPI data
   D'2023.07.26 00:00',  // Fed interest rate decision
   D'2023.08.01 00:00',  // RBA interest rate decision
   D'2023.08.04 00:00',  // U.S. Non-farm payrolls
   D'2023.08.09 00:00',  // U.S. CPI data
   D'2023.09.05 00:00',  // RBA interest rate decision
   D'2023.09.08 00:00',  // U.S. Non-farm payrolls
   D'2023.09.20 00:00',  // Fed interest rate decision
   D'2023.10.03 00:00',  // RBA interest rate decision
   D'2023.10.06 00:00',  // U.S. Non-farm payrolls
   D'2023.10.11 00:00',  // U.S. CPI data
   D'2023.11.07 00:00',  // RBA interest rate decision
   D'2023.11.03 00:00',  // U.S. Non-farm payrolls
   D'2023.11.08 00:00',  // U.S. CPI data
   D'2023.11.29 00:00',  // U.S. GDP data release
   D'2023.12.05 00:00',  // RBA interest rate decision
   D'2023.12.08 00:00',  // U.S. Non-farm payrolls
   D'2023.12.13 00:00',  // Fed interest rate decision
   D'2023.12.20 00:00',  // RBA meeting minutes
   
   D'2024.01.02 00:00',  // RBA interest rate decision
   D'2024.01.05 00:00',  // U.S. Non-farm payrolls
   D'2024.01.10 00:00',  // U.S. CPI data
   D'2024.01.30 00:00',  // Fed interest rate decision
   D'2024.02.06 00:00',  // RBA interest rate decision
   D'2024.02.02 00:00',  // U.S. Non-farm payrolls
   D'2024.02.09 00:00',  // U.S. CPI data
   D'2024.03.05 00:00',  // RBA interest rate decision
   D'2024.03.08 00:00',  // U.S. Non-farm payrolls
   D'2024.03.20 00:00',  // Fed interest rate decision
   D'2024.04.02 00:00',  // RBA interest rate decision
   D'2024.04.05 00:00',  // U.S. Non-farm payrolls
   D'2024.04.10 00:00',  // U.S. CPI data
   D'2024.04.12 00:00',  // U.S. PPI data release
   D'2024.05.07 00:00',  // RBA interest rate decision
   D'2024.05.03 00:00',  // U.S. Non-farm payrolls
   D'2024.05.08 00:00',  // U.S. CPI data
   D'2024.06.04 00:00',  // RBA interest rate decision
   D'2024.06.07 00:00',  // U.S. Non-farm payrolls
   D'2024.06.12 00:00',  // U.S. CPI data
   D'2024.06.19 00:00'   // Fed interest rate decision  
};

string currency_pairs[] = {
// Major Pairs
    "EURUSD", // Euro/US Dollar
    "USDJPY", // US Dollar/Japanese Yen
    "GBPUSD", // British Pound/US Dollar
    "USDCHF", // US Dollar/Swiss Franc
    "AUDUSD", // Australian Dollar/US Dollar
    "USDCAD", // US Dollar/Canadian Dollar
    "NZDUSD", // New Zealand Dollar/US Dollar

// Minor Pairs (Cross-Currency Pairs)
    "EURGBP", // Euro/British Pound
    "EURJPY", // Euro/Japanese Yen
    "EURCHF", // Euro/Swiss Franc
    "EURAUD", // Euro/Australian Dollar
    "EURCAD", // Euro/Canadian Dollar
    "EURNZD", // Euro/New Zealand Dollar
    "GBPJPY", // British Pound/Japanese Yen
    "GBPCHF", // British Pound/Swiss Franc
    "GBPAUD", // British Pound/Australian Dollar
    "GBPCAD", // British Pound/Canadian Dollar
    "GBPNZD", // British Pound/New Zealand Dollar
    "AUDJPY", // Australian Dollar/Japanese Yen
    "AUDCHF", // Australian Dollar/Swiss Franc
    "AUDCAD", // Australian Dollar/Canadian Dollar
    "AUDNZD", // Australian Dollar/New Zealand Dollar
    "CADJPY", // Canadian Dollar/Japanese Yen
    "CADCHF", // Canadian Dollar/Swiss Franc
    "NZDJPY", // New Zealand Dollar/Japanese Yen
    "NZDCHF", // New Zealand Dollar/Swiss Franc

// Exotic Pairs
    "USDTRY"  // US Dollar/Turkish Lira
};

DateRange g_no_trade_periods[];
int g_no_trade_period_count;
bool g_trading_switch = true;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {  
      //No Trade 
      g_no_trade_period_count = calculateNoTradePeriods(g_major_news_dates, g_no_trade_periods);
      
      //Declare Magic Number for all trades
      Trade = new CTrade();
      Trade.SetExpertMagicNumber(InpMagicNumber);
         
      ArraySetAsSeries(g_bar, true); //For Appending to the end of the array
      
      
      ArrayResize(all_currency_data, ArraySize(currency_pairs));
      
      // Initialize currency structure with all pairs
      for(int i = 0; i < ArraySize(currency_pairs); i++){
         all_currency_data[i].symbol = currency_pairs[i];
      }
      
      // Set up handle for ATR indicator on the initialisation of expert
      for(int i = 0; i < ArraySize(currency_pairs); i++){
         all_currency_data[i].atr_handle = iATR(currency_pairs[i],Period(),atr_period);
         Print("Handle for ATR /", Symbol()," / ", EnumToString(Period()),"successfully created");
         //Error Handling
         if(all_currency_data[i].atr_handle == INVALID_HANDLE) Print(__FUNCTION__, " > Handle is invalid...Check the name!");  
      }
      
      // Setup up handle for ssl indicator on the oninit
      for(int i = 0; i < ArraySize(currency_pairs); i++){
         g_ssl_name = "Market\\ssl.ex5";
         all_currency_data[i].g_handle_ssl = iCustom(currency_pairs[i],Period(),g_ssl_name,13,true,0);
         Print("Handle for SSL /", Symbol()," / ", EnumToString(Period()),"successfully created");
         //Error Handling
         if(all_currency_data[i].g_handle_ssl == INVALID_HANDLE) Print(__FUNCTION__, " > Handle is invalid...Check the name!");
      }
      
      // Setup handle for Waddah Attar Explosion on the OnInit
      for(int i = 0; i < ArraySize(currency_pairs); i++){
         g_wae_name = "Market\\waddah_attar_explosion.ex5";
         all_currency_data[i].g_wae_handle = iCustom(currency_pairs[i], Period(), g_wae_name,20,40,20,2.0,150,400,15,150,false,2,false,false,false,false);
         Print("Handle for WAE /", Symbol()," / ", EnumToString(Period()),"successfully created");
         //Error Handling
         if(all_currency_data[i].g_wae_handle == INVALID_HANDLE) {
            Print(__FUNCTION__, " > Handle is invalid...Check the name!");
            return(INIT_FAILED);
         }
      } 
   
      // Setup handle for Geometric Mean Average on the OnInit
      for(int i = 0; i < ArraySize(currency_pairs); i++){
         g_gma_name = "Market\\YGMA.ex5";
         all_currency_data[i].g_handle_gma = iCustom(currency_pairs[i], Period(), g_gma_name,5,12);
         Print("Handle for GMA /", Symbol()," / ", EnumToString(Period()),"successfully created");
         //Error Handling
         if(all_currency_data[i].g_handle_gma == INVALID_HANDLE) {
            Print(__FUNCTION__, " > Handle is invalid...Check the name!");
            return(INIT_FAILED);
         }
      }
 
      // Setup handle for Relative Vigor Index on the OnInit
      for(int i = 0; i < ArraySize(currency_pairs); i++){
         g_rvi_name = "Market\\rvi.ex5";
         all_currency_data[i].g_handle_rvi = iCustom(currency_pairs[i], Period(), g_rvi_name,10);
         Print("Handle for RVI /", Symbol()," / ", EnumToString(Period()),"successfully created");
         //Error Handling
         if(all_currency_data[i].g_handle_rvi == INVALID_HANDLE) {
            Print(__FUNCTION__, " > Handle is invalid...Check the name!");
            return(INIT_FAILED);
         }
      }
      
      return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
      //TEMPLATE
      //Remove indicator handle from Metatrader Cache
      //IndicatorRelease(HandleMacd);
      IndicatorRelease(atr_handle);
      IndicatorRelease(g_handle_ssl);
      IndicatorRelease(g_wae_handle);
      IndicatorRelease(g_handle_gma);
      IndicatorRelease(g_handle_rvi);
      Print("Handle Released");
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   //Quick check to see if trading is possible
   if (!isTradeAllowed()) return;
   
   //Get the current date of the tick
   datetime current_tick_date = TimeCurrent();
   //Reset
   g_trading_switch = true;
   
   // Set Trading Switch based on Volatility day and Risk Exposure
   if(isNoTradeDay(g_no_trade_periods, g_no_trade_period_count, current_tick_date)){
      Print("Today is a no-trade day due to significant volatility");
      g_trading_switch = false; //Set No Trade Switch
   } else {
      g_trading_switch = true; //Set Yes to Trade Switch
      //Calculate current risk exposure
      double current_risk_percentage = calculateCurrentRiskExposure();
   
      // Calculate available risk
      double available_risk_percentage = MaxLossPrc - current_risk_percentage;
      if(available_risk_percentage <= 0.5){
         Print("No available risk capacity. Skipping trade.");
         g_trading_switch = false; 
      }
   }
   
   //Declare Variables     
   TicksReceivedCount++; //Counts the number of ticks received
   
   // Start looping through the currency pairs and apply strategy
   for (int i = 0; i < ArraySize(currency_pairs); i++){ 
      string symbol = currency_pairs[i];        
      //Checks for new candle
      bool is_new_candle = false;
      if(TimeLastTickProcessed != iTime(symbol,Period(),0))
      {
         is_new_candle = true;
         TimeLastTickProcessed=iTime(symbol,Period(),0);
      }
   
      //If there is a new candle, process any trades
      if(is_new_candle == true && g_trading_switch == true)
      {
         //Output the date of the bar
         datetime current_bar_time = iTime(symbol, PERIOD_CURRENT,0);
         //Convert string to output
         string time_str = TimeToString(current_bar_time, TIME_DATE | TIME_MINUTES);
         Print("Current bar date and time: ", time_str);
      
         //Counts the number of ticks processed
         TicksProcessedCount++;
         
         // Calculate the lot size for the current symbol based on available risk
         // Check if position is still open and or executed. If not open and or executed, return 0.
         // Difference between a pending order and an executed / open order
         // A Continuation trade states that a trade has happened in the past and there
         // was no crossing of the base line. 
         if (!PositionSelect(symbol) && (!OrderSelect(OrderGetTicket(i)))) 
         {            
            // Set the Global Variable to indicate partial close
            g_partial_close = 0;
            // Continuation check baseline
            if(g_continuation_trade_direction == ORDER_TYPE_BUY){
               //Get in trade candle count past baseline data
               //Set symbol string and indicator buffers
               g_continuation_start_candle = 0;
               //Get the Buffer Data for Baseline
               double geo_avg[];
               CopyBuffer(all_currency_data[i].g_handle_gma,0,g_continuation_start_candle,g_continuation_candle_count,geo_avg);
               //Set array as series so bar 0 is current bar
               ArraySetAsSeries(geo_avg, true);
               double price = iClose(symbol, Period(), 1);
               //Loop through bars 
               for(int j = 0; j < ArraySize(geo_avg); j++){
                  //Check bar baseline data in relation to price
                  if(price < geo_avg[j]){
                     //Crossed baseline continuation false
                     all_currency_data[i].g_continuation = false;
                     break;
                  } else {
                     all_currency_data[i].g_continuation = true;
                  }
               }
               
               if(all_currency_data[i].g_continuation == true){
                  // Check the trigger for direction
                  // Set symbol string and indicator buffers
                  g_continuation_start_candle = 0;
                  // How many candles are required to be stored in Expert
                  const int continuation_required_candle = 2;
                  //the upper SSL at 0
                  double continuation_buy_ssl[]; 
                  CopyBuffer(all_currency_data[i].g_handle_ssl,0,g_continuation_start_candle,continuation_required_candle,continuation_buy_ssl);
                  // Current Candle is 1 
                  // Prior Candle is 0
                  // Compare the value to see if there is a value for the buy or sell ssl
                  if((continuation_buy_ssl[1] != DBL_MAX)){ 
                     Print("Buy: ", continuation_buy_ssl[1]);
                     all_currency_data[i].g_continuation_trade = "Long";
                     // Reset Continuation Variables on new open
                     g_continuation_candle_count = 0;
                     all_currency_data[i].g_continuation_trade = "na";
                     g_continuation_start_candle = 0;    
                  } else {
                     all_currency_data[i].g_continuation_trade = "No Continuation";
                  }
               }   
              } else if(g_continuation_trade_direction == ORDER_TYPE_SELL){
                  // Get in trade candle count past baseline data
                  // Set symbol string and indicator buffers
                  g_continuation_start_candle = 0;
                  // Get the Buffer Data 
                  double geo_avg[];
                  CopyBuffer(all_currency_data[i].g_handle_gma,0,g_continuation_start_candle,g_continuation_candle_count,geo_avg);
                  // Set array as series so bar 0 is current bar
                  ArraySetAsSeries(geo_avg, true);
                  double price = iClose(symbol, Period(), 1);
                  //Loop through bars 
                  for(int j = 0; j < ArraySize(geo_avg); j++){
                     //Check bar baseline data in relation to price
                     if(price > geo_avg[j]){
                        //Crossed baseline continuation false
                        g_continuation = false;
                        break;
                     } else {
                        g_continuation = true;
                     }
                 }
                 
                 if(g_continuation == true){
                     //Check the trigger for direction
                     //Set symbol string and indicator buffers
                     g_continuation_start_candle = 0;
                     const int continuation_required_candle   = 2; //How many candles are required to be stored in Expert
     
                     double continuation_sell_ssl[]; //the lower SSL at 1
                     CopyBuffer(g_handle_ssl[i],1,g_continuation_start_candle,continuation_required_candle,continuation_sell_ssl);
              
                     //Current Candle is 1 
                     //Prior Candle is 0
                     // Compare the value to see if there is a value for the buy or sell ssl
                     if((continuation_sell_ssl[1] != DBL_MAX))
                     {
                        Print("Sell: ", continuation_sell_ssl[1]);
                        g_continuation_trade = "Short";
                        //Reset Continuation Variables on new open
                        g_continuation_candle_count = 0;
                        g_continuation_trade = "na";
                        g_continuation_start_candle = 0; 
                     } else {
                        g_continuation_trade = "No continuation";
                     }  
                 }
              }
            }
       
      //Initiate String for indicatorMetrics Variable. This will reset variable each time OnTick function runs.
      string indicator_metrics = "";  
      StringConcatenate(indicator_metrics,symbol," | Last Processed: ",TimeLastTickProcessed," | Open Ticket: ", TicketNumber);
      
      //Strategy Trigger - SSL
      string open_signal_ssl = getSslOpenSignal(); 
      StringConcatenate(indicator_metrics, indicator_metrics, " | SSL Bias: ", open_signal_ssl); //Concatenate indicator values to output comment for user
      
      //Another Confirmation Trigger - RVI
      string open_confirmation_rvi = rviConfirmation();
      StringConcatenate(indicator_metrics, indicator_metrics, " | Confirmation Bias: ", open_confirmation_rvi); //Concatenate indicator values to output comment for user
      
      //Money Management - ATR
      g_current_atr = getAtrValue(); //Gets ATR value double using custom function - convert double to string as per symbol digits
      StringConcatenate(indicator_metrics, indicator_metrics, " | ATR: ", g_current_atr);
           
      //Volume Filter - WAE
      string open_signal_wae = getWaeOpenSignal(); 
      StringConcatenate(indicator_metrics, indicator_metrics, " | WAE Bias: ", open_signal_wae); //Concatenate indicator values to output comment for user
   
      //Baseline Filter - GMA
      string open_signal_gma = getGmaOpenSignal();  
      StringConcatenate(indicator_metrics, indicator_metrics, " | GMA Bias: ", open_signal_gma); //Concatenate indicator values to output comment for user
      
      //Individual Indicator Tester
      if((open_signal_ssl == "Long" && open_signal_wae == "Volume Trade" && open_signal_gma == "Long" && open_confirmation_rvi == "Long")||g_continuation_trade == "Long"){
         if(g_stop_order)
            TicketNumber = ProcessTradeOpen(ORDER_TYPE_BUY_STOP, g_current_atr);
         else if(g_market_order)
            TicketNumber = ProcessTradeOpen(ORDER_TYPE_BUY, g_current_atr);
      } else if((open_signal_ssl == "Short" && open_signal_wae == "Volume Trade" && open_signal_gma == "Short" && open_confirmation_rvi == "Short")||g_continuation_trade == "Short"){
          //Reset Continuation Variables on new open
          if(g_stop_order)
            TicketNumber = ProcessTradeOpen(ORDER_TYPE_SELL_STOP, g_current_atr);
         else if(g_market_order)
            TicketNumber = ProcessTradeOpen(ORDER_TYPE_SELL, g_current_atr);
      } else {
         Print("SSL ",open_signal_ssl);
         Print("RVI ",open_confirmation_rvi);
         Print("WAE ",open_signal_wae);
         Print("GMA ",open_signal_gma);
         Print("ATR ",g_current_atr);
         Print("No Trade Signal from OnTick");
      }
      
      PositionSelect(Symbol());
      //Adjust Open Positions - Trailing Stop Loss
      if(TslCheck == true && (SymbolInfoDouble(Symbol(), SYMBOL_ASK) > PositionGetDouble(POSITION_PRICE_OPEN)) || SymbolInfoDouble(Symbol(), SYMBOL_BID) < PositionGetDouble(POSITION_PRICE_OPEN))
         AdjustTsl(PositionGetTicket(0), g_current_atr, AtrLossMulti);
         
      
    
   
   //Exit Order if the RVI crosses 
   if(g_rvi_exit == true) 
         rviExitOrder(OrderGetInteger(ORDER_TICKET));
         
   //Scaling out Strategy. Take profit at ATR * Profit Multiple and place at break even. Check on every tick.
   if(TicketNumber && (g_order_type == ORDER_TYPE_SELL || g_order_type == ORDER_TYPE_BUY)){
      g_continuation_trade_direction = g_order_type;
      
      //keeping track for continuation trade
      if(is_new_candle == true){
         g_continuation_candle_count++;
      }
      //Exit position - RVI
      if(g_rvi_exit == true) 
         rviExit(PositionGetInteger(POSITION_TICKET));
         
      //Get position details
      g_open_price    = PositionGetDouble(POSITION_PRICE_OPEN);
      g_buy_current_price = SymbolInfoDouble(Symbol(), SYMBOL_BID);
      g_sell_current_price = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
      g_stop_loss     = PositionGetDouble(POSITION_SL);
      g_take_profit   = PositionGetDouble(POSITION_TP);
      g_volume        = PositionGetDouble(POSITION_VOLUME);
      g_direction     = PositionGetInteger(POSITION_TYPE); //0 = Buy 1 = Sell
         
      //Define profit target for scaling out: Dynamic target of ATR with multiplier
      g_current_atr = getAtrValue();
      g_profit_target = g_current_atr;
      g_min_volume = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN);
      
      //close half of the position
      g_close_volume = g_volume / 2;
      
      //DEBUG
      g_sell_difference = g_open_price - g_buy_current_price;
      g_buy_difference = g_sell_current_price - g_open_price;
      
      //Check if the position is eligible for partial close
      if(g_partial_close == 0 && NormalizeDouble(g_close_volume,2) >= g_min_volume){
         //Normalize the volume to try to fix Invalid volume
         g_close_volume = normalizeVolume(g_close_volume);
         if(g_direction == POSITION_TYPE_BUY){
            //For Long Positions
            //Calculate if profit target is reached
            if(g_sell_current_price - g_open_price >= g_profit_target){
               PositionSelect(Symbol());
               Trade.PositionClosePartial(PositionGetTicket(0), g_close_volume);
               //Set the Global Variable to indicate partial close
               g_partial_close = 1;
               //Move stop loss to breakeven for the remaining position
               //Trade.PositionModify(TicketNumber, open_price, 0);
               
            }   
         } else if(g_direction == POSITION_TYPE_SELL) {
            // For Short Positions
            if(g_open_price - g_buy_current_price >= g_profit_target){
               PositionSelect(Symbol());
               Trade.PositionClosePartial(PositionGetTicket(0), g_close_volume);
               //Set the Global Variable to indicate partial close
               g_partial_close = 1;
               //Move stop loss to breakeven for the remaining position
               //Trade.PositionModify(TicketNumber, open_price, 0);   
               
            }
         }  
      }
    }
  } 
          
   //Comment for user
   Comment("\n\rExpert: ", InpMagicNumber, "\n\r",
            "MT5 Server Time: ", TimeCurrent(), "\n\r",
            "Symbols Traded: \n\r", 
            Symbol());
  }
 
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Custom function                                                  |
//+------------------------------------------------------------------+
//Confirmation Trigger
string getSslOpenSignal(){
   //Set symbol string and indicator buffers
   const int start_candle      = 0;
   const int required_candle   = 2; //How many candles are required to be stored in Expert
     
   double sell_ssl[];
   CopyBuffer(g_handle_ssl,3,start_candle,required_candle,sell_ssl);
   double buy_ssl[];
   CopyBuffer(g_handle_ssl,2,start_candle,required_candle,buy_ssl);
   
   //Current Candle is 1 
   //Prior Candle is 0
   // Compare the value to see if there is a value for the buy or sell ssl
   if(sell_ssl[0] == DBL_MAX && buy_ssl[0] == DBL_MAX){
      Print("No Trade");
      return "No SSL Trade";
   }
   else if((sell_ssl[0] != DBL_MAX) && (buy_ssl[0] == DBL_MAX))
   {
      Print("Sell: ", sell_ssl[0]);
      return "Short";
   }
   else if((buy_ssl[0] != DBL_MAX) && (sell_ssl[0] == DBL_MAX))
   {
      Print("Buy: ", buy_ssl[0]);
      return "Long";
   }  
   else
   {
      Print("Error");
      return "Error";
   }
      
}

//Volume Indicator
string getWaeOpenSignal(){
   /* ColorValue     = Buffer  0; //values
      Color          = Buffer 1; //signal 1-long/2-short
      Explosion      = Buffer 2; //Signal value
      Dead           = Buffer 3; //Signal value*/
      
   //Set symbol string and indicator buffers
   const int start_candle      = 0;
   const int required_candles  = 3; //How many candles are required to be stored in Expert
   
   //Get the Buffer Data from Indicator Window 2
   //Signal Line 1
   //DeadZonePip Level 2 
   double macd[];
   double signal[];
   CopyBuffer(g_wae_handle,0,start_candle,required_candles,macd);
   CopyBuffer(g_wae_handle,2,start_candle,required_candles,signal);
   
   
   double current_macd = macd[1]; //Bar that just closed
   double current_signal = signal[1];
   double prior_macd = macd[0];
   double prior_signal = signal[0];
   
   Print("Current Macd ", macd[1]);
   Print("Current Signal ", signal[1]);
   
   if(current_macd>=current_signal)
      return "Volume Trade";
   else
      return "Volume No Trade";
  
}

//Volume Indicator
string getGmaOpenSignal(){
      
   //Set symbol string and indicator buffers
   const int start_candle      = 0;
   const int required_candle  = 3; //How many candles are required to be stored in Expert
   
   //Get the Buffer Data 
   double geo_avg[];
   double ygma_avg[];
   
   CopyBuffer(g_handle_gma,0,start_candle,required_candle,geo_avg);
   CopyBuffer(g_handle_gma,1,start_candle,required_candle,ygma_avg);
   
   double current_gma = geo_avg[1]; //Bar that just closed
   double current_ygma = ygma_avg[1]; //Bar that just closed
   double prior_gma   = geo_avg[0];
   double price       = iClose(Symbol(), Period(), 1);
   
   Print("Current Gma ", geo_avg[1]);
   Print("Prior Gma ", geo_avg[0]);
   Print("Price ", price);
   
   if((price < current_gma))
      return "Short";
   else if((price > current_gma))
      return "Long";
   else
      return "Baseline No Trade";
  
}

//Custom function
// Exit Indicator
// RVI
// Crossover 
void rviExit(ulong ticket_number)
{
   //Set symbol string and variables
   string current_symbol   = Symbol();
   double rvi_buffer[];
   double signal_buffer[];
 
   const int start_candle      = 0;
   const int required_candle  = 3; //How many candles are required to be stored in Expert
   
   //Check correct ticket number is selected for further position data to be stored. Return if error.
   if (!PositionSelectByTicket(ticket_number))
      return;

   //Store position data variables
   ulong  position_direction = PositionGetInteger(POSITION_TYPE);
   
  // The RVI will be above the signal line
      // RVI 0 Signal 1
      // Get the rvi and signal values for bar 1 and bar 2
      // Compare, if Rvi 1 is above signal 1 and fast 2 is not above slow 2 then there is a cross up.
   if(CopyBuffer(g_handle_rvi,0,start_candle,required_candle,rvi_buffer) < 3)
   {
      Print("Insufficient results from RVI");
      return;
   } 
       
   if(CopyBuffer(g_handle_rvi,1,start_candle,required_candle,signal_buffer) < 3) 
   {
      Print("Insufficient results from SIGNAL");
      return;
   }
   //Check if position direction is long 
   if (position_direction == POSITION_TYPE_BUY)
   {
      if((rvi_buffer[1] < signal_buffer[1]) && (rvi_buffer[0] >= signal_buffer[0])) {
            //Close Trade if long.
            Trade.PositionClose(Symbol(), ticket_number);
            g_continuation = false;
            return;
         }
      //Return once complete
      return;
   } 
   
   //Check if position direction is short 
   if (position_direction == POSITION_TYPE_SELL)
   {
      if((rvi_buffer[1] > signal_buffer[1]) && (rvi_buffer[0] <= signal_buffer[0])) 
      {
         //Close Trade if short.
         Trade.PositionClose(Symbol(), ticket_number);
         g_continuation = false;
         return;
      }
      //Return once complete
      return;
   } 
}

//Custom function
// Exit Indicator
// RVI
// Crossover 
void rviExitOrder(ulong ticket_number)
{
   //Set symbol string and variables
   string current_symbol   = Symbol();
   double rvi_buffer[];
   double signal_buffer[];
 
   const int start_candle      = 0;
   const int required_candle  = 3; //How many candles are required to be stored in Expert
   
   //Check correct ticket number is selected for further position data to be stored. Return if error.
   if (!OrderSelect(ticket_number))
      return;

   //Store position data variables
   ulong  order_direction = OrderGetInteger(ORDER_TYPE);
   
  // The RVI will be above the signal line
      // RVI 0 Signal 1
      // Get the rvi and signal values for bar 1 and bar 2
      // Compare, if Rvi 1 is above signal 1 and fast 2 is not above slow 2 then there is a cross up.
   if(CopyBuffer(g_handle_rvi,0,start_candle,required_candle,rvi_buffer) < 3)
   {
      Print("Insufficient results from RVI");
      return;
   } 
       
   if(CopyBuffer(g_handle_rvi,1,start_candle,required_candle,signal_buffer) < 3) 
   {
      Print("Insufficient results from SIGNAL");
      return;
   }
   //Check if position direction is long 
   if (order_direction == ORDER_TYPE_BUY_STOP)
   {
      if((rvi_buffer[2] < signal_buffer[2])) {
            //Close Trade if long.
            Trade.OrderDelete(ticket_number);
            g_continuation = false;
            return;
         }
      //Return once complete
      return;
   } 
   
   //Check if position direction is short 
   if (order_direction == ORDER_TYPE_SELL_STOP)
   {
      if((rvi_buffer[2] > signal_buffer[2])) 
      {
         //Close Trade if short.
         Trade.OrderDelete(ticket_number);
         g_continuation = false;
         return;
      }
      //Return once complete
      return;
   } 
}

//RVI Confirmation
string rviConfirmation()
{
   //Set symbol string and variables
   string current_symbol   = Symbol();
   double rvi_buffer[];
   double signal_buffer[];
 
   const int start_candle      = 0;
   const int required_candle  = 3; //How many candles are required to be stored in Expert
   
  // The RVI will be above the signal line
      // RVI 0 Signal 1
      // Get the rvi and signal values for bar 1 and bar 2
      // Compare, if Rvi 1 is above signal 1 and fast 2 is not above slow 2 then there is a cross up.
   if(CopyBuffer(g_handle_rvi,0,start_candle,required_candle,rvi_buffer) < 3)
   {
      Print("Insufficient results from RVI");
      return "Insufficient results from RVI";
   } 
       
   if(CopyBuffer(g_handle_rvi,1,start_candle,required_candle,signal_buffer) < 3) 
   {
      Print("Insufficient results from SIGNAL");
      return "Insufficient results from SIGNAL";
   }
   //Check if RVI is short 
   if((rvi_buffer[2] <= signal_buffer[2])) {
      return "Short";
   }
   //Check if RVI is long
   if((rvi_buffer[2] >= signal_buffer[2])) 
   {
      return "Long";
   }
   return "Nothing Happened";  
}

//Adjust Trailing Stop Loss based off ATR
void AdjustTsl(ulong Ticket, double CurrentAtr, double AtrMulti)
{
   //Set symbol string and variables
   string CurrentSymbol   = Symbol();
   double Price           = 0.0;
   double OptimalStopLoss = 0.0;  

   //Check correct ticket number is selected for further position data to be stored. Return if error.
   PositionSelect(Symbol());
   if (!PositionSelectByTicket(PositionGetTicket(0)))
      return;

   //Store position data variables
   ulong  PositionDirection = PositionGetInteger(POSITION_TYPE);
   double CurrentStopLoss   = PositionGetDouble(POSITION_SL);
   double CurrentTakeProfit = PositionGetDouble(POSITION_TP);
   
   //Check if position direction is long 
   if (PositionDirection==POSITION_TYPE_BUY)
   {
      //Get optimal stop loss value
      Price           = NormalizeDouble(SymbolInfoDouble(CurrentSymbol, SYMBOL_ASK), Digits());
      OptimalStopLoss = NormalizeDouble(Price - CurrentAtr*AtrMulti, Digits());
      
      //Check if optimal stop loss is greater than current stop loss. If TRUE, adjust stop loss
      if(OptimalStopLoss > CurrentStopLoss)
      {
         PositionSelect(Symbol());
         Trade.PositionModify(PositionGetTicket(0),OptimalStopLoss,CurrentTakeProfit);
         Print("Ticket ", PositionGetTicket(0), " for symbol ", CurrentSymbol," stop loss adjusted to ", OptimalStopLoss);
      }

      //Return once complete
      return;
   } 

   //Check if position direction is short 
   if (PositionDirection==POSITION_TYPE_SELL)
   {
      //Get optimal stop loss value
      Price           = NormalizeDouble(SymbolInfoDouble(CurrentSymbol, SYMBOL_BID), Digits());
      OptimalStopLoss = NormalizeDouble(Price + CurrentAtr*AtrMulti, Digits());

      //Check if optimal stop loss is less than current stop loss. If TRUE, adjust stop loss
      if(OptimalStopLoss < CurrentStopLoss)
      {
         PositionSelect(Symbol());
         Trade.PositionModify(PositionGetTicket(0),OptimalStopLoss,CurrentTakeProfit);
         Print("Ticket ", PositionGetTicket(0), " for symbol ", CurrentSymbol," stop loss adjusted to ", OptimalStopLoss);
      }
      
      //Return once complete
      return;
   } 
}
//Custom Function
//isTradeAllowed()
//bool
bool isTradeAllowed()
{
   return((bool)MQLInfoInteger(MQL_TRADE_ALLOWED) && //Trading allowed in input dialog
          (bool)TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) && //Trading allowed in terminal
          (bool)AccountInfoInteger(ACCOUNT_TRADE_ALLOWED) && //Is account able to trade
          (bool)AccountInfoInteger(ACCOUNT_TRADE_EXPERT)); //Is account able to auto trade
}

//Custom Function to get ATR value
double getAtrValue()
{
   //Set symbol string and indicator buffer
   const int start_candle     = 0;
   const int required_candles = 3; //How many candles are required to be stored in Expert 

   //Indicator Variables and Buffers
   const int index_atr        = 0; //ATR Value
   double    atr_buffer[];         //[prior,current confirmed,not confirmed] 

   //Populate buffers for ATR Value; check errors
   bool fill_atr = CopyBuffer(atr_handle,index_atr,start_candle,required_candles,atr_buffer); //Copy buffer uses oldest as 0 (reversed)
   if(fill_atr==false)return(0);

   //Find ATR Value for Candle '1' Only
   double current_atr   = NormalizeDouble(atr_buffer[1],5);

   //Return ATR Value
   return(current_atr);
}

//Finds the optimal lot size for the trade - Orghard Forex mod by Dillon Grech
//https://www.youtube.com/watch?v=Zft8X3htrcc&t=724s
double OptimalLotSize(string CurrentSymbol, double EntryPrice, double StopLoss)
{
   //Set symbol string and calculate point value
   double TickSize      = SymbolInfoDouble(CurrentSymbol,SYMBOL_TRADE_TICK_SIZE);
   double TickValue     = SymbolInfoDouble(CurrentSymbol,SYMBOL_TRADE_TICK_VALUE);
   if(SymbolInfoInteger(CurrentSymbol,SYMBOL_DIGITS) <= 3)
      TickValue = TickValue/100;
   double PointAmount   = SymbolInfoDouble(CurrentSymbol,SYMBOL_POINT);
   double TicksPerPoint = TickSize/PointAmount;
   double PointValue    = TickValue/TicksPerPoint;

   //Calculate risk based off entry and stop loss level by pips
   double RiskPoints = MathAbs((EntryPrice - StopLoss)/TickSize);
      
   //Set risk model - Fixed or compounding
   if(RiskCompounding == true)
      CurrentEquityRisk = AccountInfoDouble(ACCOUNT_EQUITY);
   else
      CurrentEquityRisk = StartingEquity; 

   //Calculate total risk amount in dollars
   double RiskAmount = CurrentEquityRisk * MaxLossPrc;

   //Calculate lot size
   double RiskLots   = NormalizeDouble(RiskAmount/(RiskPoints*PointValue),2);


   //Print values in Journal to check if operating correctly
   PrintFormat("TickSize=%f,TickValue=%f,PointAmount=%f,TicksPerPoint=%f,PointValue=%f,",
                  TickSize,TickValue,PointAmount,TicksPerPoint,PointValue);   
   PrintFormat("EntryPrice=%f,StopLoss=%f,RiskPoints=%f,RiskAmount=%f,RiskLots=%f,",
                  EntryPrice,StopLoss,RiskPoints,RiskAmount,RiskLots);   

   //Return optimal lot size
   return RiskLots;
}

//Processes open trades for buy and sell
ulong ProcessTradeOpen(ENUM_ORDER_TYPE order_type, double CurrentAtr)
{
   //Set symbol string and variables
   string CurrentSymbol   = Symbol();  
   double Price           = 0;
   double StopLossPrice   = 0;
   double TakeProfitPrice = 0;
   double spread = SymbolInfoDouble(CurrentSymbol, SYMBOL_ASK) - SymbolInfoDouble(CurrentSymbol, SYMBOL_BID);
   
   //Get Previous Bars information for Pending Stop Orders
   CopyRates(Symbol(), PERIOD_CURRENT, 0, 2, g_bar);
   double high = g_bar[1].high;
   double low = g_bar[1].low;
   

   //Get price, stop loss, take profit for open and close orders
   if(order_type == ORDER_TYPE_BUY_STOP || order_type == ORDER_TYPE_BUY)
   {
      Price           = NormalizeDouble(SymbolInfoDouble(CurrentSymbol, SYMBOL_ASK), Digits());
      StopLossPrice   = NormalizeDouble(Price - CurrentAtr*AtrLossMulti, Digits());
      TakeProfitPrice = NormalizeDouble(Price + CurrentAtr*AtrProfitMulti, Digits());
   }
   else if(order_type == ORDER_TYPE_SELL_STOP || order_type == ORDER_TYPE_SELL)
   {
      Price           = NormalizeDouble(SymbolInfoDouble(CurrentSymbol, SYMBOL_BID), Digits());
      StopLossPrice   = NormalizeDouble(Price + CurrentAtr*AtrLossMulti, Digits());
      TakeProfitPrice = NormalizeDouble(Price - CurrentAtr*AtrProfitMulti, Digits());  
   }
   
   //Get lot size
   double LotSize = OptimalLotSize(CurrentSymbol,Price,StopLossPrice);
   LotSize = (int)(LotSize/SymbolInfoDouble(CurrentSymbol,SYMBOL_VOLUME_STEP)) * SymbolInfoDouble(CurrentSymbol,SYMBOL_VOLUME_STEP);
   LotSize = MathMin(LotSize,SymbolInfoDouble(CurrentSymbol,SYMBOL_VOLUME_MAX));
   LotSize = MathMax(LotSize,SymbolInfoDouble(CurrentSymbol,SYMBOL_VOLUME_MIN));
   Print("Lots Trade Open: ", LotSize);
   
   //Exit any trades that are currently open. Enter new trade.
   Trade.PositionClose(CurrentSymbol);
   
   
   if(order_type == ORDER_TYPE_BUY_STOP)
   {
      TicketNumber = Trade.BuyStop(LotSize, high+spread, Symbol(), StopLossPrice, TakeProfitPrice, ORDER_TIME_GTC);
   }
   else if(order_type == ORDER_TYPE_SELL_STOP)
   {
      TicketNumber = Trade.SellStop(LotSize, low-spread, Symbol(), StopLossPrice, TakeProfitPrice, ORDER_TIME_GTC);
   } else {
      //For Market Orders
      TicketNumber = Trade.PositionOpen(CurrentSymbol,order_type,LotSize,Price,StopLossPrice,TakeProfitPrice,InpTradeComment);
      //Used for market order
      //Get Position Ticket Number
      PositionSelect(Symbol());
      ulong  Ticket = PositionGetTicket(0);
   }
   
   //Add in any error handling
   Print("Trade Processed For ", CurrentSymbol," OrderType ",order_type, " Lot Size ", LotSize, " Current Atr: ", CurrentAtr," Ticket: ", PositionGetTicket(0));
   Print("Volume ", PositionGetDouble(POSITION_VOLUME));
   Print("Close Volume ", PositionGetDouble(POSITION_VOLUME) / 2);
   Print("Minimum Volume ", SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN));

   // Return ticket number
   return(TicketNumber);
}

//+-------------------------------------------------------------------------------------
/* Normalize volume to meet broker requirements*/
//+------------------------------------------------------------------
double normalizeVolume(double volume){
   double min_volume = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN);
   double max_volume = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX);
   double volume_step = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_STEP);
   
   // Ensure the volume is within the allowed range
   if (volume < min_volume)
      volume = min_volume;
   else if(volume > max_volume)
      volume = max_volume;
      
   // Ensure the volume is a multiple of the volume step
   volume = MathFloor(volume / volume_step) * volume_step;
   
   // Check if the normalized volume is still valid
   if (volume < min_volume || volume > max_volume)
   {
      Print("Normalized volume is invalid: ", volume);
      return -1;
   }
   
   return volume;
}


//Determine if trading is allowed based on time
bool isNoTradeDay(DateRange &no_trade_period[], int size, datetime today){
   // For Live Trading
   //datetime today = __DATE__;
   
   // For Testing
   today = stripTime(today);
   
   for(int i=0; i < size; i++){
      // need to make the dates comparable by year month and day
      datetime start = stripTime(no_trade_period[i].start);
      datetime end = stripTime(no_trade_period[i].end);
      
      if(today >= start && today <= end){
         return true;
      }
   }
   return false;
}

//Function to strip time component
datetime stripTime(datetime dt){
   MqlDateTime mdt;
   TimeToStruct(dt, mdt);
   mdt.hour = 0;
   mdt.min = 0;
   mdt.sec = 0;
   return StructToTime(mdt);
}

//--------------------------------------------------------------
// calculateNoTradePeriods
// datetime events, DateRange &noTradePeriods[]
//--------------------------------------------------------------
int calculateNoTradePeriods(datetime &events[], DateRange &no_trade_periods[]) {
   int count = ArraySize(events);
   ArrayResize(no_trade_periods, count);
   
   for(int i=0; i < count; i++){
      no_trade_periods[i].start = events[i] - 6 * 86400;
      no_trade_periods[i].end = events[i] + 6 * 86400;
   }
   
   //ArraySort(no_trade_periods); !constant cannot be modified
   bubbleSort(no_trade_periods, count);
   
   //Merged array
   int newSize = 0;
   //Merge overlapping periods
   for(int i = 0; i < count; i++){
      if(newSize == 0 || (no_trade_periods[newSize - 1].end < no_trade_periods[i].start)){
         no_trade_periods[newSize] = no_trade_periods[i];
         newSize += 1;    
      } else {
         // If the current period overlpas with the previous, extend the previous period's end date
         no_trade_periods[newSize - 1].end = MathMax(no_trade_periods[newSize - 1].end, no_trade_periods[i].end);
      }
   }
   
   //Resize the noTradePeriods array to the new merged size
   ArrayResize(no_trade_periods, newSize);
   
   return newSize; // Return the number of merged no-trade periods
}

// Comparison function
// to sort DateRange by start date
int compareDateRange(const DateRange &a, const DateRange &b){
   if(a.start < b.start) return -1;
   if(a.start > b.start) return 1;
   return 0;
}

// Custome bubble sort function for DateRange array
void bubbleSort(DateRange &arr[], int size){
   for(int i = 0; i < size - 1; i++){
      for(int j = 0; j < size - i - 1; j++){
         if(compareDateRange(arr[j], arr[j+1]) > 0){
            //Swap the elements
            DateRange temp = arr[j];
            arr[j] = arr[j+1];
            arr[j+1] = temp;     
         }
      }
   }
}

// Function to calculate the current risk exposure from all open trades
double calculateCurrentRiskExposure() {
   double total_risk = 0.0;
   double account_balance = AccountInfoDouble(ACCOUNT_BALANCE);
  
   // Loop through all open positions
   for(int i = 0; i < PositionsTotal(); i++) {
   ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket)) {
         if(position_direction == POSITION_TYPE_BUY || position_direction == POSITION_TYPE_SELL){
            string symbol = PositionGetString(POSITION_SYMBOL);
            double volume = PositionGetDouble(POSITION_VOLUME);
            double stop_loss = PositionGetDouble(POSITION_SL);
            double price = PositionGetDouble(POSITION_PRICE_OPEN);
            //Calculate the pip value
            double pip_value = getPipValue(symbol, volume);
            double stop_loss_pips = stopLossToPips(price, stop_loss, symbol);
            double risk = volume * stop_loss_pips * pip_value;
         
            total_risk += risk; 
         }
      }
   }
   
   //Calculate the risk as a percentage of the account balance
   double total_risk_percentage = (total_risk / account_balance) * 100.0;
   return total_risk_percentage;
}

double getPipValue(string symbol, double volume)
{
   // Get the point size for the symbol
   double pointSize = SymbolInfoDouble(symbol, SYMBOL_POINT);
   
   // Get the lot size (assume 1 standard lot, i.e., 100,000 units of base currency)
  
   // Get the contract size
   double contractSize = SymbolInfoDouble(symbol, SYMBOL_TRADE_CONTRACT_SIZE);
   
   // Calculate the pip value
   double pipValue = pointSize * contractSize * volume;

   // Adjust pip value for currency pairs that are not quoted in account currency
   if (SymbolInfoString(symbol, SYMBOL_CURRENCY_PROFIT) != AccountInfoString(ACCOUNT_CURRENCY))
   {
      double rate = 1.0;
      if (SymbolInfoString(symbol, SYMBOL_CURRENCY_PROFIT) + AccountInfoString(ACCOUNT_CURRENCY) != "USDUSD")
      {
         rate = SymbolInfoDouble(SymbolInfoString(symbol, SYMBOL_CURRENCY_PROFIT) + AccountInfoString(ACCOUNT_CURRENCY), SYMBOL_BID);
      }
      pipValue *= rate;
   }
   
   return pipValue;
}


//| Function to convert stop loss level to pips
double stopLossToPips(double entry_price, double stop_loss_price, string symbol){
   //Get the point size for the symbol
   double point_size = SymbolInfoDouble(symbol, SYMBOL_POINT);
   
   //Calculate the price difference
   double price_difference = MathAbs(entry_price - stop_loss_price);
   
   //Convert the price difference to pips
   double stop_loss_pips = price_difference / point_size;
   
   return stop_loss_pips;
}

//| Calculate Required Margin
double calculateRequiredMargin(string symbol, double volume){
   double margin = 0.0;
   if(OrderCalcMargin(ORDER_TYPE_BUY, symbol, volume, SymbolInfoDouble(symbol, SYMBOL_BID), margin)){
      return margin;
   } else {
      Print("Error calculating margin: ", GetLastError());
      return -1;
   }
}

//| Check Sufficient Margin
bool checkSufficientMargin(string symbol, double volume){
   double required_margin = calculateRequiredMargin(symbol, volume);
   double free_margin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
   
   if(free_margin >= required_margin){
      Print("Sufficient margin available.");
      return true;
   } else {
      Print("Insufficient margin. Required: ", required_margin, " Free: ", free_margin);
      return false;
   }
}

