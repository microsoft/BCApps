codeunit 134765 TestAccountantPortalWS
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Accountant Portal Web Services]
        isInitialized := false;
    end;

    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        IncomingDocument: Record "Incoming Document";
        ApprovalEntry: Record "Approval Entry";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        Vendor: Record Vendor;
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        Assert: Codeunit Assert;
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryRandom: Codeunit "Library - Random";
        AccountantPortalActivityCues: TestPage "AccountantPortal Activity Cues";
        AccountantPortalFinanceCues: TestPage "Accountant Portal Finance Cues";
        MasterStyle: enum "Cues And KPIs Style";
        isInitialized: Boolean;
        RequestsToApproveErr: Label 'Expected Request to approve count are not equal';
        RequestsSentForApprovalErr: Label 'Expected Requests Sent For Approval count are not equal';

    [Test]
    [Scope('OnPrem')]
    procedure TestFinanceCues()
    var
        FinanceCue: Record "Finance Cue";
    begin
        // [SCENARIO] Exercise Page for Accountant Portal Finance Cues.
        Initialize();

        // [GIVEN] Cue data available.
        SetupData();

        // [WHEN] The Page is ran.
        AccountantPortalFinanceCues.OpenView();

        // [THEN] Various activities cue fields are validated.
        VerifyFinanceCues(AccountantPortalFinanceCues,
          FinanceCue.FieldName("Overdue Purchase Documents"), '                             3', MasterStyle::Unfavorable);
        VerifyFinanceCues(AccountantPortalFinanceCues,
          FinanceCue.FieldName("Purchase Discounts Next Week"), '                             6', MasterStyle::None);
        VerifyFinanceCues(AccountantPortalFinanceCues,
          FinanceCue.FieldName("Purchase Documents Due Today"), '                             3', MasterStyle::Ambiguous);
        VerifyFinanceCues(AccountantPortalFinanceCues,
          FinanceCue.FieldName("Overdue Sales Documents"), '                             3', MasterStyle::None);
        VerifyFinanceCues(AccountantPortalFinanceCues,
          FinanceCue.FieldName("Vendors - Payment on Hold"), '                             2', MasterStyle::None);
        VerifyFinanceCues(AccountantPortalFinanceCues,
          FinanceCue.FieldName("POs Pending Approval"), '                             0', MasterStyle::None);
        VerifyFinanceCues(AccountantPortalFinanceCues,
          FinanceCue.FieldName("SOs Pending Approval"), '                             0', MasterStyle::None);
        VerifyFinanceCues(AccountantPortalFinanceCues,
          FinanceCue.FieldName("Approved Sales Orders"), '                            22', MasterStyle::None);
        VerifyFinanceCues(AccountantPortalFinanceCues,
          FinanceCue.FieldName("Approved Purchase Orders"), '                            14', MasterStyle::None);
        VerifyFinanceCues(AccountantPortalFinanceCues,
          FinanceCue.FieldName("Purchase Return Orders"), '                             0', MasterStyle::None);
        VerifyFinanceCues(AccountantPortalFinanceCues,
          FinanceCue.FieldName("Sales Return Orders - All"), '                             2', MasterStyle::None);
        VerifyFinanceCues(AccountantPortalFinanceCues,
          FinanceCue.FieldName("Customers - Blocked"), '                             0', MasterStyle::None);
        VerifyFinanceCues(AccountantPortalFinanceCues,
          FinanceCue.FieldName("New Incoming Documents"), '                             6', MasterStyle::None);
        VerifyFinanceCues(AccountantPortalFinanceCues,
          FinanceCue.FieldName("Approved Incoming Documents"), '                             0', MasterStyle::None);
        VerifyFinanceCues(AccountantPortalFinanceCues,
          FinanceCue.FieldName("OCR Pending"), '                             3', MasterStyle::None);
        VerifyFinanceCues(AccountantPortalFinanceCues,
          FinanceCue.FieldName("OCR Completed"), '                             2', MasterStyle::None);

        AccountantPortalFinanceCues.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestActivitiesCues()
    var
        ActivitiesCue: Record "Activities Cue";
        AcctWebServicesMgt: Codeunit "Acct. WebServices Mgt.";
    begin
        // [SCENARIO] Exercise Page for Accountant Portal Activities Cues.
        Initialize();

        // [GIVEN] Cue data available.
        SetupData();

        // [WHEN] The Page is ran.
        AccountantPortalActivityCues.OpenView();

        // [THEN] Various fields are validated.
        VerifyActivitiesCues(AccountantPortalActivityCues, ActivitiesCue.FieldName("Ongoing Sales Invoices"), '                             2', MasterStyle::None);
        VerifyActivitiesCues(AccountantPortalActivityCues, ActivitiesCue.FieldName("Ongoing Purchase Invoices"), '                             1', MasterStyle::None);
        VerifyActivitiesCues(AccountantPortalActivityCues, ActivitiesCue.FieldName("Sales This Month"), '                         ' + AcctWebServicesMgt.FormatAmountString(0.0), MasterStyle::Ambiguous);
        VerifyActivitiesCues(AccountantPortalActivityCues, ActivitiesCue.FieldName("Top 10 Customer Sales YTD"), '                         ' + AcctWebServicesMgt.FormatAmountString(0.0), MasterStyle::Favorable);
        VerifyActivitiesCues(AccountantPortalActivityCues, ActivitiesCue.FieldName("Overdue Purch. Invoice Amount"), '                      ' + AcctWebServicesMgt.FormatAmountString(-123.45), MasterStyle::Favorable);
        VerifyActivitiesCues(AccountantPortalActivityCues, ActivitiesCue.FieldName("Overdue Sales Invoice Amount"), '                       ' + AcctWebServicesMgt.FormatAmountString(654.32), MasterStyle::None);
        VerifyActivitiesCues(AccountantPortalActivityCues, '                           ' + ActivitiesCue.FieldName("Average Collection Days"), '0.0', MasterStyle::Favorable);
        VerifyActivitiesCues(AccountantPortalActivityCues, ActivitiesCue.FieldName("Ongoing Sales Quotes"), '                             1', MasterStyle::None);
        VerifyActivitiesCues(AccountantPortalActivityCues, ActivitiesCue.FieldName("Sales Inv. - Pending Doc.Exch."), '                             1', MasterStyle::None);
        VerifyActivitiesCues(AccountantPortalActivityCues, ActivitiesCue.FieldName("Sales CrM. - Pending Doc.Exch."), '                             1', MasterStyle::None);
        VerifyActivitiesCues(AccountantPortalActivityCues, ActivitiesCue.FieldName("My Incoming Documents"), '                             6', MasterStyle::None);
        VerifyActivitiesCues(AccountantPortalActivityCues, ActivitiesCue.FieldName("Non-Applied Payments"), '                             2', MasterStyle::None);
        VerifyActivitiesCues(AccountantPortalActivityCues, ActivitiesCue.FieldName("Purch. Invoices Due Next Week"), '                             6', MasterStyle::None);
        VerifyActivitiesCues(AccountantPortalActivityCues, ActivitiesCue.FieldName("Sales Invoices Due Next Week"), '                             2', MasterStyle::None);
        VerifyActivitiesCues(AccountantPortalActivityCues, ActivitiesCue.FieldName("Ongoing Sales Orders"), '                            42', MasterStyle::None);
        VerifyActivitiesCues(AccountantPortalActivityCues, ActivitiesCue.FieldName("Inc. Doc. Awaiting Verfication"), '                             1', MasterStyle::None);
        VerifyActivitiesCues(AccountantPortalActivityCues, ActivitiesCue.FieldName("Purchase Orders"), '                            21', MasterStyle::None);

        AccountantPortalActivityCues.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetAmountFormatStandard()
    var
        ActivitiesCue: Record "Activities Cue";
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 281231] GetAmountFormat returns correct format depending on Local Currency settings in General Ledger Setup
        Initialize();

        // [GIVEN] Local Currency not set in General Ledger Setup
        GeneralLedgerSetup."LCY Code" := '';
        GeneralLedgerSetup.Validate("Local Currency Symbol", '');
        GeneralLedgerSetup.Modify(true);

        // [WHEN] Get Amount Format from Activities Cue
        // [THEN] Standard Format returned
        Assert.AreEqual(
          '<Precision,0:0><Standard Format,0>',
          ActivitiesCue.GetAmountFormat(),
          'Standard Format not displaying correctly.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetAmountFormatModified()
    var
        ActivitiesCue: Record "Activities Cue";
        GeneralLedgerSetup: Record "General Ledger Setup";
        LCYSymbol: Text[10];
    begin
        // [FEATURE] [UT]
        // [SCENARIO 281231] GetAmountFormat returns correct format depending on Local Currency settings in General Ledger Setup
        Initialize();

        // [GIVEN] Local Currency Symbol set in General Ledger Setup
        LCYSymbol := CopyStr(LibraryRandom.RandText(MaxStrLen(LCYSymbol)), 1, MaxStrLen(LCYSymbol));
        GeneralLedgerSetup.Validate("Local Currency Symbol", LCYSymbol);
        GeneralLedgerSetup.Modify(true);

        // [WHEN] Get Amount Format from Activities Cue
        // [THEN] Modified Local Currency Format returned
        Assert.AreEqual(
          LCYSymbol + '<Precision,0:0><Standard Format,0>',
          ActivitiesCue.GetAmountFormat(),
          'Modified local currency not displaying correctly.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFinanceCuesRequestToApprove()
    var
        ApprovalEntry: Record "Approval Entry";
    begin
        // [SCENARIO 470975] “Request Sent for Approval” and “Request to Approve” fields do not get updated as expected in the Company Hub.
        Initialize();

        // [GIVEN] Delete All Approval Entry
        ApprovalEntry.DeleteAll();

        // [GIVEN] Create three approval entry 
        CreateApprovalEntry(17, UserId, "Approval Status"::Open);
        CreateApprovalEntryForRequestSentForApprove(18, 'ABC', "Approval Status"::Open);
        CreateApprovalEntryForRequestSentForApprove(19, 'ABC', "Approval Status"::Open);

        // [WHEN] The Page is ran.
        AccountantPortalFinanceCues.OpenView();

        // [VERIFY] Verify Request to Approve and Request  Sent for Approval has same count 
        Assert.AreEqual('                             1', Format(AccountantPortalFinanceCues.RequestsToApproveAmount.Value), RequestsToApproveErr);
        Assert.AreEqual('                             2', Format(AccountantPortalFinanceCues.RequestsSentForApprovalAmount.Value), RequestsSentForApprovalErr);

        // [THEN] Close the page
        AccountantPortalFinanceCues.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestActivitiesCuesRequestToApprove()
    begin
        // [SCENARIO 470975] “Request Sent for Approval” and “Request to Approve” fields do not get updated as expected in the Company Hub.
        Initialize();

        // [GIVEN] Delete All Approval Entry
        ApprovalEntry.DeleteAll();

        // [GIVEN] Create one approval entry 
        CreateApprovalEntry(21, UserId, "Approval Status"::Open);

        // [WHEN] The Page is ran.
        AccountantPortalActivityCues.OpenView();

        // [THEN] Request to Approve  field are validated.
        Assert.AreEqual('                             1', Format(AccountantPortalActivityCues.RequeststoApproveAmount.Value), RequestsToApproveErr);

        // [THEN] Close the page
        AccountantPortalActivityCues.Close();
    end;


    local procedure Initialize()
    begin
        LibrarySetupStorage.Restore();
        if isInitialized then
            exit;

        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        isInitialized := true;
    end;

    local procedure VerifyActivitiesCues(AccountantPortalActivityCues: TestPage "AccountantPortal Activity Cues"; FieldName: Text; Amount: Text; Style: enum "Cues And KPIs Style")
    begin
        case FieldName of
            'Ongoing Sales Invoices':
                begin
                    Assert.AreEqual(Amount, Format(AccountantPortalActivityCues.OngoingSalesInvoicesAmount),
                      'Expected amount Ongoing Sales Invoices');
                    Assert.AreEqual(Format(Style), Format(AccountantPortalActivityCues.OngoingSalesInvoicesStyle),
                      'Expected style Ongoing Sales Invoices');
                end;
            'Ongoing Purchase Invoices':
                begin
                    Assert.AreEqual(Amount, Format(AccountantPortalActivityCues.OngoingPurchaseInvoicesAmount),
                      'Expected amount Ongoing Purchase Invoices');
                    Assert.AreEqual(Format(Style), Format(AccountantPortalActivityCues.OngoingPurchaseInvoicesStyle),
                      'Expected style Ongoing Purchase Invoices');
                end;
            'Sales This Month':
                begin
                    Assert.AreEqual(Amount, Format(AccountantPortalActivityCues.SalesThisMonthAmount),
                      'Expected amount Sales This Month');
                    Assert.AreEqual(Format(Style), Format(AccountantPortalActivityCues.SalesThisMonthStyle),
                      'Expected style Sales This Month');
                end;
            'Top 10 Customer Sales YTD':
                begin
                    Assert.AreEqual(Amount, Format(AccountantPortalActivityCues.Top10CustomerSalesYTDAmount),
                      'Expected amount Top 10 Customer Sales YTD');
                    Assert.AreEqual(Format(Style), Format(AccountantPortalActivityCues.Top10CustomerSalesYTDStyle),
                      'Expected style Top 10 Customer Sales YTD');
                end;
            'Overdue Purch. Invoice Amount':
                begin
                    Assert.AreEqual(Amount, Format(AccountantPortalActivityCues.OverduePurchInvoiceAmount),
                      'Expected amount Overdue Purch. Invoice Amount');
                    Assert.AreEqual(Format(Style), Format(AccountantPortalActivityCues.OverduePurchInvoiceStyle),
                      'Expected style Overdue Purch. Invoice Amount');
                end;
            'Overdue Sales Invoice Amount':
                begin
                    Assert.AreEqual(Amount, Format(AccountantPortalActivityCues.OverdueSalesInvoiceAmount),
                      'Expected amount Overdue Sales Invoice Amount');
                    Assert.AreEqual(Format(Style), Format(AccountantPortalActivityCues.OverdueSalesInvoiceStyle),
                      'Expected style Overdue Sales Invoice Amount');
                end;
            'Average Collection Days':
                begin
                    Assert.AreEqual(Amount, Format(AccountantPortalActivityCues.AverageCollectionDaysAmount),
                      'Expected amount Average Collection Days');
                    Assert.AreEqual(Format(Style), Format(AccountantPortalActivityCues.AverageCollectionDaysStyle),
                      'Expected style Average Collection Days');
                end;
            'Ongoing Sales Quotes':
                begin
                    Assert.AreEqual(Amount, Format(AccountantPortalActivityCues.OngoingSalesQuotesAmount),
                      'Expected amount Ongoing Sales Quotes');
                    Assert.AreEqual(Format(Style), Format(AccountantPortalActivityCues.OngoingSalesQuotesStyle),
                      'Expected style Ongoing Sales Quotes');
                end;
            'Requests to Approve':
                begin
                    Assert.AreEqual(Amount, Format(AccountantPortalActivityCues.RequeststoApproveAmount),
                      'Expected amount Requests to Approve');
                    Assert.AreEqual(Format(Style), Format(AccountantPortalActivityCues.RequeststoApproveStyle),
                      'Expected style Requests to Approve');
                end;
            'Sales Invoices - Pending Document Exchange':
                begin
                    Assert.AreEqual(Amount, Format(AccountantPortalActivityCues.SalesInvPendDocExchangeAmount),
                      'Expected amount Sales Invoices - Pending Document Exchange');
                    Assert.AreEqual(Format(Style), Format(AccountantPortalActivityCues.SalesInvPendDocExchangeStyle),
                      'Expected style Sales Invoices - Pending Document Exchange');
                end;
            'Sales Credit Memos - Pending Document Exchange':
                begin
                    Assert.AreEqual(Amount, Format(AccountantPortalActivityCues.SalesCrMPendDocExchangeAmount),
                      'Expected amount Sales Credit Memos - Pending Document Exchange');
                    Assert.AreEqual(Format(Style), Format(AccountantPortalActivityCues.SalesCrMPendDocExchangeStyle),
                      'Expected style Sales Credit Memos - Pending Document Exchange');
                end;
            'My Incoming Documents':
                begin
                    Assert.AreEqual(Amount, Format(AccountantPortalActivityCues.MyIncomingDocumentsAmount),
                      'Expected amount My Incoming Documents');
                    Assert.AreEqual(Format(Style), Format(AccountantPortalActivityCues.MyIncomingDocumentsStyle),
                      'Expected style My Incoming Documents');
                end;
            'Non-Applied Payments':
                begin
                    Assert.AreEqual(Amount, Format(AccountantPortalActivityCues.NonAppliedPaymentsAmount),
                      'Expected amount Non-Applied Payments');
                    Assert.AreEqual(Format(Style), Format(AccountantPortalActivityCues.NonAppliedPaymentsStyle),
                      'Expected style Non-Applied Payments');
                end;
            'Purch. Invoices Due Next Week':
                begin
                    Assert.AreEqual(Amount, Format(AccountantPortalActivityCues.PurchInvoicesDueNextWeekAmount),
                      'Expected amount Purch. Invoices Due Next Week');
                    Assert.AreEqual(Format(Style), Format(AccountantPortalActivityCues.PurchInvoicesDueNextWeekStyle),
                      'Expected style Purch. Invoices Due Next Week');
                end;
            'Ongoing Sales Orders':
                begin
                    Assert.AreEqual(Amount, Format(AccountantPortalActivityCues.OngoingSalesOrdersAmount),
                      'Expected amount Ongoing Sales Orders');
                    Assert.AreEqual(Format(Style), Format(AccountantPortalActivityCues.OngoingSalesOrdersStyle),
                      'Expected style Ongoing Sales Orders');
                end;
            'Inc. Doc. Awaiting Verfication':
                begin
                    Assert.AreEqual(Amount, Format(AccountantPortalActivityCues.IncDocAwaitingVerifAmount),
                      'Expected amount Inc. Doc. Awaiting Verfication');
                    Assert.AreEqual(Format(Style), Format(AccountantPortalActivityCues.IncDocAwaitingVerifStyle),
                      'Expected style Inc. Doc. Awaiting Verfication');
                end;
            'Purchase Orders':
                begin
                    Assert.AreEqual(Amount, Format(AccountantPortalActivityCues.PurchaseOrdersAmount),
                      'Expected amount Purchase Orders');
                    Assert.AreEqual(Format(Style), Format(AccountantPortalActivityCues.PurchaseOrdersStyle),
                      'Expected style Purchase Orders');
                end;
        end
    end;

    local procedure VerifyFinanceCues(AccountantPortalFinanceCues: TestPage "Accountant Portal Finance Cues"; FieldName: Text; Amount: Text; Style: Enum "Cues And KPIs Style")
    begin
        case FieldName of
            'Overdue Purchase Documents':
                begin
                    Assert.AreEqual(Amount, Format(AccountantPortalFinanceCues.OverduePurchaseDocumentsAmount),
                      'Expected amount Overdue Purchase Documents');
                    Assert.AreEqual(Format(Style), Format(AccountantPortalFinanceCues.OverduePurchaseDocumentsStyle),
                      'Expected style Overdue Purchase Documents');
                end;
            'Purchase Discounts Next Week':
                begin
                    Assert.AreEqual(Amount, Format(AccountantPortalFinanceCues.PurchaseDiscountsNextWeekAmount),
                      'Expected amount Purchase Discounts Next Week');
                    Assert.AreEqual(Format(Style), Format(AccountantPortalFinanceCues.PurchaseDiscountsNextWeekStyle),
                      'Expected style Purchase Discounts Next Week');
                end;
            'Purchase Documents Due Today':
                begin
                    Assert.AreEqual(Amount, Format(AccountantPortalFinanceCues.PurchaseDocumentsDueTodayAmount),
                      'Expected amount Purchase Documents Due Today');
                    Assert.AreEqual(Format(Style), Format(AccountantPortalFinanceCues.PurchaseDocumentsDueTodayStyle),
                      'Expected style Purchase Documents Due Today');
                end;
            'Overdue Sales Documents':
                begin
                    Assert.AreEqual(Amount, Format(AccountantPortalFinanceCues.OverdueSalesDocumentsAmount),
                      'Expected amount Overdue Sales Documents');
                    Assert.AreEqual(Format(Style), Format(AccountantPortalFinanceCues.OverdueSalesDocumentsStyle),
                      'Expected style Overdue Sales Documents');
                end;
            'Vendors - Payment on Hold':
                begin
                    Assert.AreEqual(Amount, Format(AccountantPortalFinanceCues.VendorsPaymentsOnHoldAmount),
                      'Expected amount Vendors - Payment on Hold');
                    Assert.AreEqual(Format(Style), Format(AccountantPortalFinanceCues.VendorsPaymentsOnHoldStyle),
                      'Expected style Vendors - Payment on Hold');
                end;
            'POs Pending Approval':
                begin
                    Assert.AreEqual(Amount, Format(AccountantPortalFinanceCues.POsPendingApprovalAmount),
                      'Expected amount POs Pending Approval');
                    Assert.AreEqual(Format(Style), Format(AccountantPortalFinanceCues.POsPendingApprovalStyle),
                      'Expected style POs Pending Approval');
                end;
            'SOs Pending Approval':
                begin
                    Assert.AreEqual(Amount, Format(AccountantPortalFinanceCues.SOsPendingApprovalAmount),
                      'Expected amount SOs Pending Approval');
                    Assert.AreEqual(Format(Style), Format(AccountantPortalFinanceCues.SOsPendingApprovalStyle),
                      'Expected style SOs Pending Approval');
                end;
            'Approved Sales Orders':
                begin
                    Assert.AreEqual(Amount, Format(AccountantPortalFinanceCues.ApprovedSalesOrdersAmount),
                      'Expected amount Approved Sales Orders');
                    Assert.AreEqual(Format(Style), Format(AccountantPortalFinanceCues.ApprovedSalesOrdersStyle),
                      'Expected style Approved Sales Orders');
                end;
            'Approved Purchase Orders':
                begin
                    Assert.AreEqual(Amount, Format(AccountantPortalFinanceCues.ApprovedPurchaseOrdersAmount),
                      'Expected amount Approved Purchase Orders');
                    Assert.AreEqual(Format(Style), Format(AccountantPortalFinanceCues.ApprovedPurchaseOrdersStyle),
                      'Expected style Approved Purchase Orders');
                end;
            'Purchase Return Orders':
                begin
                    Assert.AreEqual(Amount, Format(AccountantPortalFinanceCues.PurchaseReturnOrdersAmount),
                      'Expected amount Purchase Return Orders');
                    Assert.AreEqual(Format(Style), Format(AccountantPortalFinanceCues.PurchaseReturnOrdersStyle),
                      'Expected style Purchase Return Orders');
                end;
            'Sales Return Orders - All':
                begin
                    Assert.AreEqual(Amount, Format(AccountantPortalFinanceCues.SalesReturnOrdersAllAmount),
                      'Expected amount Sales Return Orders - All');
                    Assert.AreEqual(Format(Style), Format(AccountantPortalFinanceCues.SalesReturnOrdersAllStyle),
                      'Expected style Sales Return Orders - All');
                end;
            'Customers - Blocked':
                begin
                    Assert.AreEqual(Amount, Format(AccountantPortalFinanceCues.CustomersBlockedAmount),
                      'Expected amount Customers - Blocked');
                    Assert.AreEqual(Format(Style), Format(AccountantPortalFinanceCues.CustomersBlockedStyle),
                      'Expected style Customers - Blocked');
                end;
            'New Incoming Documents':
                begin
                    Assert.AreEqual(Amount, Format(AccountantPortalFinanceCues.NewIncomingDocumentsAmount),
                      'Expected amount New Incoming Documents');
                    Assert.AreEqual(Format(Style), Format(AccountantPortalFinanceCues.NewIncomingDocumentsStyle),
                      'Expected style New Incoming Documents');
                end;
            'Approved Incoming Documents':
                begin
                    Assert.AreEqual(Amount, Format(AccountantPortalFinanceCues.ApprovedIncomingDocumentsAmount),
                      'Expected amount Approved Incoming Documents');
                    Assert.AreEqual(Format(Style), Format(AccountantPortalFinanceCues.ApprovedIncomingDocumentsStyle),
                      'Expected style Approved Incoming Documents');
                end;
            'OCR Pending':
                begin
                    Assert.AreEqual(Amount, Format(AccountantPortalFinanceCues.OCRPendingAmount),
                      'Expected amount OCR Pending');
                    Assert.AreEqual(Format(Style), Format(AccountantPortalFinanceCues.OCRPendingStyle),
                      'Expected style OCR Pending');
                end;
            'OCR Completed':
                begin
                    Assert.AreEqual(Amount, Format(AccountantPortalFinanceCues.OCRCompletedAmount),
                      'Expected amount OCR Completed');
                    Assert.AreEqual(Format(Style), Format(AccountantPortalFinanceCues.OCRCompletedStyle),
                      'Expected style OCR Completed');
                end;
            'Requests to Approve':
                begin
                    Assert.AreEqual(Amount, Format(AccountantPortalFinanceCues.RequestsToApproveAmount),
                      'Expected amount Requests to Approve');
                    Assert.AreEqual(Format(Style), Format(AccountantPortalFinanceCues.RequestsToApproveStyle),
                      'Expected style Requests to Approve');
                end;
            'Requests Sent for Approval':
                begin
                    Assert.AreEqual(Amount, Format(AccountantPortalFinanceCues.RequestsSentForApprovalAmount),
                      'Expected amount Requests Sent for Approval');
                    Assert.AreEqual(Format(Style), Format(AccountantPortalFinanceCues.RequestsSentForApprovalStyle),
                      'Expected style Requests Sent for Approval');
                end;
            'Cash Accounts Balance':
                begin
                    Assert.AreEqual(Amount, Format(AccountantPortalFinanceCues.CashAccountsBalanceAmount),
                      'Expected amount Cash Accounts Balance');
                    Assert.AreEqual(Format(Style), Format(AccountantPortalFinanceCues.CashAccountsBalanceStyle),
                      'Expected style Cash Accounts Balance');
                end;
        end
    end;

    [Normal]
    local procedure CreateBankAccountReconciliation(StatementType: Enum "Bank Acc. Rec. Stmt. Type"; BankAccountNo: Code[20]; StatementNo: Code[20])
    begin
        BankAccReconciliation.Init();
        BankAccReconciliation."Statement Type" := StatementType;
        BankAccReconciliation."Bank Account No." := BankAccountNo;
        BankAccReconciliation."Statement No." := StatementNo;
        BankAccReconciliation.Insert();
    end;

    [Normal]
    local procedure CreateVendorLedgerEntry(EntryNumber: Integer; DocumentType: Enum "Gen. Journal Document Type"; DueDate: Date; Open: Boolean)
    begin
        VendorLedgerEntry.Init();
        VendorLedgerEntry."Entry No." := EntryNumber;
        VendorLedgerEntry."Document Type" := DocumentType;
        VendorLedgerEntry."Due Date" := DueDate;
        VendorLedgerEntry."Pmt. Discount Date" := DueDate;
        VendorLedgerEntry.Open := Open;
        VendorLedgerEntry."Posting Date" := DueDate;
        VendorLedgerEntry.Insert();
    end;

    [Normal]
    local procedure CreateCustomerLedgerEntry(EntryNo: Integer; DocumentType: Enum "Gen. Journal Document Type"; DueDate: Date; Open: Boolean)
    begin
        CustLedgerEntry.Init();
        CustLedgerEntry."Entry No." := EntryNo;
        CustLedgerEntry."Document Type" := DocumentType;
        CustLedgerEntry."Due Date" := DueDate;
        CustLedgerEntry.Open := Open;
        CustLedgerEntry.Insert();
    end;

    [Normal]
    local procedure CreateSalesHeader(DocumentType: Enum "Sales Document Type"; No: Text[20])
    begin
        SalesHeader.SetRange("Document Type", DocumentType);
        SalesHeader.SetRange("No.", No);
        if not SalesHeader.FindFirst() then begin
            SalesHeader.Init();
            SalesHeader."Document Type" := DocumentType;
            SalesHeader."No." := No;
            SalesHeader.Insert();
        end;
    end;

    [Normal]
    local procedure CreatePurchaseHeader(DocumentType: Enum "Purchase Document Type"; No: Text[20])
    begin
        PurchaseHeader.SetRange("Document Type", DocumentType);
        PurchaseHeader.SetRange("No.", No);
        if not PurchaseHeader.FindFirst() then begin
            PurchaseHeader.Init();
            PurchaseHeader."Document Type" := DocumentType;
            PurchaseHeader."No." := No;
            PurchaseHeader.Insert();
        end;
    end;

    [Normal]
    local procedure CreateSalesInvoiceHeader(No: Text[20]; DocExchangeStatus: Enum "Sales Document Exchange Status")
    begin
        SalesInvoiceHeader.Init();
        SalesInvoiceHeader."No." := No;
        SalesInvoiceHeader."Document Exchange Status" := DocExchangeStatus;
        SalesInvoiceHeader.Insert();
    end;

    [Normal]
    local procedure CreateIncomingDocument(EntryNo: Integer; Processed: Boolean; OCRStatus: Integer)
    begin
        IncomingDocument.Init();
        IncomingDocument."Entry No." := EntryNo;
        IncomingDocument.Processed := Processed;
        IncomingDocument."OCR Status" := OCRStatus;
        IncomingDocument.Insert();
    end;

    [Normal]
    local procedure CreateApprovalEntry(EntryNo: Integer; ApproverID: Text[50]; Status: Enum "Approval Status")
    begin
        ApprovalEntry.Init();
        ApprovalEntry."Entry No." := EntryNo;
        ApprovalEntry."Approver ID" := ApproverID;
        ApprovalEntry.Status := Status;
        ApprovalEntry.Insert();
    end;

    [Normal]
    local procedure CreateSalesCrMemoHeader(No: Text[20]; DocExchangeStatus: Enum "Sales Document Exchange Status")
    begin
        SalesCrMemoHeader.Init();
        SalesCrMemoHeader."No." := No;
        SalesCrMemoHeader."Document Exchange Status" := DocExchangeStatus;
        SalesCrMemoHeader.Insert();
    end;

    [Normal]
    local procedure CreateVendor(No: Text[20]; Blocked: Enum "Vendor Blocked")
    begin
        Vendor.SetRange("No.", No);
        if not Vendor.FindFirst() then begin
            Vendor.Init();
            Vendor."No." := No;
            Vendor.Blocked := Blocked;
            Vendor.Insert();
        end;
    end;

    [Normal]
    local procedure CreateDetailedVendorLedgEntry(VendorEntryNo: Integer; PostingDate: Date; AmountLCY: Decimal; DocumentType: Enum "Gen. Journal Document Type")
    begin
        DetailedVendorLedgEntry.Init();
        DetailedVendorLedgEntry."Vendor Ledger Entry No." := VendorEntryNo;
        DetailedVendorLedgEntry."Posting Date" := PostingDate;
        DetailedVendorLedgEntry."Amount (LCY)" := AmountLCY;
        DetailedVendorLedgEntry."Document Type" := DocumentType;
        DetailedVendorLedgEntry."Initial Document Type" := DocumentType;
        DetailedVendorLedgEntry."Initial Entry Due Date" := PostingDate;
        DetailedVendorLedgEntry.Insert();
    end;

    [Normal]
    local procedure CreateDetailedCustLedgEntry(CustEntryNo: Integer; PostingDate: Date; AmountLCY: Decimal; DocumentType: Enum "Gen. Journal Document Type")
    begin
        DetailedCustLedgEntry.Init();
        DetailedCustLedgEntry."Cust. Ledger Entry No." := CustEntryNo;
        DetailedCustLedgEntry."Posting Date" := PostingDate;
        DetailedCustLedgEntry."Amount (LCY)" := AmountLCY;
        DetailedCustLedgEntry."Document Type" := DocumentType;
        DetailedCustLedgEntry."Initial Document Type" := DocumentType;
        DetailedCustLedgEntry."Initial Entry Due Date" := PostingDate;
        DetailedCustLedgEntry.Insert();
    end;

    [Normal]
    local procedure SetupData()
    begin
        BankAccReconciliation.DeleteAll();
        VendorLedgerEntry.DeleteAll();
        CustLedgerEntry.DeleteAll();
        // SalesHeader.DeleteAll();
        // PurchaseHeader.DeleteAll();
        SalesInvoiceHeader.DeleteAll();
        IncomingDocument.DeleteAll();
        ApprovalEntry.DeleteAll();
        SalesCrMemoHeader.DeleteAll();
        // Vendor.DeleteAll();
        DetailedVendorLedgEntry.DeleteAll();
        DetailedCustLedgEntry.DeleteAll();

        // Non Applied Documents (Unprocessed Payments)
        CreateBankAccountReconciliation("Bank Acc. Rec. Stmt. Type"::"Payment Application", 'GIRO', '1234');
        CreateBankAccountReconciliation("Bank Acc. Rec. Stmt. Type"::"Bank Reconciliation", 'WWB-USD', '9876');
        CreateBankAccountReconciliation("Bank Acc. Rec. Stmt. Type"::"Payment Application", 'GIRO', '4567');

        // Overdue Purchase Documents & Overdue Purchase Invoice Amount
        // Purchase Discounts Next Week
        // Purchase Invoices Due Next Week
        // Purchase Documents Due Today
        CreateVendorLedgerEntry(12, "Gen. Journal Document Type"::Invoice, CalcDate('<-WD2>', Today), true);
        CreateVendorLedgerEntry(23, "Gen. Journal Document Type"::"Credit Memo", CalcDate('<-10D>', Today), true);
        CreateVendorLedgerEntry(34, "Gen. Journal Document Type"::Invoice, Today, false);
        CreateVendorLedgerEntry(45, "Gen. Journal Document Type"::"Credit Memo", CalcDate('<+20D>', Today), true);
        CreateVendorLedgerEntry(16, "Gen. Journal Document Type"::Invoice, CalcDate('<+7D>', Today), true);
        CreateVendorLedgerEntry(27, "Gen. Journal Document Type"::"Credit Memo", CalcDate('<+7D>', Today), true);
        CreateVendorLedgerEntry(38, "Gen. Journal Document Type"::Invoice, Today, false);
        CreateVendorLedgerEntry(49, "Gen. Journal Document Type"::"Credit Memo", CalcDate('<+14D>', Today), true);
        CreateVendorLedgerEntry(26, "Gen. Journal Document Type"::Invoice, CalcDate('<+7D>', Today), true);
        CreateVendorLedgerEntry(37, "Gen. Journal Document Type"::"Credit Memo", CalcDate('<+7D>', Today), true);
        CreateVendorLedgerEntry(48, "Gen. Journal Document Type"::Invoice, Today, false);
        CreateVendorLedgerEntry(59, "Gen. Journal Document Type"::"Credit Memo", CalcDate('<+14D>', Today), true);
        CreateVendorLedgerEntry(66, "Gen. Journal Document Type"::Invoice, CalcDate('<+7D>', Today), true);
        CreateVendorLedgerEntry(77, "Gen. Journal Document Type"::"Credit Memo", CalcDate('<+7D>', Today), true);
        CreateVendorLedgerEntry(88, "Gen. Journal Document Type"::Invoice, Today, false);
        CreateVendorLedgerEntry(99, "Gen. Journal Document Type"::"Credit Memo", CalcDate('<+14D>', Today), true);
        CreateVendorLedgerEntry(101, "Gen. Journal Document Type"::Invoice, CalcDate('<-4D>', Today), true);
        CreateDetailedVendorLedgEntry(101, CalcDate('<-4D>', Today), 123.45, "Gen. Journal Document Type"::Invoice);

        // Overdue Sales Documents & Overdue Sales Invoice Amount
        CreateCustomerLedgerEntry(212, "Gen. Journal Document Type"::Invoice, CalcDate('<-WD2>', Today), true);
        CreateCustomerLedgerEntry(323, "Gen. Journal Document Type"::"Credit Memo", CalcDate('<-10D>', Today), true);
        CreateCustomerLedgerEntry(434, "Gen. Journal Document Type"::Invoice, Today, false);
        CreateCustomerLedgerEntry(545, "Gen. Journal Document Type"::"Credit Memo", CalcDate('<+20D>', Today), true);
        CreateCustomerLedgerEntry(101, "Gen. Journal Document Type"::Invoice, CalcDate('<-4D>', Today), true);
        CreateDetailedCustLedgEntry(101, CalcDate('<-4D>', Today), 654.32, "Gen. Journal Document Type"::Invoice);

        // Vendors - Payments On Hold
        CreateVendor('11', "Vendor Blocked"::" ");
        CreateVendor('22', "Vendor Blocked"::Payment);
        CreateVendor('33', "Vendor Blocked"::All);
        CreateVendor('44', "Vendor Blocked"::Payment);

        // Ongoing Sales Invoices & Ongoing Sales Quotes & Sales Return Orders -All
        CreateSalesHeader("Sales Document Type"::Invoice, '12');
        CreateSalesHeader("Sales Document Type"::Quote, '14');
        CreateSalesHeader("Sales Document Type"::"Return Order", '16');
        CreateSalesHeader("Sales Document Type"::"Return Order", '18');

        // Ongoing Purchase Invoices
        CreatePurchaseHeader("Purchase Document Type"::Invoice, '13');

        // Sales Invoices - Pending Doc Exchange
        CreateSalesInvoiceHeader('14', "Sales Document Exchange Status"::"Delivery Failed");

        // My Incoming Documents & OCR Complete & OCR Pending
        // Inc. Doc Awaiting Verification & New Incoming Docs
        CreateIncomingDocument(15, false, 0);
        CreateIncomingDocument(17, false, 4);
        CreateIncomingDocument(19, false, 4);
        CreateIncomingDocument(21, false, 1);
        CreateIncomingDocument(23, false, 2);
        CreateIncomingDocument(25, false, 5);

        // Requests to Approve
        CreateApprovalEntry(16, 'BOB', "Approval Status"::" ");

        // Sales Cr. Memo - Pending Doc Exch
        CreateSalesCrMemoHeader('17', "Sales Document Exchange Status"::"Delivery Failed");
    end;

    [Normal]
    local procedure CreateApprovalEntryForRequestSentForApprove(EntryNo: Integer; ApproverID: Text[50]; Status: Enum "Approval Status")
    begin
        ApprovalEntry.Init();
        ApprovalEntry."Entry No." := EntryNo;
        ApprovalEntry."Approver ID" := ApproverID;
        ApprovalEntry."Sender ID" := UserId;
        ApprovalEntry.Status := Status;
        ApprovalEntry.Insert();
    end;
}

