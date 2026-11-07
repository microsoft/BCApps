codeunit 137182 "Costing Corsica Features"
{
    Subtype = Test;

    trigger OnRun()
    begin
    end;

    var
        Corsica_UpdateSalesStatistics: Codeunit Corsica_UpdateSalesStatistics;
        RunManager: Codeunit "Testscript Run Manager";
        Corsica_ClosingInventoryPeriod: Codeunit Corsica_ClosingInventoryPeriod;
        Corsica_Resiliency: Codeunit Corsica_Resiliency;
        Corsica_AdjCostOfCOGS: Codeunit Corsica_AdjCostOfCOGS;
        Corsica_TracingCost_VE_GL: Codeunit Corsica_TracingCost_VE_GL;
        Corsica_ValuingInvtAtAvgCost: Codeunit Corsica_ValuingInvtAtAvgCost;
        CETAFInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure Corsica_UpdateSalesStatTC1()
    begin
        // [FEATURE] [Sales Statistics] [Adjust Cost Item Entries] [Cost Standard] [FIFO] [Revaluation]
        // [SCENARIO TC-1-1] Customer and Inv/CrM Statistics reflect Positive Revaluation with Adjustment

        // [GIVEN] Purch Order (partially ship/inv); Sales Order (partially ship/inv);
        // [THEN] Sales Invoice Statistics; Customer Statistics

        // [GIVEN] AdjCostItemEntries; Revaluation
        // [WHEN] Adjust Cost Item Entries
        // [THEN] Sales Invoice Statistics; Customer Statistics

        // [GIVEN] Purch Order (fully invoiced); Sales Ret.Order invoiced;
        // [THEN] Sales Credit Memo Statistics; Customer Statistics

        // [GIVEN] Sales CrM2;
        // [THEN] Sales Credit Memo Statistics; Customer Statistics

        // [WHEN] Adjust Cost Item Entries
        // [THEN] Customer Statistics; Sales Invoice Statistics; Sales Credit Memo Statistics (CrM1,2)

        CETAFInitialize();
        Corsica_UpdateSalesStatistics.PerformTestCase1();
        RunManager.ValidateRun('Corsica_UpdateSalesStatistics', 'PerformTestCase1');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Corsica_UpdateSalesStatTC2()
    begin
        // [FEATURE] [Sales Statistics] [Adjust Cost Item Entries] [Cost Standard] [Cost Average] [Revaluation]
        // [SCENARIO TC-1-2] Customer and Inv/CrM Statistics reflect Positive Revaluation without Adjustment

        // [GIVEN] Purch Inv; Sales Inv;
        // [THEN] Sales Invoice Statistics; Customer Statistics

        // [GIVEN] Revaluation; Sales Inv;
        // [THEN] Sales Invoice Statistics; Customer Statistics

        // [GIVEN] Sales Ret. Order invoiced;
        // [THEN] Sales Credit Memo Statistics; Customer Statistics

        // [GIVEN] Sales CrM;
        // [THEN] Sales Credit Memo Statistics; Customer Statistics

        CETAFInitialize();
        Corsica_UpdateSalesStatistics.PerformTestCase2();
        RunManager.ValidateRun('Corsica_UpdateSalesStatistics', 'PerformTestCase2');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Corsica_UpdateSalesStatTC3()
    begin
        // [FEATURE] [Sales Statistics] [Adjust Cost Item Entries] [Cost Standard] [FIFO] [Revaluation]
        // [SCENARIO TC-2-1] Customer and Inv/CrM Statistics reflect Negative Revaluation with Adjustment

        // [GIVEN] Sales Order1 (partially ship/inv);
        // [THEN] Sales Invoice Statistics; Customer Statistics

        // [GIVEN] Purch Order (partially ship/inv); Sales Inv2; MOdify Purch Order - decrease cost;Purch Order (fully ship/inv)
        // [WHEN] Adjust Cost Item Entries
        // [THEN] Sales Invoice Statistics (Inv1,2); Customer Statistics

        // [GIVEN] Sales Order1 (fully invoiced);
        // [WHEN] Adjust Cost Item Entries
        // [THEN] Sales Invoice Statistics (Inv3); Customer Statistics

        // [GIVEN] Revaluation;
        // [WHEN] Adjust Cost Item Entries
        // [THEN] Sales Invoice Statistics (Inv2); Customer Statistics

        // [GIVEN] Sales Ret. Order1 invoiced;
        // [THEN] Sales Credit Memo Statistics; Customer Statistics

        // [GIVEN] Sales Ret. Order2 invoiced;
        // [THEN] Customer Statistics

        // [GIVEN] Sales CrM;
        // [THEN] Sales Credit Memo Statistics; Customer Statistics

        CETAFInitialize();
        Corsica_UpdateSalesStatistics.PerformTestCase3();
        RunManager.ValidateRun('Corsica_UpdateSalesStatistics', 'PerformTestCase3');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Corsica_UpdateSalesStatTC4()
    begin
        // [FEATURE] [Sales Statistics] [Adjust Cost Item Entries] [Cost Standard] [Cost Average] [Item Charges] [ACY]
        // [SCENARIO TC-3-1] Customer and Inv/CrM Statistics reflect Item Charges (Inventoriable)

        // [GIVEN] ACY is set
        // [GIVEN] Purch Inv (3 lines, 2nd line is Item Charges for 1st line); Adjust Cost Item Entries; Sales Order (partially ship/inv)
        // [THEN] Sales Invoice (Inv1) Statistics; Customer Statistics

        // [GIVEN] Sales CrM (avg)
        // [THEN] Sales Credit Memo Statistics; Customer Statistics

        // [GIVEN] Sales Inv (by Get shipment lines)
        // [THEN] Sales Invoice (Inv2) Statistics; Customer Statistics

        // [GIVEN] Sales CrM (std);
        // [THEN] Sales Credit Memo Statistics; Customer Statistics

        // [GIVEN] Sales Order (std)(partially ship/inv);
        // [THEN] Sales Invoice (Inv3) Statistics; Customer Statistics

        // [GIVEN] Purch Order (2 lines of Item Charges assigned to Rcpts); Adjust Cost Item Entries;
        // [THEN] Sales Invoice Statistics (Inv1, Inv2); Customer Statistics

        // [GIVEN] Purch Inv (Item Charges assigned)
        // [THEN] Sales Invoice Statistics (Inv1, Inv2); Customer Statistics

        CETAFInitialize();
        Corsica_UpdateSalesStatistics.PerformTestCase4();
        RunManager.ValidateRun('Corsica_UpdateSalesStatistics', 'PerformTestCase4');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Corsica_UpdateSalesStatTC5()
    begin
        // [FEATURE] [Sales Statistics] [Adjust Cost Item Entries] [Cost Standard] [FIFO] [Item Charges] [Non-Inventoriable] [ACY]
        // [SCENARIO TC-3-2] Customer and Inv/CrM Statistics reflect Item Charges (Non-Inventoriable)

        // [GIVEN] ACY is set
        // [GIVEN] Purch Order (partially rcpt/inv); Sales Shpt (fifo); Sales Inv2 (std)
        // [THEN] Sales Invoice Statistics (Inv1); Customer Statistics

        // [GIVEN] Invoice Sales Order (Inv2); Invoice Purch Order (fifo); Adjust Cost Item Entries;
        // [THEN] Sales Invoice Statistics (Inv2); Customer Statistics

        // [GIVEN] Sales CrM1 (fifo);
        // [THEN] Sales Credit Memo (Crm1) Statistics; Customer Statistics

        // [GIVEN] Sales Order (1 line of Item Charge assigned to diff Shpt and Ret.Rcpt); Adjust Cost Item Entries;

        // [GIVEN] Sales CrM2 (std);
        // [THEN] Sales Credit Memo (CrM2) Statistics; Customer Statistics

        CETAFInitialize();
        Corsica_UpdateSalesStatistics.PerformTestCase5();
        RunManager.ValidateRun('Corsica_UpdateSalesStatistics', 'PerformTestCase5');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Corsica_UpdateSalesStatTC7()
    begin
        // [FEATURE] [Sales Statistics] [FIFO] [ACY]
        // [SCENARIO TC-5-1] Customer and Inv/CrM Statistics reflect Negative Quantity in Sales Document Lines

        // [GIVEN] ACY is set
        // [GIVEN] Sales Order1 (partially ship/inv);
        // [GIVEN] Add a new line with negative quantity
        // [WHEN] Sales Order1 (fully ship/inv);
        // [THEN] Sales Invoice Statistics (Inv2); Customer Statistics

        // [WHEN] Sales CrM1 with pos/neg Qty in lines, where total in 0
        // [THEN] Sales Credit Memo Statistics; Customer Statistics

        CETAFInitialize();
        Corsica_UpdateSalesStatistics.PerformTestCase7();
        RunManager.ValidateRun('Corsica_UpdateSalesStatistics', 'PerformTestCase7');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Corsica_UpdateSalesStatTC9()
    begin
        // [FEATURE] [Sales Statistics] [Adjust Cost Item Entries] [Cost Standard] [Cost Average] [Item Charges] [Revaluation] [ACY]
        // [SCENARIO TC-9-1] Customer and Inv/CrM Statistics reflect all Sources of Cost Change apply (complete shipment)

        // [GIVEN] ACY is set
        // [GIVEN] Purch Order1, 1 line Item Charges (partially rcpt/inv);

        // [WHEN] Sales Order1 (Item Charges,Item,Res) (partially ship/inv);
        // [THEN] Sales Invoice Statistics; Customer Statistics

        // [GIVEN] Adjust Cost Item Entries; Revaluation;
        // [WHEN] Adjust Cost Item Entries
        // [THEN] Sales Invoice Statistics; Customer Statistics

        // [WHEN] Sales Ret.Order1 (Item Charges,Item,Res) (partially ship/inv);
        // [THEN] Sales Credit Memo Statistics; Customer Statistics

        // [WHEN] Sales CrM2 (Item,2 x Res) (partially ship/inv);
        // [THEN] Sales Credit Memo (CrM2) Statistics; Customer Statistics

        // [WHEN] Sales Order1 - Invoiced
        // [THEN] Customer Statistics

        CETAFInitialize();
        Corsica_UpdateSalesStatistics.PerformTestCase9();
        RunManager.ValidateRun('Corsica_UpdateSalesStatistics', 'PerformTestCase9');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Corsica_UpdateSalesStatTC10()
    begin
        // [FEATURE] [Sales Statistics] [Adjust Cost Item Entries] [Cost Standard] [FIFO] [Item Charges] [Revaluation] [ACY]
        // [SCENARIO TC-9-1] Customer and Inv/CrM Statistics reflect all Sources of Cost Change apply (partial shipment)

        // [GIVEN] ACY is set
        // [GIVEN] Purch Inv1, 1 line Item Charges
        // [WHEN] 2 x Sales Inv (partially ship/inv)
        // [THEN] Sales Invoice (Inv1,2) Statistics; Customer Statistics

        // [GIVEN] Sales Ret.Order1
        // [WHEN] Adjust Cost Item Entries
        // [THEN] Sales Invoice (Inv2) Statistics; Customer Statistics

        // [GIVEN] Sales Order3 with Item Charges (applied to Shpt1, Ret.Rcpt1)
        // [WHEN] Adjust Cost Item Entries
        // [THEN] Sales Invoice (Inv1,2) Statistics; Customer Statistics

        // [GIVEN] Revaluation;
        // [WHEN] Adjust Cost Item Entries
        // [THEN] Sales Invoice (Inv1,2) Statistics; Customer Statistics

        // [WHEN] Invoice modified Sales Order1
        // [THEN] Customer Statistics

        // [WHEN] Sales CrM2 (Item,Res,Item Charge) (partially ship/inv);
        // [THEN] Sales Credit Memo (CrM2) Statistics; Customer Statistics

        CETAFInitialize();
        Corsica_UpdateSalesStatistics.PerformTestCase10();
        RunManager.ValidateRun('Corsica_UpdateSalesStatistics', 'PerformTestCase10');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Corsica_UpdateSalesStatTC11()
    begin
        // [FEATURE] [Sales Statistics] [Cost Standard] [Cost Average] [Item Charges] [ACY]
        // [SCENARIO TC-10-1] Customer and Inv/CrM Statistics reflect documents deletion

        // [GIVEN] ACY is set
        // [GIVEN] Sales Ret.Order1 (Item Charges,Item,Res) (partially ship/inv);
        // [GIVEN] Assign item charge 3rd line
        // [GIVEN] Ship/Inv Sales Order
        // [WHEN] Delete Invoiced Sales Ret.Order
        // [THEN] Sales Credit Memo Statistics; Customer Statistics

        CETAFInitialize();
        Corsica_UpdateSalesStatistics.PerformTestCase11();
        RunManager.ValidateRun('Corsica_UpdateSalesStatistics', 'PerformTestCase11');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Corsica_UpdateSalesStatTC12()
    begin
        // [FEATURE] [Sales Statistics] [Adjust Cost Item Entries] [Cost Standard] [Cost Average] [Item Charges] [Revaluation] [ACY]
        // [SCENARIO TC-11-1] Customer and Inv/CrM Statistics reflect compressed Item Ledger, Value Entries

        // [GIVEN] ACY is set
        // [GIVEN] Purch Order1 (partially rcpt/inv)
        // [GIVEN] Purch Inv2 with Item Charges applied to Rcpt1
        // [GIVEN] Adjust Cost Item Entries
        // [WHEN] Sales Order1 (Item, Res, Item Charges) (partially shpt/inv)
        // [THEN] Sales Order (1) Statistics; Sales Invoice (Inv1) Statistics; Customer Statistics

        // [WHEN] Sales CrM1 (2xRes,Item)
        // [THEN] Sales Credit Memo (CrM1) Statistics; Customer Statistics

        // [WHEN] Sales Inv2 (partially shpt/inv)
        // [THEN] Sales Invoice (Inv2) Statistics; Customer Statistics

        // [GIVEN] Sales Inv3 (2xItem,Item Charges)
        // [GIVEN] Invoice Purch Order1
        // [GIVEN] Adjust Cost Item Entries
        // [WHEN] Invoice Sales Order1
        // [THEN] Sales Invoice (Inv4) Statistics; Customer Statistics

        // [GIVEN] Sales Order2 (partially shpt/inv)
        // [THEN] Sales Invoice (Inv5) Statistics; Customer Statistics

        // [GIVEN] Sales Inv6 (2xItem,Res)
        // [WHEN] Sales CrM2
        // [THEN] Sales Credit Memo (CrM2) Statistics; Customer Statistics

        // [GIVEN]  Adjust Cost Item Entries; Revaluation;
        // [WHEN] Adjust Cost Item Entries
        // [THEN] Customer Statistics

        CETAFInitialize();
        Corsica_UpdateSalesStatistics.PerformTestCase12();
        RunManager.ValidateRun('Corsica_UpdateSalesStatistics', 'PerformTestCase12');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Corsica_UpdateSalesStatTC13()
    begin
        // [FEATURE] [Sales Statistics] [Adjust Cost Item Entries] [Cost Standard] [FIFO] [Undo Receipt] [Undo Shipment] [ACY]
        // [SCENARIO TC-12-1] Customer and Inv/CrM Statistics reflect Undo functionality

        // [GIVEN] ACY is set
        // [GIVEN] Purch Inv1, Sales Order1 (2 x partially shpt/inv)
        // [WHEN] Adjust Cost Item Entries
        // [THEN] Sales Order (1) Statistics;

        // [GIVEN] Undo Sales Shpt2
        // [WHEN] Adjust Cost Item Entries
        // [THEN] Sales Order (1) Statistics;

        // [GIVEN] Undo Sales Shpt1
        // [WHEN] Adjust Cost Item Entries
        // [THEN] Sales Order (1) Statistics;

        // [GIVEN] Sales Ret.Order1 (partial ret.rcpt1)
        // [GIVEN] Modify Sales Ret.Order1 (partial ret.rcpt2)
        // [WHEN] Adjust Cost Item Entries
        // [THEN] Sales Ret.Order (1) Statistics;

        // [GIVEN] Undo Sales Ret.Rcpt2
        // [WHEN] Adjust Cost Item Entries
        // [THEN] Sales Ret.Order (1) Statistics;

        CETAFInitialize();
        Corsica_UpdateSalesStatistics.PerformTestCase13();
        RunManager.ValidateRun('Corsica_UpdateSalesStatistics', 'PerformTestCase13');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Corsica_ClosingInvPerTC2()
    begin
        // [FEATURE] [Inventory Period] [Adjust Cost Item Entries] [Cost Average]
        // [SCENARIO 2] Reopen Inventory Period is closed by later closing

        // [GIVEN] Purch Inv on 2501
        // [GIVEN] Sales Inv on 2701
        // [GIVEN] Adjust Cost Item Entries on 2701;
        // [WHEN] Close Inventory Period 1 on 2701
        // [THEN] Inventory Period 1 is "Closed"

        // [GIVEN] Purch Inv on 2801
        // [WHEN] Reopen Inventory Period on 2701
        // [THEN] Inventory Period 1 is "Open"

        // [WHEN] Adjust Cost Item Entries; Close Inventory Period 2 on 2801
        // [THEN] There are 2 Inventory Periods; Both Inventory Periods are "Closed"

        CETAFInitialize();
        Corsica_ClosingInventoryPeriod.TestCase2();
        RunManager.ValidateRun('Corsica_ClosingInventoryPeriod', ' TestCase2');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Corsica_ClosingInvPerTC5_1()
    begin
        // [FEATURE] [Inventory Period] [Adjust Cost Item Entries] [Cost Standard] [FIFO]
        // [SCENARIO 5-1] Reopen Inventory Period is NOT closed by later posting

        // [GIVEN] Purch Inv on 2501
        // [GIVEN] Sales Inv on 2601
        // [GIVEN] Adjust Cost Item Entries; Close Inventory Period 1 on 2601
        // [GIVEN] Create Sales Order1 on 2701
        // [GIVEN] Reopen Inventory Period on 2601
        // [WHEN] Ship/Inv Sales Order 1
        // [THEN] all Inventory Periods is "Open"

        CETAFInitialize();
        Corsica_ClosingInventoryPeriod."TestCase5-1"();
        RunManager.ValidateRun('Corsica_ClosingInventoryPeriod', ' TestCase5-1');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Corsica_ClosingInvPerTC5_2()
    begin
        // [FEATURE] [Inventory Period] [Adjust Cost Item Entries] [Cost Standard] [Cost Average] [FIFO]
        // [SCENARIO 5-2] Reopen earlier Inventory Period opens later periods

        // [GIVEN] Purch Inv1 on 2501
        // [GIVEN] Sales Inv1 (partial) on 2701
        // [GIVEN] Adjust Cost Item Entries; Close Inventory Period 1 on 2701
        // [GIVEN] Sales Inv2 (partial) on 2801
        // [GIVEN] Adjust Cost Item Entries; Close Inventory Period 2 on 2801
        // [GIVEN] Sales Inv3 (partial) on 2901
        // [WHEN] Adjust Cost Item Entries; Close Inventory Period 3 on 2901
        // [THEN] All three Inventory Periods are "Closed"

        // [GIVEN] Reopen Inventory Period 2 on 2801
        // [WHEN] Purch Inv2 on 2801
        // [THEN] Inventory Period 1 is "Closed"; Inventory Periods 2,3 are "Open"

        // [WHEN] Adjust Cost Item Entries; Close Inventory Period 2 on 2801
        // [THEN] Inventory Periods 1,2 are "Closed"; Inventory Period 3 is "Open"
        // [THEN] Value Entry (COUNT=3, "Posting Date"=2801)

        // [GIVEN] Reopen Inventory Period 1 on 2701
        // [THEN] All three Inventory Periods are "Open"

        CETAFInitialize();
        Corsica_ClosingInventoryPeriod."TestCase5-2"();
        RunManager.ValidateRun('Corsica_ClosingInventoryPeriod', ' TestCase5-2');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Corsica_ClosingInvPerTC6()
    begin
        // [FEATURE] [Inventory Period] [Adjust Cost Item Entries] [Cost Standard] [Cost Average] [FIFO] [Fixed Application]
        // [SCENARIO 6] "Remaining Quantity" on ILE reflects fixed application

        // [GIVEN] Purch Rcpt1 on 2501
        // [GIVEN] Sales Shpt1 on 2701
        // [GIVEN] Purch Rcpt2 on 2701
        // [GIVEN] Sales Inv1 on 2701
        // [GIVEN] Puch Inv1 (by Get Rcpt Lines - Rcpt1,2) on 2801
        // [WHEN] Adjust Cost Item Entries; Close Inventory Period 1 on 2801
        // [THEN] Inventory Period 1 is "Closed"

        // [GIVEN] Purch Rcpt3 on 2901
        // [WHEN] Sales Shpt2 on 3001
        // [THEN] ILE ("Item No.","Document No.","Posting Date","Remaining Quantity")

        // [GIVEN] Sales Inv2 (by Get Shpt LInes - Shpt1,2) on 3001
        // [GIVEN] Sales Shpt3 on 3101 (applied to Rcpts)
        // [THEN] ILE ("Item No.","Document No.","Posting Date","Remaining Quantity" - decreased)

        CETAFInitialize();
        Corsica_ClosingInventoryPeriod.TestCase6();
        RunManager.ValidateRun('Corsica_ClosingInventoryPeriod', ' TestCase6');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Corsica_ClosingInvPerTC7_2()
    begin
        // [FEATURE] [Inventory Period] [Adjust Cost Item Entries] [Cost Standard] [FIFO] [Physical Inventory]
        // [SCENARIO 7-2] Close Inventory Period after phys. inventory and adjustments.

        // [GIVEN] Purch Inv1 on 0112
        // [GIVEN] Sales Inv1 on 0212
        // [GIVEN] Physical Inventory on 1012, decreasing Inventory (-1)
        // [GIVEN] Physical Inventory on 1112, increasing Inventory (+1)
        // [GIVEN] Sales Inv2 on 1712
        // [GIVEN] Sales Inv3 on 1812
        // [GIVEN] Purch Inv2 on 2112
        // [GIVEN] Adjust Cost Item Entries;
        // [GIVEN] Sales Inv4 on 2212
        // [GIVEN] Sales Inv3 on 2312
        // [GIVEN] Adjust Cost Item Entries;
        // [WHEN] Close Inventory Period on 3112
        // [THEN] N/A !

        CETAFInitialize();
        Corsica_ClosingInventoryPeriod."TestCase7-2"();
        RunManager.ValidateRun('Corsica_ClosingInventoryPeriod', ' TestCase7-2');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure Corsica_ResiliencyTC1_1()
    begin
        // [FEATURE] [Adjust Cost Item Entries] [Post Inventory Cost to G/L] [Average Cost Calc. Type] [Automatic Cost Posting] [Item Charges]
        // [SCENARIO 1-1] Actual cost adjusted and posted to G/L

        // [GIVEN] CalcType="Item&Location&Variant"
        // [GIVEN] Purch Order1 (partial rcpt/inv)
        // [GIVEN] Purch Order2 (partial rcpt/inv)
        // [GIVEN] Sales Inv1
        // [WHEN] Adjust Cost Item Entries ("Item2");
        // [THEN] Value Entry (COUNT=0) by adjustment for "Item1"
        // [THEN] Value Entry ("Cost Amount (Actual)","Cost Posted to G/L") for "Item2"

        // [GIVEN] Purch Item Charges (applied to Rcpt1,2)
        // [WHEN] Adjust Cost Item Entries ("Item1");
        // [THEN] Value Entry (COUNT=1) by adjustment for "Item2"
        // [THEN] Value Entry ("Cost Amount (Actual)","Cost Posted to G/L") for "Item1"

        // [WHEN] Post Inventory Cost to G/L
        // [THEN] G/L Entry (COUNT=37) !

        CETAFInitialize();
        Corsica_Resiliency."TCS-1-1"();
        RunManager.ValidateRun('Corsica_Resiliency', 'TCS-1-1');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure Corsica_ResiliencyTC1_2()
    begin
        // [FEATURE] [Adjust Cost Item Entries] [Post Inventory Cost to G/L] [Average Cost Calc. Type] [Automatic Cost Posting] [Item Charges] [Expected Cost]
        // [SCENARIO 1-2] Expected cost adjusted and posted to G/L

        // [GIVEN] CalcType="Item&Location&Variant"
        // [GIVEN] Purch Order1 (partial rcpt/inv)
        // [GIVEN] Purch Order2 (partial rcpt)
        // [GIVEN] Sales Shpt1
        // [WHEN] Adjust Cost Item Entries ("Item2");
        // [THEN] Value Entry (COUNT=0) by adjustment for "Item1"
        // [THEN] Value Entry ("Cost Amount (Expected)","Expected Cost Posted to G/L") for "Item2"

        // [WHEN] Post Inventory Cost to G/L
        // [THEN] Value Entry ("Expected Cost Posted to G/L") for "Item2"

        CETAFInitialize();
        Corsica_Resiliency."TCS-1-2"();
        RunManager.ValidateRun('Corsica_Resiliency', 'TCS-1-2');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Corsica_ResiliencyTC1_3()
    begin
        // [FEATURE] [Adjust Cost Item Entries] [Item Variant] [Item Charges] [Expected Cost] [Cost Average]
        // [SCENARIO 1-3] Expected cost adjusted for Item - Variant - Location with "Average Cost Calc. Type" = "Item"

        // [GIVEN] Items with variants: "Item1-V0", "Item2-V0", "Item1-V1", "Item2-V2"
        // [GIVEN] Purch Order1 (to BLUE) (partial rcpt/inv)
        // [GIVEN] Purch Order2 (to RED) (partial rcpt/inv)
        // [GIVEN] Purch Order3 (to BLUE) (partial rcpt)
        // [GIVEN] Purch Order4 (to RED) (partial rcpt)
        // [GIVEN] Sales Order1 (to BLUE) (shpt1)
        // [GIVEN] Sales Order2 (to RED) (shpt2)
        // [WHEN] Adjust Cost Item Entries ("Item1");
        // [THEN] Value Entry (COUNT=0) by adjustment for "Item2"
        // [THEN] Value Entry ("Cost Amount (Expected)") for "Item1" (V0,V1) on (BLUE,RED)

        // [GIVEN] Purch Item Charges (applied to Rcpt3)
        // [WHEN] Adjust Cost Item Entries ("Item2");
        // [THEN] Value Entry (COUNT=4) by adjustment for "Item1"
        // [THEN] Value Entry ("Cost Amount (Expected)") for "Item2" (V0,V1) on (BLUE,RED)

        CETAFInitialize();
        Corsica_Resiliency."TCS-1-3"();
        RunManager.ValidateRun('Corsica_Resiliency', 'TCS-1-3');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Corsica_ResiliencyTC2_1()
    begin
        // [FEATURE] [Adjust Cost Item Entries] [Item Category] [Expected Cost] [Cost Average] [FIFO] [LIFO]
        // [SCENARIO 2-1] Expected cost adjusted for Items per Item Category

        // [GIVEN] 3 Items
        // [GIVEN] Purch Order1 (partial rcpt/inv)
        // [GIVEN] Purch Order2 (partial rcpt)
        // [GIVEN] Sales Order1 (shpt1)
        // [WHEN] Adjust Cost Item Entries (Item Category = 'FURNITURE');
        // [THEN] Value Entry (COUNT=3) by "Sale" adjustment
        // [THEN] Value Entrie ("Cost Amount (Expected)") for items of Category 'FURNITURE'

        // [GIVEN] Purch Order3 (partial rcpt)
        // [WHEN] Adjust Cost Item Entries (Item Category = 'MISC');
        // [THEN] Value Entry (COUNT=6) by "Sale" adjustment
        // [THEN] Value Entry ("Cost Amount (Expected)") for items of Category 'MISC'

        CETAFInitialize();
        Corsica_Resiliency."TCS-2-1"();
        RunManager.ValidateRun('Corsica_Resiliency', 'TCS-2-1');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Corsica_ResiliencyTC2_2()
    begin
        // [FEATURE] [Adjust Cost Item Entries] [Item Category] [Item Variant] [Expected Cost] [Cost Average] [FIFO] [LIFO]
        // [SCENARIO 2-2] Expected cost adjusted for Item-Variant per Item Category

        // [GIVEN] 10 Items with variants
        // [GIVEN] Purch Order1 (to BLUE) (partial rcpt/inv)
        // [GIVEN] Purch Order2 (to RED) (partial rcpt/inv)
        // [GIVEN] Purch Order3 (to BLUE) (partial rcpt)
        // [GIVEN] Purch Order4 (to RED) (partial rcpt)
        // [GIVEN] Sales Order1 (to BLUE) (shpt1)
        // [GIVEN] Sales Order2 (to RED) (shpt2)
        // [WHEN] Adjust Cost Item Entries (Item Category = 'FURNITURE');
        // [THEN] Value Entry (COUNT=10) by "Sale" adjustment
        // [THEN] Value Entry ("Cost Amount (Expected)") for item-Variants of Category 'FURNITURE'

        // [GIVEN] Purch Order5 (to BLUE) (partial rcpt)
        // [GIVEN] Purch Order6 (to RED) (partial rcpt)
        // [WHEN] Adjust Cost Item Entries (Item Category = 'MISC');
        // [THEN] Value Entry (COUNT=20) by "Sale" adjustment
        // [THEN] Value Entry ("Cost Amount (Expected)") for item-Variants of Category 'MISC'

        CETAFInitialize();
        Corsica_Resiliency."TCS-2-2"();
        RunManager.ValidateRun('Corsica_Resiliency', 'TCS-2-2');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Corsica_ResiliencyTC3_1()
    begin
        // [FEATURE] [Adjust Cost Item Entries] [Item Charges] [Expected Cost] [Cost Standard] [FIFO] [LIFO] [Production]
        // [SCENARIO 3-1] Actial cost adjusted for consumed and output Items

        // [GIVEN] 5 Items
        // [GIVEN] Purch Order1 (partial rcpt/inv)
        // [GIVEN] Purch Order2 (partial rcpt)
        // [GIVEN] Finish Production Order (A = B + C)
        // [GIVEN] Sales Order1 (shpt1)
        // [WHEN] Adjust Cost Item Entries (item "LI");
        // [THEN] Value Entry (COUNT=1) by "Sale" adjustment for "LI"
        // [THEN] Value Entry ("Cost Amount (Expected)") for item "LI"

        // [GIVEN] Purch Item Charges (applied to Rcpt2)
        // [WHEN] Adjust Cost Item Entries (al items except item "LI");
        // [THEN] Value Entry (COUNT=1) by "Sale" adjustment for "LI"
        // [THEN] Value Entry ("Cost Amount (Expected)","Cost Amount (Actual)")

        CETAFInitialize();
        Corsica_Resiliency."TCS-3-1"();
        RunManager.ValidateRun('Corsica_Resiliency', 'TCS-3-1');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Corsica_ResiliencyTC3_2()
    begin
        // [FEATURE] [Adjust Cost Item Entries] [Item Category] [Item Charges] [Expected Cost] [Cost Standard] [Cost Average] [FIFO] [LIFO] [Production]
        // [SCENARIO 3-1] Actial cost adjusted for consumed and output Items per Item Category

        // [GIVEN] 7 Items
        // [GIVEN] Purch Order1 (partial rcpt/inv)
        // [GIVEN] Purch Order2 (partial rcpt)
        // [GIVEN] Finish Production Order (A = B + C)
        // [GIVEN] Sales Order1 (shpt1)
        // [WHEN] Adjust Cost Item Entries (Item Category = 'FURNITURE');
        // [THEN] Value Entry (COUNT=3) by "Sale" adjustment
        // [THEN] Value Entry ("Cost Amount (Expected)","Cost Amount (Actual)")

        // [GIVEN] Purch Item Charges (applied to Rcpt2)
        // [WHEN] Adjust Cost Item Entries (Item Category = 'MISC');
        // [THEN] Value Entry (COUNT=7) by "Sale" adjustment
        // [THEN] Value Entry ("Cost Amount (Expected)","Cost Amount (Actual)")

        CETAFInitialize();
        Corsica_Resiliency."TCS-3-2"();
        RunManager.ValidateRun('Corsica_Resiliency', 'TCS-3-2');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Corsica_ResiliencyTC4()
    begin
        // [FEATURE] [Adjust Cost Item Entries] [Expected Cost] [Cost Average] [FIFO] [LIFO] [Fixed Application]
        // [SCENARIO 4] Expected cost adjusted for Shipment with fixed application to multiple Receipts

        // [GIVEN] 3 Items
        // [GIVEN] Purch Order1 (partial rcpt/inv)
        // [GIVEN] Purch Order2,3 (partial rcpt)
        // [GIVEN] Sales Order1 (shpt1) (applied to Rcpt1,2,3)
        // [GIVEN] Raise "Unit cost" in purchase lines by 10 for the three purchase orders and post the orders as invoiced (inv 1,2,3)
        // [GIVEN] Purch Inv4 (2 lines)
        // [GIVEN] Purch Inv5 (1 line)
        // [WHEN] Adjust Cost Item Entries
        // [THEN] Value Entry (COUNT=9) by "Sale" adjustment
        // [THEN] Value Entry ("Cost Amount (Expected)")

        CETAFInitialize();
        Corsica_Resiliency."TCS-4"();
        RunManager.ValidateRun('Corsica_Resiliency', 'TCS-4');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Corsica_ResiliencyTC5()
    begin
        // [FEATURE] [Adjust Cost Item Entries] [Expected Cost] [Cost Average] [FIFO] [LIFO]
        // [SCENARIO 5] Expected cost adjusted for Shipment and Ret.Receipt

        // [GIVEN] 3 Items
        // [GIVEN] Purch Order1 (partial rcpt/inv)
        // [GIVEN] Purch Order2 (partial rcpt)
        // [GIVEN] Sales Order1 (shpt1)
        // [GIVEN] Sales Ret.Order1 (ret.rcpt1)
        // [GIVEN] Raise "unit cost" in lines of Purch Order2 by 10 and post both orders as invoiced
        // [WHEN] Adjust Cost Item Entries
        // [THEN] Value Entry (COUNT=6) by adjustment
        // [THEN] Value Entry ("Cost Amount (Expected)")

        CETAFInitialize();
        Corsica_Resiliency."TCS-5"();
        RunManager.ValidateRun('Corsica_Resiliency', 'TCS-5');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Corsica_ResiliencyTC6()
    begin
        // [FEATURE] [Adjust Cost Item Entries] [Expected Cost] [Cost Average] [FIFO] [LIFO]
        // [SCENARIO 6] Expected cost adjusted for Receipt posted on earlier date

        // [GIVEN] 3 Items
        // [GIVEN] Sales Order1 (shpt1)
        // [GIVEN] Purch Order1 (partial rcpt1)
        // [GIVEN] Sales Order2 (shpt2)
        // [GIVEN] Purch Order2 (partial rcpt2)
        // [GIVEN] Raise unit cost in purchase lines by 10 for the two purchase orders and post the orders as invoiced
        // [WHEN] Adjust Cost Item Entries
        // [THEN] Value Entry (COUNT=6) by adjustment
        // [THEN] Value Entry ("Cost Amount (Expected)")

        // [GIVEN] Purch Inv3 (-4d)
        // [WHEN] Adjust Cost Item Entries
        // [THEN] Value Entry (COUNT=8) by adjustment
        // [THEN] Value Entry ("Cost Amount (Expected)")

        CETAFInitialize();
        Corsica_Resiliency."TCS-6"();
        RunManager.ValidateRun('Corsica_Resiliency', 'TCS-6');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Corsica_ResiliencyTC7()
    begin
        // [FEATURE] [Adjust Cost Item Entries] [Expected Cost] [Cost Average] [FIFO] [LIFO] [Revaluation] [Fixed Application]
        // [SCENARIO 7] Expected cost adjusted for revaluated inventory

        // [GIVEN] 3 Items
        // [GIVEN] Sales Order1 (shpt1)
        // [GIVEN] Purch Order1 (partial rcpt1)
        // [GIVEN] Sales Order2 (shpt2) (applied to Rcpt1)
        // [GIVEN] Purch Order2 (partial rcpt2)
        // [GIVEN] Sales Ret.Order1 (ret.rcpt1)
        // [GIVEN] Raise unit cost in purchase lines by 10 for the two purchase orders and post the orders as invoiced
        // [WHEN] Adjust Cost Item Entries
        // [THEN] Value Entry (COUNT=12) by adjustment
        // [THEN] Value Entry ("Cost Amount (Expected)")

        // [GIVEN] positive Revaluation
        // [WHEN] Adjust Cost Item Entries
        // [THEN] Value Entry (COUNT=18) by adjustment
        // [THEN] Value Entry ("Cost Amount (Expected)")

        CETAFInitialize();
        Corsica_Resiliency."TCS-7"();
        RunManager.ValidateRun('Corsica_Resiliency', 'TCS-7');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Corsica_ResiliencyTC9_1_1()
    begin
        // [FEATURE] [Post Inventory Cost to G/L] [Post Method per Entry]
        // [SCENARIO 9-1-1] Rename "Location Code" in inventory posting setup

        // [GIVEN] 4 items; Purch Rcpt (RED +10); Purch Rcpt with DIMs (BLUE +10); Sales Inv with DIMs (BLUE -12)
        // [GIVEN] Rename "Location Code" on Inventory Posting Setup
        // [GIVEN] "Post Value Entry to G/L" (COUNT = 24)
        // [WHEN] Post Inventory Cost to G/L (per Entry)
        // [THEN] "Post Value Entry to G/L" (COUNT = 12)

        CETAFInitialize();
        Corsica_Resiliency."TCS-9-1-1"();
        RunManager.ValidateRun('Corsica_Resiliency', 'TCS-9-1-1');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Corsica_ResiliencyTC9_1_2()
    begin
        // [FEATURE] [Post Inventory Cost to G/L] [Post Method per Entry]
        // [SCENARIO 9-1-2] Blank "Inventory Account" in inventory posting setup

        // [GIVEN] 4 items; Purch Rcpt (RED +10); Purch Rcpt with DIMs (BLUE +10); Sales Inv with DIMs (BLUE -12)
        // [GIVEN] Blank "Inventory Account" in inventory posting setup
        // [GIVEN] "Post Value Entry to G/L" (COUNT = 24)
        // [WHEN] Post Inventory Cost to G/L (per Entry)
        // [THEN] "Post Value Entry to G/L" (COUNT = 2)

        CETAFInitialize();
        Corsica_Resiliency."TCS-9-1-2"();
        RunManager.ValidateRun('Corsica_Resiliency', 'TCS-9-1-2');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Corsica_ResiliencyTC9_1_5()
    begin
        // [FEATURE] [Post Inventory Cost to G/L] [Post Method per Entry]
        // [SCENARIO 9-1-5] Block G/L Accounts: "Inventory Account" in Inventory Posting Setup and "Direct Cost Applied Account" in Gen.Posting Setup

        // [GIVEN] 4 items; Purch Rcpt (RED +10); Purch Rcpt with DIMs (BLUE +10); Sales Inv with DIMs (BLUE -12)
        // [GIVEN] Block "Inventory Account" in inventory posting setup
        // [GIVEN] "Post Value Entry to G/L" (COUNT = 24)
        // [WHEN] Post Inventory Cost to G/L (per Entry)
        // [THEN] "Post Value Entry to G/L" (COUNT = 9)

        CETAFInitialize();
        Corsica_Resiliency."TCS-9-1-5"();
        RunManager.ValidateRun('Corsica_Resiliency', 'TCS-9-1-5');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Corsica_ResiliencyTC9_1_6()
    begin
        // [FEATURE] [Post Inventory Cost to G/L] [Post Method per Entry]
        // [SCENARIO 9-1-6] Block G/L Account: "Inventory Account (Interim)" in inventory posting setup

        // [GIVEN] 4 items; Purch Rcpt (RED +10); Purch Rcpt with DIMs (BLUE +10); Sales Inv with DIMs (BLUE -12)
        // [GIVEN] Block "Inventory Account (Interim)" in inventory posting setup
        // [GIVEN] "Post Value Entry to G/L" (COUNT = 24)
        // [WHEN] Post Inventory Cost to G/L (per Entry)
        // [THEN] "Post Value Entry to G/L" (COUNT = 6)

        CETAFInitialize();
        Corsica_Resiliency."TCS-9-1-6"();
        RunManager.ValidateRun('Corsica_Resiliency', 'TCS-9-1-6');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Corsica_ResiliencyTC9_2_1()
    begin
        // [FEATURE] [Post Inventory Cost to G/L] [Post Method per Posting Group]
        // [SCENARIO 9-2-1] Rename "Location Code" in inventory posting setup

        // [GIVEN] 4 items; Purch Rcpt (RED +10); Purch Rcpt with DIMs (BLUE +10); Sales Inv with DIMs (BLUE -12)
        // [GIVEN] Rename "Location Code" on Inventory Posting Setup
        // [GIVEN] "Post Value Entry to G/L" (COUNT = 24)
        // [WHEN] Post Inventory Cost to G/L (per Posting Group)
        // [THEN] "Post Value Entry to G/L" (COUNT = 12)
        CETAFInitialize();
        Corsica_Resiliency."TCS-9-2-1"();
        RunManager.ValidateRun('Corsica_Resiliency', 'TCS-9-2-1');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Corsica_ResiliencyTC9_2_2()
    begin
        // [FEATURE] [Post Inventory Cost to G/L] [Post Method per Posting Group]
        // [SCENARIO 9-2-2] Blank "Inventory Account" in inventory posting setup

        // [GIVEN] 4 items; Purch Rcpt (RED +10); Purch Rcpt with DIMs (BLUE +10); Sales Inv with DIMs (BLUE -12)
        // [GIVEN] Blank "Inventory Account" in inventory posting setup
        // [GIVEN] "Post Value Entry to G/L" (COUNT = 24)
        // [WHEN] Post Inventory Cost to G/L (per Posting Group)
        // [THEN] "Post Value Entry to G/L" (COUNT = 2)
        CETAFInitialize();
        Corsica_Resiliency."TCS-9-2-2"();
        RunManager.ValidateRun('Corsica_Resiliency', 'TCS-9-2-2');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Corsica_ResiliencyTC9_2_4()
    begin
        // [FEATURE] [Post Inventory Cost to G/L] [Post Method per Posting Group]
        // [SCENARIO 9-2-4] Block G/L Accounts: "Inventory Account" in Inventory Posting Setup and "Direct Cost Applied Account" in Gen.Posting Setup

        // [GIVEN] 4 items; Purch Rcpt (RED +10); Purch Rcpt with DIMs (BLUE +10); Sales Inv with DIMs (BLUE -12)
        // [GIVEN] Block "Inventory Account" in inventory posting setup
        // [GIVEN] "Post Value Entry to G/L" (COUNT = 24)
        // [WHEN] Post Inventory Cost to G/L (per Posting Group)
        // [THEN] "Post Value Entry to G/L" (COUNT = 9)
        CETAFInitialize();
        Corsica_Resiliency."TCS-9-2-4"();
        RunManager.ValidateRun('Corsica_Resiliency', 'TCS-9-2-4');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Corsica_ResiliencyTC9_2_5()
    begin
        // [FEATURE] [Post Inventory Cost to G/L] [Post Method per Posting Group]
        // [SCENARIO 9-1-6] Block G/L Account: "Inventory Account (Interim)" in inventory posting setup

        // [GIVEN] 4 items; Purch Rcpt (RED +10); Purch Rcpt with DIMs (BLUE +10); Sales Inv with DIMs (BLUE -12)
        // [GIVEN] Block "Inventory Account (Interim)" in inventory posting setup
        // [GIVEN] "Post Value Entry to G/L" (COUNT = 24)
        // [WHEN] Post Inventory Cost to G/L (per Posting Group)
        // [THEN] "Post Value Entry to G/L" (COUNT = 6)
        CETAFInitialize();
        Corsica_Resiliency."TCS-9-2-5"();
        RunManager.ValidateRun('Corsica_Resiliency', 'TCS-9-2-5');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure Corsica_AdjCostCOGSTC1_1()
    begin
        // [FEATURE] [Adjust Cost Item Entries]
        // [SCENARIO 1-1] Purch-Sales-Purch; Adjustment puts VEs on Sales Invoice date

        // [GIVEN] 5 Items (Costing Methods: FIFO,Avg,LIFO,Std,Avg)
        // [GIVEN] Purch Rcpt1 on 2501; Sales Shpt1 on 2601; Purch Inv1 on 2701; Sales Inv1 on 2801; Purch Rcpt2 on 2901;Purch Inv2 on 3001;
        // [WHEN] Adjust Cost Item Entries on 3101
        // [THEN] Adjustment Value Entries (COUNT=5,"Posting Date"=2801)
        CETAFInitialize();
        Corsica_AdjCostOfCOGS."TCS-1-1"();
        RunManager.ValidateRun('Corsica_AdjCostOfCOGS', 'TCS-1-1');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure Corsica_AdjCostCOGSTC1_2()
    begin
        // [FEATURE] [Adjust Cost Item Entries] [Item Variant]
        // [SCENARIO 1-2] Purch-Sales-Purch; Adjustment puts VEs on Sales Invoice date

        // [GIVEN] 5 Items (Costing Methods: FIFO,Avg,LIFO,Std,Avg) + 4 variants
        // [GIVEN] Purch Rcpt1 on 2501; Sales Shpt1 on 2601; Purch Inv1 on 2701; Sales Inv1 on 2801; Purch Rcpt2 on 2901;Purch Inv2 on 3001;
        // [WHEN] Adjust Cost Item Entries on 3101
        // [THEN] Adjustment Value Entries (COUNT=9,"Posting Date"=2801)
        CETAFInitialize();
        Corsica_AdjCostOfCOGS."TCS-1-2"();
        RunManager.ValidateRun('Corsica_AdjCostOfCOGS', 'TCS-1-2');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure Corsica_AdjCostCOGSTC1_3()
    begin
        // [FEATURE] [Adjust Cost Item Entries] [Expected Cost]
        // [SCENARIO 1-3] AutoCostAdjmt=6; Sales Shpt;Purch Rcpt;Sales Inv;Purch Inv; Auto Adjustment puts VEs on Sales Shpt/Invoice dates

        // [GIVEN] AutoCostAdjmt=6;
        // [GIVEN] 5 Items (Costing Methods: FIFO,Avg,LIFO,Std,Avg)
        // [GIVEN] Sales Shpt1 on 2501; Purch Rcpt1 on 2601; Sales Inv1 on 2701; Purch Rcpt2 on 2801; Purch Inv2 on 2901; Purch Inv1 on 3001;
        // [THEN] Adjustment Value Entries (COUNT=5,"Posting Date"=2501) for "Expected Cost"
        // [THEN] Adjustment Value Entries (COUNT=6,"Posting Date"=2701) for NOT "Expected Cost"
        CETAFInitialize();
        Corsica_AdjCostOfCOGS."TCS-1-3"();
        RunManager.ValidateRun('Corsica_AdjCostOfCOGS', 'TCS-1-3');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure Corsica_AdjCostCOGSTC1_4()
    begin
        // [FEATURE] [Adjust Cost Item Entries] [Item Variant] [Expected Cost] [Transfer]
        // [SCENARIO 1-4] AutoCostAdjmt=6; Purch-Transfer-Sales-PurchItemCharges ; Auto Adjustment puts VEs on dates of applied-to Value Entries

        // [GIVEN] AutoCostAdjmt=6;
        // [GIVEN] 5 Items (Costing Methods: FIFO,Avg,LIFO,Std,Avg) + 4 variants
        // [GIVEN] Purch Rcpt1 on 2501; Transfer Shpt on 2601; Purch Inv1 on 2701; Transfer Rcpt on 2601; Sales Shpt1 on 2901; Sales Inv1 on 0102;
        // [GIVEN] Purch Rcpt2 on 3001; Purch Inv2 on 3101; Purch Item Charges (for Rcpt1) on 3101;
        // [THEN] Adjustment Value Entries (COUNT=9) for "Expected Cost"
        // [THEN] Adjustment Value Entries (COUNT=61) for NOT "Expected Cost"
        // [THEN] Adjustment Value Entries ("Posting Date" = date of applied VE)
        CETAFInitialize();
        Corsica_AdjCostOfCOGS."TCS-1-4"();
        RunManager.ValidateRun('Corsica_AdjCostOfCOGS', 'TCS-1-4');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure Corsica_AdjCostCOGSTC1_5()
    begin
        // [FEATURE] [Adjust Cost Item Entries] [Item Variant]
        // [SCENARIO 1-5] Purch-Sales(inv before shpt)-Purch(before Sales); Adjustment puts VEs on Sales Invoice date

        // [GIVEN] 5 Items (Costing Methods: FIFO,Avg,LIFO,Std,Avg) + 4 variants
        // [GIVEN] Purch Rcpt1 on 2501; Sales Shpt on 2801; purch Inv1 (partial) on 2601; Sales Inv1 on 2701; Purch Rcpt2 on 2301; Purch Inv2 on 2401;
        // [WHEN] Adjust Cost Item Entries on 3101
        // [THEN] Adjustment Value Entries (COUNT=9,"Posting Date"=2701)
        CETAFInitialize();
        Corsica_AdjCostOfCOGS."TCS-1-5"();
        RunManager.ValidateRun('Corsica_AdjCostOfCOGS', 'TCS-1-5');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure Corsica_AdjCostCOGSTC1_6()
    begin
        // [FEATURE] [Adjust Cost Item Entries] [Item Variant]
        // [SCENARIO 1-6] Purch-Sales-Purch(before Sales); Adjustment puts VEs on Sales Shpt/Invoice date

        // [GIVEN] 5 Items (Costing Methods: FIFO,Avg,LIFO,Std,Avg) + 4 variants
        // [GIVEN] Purch Rcpt1 on 2501;Sales Shpt on 2701; Sales Inv1(part) on 2801;purch Inv1 on 2301;
        // [WHEN] Adjust Cost Item Entries on 2601
        // [THEN] Adjustment Value Entries (COUNT=9,"Posting Date"=2701) for "Expected Cost"
        // [THEN] Adjustment Value Entries (COUNT=9,"Posting Date"=2801) for NOT "Expected Cost"
        CETAFInitialize();
        Corsica_AdjCostOfCOGS."TCS-1-6"();
        RunManager.ValidateRun('Corsica_AdjCostOfCOGS', 'TCS-1-6');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure Corsica_AdjCostCOGSTC2_1()
    begin
        // [FEATURE] [Adjust Cost Item Entries] [Expected Cost] [Undo Shipment]
        // [SCENARIO 2-1] AutoCostAdjmt=6; Purch-Sales-Undo-Purch; Auto Adjustment puts VEs on Sales Shpt\Invoice date

        // [GIVEN] AutoCostAdjmt=6;
        // [GIVEN] 5 Items (Costing Methods: FIFO,Avg,LIFO,Std,Avg)
        // [GIVEN] Purch Rcpt1 on 2501; Sales Shpt1 on 2601; Purch Inv1 on 2701;Undo Shpt1 on 2801;Purch Rcpt2 on 2901;Sales Inv1 on 3001; Purch Inv2 on 3101
        // [THEN] Adjustment Value Entries (COUNT=5,"Posting Date"=2601) for "Expected Cost"
        // [THEN] Adjustment Value Entries (COUNT=6,"Posting Date"=3001) for NOT "Expected Cost"
        CETAFInitialize();
        Corsica_AdjCostOfCOGS."TCS-2-1"();
        RunManager.ValidateRun('Corsica_AdjCostOfCOGS', 'TCS-2-1');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure Corsica_AdjCostCOGSTC3_1()
    begin
        // [FEATURE] [Adjust Cost Item Entries] [Item Charges] [FIFO] [Rounding]
        // [SCENARIO 3-1] Late Item Charges do not affect Sales cost adjustment

        // [GIVEN] Purch Rcpt1 (1 line) on 2501; Sales Shpt1 (3 lines) on 2601; Purch Inv1 on 2701; Sales Inv1 on 2801
        // [WHEN] Adjust Cost Item Entries on 2901
        // [THEN] Rounding Value Entries (COUNT=1,"Posting Date"=2701)
        // [THEN] Adjustment Value Entries (COUNT=3,"Posting Date"=2801)

        // [GIVEN] Purch Item Charges (for Rcpt1) on 3001
        // [WHEN] Adjust Cost Item Entries on 3101
        // [THEN] Rounding Value Entries (COUNT=1,"Posting Date"=2701)
        // [THEN] Adjustment Value Entries (COUNT=3,"Posting Date"=2801)

        CETAFInitialize();
        Corsica_AdjCostOfCOGS."TCS-3-1"();
        RunManager.ValidateRun('Corsica_AdjCostOfCOGS', 'TCS-3-1');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure Corsica_AdjCostCOGSTC4_1()
    begin
        // [FEATURE] [Adjust Cost Item Entries] [Production]
        // [SCENARIO 4-1] Adjusted Cost on Consumption and Output dates

        // [GIVEN] Purch Rcpt1 (B,C) on 2501; Prod Order (A=B+C) on 2601;Purch Rcpt1 (B,C) on 2701;
        // [GIVEN] Consump on 2801; Output on 2901; Finish ProdOrder on 3001;
        // [WHEN] Adjust Cost Item Entries on 3101
        // [THEN] Adjustment Value Entries (COUNT=2,"Posting Date"=2801)
        // [THEN] Output Value Entries (COUNT=2,"Posting Date"=2901)

        // [GIVEN] Purch Inv1,2 on 0102;
        // [WHEN] Adjust Cost Item Entries on 0202
        // [THEN] Adjustment Value Entries (COUNT=2,"Posting Date"=2801)
        // [THEN] Output Value Entries (COUNT=2,"Posting Date"=2901)

        CETAFInitialize();
        Corsica_AdjCostOfCOGS."TCS-4-1"();
        RunManager.ValidateRun('Corsica_AdjCostOfCOGS', 'TCS-4-1');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure Corsica_AdjCostCOGSTC5()
    begin
        // [FEATURE] [Adjust Cost Item Entries]
        // [SCENARIO 5] Purch-Sales-Purch; Adjustment puts VEs on Sales Invoice date

        // [GIVEN] 5 Items (Costing Methods: FIFO,Avg,LIFO,Std,Avg)
        // [GIVEN] Purch Rcpt1 on 2501; Sales Shpt1 on 2601; Purch Rcpt2 on 2701; Purch Inv2 on 2801; Sales Inv1 on 2901; Purch Inv1 on 3001;
        // [WHEN] Adjust Cost Item Entries on 3101
        // [THEN] Adjustment Value Entries (COUNT=5,"Posting Date"=2901)

        // [GIVEN] Sales Shpt1 on 0102; Purch Rcpt3 on 0202; Purch Inv3 on 0302; Sales Inv2 on 0402
        // [THEN] N/A !
        CETAFInitialize();
        Corsica_AdjCostOfCOGS."GeneralPrepTCS-5"();
        RunManager.ValidateRun('Corsica_AdjCostOfCOGS', 'GeneralPrepTCS-5');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure Corsica_TracingCostTC1()
    begin
        // [FEATURE] [G/L - Item Ledger Relation] [Automatic Cost Posting] [Expected Cost]
        // [SCENARIO 1] AutoCostAdjmt=6; PO-Rec; SO-Ship; SRetO; PRetO; PO-Inv;SO-Inv; Trsf; PrO(fin);Trsf; SO(Ship,Inv)

        // [THEN] G/L Entry (COUNT); Value Entry (COUNT,"Posting Date" same as in G/L); GLItemLedgerRelation (COUNT)

        CETAFInitialize();
        Corsica_TracingCost_VE_GL."TCS-1"();
        RunManager.ValidateRun('Corsica_TracingCost_VE_GL', 'TCS-1');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Corsica_TracingCostTC3_1()
    begin
        // [FEATURE] [G/L - Item Ledger Relation] [Post Inventory Cost to G/L] [Post Method per Entry] [Expected Cost]
        // [SCENARIO 3-1] PO-Rec; SO-Ship; SRetO; PRetO; PO-Inv;SO-Inv; Trsf; PrO(fin);Trsf; SO(Ship,Inv); Adj. Cost; Post To GL;

        // [THEN] G/L Entry (COUNT); Value Entry (COUNT,"Posting Date" same as in G/L); GLItemLedgerRelation (COUNT)
        CETAFInitialize();
        Corsica_TracingCost_VE_GL."TCS-3-1"();
        RunManager.ValidateRun('Corsica_TracingCost_VE_GL', 'TCS-3-1');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Corsica_TracingCostTC3_2()
    begin
        // [FEATURE] [G/L - Item Ledger Relation] [Post Inventory Cost to G/L] [Post Method per Entry] [Expected Cost]
        // [SCENARIO 3-2] Posting Errors exist; PO-Rec; SO-Ship; SRetO; PRetO; PO-Inv;SO-Inv; Trsf; PrO(fin);Trsf; SO(Ship,Inv); Adj. Cost; Post To GL;

        // [GIVEN] Block "Inventory Account (Interim)"
        // [THEN] Posting Errors exist

        CETAFInitialize();
        Corsica_TracingCost_VE_GL."TCS-3-2"();
        RunManager.ValidateRun('Corsica_TracingCost_VE_GL', 'TCS-3-2');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Corsica_TracingCostTC3_3()
    begin
        // [FEATURE] [G/L - Item Ledger Relation] [Post Inventory Cost to G/L] [Post Method per Entry]
        // [SCENARIO 3-3] Posting Manually without Expected Cost Posting; PO-Rec; SO-Ship; SRetO; PRetO; PO-Inv;SO-Inv; Trsf; PrO(fin);Trsf; SO(Ship,Inv); Adj. Cost; Post To GL;

        // [THEN] G/L Entry (COUNT); Value Entry (COUNT,"Posting Date" same as in G/L); GLItemLedgerRelation (COUNT)

        CETAFInitialize();
        Corsica_TracingCost_VE_GL."TCS-3-3"();
        RunManager.ValidateRun('Corsica_TracingCost_VE_GL', 'TCS-3-3');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Corsica_TracingCostTC4_1()
    begin
        // [FEATURE] [G/L - Item Ledger Relation] [Post Inventory Cost to G/L] [Post Method per Posting Group] [Expected Cost]
        // [SCENARIO 4-1]  PO-Rec; SO-Ship; SRetO; PRetO; PO-Inv;SO-Inv; Trsf; PrO(fin);Trsf; SO(Ship,Inv); Adj. Cost; Post To GL;

        // [THEN] G/L Entry (COUNT); Value Entry (COUNT,"Posting Date" same as in G/L); GLItemLedgerRelation (COUNT)
        CETAFInitialize();
        Corsica_TracingCost_VE_GL."TCS-4-1"();
        RunManager.ValidateRun('Corsica_TracingCost_VE_GL', 'TCS-4-1');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Corsica_TracingCostTC4_2()
    begin
        // [FEATURE] [G/L - Item Ledger Relation] [Post Inventory Cost to G/L] [Post Method per Posting Group] [Expected Cost]
        // [SCENARIO 4-2] Posting Errors exist; PO-Rec; SO-Ship; SRetO; PRetO; PO-Inv;SO-Inv; Trsf; PrO(fin);Trsf; SO(Ship,Inv); Adj. Cost; Post To GL;

        // [GIVEN] Block "Inventory Account (Interim)"
        // [THEN] Posting Errors exist

        CETAFInitialize();
        Corsica_TracingCost_VE_GL."TCS-4-2"();
        RunManager.ValidateRun('Corsica_TracingCost_VE_GL', 'TCS-4-2');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Corsica_TracingCostTC4_3()
    begin
        // [FEATURE] [G/L - Item Ledger Relation] [Post Inventory Cost to G/L] [Post Method per Posting Group]
        // [SCENARIO 4-3] Posting Manually without Expected Cost Posting; PO-Rec; SO-Ship; SRetO; PRetO; PO-Inv;SO-Inv; Trsf; PrO(fin);Trsf; SO(Ship,Inv); Adj. Cost; Post To GL;

        // [THEN] G/L Entry (COUNT); Value Entry (COUNT,"Posting Date" same as in G/L); GLItemLedgerRelation (COUNT)

        CETAFInitialize();
        Corsica_TracingCost_VE_GL."TCS-4-3"();
        RunManager.ValidateRun('Corsica_TracingCost_VE_GL', 'TCS-4-3');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Corsica_ValInvAvgCostTC1_1()
    begin
        // [FEATURE] [Adjust Cost Item Entries] [Average Cost Calc. Type] [Cost Average]
        // [SCENARIO 1-1] Different Sources of Item/Value Increase for Average Cost Calculation Type Item & Location & Variant

        // [GIVEN] PosAdj; SO1-ship,inv(part); PO-rec; Trsf; SO2-ship,inv(part); PO-inv; SO1-inv; SO2-inv; Reval; SI3,4
        // [WHEN] Adjust Cost Item Entries
        // [THEN] ILE ("Cost Amount (Actual)"); Item ("Unit Cost"); SKU ("Unit Cost");
        CETAFInitialize();
        Corsica_ValuingInvtAtAvgCost."TCS-1-1"();
        RunManager.ValidateRun('Corsica_ValuingInvtAtAvgCost', 'TCS-1-1');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Corsica_ValInvAvgCostTC1_2()
    begin
        // [FEATURE] [Adjust Cost Item Entries] [Average Cost Calc. Type] [Cost Average] [Expected Cost]
        // [SCENARIO 1-2] Different Sources of Item/Value Increase for Average Cost Calculation Type Item

        // [GIVEN] PI1,2,3; Trsf1; SO1,2-ship,inv(part); Trsf2; PI3; SO1,2-inv; Reval; SI3,4;
        // [WHEN] Adjust Cost Item Entries
        // [THEN] ILE ("Cost Amount (Expected)","Cost Amount (Actual)"); Item ("Unit Cost"); SKU ("Unit Cost");

        CETAFInitialize();
        Corsica_ValuingInvtAtAvgCost."TCS-1-2"();
        RunManager.ValidateRun('Corsica_ValuingInvtAtAvgCost', 'TCS-1-2');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Corsica_ValInvAvgCostTC1_3()
    begin
        // [FEATURE] [Adjust Cost Item Entries] [Average Cost Calc. Type] [Cost Average]
        // [SCENARIO 1-3] Manufacturing as source of Item/Value Increase/Decrease

        // [GIVEN] PosAdj1,2,3; PrO(cons,neg.cons,cons;out,neg.out,out); SI;
        // [WHEN] Adjust Cost Item Entries
        // [THEN] ILE ("Cost Amount (Actual)"); Item ("Unit Cost"); SKU ("Unit Cost");

        CETAFInitialize();
        Corsica_ValuingInvtAtAvgCost."TCS-1-3"();
        RunManager.ValidateRun('Corsica_ValuingInvtAtAvgCost', 'TCS-1-3');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Corsica_ValInvAvgCostTC1_4()
    begin
        // [FEATURE] [Adjust Cost Item Entries] [Reserve] [Cost Average] [Fixed Application]
        // [SCENARIO 1-4] Item Application

        // [GIVEN] ItemTrack="LOTALL"; PO1-rec,inv(part) + reserve;  PO2-rec + reserve; Tsfr + reserve; SI1 + apply;
        // [GIVEN] PO3,4-rec + reserve; SO2-ship,inv(part) + reserve; Undo Rcpt1; SI2 + reserve; SRetO + reserve; PO2-inv;
        // [WHEN] Adjust Cost Item Entries
        // [THEN] ILE ("Cost Amount (Actual)"); Item ("Unit Cost"); SKU ("Unit Cost");

        CETAFInitialize();
        Corsica_ValuingInvtAtAvgCost."TCS-1-4"();
        RunManager.ValidateRun('Corsica_ValuingInvtAtAvgCost', 'TCS-1-4');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Corsica_ValInvAvgCostTC2_1()
    begin
        // [FEATURE] [Adjust Cost Item Entries] [Average Cost Calc. Type] [Inventory Period] [Cost Average]
        // [SCENARIO 2-1] Change of Average Cost Period for Reopened Inventory Period

        // [GIVEN] SI1; PI1,2; PO3,4-rec; SO2-ship,inv(part); Close Inv.Per; Reopen Inv.Per;
        // [WHEN] Adjust Cost Item Entries
        // [THEN] ILE ("Cost Amount (Actual)"); Item ("Unit Cost"); SKU ("Unit Cost");
        CETAFInitialize();
        Corsica_ValuingInvtAtAvgCost."TCS-2-1"();
        RunManager.ValidateRun('Corsica_ValuingInvtAtAvgCost', 'TCS-2-1');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Corsica_ValInvAvgCostTC2_2()
    begin
        // [FEATURE] [Adjust Cost Item Entries] [Average Cost Calc. Type] [Inventory Period] [Cost Average] [Item Charges]
        // [SCENARIO 2-2] Change of Average Cost Period for Fiscal Year with closed Inventory Periods

        // [GIVEN] PI1,2 on 2312; SI1,2 on 27-2812; PI3,4,5 on 29-3012; SI3 on 3112; PI6 on 0101;
        // [GIVEN] Neg.Adj on 0401; SCrM on 0501; Neg.Adj on 0601; PI7 on 3103; PI8 on 0104; Reval on 3112;
        // [GIVEN] Close Inv.Per on 3112; Close Fiscal Year; Reval on 3003; Change Avg.Acc.Per
        // [GIVEN] PI9,10 + ItCh on 0204; SI4,5 on 0106;
        // [WHEN] Adjust Cost Item Entries
        // [THEN] ILE (COUNT=46,"Cost Amount (Actual)"); Item ("Unit Cost"); SKU ("Unit Cost");
        CETAFInitialize();
        Corsica_ValuingInvtAtAvgCost."TCS-2-2"();
        RunManager.ValidateRun('Corsica_ValuingInvtAtAvgCost', 'TCS-2-2');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Corsica_ValInvAvgCostTC2_3()
    begin
        // [FEATURE] [Adjust Cost Item Entries] [Average Cost Calc. Type] [Inventory Period] [Cost Average] [Fixed Application]
        // [SCENARIO 2-3] Change of Avg. Cost Period and Avg. Calc. Type for Fiscal Year with closed Inventory Periods

        // [GIVEN] PI1,2 on 3112; SI1 on 0212; SI2 on 2912; PI3 on 0101; SI3 on 0301; PI4 on 3101;
        // [GIVEN] PI5,6 on 0112; SI4,5 on 0312; SRetO1 on 0501; PI7 on 0101; NegAdj on 0201;SRetO2 on 0301;
        // [GIVEN] Reval on 3112; Close Inv.Per on 3112;
        // [GIVEN] AverageCostCalcType = Item; AdjCost; Close Fiscal Year;
        // [GIVEN] AverageCostCalcType = Item&Loc&Var; AdjCost;
        // [GIVEN] SI6,7,8 on 1501;
        // [WHEN] Adjust Cost Item Entries
        // [THEN] ILE (COUNT=36,"Cost Amount (Actual)"); Item ("Unit Cost"); SKU ("Unit Cost");

        CETAFInitialize();
        Corsica_ValuingInvtAtAvgCost."TCS-2-3"();
        RunManager.ValidateRun('Corsica_ValuingInvtAtAvgCost', 'TCS-2-3');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Corsica_ValInvAvgCostTC3_1()
    begin
        // [FEATURE] [Adjust Cost Item Entries] [Automatic Cost Posting]
        // [SCENARIO 3-1] Automatic Cost Adjustment

        // [GIVEN] AutoCostAdjmt=6; PI1 on 0101; PI2 on 1501; PI3 on 2401; Trsf on 1601; SI1-inv(part) on 1901; SI2-inv(part) on 2101;
        // [GIVEN] Trsf on 1701; PI4 on 2001; SI1,2-inv(full);
        // [GIVEN] Reval on 0701; SI3,4 on 3001;
        // [THEN] ILE (COUNT=59,"Cost Amount (Actual)"); Item ("Unit Cost"); SKU ("Unit Cost");

        CETAFInitialize();
        Corsica_ValuingInvtAtAvgCost."TCS-3-1"();
        RunManager.ValidateRun('Corsica_ValuingInvtAtAvgCost', 'TCS-3-1');
    end;

    [Normal]
    local procedure CETAFInitialize()
    begin
        RunManager.ClearTestResultTable();

        if CETAFInitialized then
            exit;

        RunManager.PrepareCETAF();
        CETAFInitialized := true;
        Commit();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Msg: Text[1024])
    begin
    end;
}

