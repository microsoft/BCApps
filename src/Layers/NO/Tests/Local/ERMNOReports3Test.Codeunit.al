codeunit 144182 "ERM NO Reports 3 Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [NO Report]
    end;

    var
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryERM: Codeunit "Library - ERM";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;
        isInitialized: Boolean;

    [Test]
    [HandlerFunctions('CustomerCollectionHandler')]
    [Scope('OnPrem')]
    procedure CustomerCollectionListReport()
    var
        ReminderHeader: Record "Reminder Header";
        Customer: Record Customer;
        NumberOfReminderLines: Integer;
    begin
        // [FEATURE] [Customer - Collection List]
        // Setup
        Initialize();

        LibrarySales.CreateCustomer(Customer);
        NumberOfReminderLines := LibraryRandom.RandIntInRange(2, 4); // Make sure it is greater than 1
        CreateReminderDoc(ReminderHeader, Customer, NumberOfReminderLines);

        // Execute and verify
        ExecuteAndVerifyCustomerCollectionReport(ReminderHeader);
    end;

    [Test]
    [HandlerFunctions('CustomerCollectionHandler')]
    [Scope('OnPrem')]
    procedure CustomerCollectionListFromCustLedgerEntriesReport()
    var
        ReminderHeader: Record "Reminder Header";
        Customer: Record Customer;
    begin
        // [FEATURE] [Customer - Collection List]
        // Setup
        Initialize();

        // Create two posted sales orders for the given customer
        LibrarySales.CreateCustomer(Customer);
        CreateAndPostSalesOrderDoc(Customer);
        CreateAndPostSalesOrderDoc(Customer);

        CreateReminderDocForCustomer(ReminderHeader, Customer);

        // Execute and verify
        ExecuteAndVerifyCustomerCollectionReport(ReminderHeader);
    end;

    [Test]
    [HandlerFunctions('CustomerOpenEntriesHandler')]
    [Scope('OnPrem')]
    procedure CustomerOpenEntries()
    var
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        NumberOfEntries: Integer;
    begin
        // [FEATURE] [Customer - Open Entries]
        Initialize();

        // Setup
        LibrarySales.CreateCustomer(Customer);
        CreateAndPostSalesOrderDoc(Customer);
        CreateAndPostSalesOrderDoc(Customer);

        // Execute
        RunReportCustomerOpenEntries(Customer);

        // Verify
        CustLedgerEntry.Reset();
        CustLedgerEntry.SetFilter("Customer No.", Customer."No.");
        NumberOfEntries := CustLedgerEntry.Count();
        Assert.AreEqual(2, NumberOfEntries, 'Two sales orders with one line each are posted so two customer ledger entries.');

        LibraryReportDataset.LoadDataSetFile();
        Assert.AreEqual(NumberOfEntries, LibraryReportDataset.RowCount(), 'There should be the number of customer ledger entries.');

        CustLedgerEntry.Reset();
        CustLedgerEntry.SetFilter("Customer No.", Customer."No.");
        CustLedgerEntry.FindSet();

        while LibraryReportDataset.GetNextRow() do begin
            CustLedgerEntry.CalcFields(Amount);
            LibraryReportDataset.AssertCurrentRowValueEquals('Amt_CustLedgEntry', CustLedgerEntry.Amount);
            CustLedgerEntry.CalcFields("Remaining Amount");
            LibraryReportDataset.AssertCurrentRowValueEquals('RemainingAmt_CustLedgEntry', CustLedgerEntry."Remaining Amount");
            CustLedgerEntry.CalcFields("Remaining Amt. (LCY)");
            LibraryReportDataset.AssertCurrentRowValueEquals('RemainingAmountLCY_CustLedgEntry', CustLedgerEntry."Remaining Amt. (LCY)");
            CustLedgerEntry.Next();
        end;
    end;

    [Test]
    [HandlerFunctions('VendorOpenEntriesHandler')]
    [Scope('OnPrem')]
    procedure VendorOpenEntries()
    var
        Vendor: Record Vendor;
        VendLedgerEntry: Record "Vendor Ledger Entry";
        NumberOfLedgerEntries: Integer;
    begin
        // [FEATURE] [Vendor - Open Entries]
        Initialize();

        // [GIVEN] Post purchase order for vendor 'A', where "No." is 'A1', "External Document No." is 'E1'
        LibraryPurchase.CreateVendor(Vendor);
        CreateAndPostPurchaseOrderDoc(Vendor);
        // [GIVEN] Post purchase order for vendor 'A', where "No." is 'A2', "External Document No." is 'E2'
        CreateAndPostPurchaseOrderDoc(Vendor);

        // [WHEN] Run report "Vendor - Open Entries" for vendor 'A', where "Use External Document No." is 'No'
        RunReportVendorOpenEntries(Vendor, false);

        // [THEN] Report contains 2 lines
        VendLedgerEntry.Reset();
        VendLedgerEntry.SetFilter("Vendor No.", Vendor."No.");
        NumberOfLedgerEntries := VendLedgerEntry.Count();
        Assert.AreEqual(2, NumberOfLedgerEntries, 'Two purchase orders with one lines each should give 2 vendor ledger entries');

        LibraryReportDataset.LoadDataSetFile();
        Assert.AreEqual(NumberOfLedgerEntries, LibraryReportDataset.RowCount(), 'There should be the same amount as vendor ledger entries.');

        VendLedgerEntry.Reset();
        VendLedgerEntry.SetFilter("Vendor No.", Vendor."No.");
        VendLedgerEntry.FindSet();
        // [THEN] Lines contains correct Amount, "Remainiong Amount", "Vendor Name", "Document No." is 'A1'/'A2'
        while LibraryReportDataset.GetNextRow() do begin
            LibraryReportDataset.AssertCurrentRowValueEquals('DocumentNo_VendorLedgerEntry', VendLedgerEntry."Document No.");
            VendLedgerEntry.CalcFields(Amount);
            LibraryReportDataset.AssertCurrentRowValueEquals('Amount_VendorLedgerEntry', VendLedgerEntry.Amount);
            VendLedgerEntry.CalcFields("Remaining Amount");
            LibraryReportDataset.AssertCurrentRowValueEquals('RemainingAmount_VendorLedgerEntry', VendLedgerEntry."Remaining Amount");
            LibraryReportDataset.AssertCurrentRowValueEquals('VendorName', Vendor.Name);
            VendLedgerEntry.Next();
        end;
    end;

    [Test]
    [HandlerFunctions('VendorOpenEntriesHandler')]
    [Scope('OnPrem')]
    procedure VendorOpenEntriesExtDocNo()
    var
        Vendor: Record Vendor;
        VendLedgerEntry: Record "Vendor Ledger Entry";
        NumberOfLedgerEntries: Integer;
    begin
        // [FEATURE] [Vendor - Open Entries] [External Document No.]
        Initialize();

        // [GIVEN] Post purchase order for vendor 'A', where "No." is 'A1', "External Document No." is 'E1'
        LibraryPurchase.CreateVendor(Vendor);
        CreateAndPostPurchaseOrderDoc(Vendor);
        // [GIVEN] Post purchase order for vendor 'A', where "No." is 'A2', "External Document No." is 'E2'
        CreateAndPostPurchaseOrderDoc(Vendor);

        // [WHEN] Run report "Vendor - Open Entries" for vendor 'A', where "Use External Document No." is 'Yes'
        RunReportVendorOpenEntries(Vendor, true);

        // [THEN] Report contains 2 lines
        VendLedgerEntry.Reset();
        VendLedgerEntry.SetFilter("Vendor No.", Vendor."No.");
        NumberOfLedgerEntries := VendLedgerEntry.Count();
        Assert.AreEqual(2, NumberOfLedgerEntries, 'Two purchase orders with one lines each should give 2 vendor ledger entries');

        LibraryReportDataset.LoadDataSetFile();
        Assert.AreEqual(NumberOfLedgerEntries, LibraryReportDataset.RowCount(), 'There should be the same amount as vendor ledger entries.');

        VendLedgerEntry.Reset();
        VendLedgerEntry.SetFilter("Vendor No.", Vendor."No.");
        VendLedgerEntry.FindSet();
        // [THEN] Lines contains correct Amount, "Remainiong Amount", "Vendor Name", "Document No." is 'E1'/'E2'
        while LibraryReportDataset.GetNextRow() do begin
            LibraryReportDataset.AssertCurrentRowValueEquals('DocumentNo_VendorLedgerEntry', VendLedgerEntry."External Document No.");
            VendLedgerEntry.CalcFields(Amount);
            LibraryReportDataset.AssertCurrentRowValueEquals('Amount_VendorLedgerEntry', VendLedgerEntry.Amount);
            VendLedgerEntry.CalcFields("Remaining Amount");
            LibraryReportDataset.AssertCurrentRowValueEquals('RemainingAmount_VendorLedgerEntry', VendLedgerEntry."Remaining Amount");
            LibraryReportDataset.AssertCurrentRowValueEquals('VendorName', Vendor.Name);
            VendLedgerEntry.Next();
        end;
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryVariableStorage.Clear();
        LibraryReportDataset.Reset();

        // Lazy Setup.
        if isInitialized then
            exit;

        LibraryERMCountryData.UpdateGeneralPostingSetup();

        isInitialized := true;
        Commit();
    end;

    local procedure CreateReminderDoc(var ReminderHeader: Record "Reminder Header"; Customer: Record Customer; NumberOfReminderLines: Integer)
    var
        ReminderLine: Record "Reminder Line";
        GLAccount: Record "G/L Account";
        VATPostingSetup: Record "VAT Posting Setup";
        Counter: Integer;
        LineNo: Integer;
    begin
        CreateReminderHeader(ReminderHeader, Customer);

        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        CreateGLAccount(GLAccount, VATPostingSetup."VAT Prod. Posting Group");

        LineNo := 10000;
        for Counter := 1 to NumberOfReminderLines do begin
            ReminderLine.Init();
            ReminderLine."Reminder No." := ReminderHeader."No.";
            ReminderLine.Type := ReminderLine.Type::"G/L Account";
            LineNo := LineNo + 10000;
            ReminderLine."Line No." := LineNo;
            ReminderLine.Validate("No.", GLAccount."No.");
            ReminderLine.Description := 'Reminder line dummy description';
            ReminderLine.Validate(Amount, LibraryRandom.RandInt(1000));
            ReminderLine.Insert(true);
        end;
    end;

    local procedure CreateReminderDocForCustomer(var ReminderHeader: Record "Reminder Header"; Customer: Record Customer)
    var
        ReminderLine: Record "Reminder Line";
        GLAccount: Record "G/L Account";
        VATPostingSetup: Record "VAT Posting Setup";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        LineNo: Integer;
    begin
        CreateReminderHeader(ReminderHeader, Customer);

        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        CreateGLAccount(GLAccount, VATPostingSetup."VAT Prod. Posting Group");

        LineNo := 10000;
        CustLedgerEntry.Reset();
        CustLedgerEntry.SetFilter("Customer No.", Customer."No.");
        CustLedgerEntry.FindSet();

        repeat
            CustLedgerEntry.CalcFields(Amount);
            ReminderLine.Init();
            ReminderLine."Reminder No." := ReminderHeader."No.";
            ReminderLine.Type := ReminderLine.Type::"Customer Ledger Entry";
            LineNo := LineNo + 10000;
            ReminderLine."Line No." := LineNo;
            ReminderLine.Validate("Entry No.", CustLedgerEntry."Entry No.");
            ReminderLine.Description := 'Reminder line dummy description';
            ReminderLine.Validate(Amount, 100);
            ReminderLine.Insert(true);
        until (CustLedgerEntry.Next() = 0);
    end;

    local procedure CreateReminderHeader(var ReminderHeader: Record "Reminder Header"; Customer: Record Customer)
    var
        ReminderTerms: Record "Reminder Terms";
    begin
        LibraryERM.CreateReminderHeader(ReminderHeader);
        LibraryERM.CreateReminderTerms(ReminderTerms);

        ReminderHeader.Validate("Customer No.", Customer."No.");
        ReminderHeader.Validate("Reminder Terms Code", ReminderTerms.Code);
        ReminderHeader.Validate("Post Interest", false);
        ReminderHeader.Validate("Post Additional Fee", false);
        ReminderHeader.Modify(true);
    end;

    local procedure ExecuteAndVerifyCustomerCollectionReport(ReminderHeader: Record "Reminder Header")
    var
        ReminderLine: Record "Reminder Line";
        IssuedReminderHeader: Record "Issued Reminder Header";
        ReminderIssue: Codeunit "Reminder-Issue";
        ReminderLineAmountArray: array[10] of Decimal;
        "Count": Integer;
        ReminderLineReminderTotalArray: array[5] of Decimal;
        ReminderLineOrigAmountArray: array[5] of Decimal;
    begin
        // Find list of generated reminder lines
        ReminderLine.Reset();
        ReminderLine.SetFilter("Reminder No.", ReminderHeader."No.");
        ReminderLine.FindSet();

        Count := 1;
        repeat
            ReminderLineAmountArray[Count] := ReminderLine.Amount;
            ReminderLineOrigAmountArray[Count] := ReminderLine."Original Amount";
            ReminderLineReminderTotalArray[Count] := ReminderLine.Amount + ReminderLine."Original Amount";
            Count := Count + 1;
        until (ReminderLine.Next() = 0);

        ReminderIssue.Set(ReminderHeader, false, WorkDate());
        ReminderIssue.Run();
        ReminderIssue.GetIssuedReminder(IssuedReminderHeader);

        // Excercise
        RunReportCollectionList(IssuedReminderHeader);
        // Verify: That the reminder collection letters are correct.
        LibraryReportDataset.LoadDataSetFile();
        Assert.AreEqual(2, LibraryReportDataset.RowCount(), 'There should be only a given set of reminder lines.');

        Count := 1;
        while LibraryReportDataset.GetNextRow() do begin
            LibraryReportDataset.AssertCurrentRowValueEquals('Amount_IssuedReminderLine', ReminderLineAmountArray[Count]);
            LibraryReportDataset.AssertCurrentRowValueEquals('OriginalAmount_IssuedReminderLine', ReminderLineOrigAmountArray[Count]);
            LibraryReportDataset.AssertCurrentRowValueEquals('ReminderTotal', ReminderLineReminderTotalArray[Count]);
            Count := Count + 1;
        end;
    end;

    local procedure CreateGLAccount(var GLAccount: Record "G/L Account"; VATProdPostGroupCode: Code[20]): Code[20]
    var
        GenProductPostingGroup: Record "Gen. Product Posting Group";
    begin
        LibraryERM.FindGenProductPostingGroup(GenProductPostingGroup);
        GenProductPostingGroup."Auto Insert Default" := false;
        GenProductPostingGroup.Modify();

        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount."Gen. Prod. Posting Group" := GenProductPostingGroup.Code;
        GLAccount."VAT Prod. Posting Group" := VATProdPostGroupCode;
        GLAccount.Modify();
        exit(GLAccount."No.");
    end;

    local procedure CreateAndPostSalesOrderDoc(Customer: Record Customer)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesHeader."Document Type", '1000', LibraryRandom.RandInt(5));
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure CreateAndPostPurchaseOrderDoc(Vendor: Record Vendor)
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(
          PurchHeader, PurchHeader."Document Type"::Invoice, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchLine, PurchHeader, PurchHeader."Document Type", '1000', LibraryRandom.RandInt(5));
        PurchLine.Validate("Direct Unit Cost", 5000.0);
        PurchLine.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);
    end;

    local procedure RunReportCollectionList(IssuedReminderHeader: Record "Issued Reminder Header")
    begin
        LibraryVariableStorage.Enqueue(IssuedReminderHeader."No.");
        Commit();
        REPORT.Run(REPORT::"Customer - Collection List");
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CustomerCollectionHandler(var IssuedReminder: TestRequestPage "Customer - Collection List")
    var
        IssuedReminderHeaderNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(IssuedReminderHeaderNo);

        IssuedReminder."Issued Reminder Header".SetFilter("No.", IssuedReminderHeaderNo);
        IssuedReminder.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    local procedure RunReportCustomerOpenEntries(Customer: Record Customer)
    begin
        LibraryVariableStorage.Enqueue(Customer."No.");
        Commit();
        REPORT.Run(REPORT::"Customer - Open Entries");
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CustomerOpenEntriesHandler(var CustomerEntry: TestRequestPage "Customer - Open Entries")
    var
        CustomerNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(CustomerNo);

        CustomerEntry.Customer.SetFilter("No.", CustomerNo);
        CustomerEntry.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    local procedure RunReportVendorOpenEntries(Vendor: Record Vendor; UseExternalDocNo: Boolean)
    begin
        LibraryVariableStorage.Enqueue(Vendor."No.");
        LibraryVariableStorage.Enqueue(UseExternalDocNo);
        Commit();
        REPORT.Run(REPORT::"Vendor - Open Entries");
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VendorOpenEntriesHandler(var VendorEntry: TestRequestPage "Vendor - Open Entries")
    var
        VendorNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(VendorNo);

        VendorEntry.Vendor.SetFilter("No.", VendorNo);
        VendorEntry.UseExternalDocNo.SetValue(Format(LibraryVariableStorage.DequeueBoolean()));
        VendorEntry.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}

