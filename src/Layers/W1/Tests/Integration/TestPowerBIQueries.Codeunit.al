codeunit 134764 TestPowerBIQueries
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Power BI]
    end;

    var
        Assert: Codeunit Assert;
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";

    [Test]
    [Scope('OnPrem')]
    procedure TestPowerBICustomerList()
    var
        Customer1: Record Customer;
        Customer2: Record Customer;
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        PowerBICustomerList: Query "Power BI Customer List";
    begin
        // [SCENARIO] Exercise Query PowerBICustomerList.

        // [GIVEN] Customers and Customer Ledger Entries.
        Customer1.DeleteAll();
        DetailedCustLedgEntry.DeleteAll();

        CreateCustomerSimple(Customer1, '1', 1000);
        CreateDetailedCustLedgEntry(Customer1, 1, 1, 100);
        CreateDetailedCustLedgEntry(Customer1, 1, 2, 200);

        CreateCustomerSimple(Customer2, '2', 2000);
        CreateDetailedCustLedgEntry(Customer2, 2, 3, 300);
        CreateDetailedCustLedgEntry(Customer2, 2, 4, 400);

        // [WHEN] The query is opened and read.
        // [THEN] Various fields are validated.

        PowerBICustomerList.Open();

        VerifyPowerBICustomerList(PowerBICustomerList, '1', 1000, 300, Today, 1, 100, 1, 1);
        VerifyPowerBICustomerList(PowerBICustomerList, '1', 1000, 300, Today, 1, 200, 1, 2);
        VerifyPowerBICustomerList(PowerBICustomerList, '2', 2000, 700, Today, 2, 300, 2, 3);
        VerifyPowerBICustomerList(PowerBICustomerList, '2', 2000, 700, Today, 2, 400, 2, 4);

        Assert.IsFalse(PowerBICustomerList.Read(), 'Unexpected record in Query PowerBICustomerList');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPowerBIVendorList()
    var
        Vendor1: Record Vendor;
        Vendor2: Record Vendor;
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        PowerBIVendorList: Query "Power BI Vendor List";
    begin
        // [SCENARIO] Exercise Query PowerBIVendorList.

        Vendor1.DeleteAll();
        DetailedVendorLedgEntry.DeleteAll();

        // [GIVEN] Vendors and Vendor Ledger Entries.

        CreateVendorSimple(Vendor1, '1');
        CreateDetailedVendLedgEntry(Vendor1, 1, 1, 100, 10);
        CreateDetailedVendLedgEntry(Vendor1, 1, 2, 200, 20);

        CreateVendorSimple(Vendor2, '2');
        CreateDetailedVendLedgEntry(Vendor2, 2, 3, 300, 30);
        CreateDetailedVendLedgEntry(Vendor2, 2, 4, 400, 40);

        // [WHEN] The query is opened and read.
        // [THEN] Various fields are validated.

        PowerBIVendorList.Open();

        VerifyPowerBIVendorList(PowerBIVendorList, '1', 10, -300, Today, 1, -100, 1, 1);
        VerifyPowerBIVendorList(PowerBIVendorList, '1', 20, -300, Today, 1, -200, 1, 2);
        VerifyPowerBIVendorList(PowerBIVendorList, '2', 30, -700, Today, 2, -300, 2, 3);
        VerifyPowerBIVendorList(PowerBIVendorList, '2', 40, -700, Today, 2, -400, 2, 4);

        Assert.IsFalse(PowerBIVendorList.Read(), 'Unexpected record in Query PowerBIVendorList');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPowerBIItemPurchasesList()
    var
        Item1: Record Item;
        Item2: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        PowerBIItemPurchasesList: Query "Power BI Item Purchase List";
    begin
        // [SCENARIO] Exercise Query PowerBIItemPurchasesList.

        Item1.DeleteAll();
        ItemLedgerEntry.DeleteAll();

        // [GIVEN] Items and Item Ledger Entries.

        CreateItemSimple(Item1, '1');
        CreateItemLedgEntry(Item1, Today, 1, 10);

        CreateItemSimple(Item2, '2');
        CreateItemLedgEntry(Item2, Today + 1, 2, 100);

        // [WHEN] The query is opened and read.
        // [THEN] Various fields are validated.

        PowerBIItemPurchasesList.Open();

        VerifyPowerBIItemPurchasesList(PowerBIItemPurchasesList, '1', 10, 1, Today);
        VerifyPowerBIItemPurchasesList(PowerBIItemPurchasesList, '2', 100, 2, Today + 1);

        Assert.IsFalse(PowerBIItemPurchasesList.Read(), 'Unexpected record in Query.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPowerBIItemSalesList()
    var
        Item1: Record Item;
        Item2: Record Item;
        ValueEntry: Record "Value Entry";
        PowerBIItemSalesList: Query "Power BI Item Sales List";
    begin
        // [SCENARIO] Exercise Query PowerBIItemSalesList.

        Item1.DeleteAll();
        ValueEntry.DeleteAll();

        // [GIVEN] Items and Value Entries.

        CreateItemSimple(Item1, '1');
        CreateValueEntry(Item1, Today, 1, 25);

        CreateItemSimple(Item2, '2');
        CreateValueEntry(Item2, Today + 1, 2, 50);

        // [WHEN] The query is opened and read.
        // [THEN] Various fields are validated.

        PowerBIItemSalesList.Open();

        VerifyPowerBIItemSalesList(PowerBIItemSalesList, '1', -25, 1, Today);
        VerifyPowerBIItemSalesList(PowerBIItemSalesList, '2', -50, 2, Today + 1);

        Assert.IsFalse(PowerBIItemSalesList.Read(), 'Unexpected record in Query.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPowerBIJobList()
    var
        Job1: Record Job;
        Job2: Record Job;
        JobLedgerEntry: Record "Job Ledger Entry";
        PowerBIJobsList: Query "Power BI Jobs List";
    begin
        // [SCENARIO] Exercise Query PowerBIJobsList.

        Job1.DeleteAll();
        JobLedgerEntry.DeleteAll();

        // [GIVEN] Jobs and Job Ledger Entries.

        CreateJobSimple(Job1, '1', true, Job1.Status::Completed);
        CreateJobLedgerEntry(Job1, 100, 1);

        CreateJobSimple(Job2, '2', false, Job2.Status::Open);
        CreateJobLedgerEntry(Job2, 200, 2);

        // [WHEN] The query is opened and read.
        // [THEN] Various fields are validated.

        PowerBIJobsList.Open();

        VerifyPowerBIJobList(PowerBIJobsList, '1', true, Job1.Status::Completed, Today, 100, 1);
        VerifyPowerBIJobList(PowerBIJobsList, '2', false, Job1.Status::Open, Today, 200, 2);

        Assert.IsFalse(PowerBIJobsList.Read(), 'Unexpected record in Query.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPowerBISalesList()
    var
        SalesHeader1: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PowerBISalesList: Query "Power BI Sales List";
    begin
        // [SCENARIO] Exercise Query PowerBISalesList.

        SalesHeader1.DeleteAll();
        SalesLine.DeleteAll();

        // [GIVEN] Sales Header and Lines.

        CreateSalesHeaderSimple(SalesHeader1, '1', Today);
        CreateSalesLineSimple(SalesHeader1, 1, 1);
        CreateSalesLineSimple(SalesHeader1, 2, 2);

        CreateSalesHeaderSimple(SalesHeader2, '2', Today + 1);
        CreateSalesLineSimple(SalesHeader2, 3, 3);
        CreateSalesLineSimple(SalesHeader2, 4, 4);

        // [WHEN] The query is opened and read.
        // [THEN] Various fields are validated.

        PowerBISalesList.Open();

        VerifyPowerBISalesList(PowerBISalesList, '1', Today, Today + 10, Today + 20, 1, 10);
        VerifyPowerBISalesList(PowerBISalesList, '1', Today, Today + 10, Today + 20, 2, 20);
        VerifyPowerBISalesList(PowerBISalesList, '2', Today + 1, Today + 11, Today + 21, 3, 30);
        VerifyPowerBISalesList(PowerBISalesList, '2', Today + 1, Today + 11, Today + 21, 4, 40);

        Assert.IsFalse(PowerBISalesList.Read(), 'Unexpected record in Query.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPowerBIPurchaseList()
    var
        PurchaseHeader1: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PowerBIPurchaseList: Query "Power BI Purchase List";
    begin
        // [SCENARIO] Exercise Query PowerBIPurchaseList.

        PurchaseHeader1.DeleteAll();
        PurchaseLine.DeleteAll();

        // [GIVEN] Purchase Header and Lines.

        CreatePurchaseHeaderSimple(PurchaseHeader1, '1', Today);
        CreatePurchaseLineSimple(PurchaseHeader1, 1, 1);
        CreatePurchaseLineSimple(PurchaseHeader1, 2, 2);

        CreatePurchaseHeaderSimple(PurchaseHeader2, '2', Today + 1);
        CreatePurchaseLineSimple(PurchaseHeader2, 3, 3);
        CreatePurchaseLineSimple(PurchaseHeader2, 4, 4);

        // [WHEN] The query is opened and read.
        // [THEN] Various fields are validated.

        PowerBIPurchaseList.Open();

        VerifyPowerBIPurchaseList(PowerBIPurchaseList, '1', Today, Today + 10, Today + 20, Today + 30, 1, 10);
        VerifyPowerBIPurchaseList(PowerBIPurchaseList, '1', Today, Today + 10, Today + 20, Today + 30, 2, 20);
        VerifyPowerBIPurchaseList(PowerBIPurchaseList, '2', Today + 1, Today + 11, Today + 21, Today + 31, 3, 30);
        VerifyPowerBIPurchaseList(PowerBIPurchaseList, '2', Today + 1, Today + 11, Today + 21, Today + 31, 4, 40);

        Assert.IsFalse(PowerBIPurchaseList.Read(), 'Unexpected record in Query.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPowerBIGLAmountList()
    var
        GLAccount1: Record "G/L Account";
        GLAccount2: Record "G/L Account";
        GLEntry: Record "G/L Entry";
        PowerBIGLAmountList: Query "Power BI GL Amount List";
    begin
        // [SCENARIO] Exercise Query PowerBIGLAmountList.

        GLAccount1.DeleteAll();
        GLEntry.DeleteAll();

        // [GIVEN] GL Accounts and Entries.

        CreateGLAccountSimple(GLAccount1, '1');
        CreateGLEntrySimple(GLAccount1, 1, 10, Today);

        CreateGLAccountSimple(GLAccount2, '2');
        CreateGLEntrySimple(GLAccount2, 2, 20, Today + 1);

        // [WHEN] The query is opened and read.
        // [THEN] Various fields are validated.

        PowerBIGLAmountList.Open();

        VerifyPowerBIGLAmountList(PowerBIGLAmountList, '1', Today, 10, 1);
        VerifyPowerBIGLAmountList(PowerBIGLAmountList, '2', Today + 1, 20, 2);

        Assert.IsFalse(PowerBIGLAmountList.Read(), 'Unexpected record in Query.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPowerBIGLBudgetedAmountList()
    var
        GLAccount1: Record "G/L Account";
        GLAccount2: Record "G/L Account";
        GLBudgetEntry: Record "G/L Budget Entry";
        PowerBIGLBudgetedAmountList: Query "Power BI GL Budgeted Amount";
    begin
        // [SCENARIO] Exercise Query PowerBIGLBudgetedAmountList.

        GLAccount1.DeleteAll();
        GLBudgetEntry.DeleteAll();

        // [GIVEN] GL Accounts and Budget Entries.

        CreateGLAccountSimple(GLAccount1, '1');
        CreateGLBudgetAmountSimple(GLAccount1, 1, 10, Today);

        CreateGLAccountSimple(GLAccount2, '2');
        CreateGLBudgetAmountSimple(GLAccount2, 2, 20, Today + 1);

        // [WHEN] The query is opened and read.
        // [THEN] Various fields are validated.

        PowerBIGLBudgetedAmountList.Open();

        VerifyPowerBIGLBudgetedAmountList(PowerBIGLBudgetedAmountList, '1', Today, 10);
        VerifyPowerBIGLBudgetedAmountList(PowerBIGLBudgetedAmountList, '2', Today + 1, 20);

        Assert.IsFalse(PowerBIGLBudgetedAmountList.Read(), 'Unexpected record in Query.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestItemListByCustomerQuery()
    var
        Customer: Record Customer;
        Item: array[2] of Record Item;
        ValueEntry: Record "Value Entry";
        ItemSalesByCustomer: Query "Item Sales by Customer";
        Qty: array[2] of Decimal;
    begin
        // [FEATURE] [Sales] [UT]
        // [SCENARIO 343131] Item List by Customer query shows sales invoices and credit-memos.
        Qty[1] := LibraryRandom.RandIntInRange(100, 200);
        Qty[2] := -LibraryRandom.RandIntInRange(10, 20);

        CreateCustomerSimple(Customer, LibraryUtility.GenerateGUID(), 0);
        CreateItemSimple(Item[1], LibraryUtility.GenerateGUID());
        CreateItemSimple(Item[2], LibraryUtility.GenerateGUID());

        MockValueEntryForSales(ValueEntry, Customer."No.", ValueEntry."Document Type"::"Sales Invoice", Item[1]."No.", Qty[1]);
        MockValueEntryForSales(ValueEntry, Customer."No.", ValueEntry."Document Type"::"Sales Credit Memo", Item[2]."No.", Qty[2]);

        ItemSalesByCustomer.SetRange(CustomerNo, Customer."No.");
        ItemSalesByCustomer.SetRange(Item_No, Item[1]."No.");
        ItemSalesByCustomer.Open();
        Assert.IsTrue(ItemSalesByCustomer.Read(), 'Sales Invoice is not displayed in Item Sales by Customer report.');
        Assert.AreEqual(Qty[1], ItemSalesByCustomer.Item_Ledger_Entry_Quantity, '');

        ItemSalesByCustomer.SetRange(Item_No, Item[2]."No.");
        ItemSalesByCustomer.Open();
        Assert.IsTrue(ItemSalesByCustomer.Read(), 'Sales Credit Memo is not displayed in Item Sales by Customer report.');
        Assert.AreEqual(Qty[2], ItemSalesByCustomer.Item_Ledger_Entry_Quantity, '');
    end;

    local procedure CreateCustomerSimple(var Customer: Record Customer; No: Code[20]; CreditLimit: Decimal)
    begin
        Customer.Init();
        Customer."No." := No;
        Customer.Name := No;
        Customer."Credit Limit (LCY)" := CreditLimit;
        Customer.Insert();
    end;

    local procedure CreateDetailedCustLedgEntry(var Customer: Record Customer; CustLedgerEntry: Integer; Entry: Integer; Amount: Decimal)
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        DetailedCustLedgEntry.Init();
        DetailedCustLedgEntry."Customer No." := Customer."No.";
        DetailedCustLedgEntry."Entry No." := Entry;
        DetailedCustLedgEntry."Cust. Ledger Entry No." := CustLedgerEntry;
        DetailedCustLedgEntry."Posting Date" := Today;
        DetailedCustLedgEntry.Amount := Amount;
        DetailedCustLedgEntry."Amount (LCY)" := Amount * 2;
        DetailedCustLedgEntry."Transaction No." := CustLedgerEntry;
        DetailedCustLedgEntry.Insert();
    end;

    local procedure CreateVendorSimple(var Vendor: Record Vendor; No: Code[20])
    begin
        Vendor.Init();
        Vendor."No." := No;
        Vendor.Name := No;
        Vendor.Insert();
    end;

    local procedure CreateDetailedVendLedgEntry(var Vendor: Record Vendor; VendLedgerEntry: Integer; Entry: Integer; Amount: Decimal; PossibleDiscount: Decimal)
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        DetailedVendorLedgEntry.Init();
        DetailedVendorLedgEntry."Vendor No." := Vendor."No.";
        DetailedVendorLedgEntry."Entry No." := Entry;
        DetailedVendorLedgEntry."Applied Vend. Ledger Entry No." := VendLedgerEntry;
        DetailedVendorLedgEntry."Posting Date" := Today;
        DetailedVendorLedgEntry.Amount := Amount;
        DetailedVendorLedgEntry."Amount (LCY)" := Amount * 2;
        DetailedVendorLedgEntry."Transaction No." := VendLedgerEntry;
        DetailedVendorLedgEntry."Remaining Pmt. Disc. Possible" := PossibleDiscount;
        DetailedVendorLedgEntry.Insert();
    end;

    local procedure CreateItemSimple(var Item: Record Item; No: Code[20])
    begin
        Item.Init();
        Item."No." := No;
        Item."Search Description" := No;
        Item.Insert();
    end;

    local procedure CreateItemLedgEntry(var Item: Record Item; RecDate: Date; EntryNo: Integer; Quantity: Decimal)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.Init();
        ItemLedgerEntry."Item No." := Item."No.";
        ItemLedgerEntry."Entry No." := EntryNo;
        ItemLedgerEntry."Posting Date" := RecDate;
        ItemLedgerEntry."Invoiced Quantity" := Quantity;
        ItemLedgerEntry."Entry Type" := ItemLedgerEntry."Entry Type"::Purchase;
        ItemLedgerEntry.Insert();
    end;

    local procedure CreateValueEntry(var Item: Record Item; RecDate: Date; EntryNo: Integer; Quantity: Decimal)
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.Init();
        ValueEntry."Item No." := Item."No.";
        ValueEntry."Entry No." := EntryNo;
        ValueEntry."Posting Date" := RecDate;
        ValueEntry."Invoiced Quantity" := Quantity;
        ValueEntry."Item Ledger Entry Type" := ValueEntry."Item Ledger Entry Type"::Sale;
        ValueEntry.Insert();
    end;

    local procedure CreateJobSimple(var Job: Record Job; No: Code[20]; Complete: Boolean; Status: Enum "Job Status")
    begin
        Job.Init();
        Job."No." := No;
        Job."Search Description" := No;
        Job.Complete := Complete;
        Job.Status := Status;
        Job.Insert();
    end;

    local procedure CreateJobLedgerEntry(var Job: Record Job; TotalCost: Decimal; EntryNo: Integer)
    var
        JobLedgerEntry: Record "Job Ledger Entry";
    begin
        JobLedgerEntry.Init();
        JobLedgerEntry."Job No." := Job."No.";
        JobLedgerEntry."Posting Date" := Today;
        JobLedgerEntry."Total Cost" := TotalCost;
        JobLedgerEntry."Entry No." := EntryNo;
        JobLedgerEntry.Insert();
    end;

    local procedure CreateSalesHeaderSimple(var SalesHeader: Record "Sales Header"; No: Code[20]; RecDate: Date)
    begin
        SalesHeader.Init();
        SalesHeader."No." := No;
        SalesHeader."Document Type" := SalesHeader."Document Type"::Invoice;
        SalesHeader."Requested Delivery Date" := RecDate;
        SalesHeader."Shipment Date" := RecDate + 10;
        SalesHeader."Due Date" := RecDate + 20;
        SalesHeader.Insert();
    end;

    local procedure CreateSalesLineSimple(var SalesHeader: Record "Sales Header"; LineNo: Integer; Quantity: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.Init();
        SalesLine."Document No." := SalesHeader."No.";
        SalesLine."Document Type" := SalesHeader."Document Type";
        SalesLine."Line No." := LineNo;
        SalesLine.Quantity := Quantity;
        SalesLine.Amount := Quantity * 10;
        SalesLine.Insert();
    end;

    local procedure CreatePurchaseHeaderSimple(var PurchaseHeader: Record "Purchase Header"; No: Code[20]; RecDate: Date)
    begin
        PurchaseHeader.Init();
        PurchaseHeader."No." := No;
        PurchaseHeader."Document Type" := PurchaseHeader."Document Type"::Invoice;
        PurchaseHeader."Order Date" := RecDate;
        PurchaseHeader."Expected Receipt Date" := RecDate + 10;
        PurchaseHeader."Due Date" := RecDate + 20;
        PurchaseHeader."Pmt. Discount Date" := RecDate + 30;
        PurchaseHeader.Insert();
    end;

    local procedure CreatePurchaseLineSimple(var PurchaseHeader: Record "Purchase Header"; LineNo: Integer; Quantity: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.Init();
        PurchaseLine."Document No." := PurchaseHeader."No.";
        PurchaseLine."Document Type" := PurchaseHeader."Document Type";
        PurchaseLine."Line No." := LineNo;
        PurchaseLine.Quantity := Quantity;
        PurchaseLine.Amount := Quantity * 10;
        PurchaseLine.Insert();
    end;

    local procedure CreateGLAccountSimple(var GLAccount: Record "G/L Account"; No: Code[20])
    begin
        GLAccount.Init();
        GLAccount."No." := No;
        GLAccount.Name := No;
        GLAccount."Account Type" := GLAccount."Account Type"::Posting;
        GLAccount.Insert();
    end;

    local procedure CreateGLEntrySimple(var GLAccount: Record "G/L Account"; EntryNo: Integer; Amount: Decimal; RecDate: Date)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.Init();
        GLEntry."G/L Account No." := GLAccount."No.";
        GLEntry."Posting Date" := RecDate;
        GLEntry.Amount := Amount;
        GLEntry."Entry No." := EntryNo;
        GLEntry.Insert();
    end;

    local procedure CreateGLBudgetAmountSimple(var GLAccount: Record "G/L Account"; EntryNo: Integer; Amount: Decimal; RecDate: Date)
    var
        GLBudgetEntry: Record "G/L Budget Entry";
    begin
        GLBudgetEntry.Init();
        GLBudgetEntry."G/L Account No." := GLAccount."No.";
        GLBudgetEntry."Entry No." := EntryNo;
        GLBudgetEntry.Amount := Amount;
        GLBudgetEntry.Date := RecDate;
        GLBudgetEntry.Insert();
    end;

    local procedure MockValueEntryForSales(var ValueEntry: Record "Value Entry"; CustomerNo: Code[20]; DocumentType: Enum "Item Ledger Document Type"; ItemNo: Code[20]; Qty: Decimal)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ValueEntry.Init();
        ValueEntry."Entry No." := LibraryUtility.GetNewRecNo(ValueEntry, ValueEntry.FieldNo("Entry No."));
        ValueEntry."Item Ledger Entry No." := LibraryUtility.GetNewRecNo(ItemLedgerEntry, ItemLedgerEntry.FieldNo("Entry No."));
        ValueEntry."Source Type" := ValueEntry."Source Type"::Customer;
        ValueEntry."Source No." := CustomerNo;
        ValueEntry."Document Type" := DocumentType;
        ValueEntry."Item No." := ItemNo;
        ValueEntry."Item Ledger Entry Quantity" := Qty;
        ValueEntry.Insert();
    end;

    local procedure VerifyPowerBICustomerList(PowerBICustomerList: Query "Power BI Customer List"; No: Code[20]; CreditLimit: Decimal; BalanceDue: Decimal; PostDate: Date; CustLedgEntry: Integer; Amount: Decimal; TransactionNo: Integer; EntryNo: Integer)
    begin
        Assert.IsTrue(PowerBICustomerList.Read(), 'Expected record in Query PowerBICustomerList');
        Assert.AreEqual(No, PowerBICustomerList.Customer_No, 'Unexpected Customer No value PowerBICustomerList');
        Assert.AreEqual(No, PowerBICustomerList.Customer_Name, 'Unexpected Customer Name value PowerBICustomerList');
        Assert.AreEqual(CreditLimit, PowerBICustomerList.Credit_Limit, 'Unexpected Customer credit limit value PowerBICustomerList');
        Assert.AreEqual(BalanceDue, PowerBICustomerList.Balance_Due, 'Unexpected Customer balance due value PowerBICustomerList');
        Assert.AreEqual(PostDate, PowerBICustomerList.Posting_Date, 'Unexpected posting date value PowerBICustomerList');
        Assert.AreEqual(CustLedgEntry, PowerBICustomerList.Cust_Ledger_Entry_No, 'Unexpected custledgerentry value PowerBICustomerList');
        Assert.AreEqual(Amount, PowerBICustomerList.Amount, 'Unexpected Amount value PowerBICustomerList');
        Assert.AreEqual(Amount * 2, PowerBICustomerList.Amount_LCY, 'Unexpected Amount LCY value PowerBICustomerList');
        Assert.AreEqual(TransactionNo, PowerBICustomerList.Transaction_No, 'Unexpected Transaction No value PowerBICustomerList');
        Assert.AreEqual(EntryNo, PowerBICustomerList.Entry_No, 'Unexpected Entry value PowerBICustomerList');
    end;

    local procedure VerifyPowerBIVendorList(PowerBIVendorList: Query "Power BI Vendor List"; No: Code[20]; RemainPmtDisc: Decimal; BalanceDue: Decimal; PostDate: Date; CustLedgEntry: Integer; Amount: Decimal; TransactionNo: Integer; EntryNo: Integer)
    begin
        Assert.IsTrue(PowerBIVendorList.Read(), 'Expected record in Query PowerBIVendorList');
        Assert.AreEqual(No, PowerBIVendorList.Vendor_No, 'Unexpected Vendor No value PowerBIVendorList');
        Assert.AreEqual(No, PowerBIVendorList.Vendor_Name, 'Unexpected Vendor Name value PowerBIVendorList');
        Assert.AreEqual(TransactionNo, PowerBIVendorList.Transaction_No, 'Unexpected Transaction No value PowerBIVendorList');
        Assert.AreEqual(EntryNo, PowerBIVendorList.Entry_No, 'Unexpected Entry No value PowerBIVendorList');
        Assert.AreEqual(RemainPmtDisc, PowerBIVendorList.Remaining_Pmt_Disc_Possible, 'Unexpected Entry No value PowerBIVendorList');
        Assert.AreEqual(PostDate, PowerBIVendorList.Posting_Date, 'Unexpected Posting date value PowerBIVendorList');
        Assert.AreEqual(CustLedgEntry, PowerBIVendorList.Applied_Vend_Ledger_Entry_No,
          'Unexpected Applied Vendor Ledger Entry value PowerBIVendorList');
        Assert.AreEqual(Amount, PowerBIVendorList.Amount, 'Unexpected Amount value PowerBIVendorList');
        Assert.AreEqual(Amount * 2, PowerBIVendorList.Amount_LCY, 'Unexpected Amount LCY value PowerBIVendorList');
        Assert.AreEqual(BalanceDue, PowerBIVendorList.Balance_Due, 'Unexpected balance due value PowerBIVendorList');
    end;

    local procedure VerifyPowerBIItemPurchasesList(PowerBIItemPurchaseList: Query "Power BI Item Purchase List"; No: Code[20]; PurchQty: Decimal; PurchaseNo: Integer; PostDate: Date)
    begin
        Assert.IsTrue(PowerBIItemPurchaseList.Read(), 'Expected record in Query PowerBIItemPurchasesList');
        Assert.AreEqual(No, PowerBIItemPurchaseList.Item_No, 'Unexpected item no PowerBIItemPurchasesList');
        Assert.AreEqual(No, PowerBIItemPurchaseList.Search_Description, 'Unexpected search description PowerBIItemPurchasesList');
        Assert.AreEqual(PurchQty, PowerBIItemPurchaseList.Purchased_Quantity, 'Unexpected purchase qty PowerBIItemPurchasesList');
        Assert.AreEqual(PurchaseNo, PowerBIItemPurchaseList.Purchase_Entry_No, 'Unexpected purchase entry no PowerBIItemPurchasesList');
        Assert.AreEqual(PostDate, PowerBIItemPurchaseList.Purchase_Post_Date, 'Unexpected purchase posting date PowerBIItemPurchasesList');
    end;

    local procedure VerifyPowerBIItemSalesList(PowerBIItemSalesList: Query "Power BI Item Sales List"; No: Code[20]; SaleQty: Decimal; SaleNo: Integer; PostDate: Date)
    begin
        Assert.IsTrue(PowerBIItemSalesList.Read(), 'Expected record in Query PowerBIItemSalesList');
        Assert.AreEqual(No, PowerBIItemSalesList.Item_No, 'Unexpected item no PowerBIItemSalesList');
        Assert.AreEqual(No, PowerBIItemSalesList.Search_Description, 'Unexpected search description PowerBIItemSalesList');
        Assert.AreEqual(SaleQty, PowerBIItemSalesList.Sold_Quantity, 'Unexpected sold qty PowerBIItemSalesList');
        Assert.AreEqual(SaleNo, PowerBIItemSalesList.Sales_Entry_No, 'Unexpected sales entry no PowerBIItemSalesList');
        Assert.AreEqual(PostDate, PowerBIItemSalesList.Sales_Post_Date, 'Unexpected sale posting date PowerBIItemSalesList');
    end;

    local procedure VerifyPowerBIJobList(PowerBIJobsList: Query "Power BI Jobs List"; No: Code[20]; Complete: Boolean; Status: Enum "Job Status"; PostDate: Date; TotalCost: Decimal; EntryNo: Integer)
    begin
        Assert.IsTrue(PowerBIJobsList.Read(), 'Expected record in Query PowerBIJobsList');
        Assert.AreEqual(No, PowerBIJobsList.Job_No, 'Unexpected Job No PowerBIJobsList');
        Assert.AreEqual(No, PowerBIJobsList.Search_Description, 'Unexpected search description PowerBIJobsList');
        Assert.AreEqual(Complete, PowerBIJobsList.Complete, 'Unexpected Complete value PowerBIJobsList');
        Assert.AreEqual(Status, PowerBIJobsList.Status, 'Unexpected Job Status PowerBIJobsList');
        Assert.AreEqual(PostDate, PowerBIJobsList.Posting_Date, 'Unexpected Posting Date PowerBIJobsList');
        Assert.AreEqual(TotalCost, PowerBIJobsList.Total_Cost, 'Unexpected Posting Date PowerBIJobsList');
        Assert.AreEqual(EntryNo, PowerBIJobsList.Entry_No, 'Unexpected Posting Date PowerBIJobsList');
    end;

    local procedure VerifyPowerBISalesList(PowerBISalesList: Query "Power BI Sales List"; No: Code[20]; ReqShipDate: Date; ShipmentDate: Date; DueDate: Date; Quantity: Decimal; Amount: Decimal)
    begin
        Assert.IsTrue(PowerBISalesList.Read(), 'Expected record in Query PowerBISalesList');
        Assert.AreEqual(No, PowerBISalesList.Document_No, 'Unexpected value for No PowerBISalesList');
        Assert.AreEqual(ReqShipDate, PowerBISalesList.Requested_Delivery_Date, 'Unexpected requested delivery date PowerBISalesList');
        Assert.AreEqual(ShipmentDate, PowerBISalesList.Shipment_Date, 'Unexpected shipment date PowerBISalesList');
        Assert.AreEqual(DueDate, PowerBISalesList.Due_Date, 'Unexpected due date PowerBISalesList');
        Assert.AreEqual(Quantity, PowerBISalesList.Quantity, 'Unexpected quantity PowerBISalesList');
        Assert.AreEqual(Amount, PowerBISalesList.Amount, 'Unexpected amount PowerBISalesList');
    end;

    local procedure VerifyPowerBIPurchaseList(PowerBIPurchaseList: Query "Power BI Purchase List"; No: Code[20]; OrderDate: Date; ExpRecDate: Date; DueDate: Date; PmtDiscDate: Date; Quantity: Decimal; Amount: Decimal)
    begin
        Assert.IsTrue(PowerBIPurchaseList.Read(), 'Expected record in Query PowerBIPurchaseList');
        Assert.AreEqual(No, PowerBIPurchaseList.Document_No, 'Unexpected purchase no PowerBIPurchaseList');
        Assert.AreEqual(OrderDate, PowerBIPurchaseList.Order_Date, 'Unexpected order date PowerBIPurchaseList');
        Assert.AreEqual(ExpRecDate, PowerBIPurchaseList.Expected_Receipt_Date, 'Unexpected expected receipt date PowerBIPurchaseList');
        Assert.AreEqual(DueDate, PowerBIPurchaseList.Due_Date, 'Unexpected due date PowerBIPurchaseList');
        Assert.AreEqual(PmtDiscDate, PowerBIPurchaseList.Pmt_Discount_Date, 'Unexpected pmt discount date PowerBIPurchaseList');
        Assert.AreEqual(Quantity, PowerBIPurchaseList.Quantity, 'Unexpected quantity PowerBIPurchaseList');
        Assert.AreEqual(Amount, PowerBIPurchaseList.Amount, 'Unexpected amount PowerBIPurchaseList');
    end;

    local procedure VerifyPowerBIGLAmountList(PowerBIGLAmountList: Query "Power BI GL Amount List"; No: Code[20]; PostDate: Date; Amount: Decimal; EntryNo: Integer)
    begin
        Assert.IsTrue(PowerBIGLAmountList.Read(), 'Expected record in query PowerBIGLAmountList');
        Assert.AreEqual(No, PowerBIGLAmountList.GL_Account_No, 'Unexpected account no PowerBIGLAmountList');
        Assert.AreEqual(No, PowerBIGLAmountList.Name, 'Unexpected name PowerBIGLAmountList');
        Assert.AreEqual(PostDate, PowerBIGLAmountList.Posting_Date, 'Unexpected posting date PowerBIGLAmountList');
        Assert.AreEqual(Amount, PowerBIGLAmountList.Amount, 'Unexpected amount PowerBIGLAmountList');
        Assert.AreEqual(EntryNo, PowerBIGLAmountList.Entry_No, 'Unexpected entry no PowerBIGLAmountList');
    end;

    local procedure VerifyPowerBIGLBudgetedAmountList(PowerBIGLBudgetedAmount: Query "Power BI GL Budgeted Amount"; No: Code[20]; BudgetDate: Date; Amount: Decimal)
    begin
        Assert.IsTrue(PowerBIGLBudgetedAmount.Read(), 'Expected record in query PowerBIGLBudgetedAmountList');
        Assert.AreEqual(No, PowerBIGLBudgetedAmount.GL_Account_No, 'Unexpected account no PowerBIGLBudgetedAmountList');
        Assert.AreEqual(No, PowerBIGLBudgetedAmount.Name, 'Unexpected name PowerBIGLBudgetedAmountList');
        Assert.AreEqual(BudgetDate, PowerBIGLBudgetedAmount.Date, 'Unexpected date PowerBIGLBudgetedAmountList');
        Assert.AreEqual(Amount, PowerBIGLBudgetedAmount.Amount, 'Unexpected amount PowerBIGLBudgetedAmountList');
    end;
}

