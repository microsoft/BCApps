codeunit 144002 "UT REP Purchase Process Vend"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Purchase] [Reports]
    end;

    var
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryRandom: Codeunit "Library - Random";
        RemainingAmountToPrintCap: Label 'RemainAmountToPrint';
        SubTitleCap: Label 'SubTitle';
        TopTotalTextCap: Label 'Total_____TopTotalText';
        TopTotalCap: Label 'V100_0____Top__';
        Assert: Codeunit Assert;
        AmountToPrintCap: Label 'AmountToPrint';
        FilterString2Cap: Label 'FilterString2';
        FilterStringCap: Label 'FilterString';
        ItemDescriptionCap: Label 'Item_Description';
        VendorBalanceCap: Label 'VendBalance';
        VendorNameCap: Label 'Vendor_Name';
        DocumentNoCap: Label 'DocNo';
        LibraryApplicationArea: Codeunit "Library - Application Area";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        IsInitialized: Boolean;

    [Test]
    [HandlerFunctions('OpenVendorEntriesEndingDateRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnOpenPageOpenVendorEntries()
    begin
        // Purpose of the test is to validate OnOpenPage Trigger of Report ID - 10093  Open Vendor Entries.
        // Setup.
        Initialize();

        // Exercise.
        LibraryLowerPermissions.SetPurchDocsCreate();
        REPORT.Run(REPORT::"Open Vendor Entries");  // Opens OpenVendorEntriesEndingDateRequestPageHandler.

        // Verify: Verify default value of Ending Date is WORKDATE on OpenVendorEntriesEndingDateRequestPageHandler.
    end;

    [Test]
    [HandlerFunctions('OpenVendorEntriesRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportOpenVendorEntries()
    var
        Vendor: Record Vendor;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // Purpose of the test is to validate OnPreReport Trigger of Report ID - 10093  Open Vendor Entries.

        // Setup: Create Vendor and Vendor Ledger Entry without Currency.
        Initialize();
        CreateVendorLedgerEntry(VendorLedgerEntry, Vendor, '', '', WorkDate(), Vendor.Blocked::" ");  // Due Date - WORKDATE.

        // Exercise.
        LibraryLowerPermissions.SetPurchDocsCreate();
        REPORT.Run(REPORT::"Open Vendor Entries");  // Opens OpenVendorEntriesRequestPageHandler.

        // Verify: Verify Filters on Vendor and Vendor Ledger Entry and Subtitle is updated on Report Open Vendor Entries.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(FilterStringCap, StrSubstNo('%1: %2', Vendor.FieldCaption("No."), Vendor."No."));
        LibraryReportDataset.AssertElementWithValueExists(
          FilterString2Cap, StrSubstNo('%1: %2', VendorLedgerEntry.FieldCaption("Vendor No."), VendorLedgerEntry."Vendor No."));
        LibraryReportDataset.AssertElementWithValueExists('Subtitle', '(Open Entries Due as of' + ' ' + Format(WorkDate(), 0, 4) + ')');  // Used for Date format - January 01,0001.
    end;

    [Test]
    [HandlerFunctions('OpenVendorEntriesRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordVendBlockedPaymentOpenVendEntries()
    var
        Vendor: Record Vendor;
    begin
        // Purpose of the test is to validate Vendor - OnAfterGetRecord of Report ID - 10093 Open Vendor Entries.

        // Setup: Run Report Open Vendor Entries for Vendor Blocked of Payment Type to verify Payment Type is updated on Report Open Vendor Entries.
        Initialize();
        OnAfterGetRecordVendorBlockedOpenVendorEntries(Vendor.Blocked::Payment);
    end;

    [Test]
    [HandlerFunctions('OpenVendorEntriesRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordVendorBlockedAllOpenVendorEntries()
    var
        Vendor: Record Vendor;
    begin
        // Purpose of the test is to validate Vendor - OnAfterGetRecord of Report ID - 10093 Open Vendor Entries.

        // Setup: Run Report Open Vendor Entries for Vendor Blocked of All Type  to verify All Type is updated on Report Open Vendor Entries.
        Initialize();
        OnAfterGetRecordVendorBlockedOpenVendorEntries(Vendor.Blocked::All);
    end;

    local procedure OnAfterGetRecordVendorBlockedOpenVendorEntries(Blocked: Enum "Vendor Blocked")
    var
        Vendor: Record Vendor;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // Create Vendor for different Blocked options and create Vendor Ledger Entry.
        CreateVendorLedgerEntry(VendorLedgerEntry, Vendor, '', '', WorkDate(), Blocked);  // Due Date - WORKDATE.

        // Exercise.
        LibraryLowerPermissions.SetPurchDocsCreate();
        REPORT.Run(REPORT::"Open Vendor Entries");  // Opens OpenVendorEntriesRequestPageHandler.

        // Verify: Verify Blocked of different type is updated on Report Open Vendor Entries.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(
          'VendorBlockedText', StrSubstNo('*** Vendor is Blocked for %1 processing ***', Vendor.Blocked));
    end;

    [Test]
    [HandlerFunctions('OpenVendorEntriesPrintAmountsRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordEntryRemAmtOpenVendorEntries()
    var
        Vendor: Record Vendor;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        CurrencyCode: Code[10];
    begin
        // Purpose of the test is to validate VendorLedgerEntry - OnAfterGetRecord of Report ID - 10093 Open Vendor Entries.

        // Setup: Run Report Open Vendor Entries to verify RemainingAmountPrint is updated with Vendor Ledger Entry Remaining Amount.
        Initialize();
        CurrencyCode := CreateCurrency();
        CreateVendorLedgerEntry(VendorLedgerEntry, Vendor, CurrencyCode, CurrencyCode, WorkDate(), Vendor.Blocked::" ");  // Due Date - WORKDATE.
        CreateDetailedVendorLedgerEntry(VendorLedgerEntry."Entry No.", Vendor."No.");

        // Exercise.
        LibraryLowerPermissions.SetPurchDocsCreate();
        REPORT.Run(REPORT::"Open Vendor Entries");  // Opens OpenVendorEntriesPrintAmountsRequestPageHandler.

        // Verify: Verify RemainingAmountPrint on Report Open Vendor Entries.
        VendorLedgerEntry.CalcFields("Remaining Amount");
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(RemainingAmountToPrintCap, -VendorLedgerEntry."Remaining Amount")
    end;

    [Test]
    [HandlerFunctions('OpenVendorEntriesPrintAmountsRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordEntryRemAmtLCYOpenVendorEntries()
    var
        Vendor: Record Vendor;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // Purpose of the test is to validate VendorLedgerEntry - OnAfterGetRecord of Report ID - 10093 Open Vendor Entries.

        // Setup: Run Report Open Vendor Entries to verify RemainingAmountPrint is updated with Vendor Ledger Entry Remaining Amount(LCY).
        Initialize();
        CreateVendorLedgerEntry(
          VendorLedgerEntry, Vendor, '', '', CalcDate('<' + Format(-LibraryRandom.RandInt(5)) + 'D>', WorkDate()), Vendor.Blocked::" ");  // Due Date Less than End Date of Report Open Vendor Entries.
        CreateDetailedVendorLedgerEntry(VendorLedgerEntry."Entry No.", Vendor."No.");

        // Exercise.
        LibraryLowerPermissions.SetPurchDocsCreate();
        REPORT.Run(REPORT::"Open Vendor Entries");  // Opens OpenVendorEntriesPrintAmountsRequestPageHandler.

        // Verify: Verify RemainingAmountPrint and OverDueDays on Report Open Vendor Entries.
        VendorLedgerEntry.CalcFields("Remaining Amt. (LCY)");
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('OverDueDays', WorkDate() - VendorLedgerEntry."Due Date");
        LibraryReportDataset.AssertElementWithValueExists(RemainingAmountToPrintCap, VendorLedgerEntry."Remaining Amt. (LCY)");
    end;

    [Test]
    [HandlerFunctions('OpenVendorEntriesPrintAmountsRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordEntryRemAmtPrintOpenVendorEntries()
    var
        Vendor: Record Vendor;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        CurrencyExchangeRate2: Record "Currency Exchange Rate";
        Currency: Record Currency;
    begin
        // Purpose of the test is to validate VendorLedgerEntry - OnAfterGetRecord of Report ID - 10093 Open Vendor Entries.
        // Setup.
        Initialize();
        CurrencyExchangeRate.FindFirst();
        CurrencyExchangeRate2.SetFilter("Currency Code", '<>%1', CurrencyExchangeRate."Currency Code");
        CurrencyExchangeRate2.FindFirst();
        CreateVendorLedgerEntry(
          VendorLedgerEntry, Vendor, CurrencyExchangeRate."Currency Code", CurrencyExchangeRate2."Currency Code", WorkDate(),
          Vendor.Blocked::" ");  // Due Date - WORKDATE;
        CreateDetailedVendorLedgerEntry(VendorLedgerEntry."Entry No.", Vendor."No.");

        // Exercise.
        LibraryLowerPermissions.SetPurchDocsCreate();
        REPORT.Run(REPORT::"Open Vendor Entries");  // Opens OpenVendorEntriesPrintAmountsRequestPageHandler.

        // Verify: Verify RemainingAmountPrint on Report Open Vendor Entries. Calclulation is on the basis of VendorLedgerEntry - OnAfterGetRecord of Report Open Vendor Entries.
        LibraryReportDataset.LoadDataSetFile();
        VendorLedgerEntry.CalcFields("Remaining Amount");
        LibraryReportDataset.AssertElementWithValueExists(
          RemainingAmountToPrintCap,
          -Round(
            CurrencyExchangeRate.ExchangeAmtFCYToFCY(
              WorkDate(), VendorLedgerEntry."Currency Code", Vendor."Currency Code", VendorLedgerEntry."Remaining Amount"),
            Currency."Amount Rounding Precision"));
    end;

    [Test]
    [HandlerFunctions('OpenVendorEntriesUseExternDocNoRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordEntryExternDocOpenVendEntries()
    var
        Vendor: Record Vendor;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // Purpose of the test is to validate VendorLedgerEntry - OnAfterGetRecord of Report ID - 10093 Open Vendor Entries.

        // Setup: Create Vendor and Vendor Ledger Entry without Currency.
        Initialize();
        CreateVendorLedgerEntry(VendorLedgerEntry, Vendor, '', '', WorkDate(), Vendor.Blocked::" ");  // Due Date - WORKDATE.
        CreateDetailedVendorLedgerEntry(VendorLedgerEntry."Entry No.", Vendor."No.");

        // Exercise.
        LibraryLowerPermissions.SetPurchDocsCreate();
        REPORT.Run(REPORT::"Open Vendor Entries");  // Opens OpenVendorEntriesUseExternalDocumentNoRequestPageHandler.

        // Verify: Verify External Document No of Vendor Ledger Entry is updated on Report Open Vendor Entries.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(DocumentNoCap, VendorLedgerEntry."External Document No.");
    end;

    [Test]
    [HandlerFunctions('TopVendorListRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportWithoutDateFilterTopVendorList()
    var
        Vendor: Record Vendor;
        TopType: Option "Balances ($)","Purchases ($)";
    begin
        // Purpose of the test is to validate OnPreReport trigger of the Report ID: 10102, Top __ Vendor List for SubTitle without DateFilter.
        // Setup.
        Initialize();
        CreateVendor(Vendor, '', Vendor.Blocked::" ");

        // Exercise.
        LibraryVariableStorage.Enqueue(Vendor."No.");  // Required inside TopVendorListRequestPageHandler.
        LibraryLowerPermissions.SetVendorView();
        RunTopVendorListReport(Vendor, TopType::"Balances ($)");

        // Verify: Verify the SubTitle after running Top __ Vendor List Report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(SubTitleCap, '(by Balance Due)');
    end;

    [Test]
    [HandlerFunctions('TopVendorListRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportWithDateFilterTopVendorList()
    var
        Vendor: Record Vendor;
        TopType: Option "Balances ($)","Purchases ($)";
    begin
        // Purpose of the test is to validate OnPreReport trigger of the Report ID: 10102, Top __ Vendor List for SubTitle with DateFilter.
        // Setup.
        Initialize();
        CreateVendor(Vendor, '', Vendor.Blocked::" ");

        // Exercise.
        LibraryVariableStorage.Enqueue(Vendor."No.");  // Required inside TopVendorListRequestPageHandler.
        Vendor.SetRange("Date Filter", WorkDate());
        LibraryLowerPermissions.SetVendorView();
        RunTopVendorListReport(Vendor, TopType::"Balances ($)");

        // Verify: Verify the SubTitle after running Top __ Vendor List Report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(SubTitleCap, '(by Balance Due as of' + ' ' + Format(WorkDate()) + ')');
    end;

    [Test]
    [HandlerFunctions('TopVendorListRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordTopTypeBalancesTotalVendorList()
    var
        Vendor: Record Vendor;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        TopType: Option "Balances ($)","Purchases ($)";
    begin
        // Purpose of the test is to validate Vendor - OnAfterGetRecord trigger of the Report ID: 10102, Top __ Vendor List for TopType of Balances.
        // Setup.
        Initialize();
        CreateVendorLedgerEntry(VendorLedgerEntry, Vendor, '', '', WorkDate(), Vendor.Blocked::" ");  // Due Date - WORKDATE.

        // Exercise.
        Vendor.SetRange("Date Filter", WorkDate());
        LibraryLowerPermissions.SetVendorView();
        RunTopVendorListReport(Vendor, TopType::"Balances ($)");

        // Verify: Verify the Top Total Text and Top Total after running Top __ Vendor List Report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(TopTotalTextCap, 'Total Amount Outstanding');
        LibraryReportDataset.AssertElementWithValueExists(TopTotalCap, 100);  // 100 for Top Total of TopType - Balances.
    end;

    [Test]
    [HandlerFunctions('TopVendorListRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordTopTypePurchasesTotalVendorList()
    var
        Vendor: Record Vendor;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        TopType: Option "Balances ($)","Purchases ($)";
    begin
        // Purpose of the test is to validate Vendor - OnAfterGetRecord trigger of the Report ID: 10102, Top __ Vendor List for TopType of Purchases.
        // Setup.
        Initialize();
        CreateVendorLedgerEntry(VendorLedgerEntry, Vendor, '', '', WorkDate(), Vendor.Blocked::" ");  // Due Date - WORKDATE.

        // Exercise.
        Vendor.SetRange("Date Filter", WorkDate());
        LibraryLowerPermissions.SetVendorView();
        RunTopVendorListReport(Vendor, TopType::"Purchases ($)");

        // Verify: Verify the Top Total Text and Top Total after running Top __ Vendor List Report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(TopTotalTextCap, 'Total Purchases');
        LibraryReportDataset.AssertElementWithValueExists(TopTotalCap, 0);  // Zero Top Total for TopType - Purchases.
    end;

    [Test]
    [HandlerFunctions('VendorAccountDetailRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordEntryAmountLCYVendorAccountDetail()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        Vendor: Record Vendor;
    begin
        // Purpose of the test is to validate Trigger OnAfterGetRecord - VendorLedgerEntry of Report ID - 10103 Vendor Account Detail for Vendor without Currency.

        // Setup: Run Report Vendor Account Detail to verify AmountToPrint is updated with Vendor Ledger Entry Amount(LCY).
        Initialize();
        CreateVendorLedgerEntry(VendorLedgerEntry, Vendor, '', '', WorkDate(), Vendor.Blocked::" ");  // Due Date - WORKDATE.
        CreateDetailedVendorLedgerEntry(VendorLedgerEntry."Entry No.", Vendor."No.");

        // Exercise.
        LibraryLowerPermissions.SetVendorView();
        REPORT.Run(REPORT::"Vendor Account Detail");  // Opens VendorAccountDetailRequestPageHandler.

        // Verify: Verify AmountToPrint and CreditTotal on Report Vendor Account Detail.
        VendorLedgerEntry.CalcFields("Amount (LCY)");
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(AmountToPrintCap, VendorLedgerEntry."Amount (LCY)");
        LibraryReportDataset.AssertElementWithValueExists('CreditTotal', -VendorLedgerEntry."Amount (LCY)");
        LibraryReportDataset.AssertElementWithValueExists(
          FilterString2Cap, StrSubstNo('%1: %2', VendorLedgerEntry.FieldCaption("Vendor No."), VendorLedgerEntry."Vendor No."));
        LibraryReportDataset.AssertElementWithValueExists(FilterStringCap, StrSubstNo('%1: %2', Vendor.FieldCaption("No."), Vendor."No."));
    end;

    [Test]
    [HandlerFunctions('VendorAccountDetailPrintAmountsRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordEntryAmountVendorAccountDetail()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        Vendor: Record Vendor;
        CurrencyCode: Code[10];
    begin
        // Purpose of the test is to validate Trigger OnAfterGetRecord - VendorLedgerEntry of Report ID - 10103 Vendor Account Detail for Vendor with Currency.

        // Setup: Run Report Vendor Account Detail to verify AmountToPrint is updated with Vendor Ledger Entry Amount.
        Initialize();
        CurrencyCode := CreateCurrency();
        CreateVendorLedgerEntry(VendorLedgerEntry, Vendor, CurrencyCode, CurrencyCode, WorkDate(), Vendor.Blocked::" ");  // Due Date - WORKDATE.
        CreateDetailedVendorLedgerEntry(VendorLedgerEntry."Entry No.", Vendor."No.");

        // Exercise.
        LibraryLowerPermissions.SetVendorView();
        REPORT.Run(REPORT::"Vendor Account Detail");  // Opens VendorAccountDetailPrintAmountsRequestPageHandler.

        // Verify: Verify AmountToPrint on Report Vendor Account Detail.
        VendorLedgerEntry.CalcFields(Amount);
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(AmountToPrintCap, VendorLedgerEntry.Amount);
    end;

    [Test]
    [HandlerFunctions('VendorAccountDetailPrintAmountsRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordEntryAmtToPrintVendorAccountDetail()
    var
        Vendor: Record Vendor;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        CurrencyExchangeRate2: Record "Currency Exchange Rate";
        Currency: Record Currency;
    begin
        // Purpose of the test is to validate Trigger OnAfterGetRecord - VendorLedgerEntry of Report ID - 10103 Vendor Account Detail for Vendor and Vendor Ledger Entry having different Currency.
        // Setup.
        Initialize();
        CurrencyExchangeRate.FindFirst();
        CurrencyExchangeRate2.SetFilter("Currency Code", '<>%1', CurrencyExchangeRate."Currency Code");
        CurrencyExchangeRate2.FindFirst();
        CreateVendorLedgerEntry(
          VendorLedgerEntry, Vendor, CurrencyExchangeRate."Currency Code", CurrencyExchangeRate2."Currency Code", WorkDate(),
          Vendor.Blocked::" ");  // Due Date - WORKDATE;
        CreateDetailedVendorLedgerEntry(VendorLedgerEntry."Entry No.", Vendor."No.");

        // Exercise.
        LibraryLowerPermissions.SetVendorView();
        REPORT.Run(REPORT::"Vendor Account Detail");  // Opens VendorAccountDetailPrintAmountsRequestPageHandler.

        // Verify: Verify AmountPrint on Report Vendor Account Detail. Calclulation is on the basis of VendorLedgerEntry - OnAfterGetRecord of Report Vendor Account Detail.
        LibraryReportDataset.LoadDataSetFile();
        VendorLedgerEntry.CalcFields(Amount);
        LibraryReportDataset.AssertElementWithValueExists(
          AmountToPrintCap,
          Round(
            CurrencyExchangeRate.ExchangeAmtFCYToFCY(
              WorkDate(), VendorLedgerEntry."Currency Code", Vendor."Currency Code", VendorLedgerEntry.Amount),
            Currency."Amount Rounding Precision"));
    end;

    [Test]
    [HandlerFunctions('VendorAccountDetailExternalDocRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordEntryExternDocVendorAccountDetail()
    var
        Vendor: Record Vendor;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // Purpose of the test is to validate OnAfterGetRecord - VendorLedgerEntry of Report ID - 10093 Open Vendor Entries for External Document No.

        // Setup: Create Vendor Ledger Entry without Currency.
        Initialize();
        CreateVendorLedgerEntry(VendorLedgerEntry, Vendor, '', '', WorkDate(), Vendor.Blocked::" ");  // Due Date - WORKDATE.
        CreateDetailedVendorLedgerEntry(VendorLedgerEntry."Entry No.", Vendor."No.");

        // Exercise.
        LibraryLowerPermissions.SetVendorView();
        REPORT.Run(REPORT::"Vendor Account Detail");  // Opens VendorAccountDetailExternalDocRequestPageHandler.

        // Verify: Verify External Document No of Vendor Ledger Entry is updated on Report Vendor Account Detail.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(DocumentNoCap, VendorLedgerEntry."External Document No.");
    end;

    [Test]
    [HandlerFunctions('VendorAccountDetailAccWithBalOnlyRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportVendorAccountDetailError()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        Vendor: Record Vendor;
    begin
        // Purpose of the test is to validate OnPreReport of Report ID - 10103 Vendor Account Detail for Accounts with Balances.
        // Setup.
        Initialize();
        CreateVendorLedgerEntry(VendorLedgerEntry, Vendor, '', '', WorkDate(), Vendor.Blocked::" ");  // Due Date - WORKDATE.

        // Exercise.
        LibraryLowerPermissions.SetVendorView();
        asserterror REPORT.Run(REPORT::"Vendor Account Detail");  // Opens VendorAccountDetailAccWithBalOnlyRequestPageHandler.

        // Verify: Verify error Code, Actual error message: Do not select Accounts with Balances Only if you are also setting Vendor Ledger Entry Filters.
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    [HandlerFunctions('VendorCommentListRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportCommentLineWithVendorCommentList()
    var
        CommentLine: Record "Comment Line";
        Vendor: Record Vendor;
    begin
        // Purpose of the test is to validate OnPreReport Trigger Of Report ID - 10104 Vendor Comment List for Comment Line with Vendor.
        // Setup.
        Initialize();
        CreateVendor(Vendor, '', Vendor.Blocked::" ");
        UpdateVendorName(Vendor);
        CreateCommentLine(CommentLine, Vendor."No.");

        // Exercise.
        LibraryLowerPermissions.SetVendorView();
        REPORT.Run(REPORT::"Vendor Comment List");  // Opens VendorCommentListRequestPageHandler.

        // Verify: Verify Filters and Vendor Name is updated on Report Vendor Comment List.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(
          FilterStringCap, StrSubstNo('%1: %2', CommentLine.FieldCaption("No."), CommentLine."No."));
        LibraryReportDataset.AssertElementWithValueExists(VendorNameCap, Vendor.Name);
    end;

    [Test]
    [HandlerFunctions('VendorCommentListRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportCommentLineWithoutVendorCommentList()
    var
        CommentLine: Record "Comment Line";
    begin
        // Purpose of the test is to validate OnAfterGetRecord - CommentLine Trigger Of Report ID - 10104 Vendor Comment List for Comment Line without Vendor.
        // Setup.
        Initialize();
        CreateCommentLine(CommentLine, '');  // Comment Line without Vendor.

        // Exercise.
        LibraryLowerPermissions.SetVendorView();
        REPORT.Run(REPORT::"Vendor Comment List");  // Opens VendorCommentListRequestPageHandler.

        // Verify: Verify No Vendor is updated on Report Vendor Comment List.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(VendorNameCap, 'No Name');
    end;

    [Test]
    [HandlerFunctions('VendorListingRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreDataItemVendorBalanceLCYVendorListing()
    var
        Vendor: Record Vendor;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // Purpose of the test is to validate OnAfterGetRecord - Vendor Trigger of Report ID - 10106 Vendor - Listing for Vendor Balance and Vendor Filter.
        // Setup.
        Initialize();
        CreateVendorLedgerEntry(VendorLedgerEntry, Vendor, '', '', WorkDate(), Vendor.Blocked::" ");  // Due Date - WORKDATE.
        CreateDetailedVendorLedgerEntry(VendorLedgerEntry."Entry No.", Vendor."No.");

        // Exercise.
        LibraryLowerPermissions.SetVendorView();
        REPORT.Run(REPORT::"Vendor - Listing");  // Opens VendorListingRequestPageHandler.

        // Verify: Verify Filters and Vendor Balance is updated as Vendor Balance (LCY) on Report Vendor - Listing.
        Vendor.CalcFields("Balance (LCY)");
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(VendorBalanceCap, Vendor."Balance (LCY)");
        LibraryReportDataset.AssertElementWithValueExists('VendFilter', StrSubstNo('%1: %2', Vendor.FieldCaption("No."), Vendor."No."));
    end;

    [Test]
    [HandlerFunctions('VendorListingPrintAmountsRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreDataItemVendorBalanceVendorListing()
    var
        Vendor: Record Vendor;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        PaymentTerms: Record "Payment Terms";
    begin
        // Purpose of the test is to validate OnAfterGetRecord - Vendor Trigger of Report ID - 10106 Vendor - Listing for Vendor Balance and Payment terms.
        // Setup.
        Initialize();
        CreatePaymentTerms(PaymentTerms);
        CreateVendorLedgerEntry(VendorLedgerEntry, Vendor, '', '', WorkDate(), Vendor.Blocked::" ");  // Due Date - WORKDATE.
        Vendor."Payment Terms Code" := PaymentTerms.Code;
        Vendor.Modify();
        CreateDetailedVendorLedgerEntry(VendorLedgerEntry."Entry No.", Vendor."No.");

        // Exercise.
        LibraryLowerPermissions.SetVendorView();
        REPORT.Run(REPORT::"Vendor - Listing");  // Opens VendorListingPrintAmountsRequestPageHandler.

        // Verify: Verify Due Date Calculation of Payment Terms and Vendor Balance is updated on Report Vendor - Listing.
        Vendor.CalcFields(Balance);
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(VendorBalanceCap, Vendor.Balance);
        LibraryReportDataset.AssertElementWithValueExists(
          'PaymentTerms__Due_Date_Calculation_', Format(PaymentTerms."Due Date Calculation"));
    end;

    [Test]
    [HandlerFunctions('VendorItemStatisticsRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportVendorItemStatistics()
    var
        ValueEntry: Record "Value Entry";
        Vendor: Record Vendor;
        PurchInvHeader: Record "Purch. Inv. Header";
        Item: Record Item;
    begin
        // Purpose of the test is to validate OnAfterGetrecord - ValueEntry Trigger of Report ID - 10113  Vendor/Item Statistics for Filters and Item Description.
        // Setup.
        Initialize();
        CreateItem(Item);
        CreateVendor(Vendor, '', Vendor.Blocked::" ");
        CreateValueEntry(ValueEntry, Vendor."No.", Item."No.");
        CreatePurchaseInvoiceHeader(PurchInvHeader, ValueEntry."External Document No.", ValueEntry."Posting Date");

        // Exercise.
        LibraryLowerPermissions.SetPurchDocsCreate();
        REPORT.Run(REPORT::"Vendor/Item Statistics");  // Opens VendorItemStatisticsRequestPageHandler.

        // Verify: Verify Filters of Vendor and Value Entry, Total Days and Item Description is updated on report Vendor/Item Statistics. Calculation is on the basis of OnAfterGetrecord - ValueEntry Trigger of the report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(FilterStringCap, StrSubstNo('%1: %2', Vendor.FieldCaption("No."), Vendor."No."));
        LibraryReportDataset.AssertElementWithValueExists(
          'Value_Entry__TABLECAPTION__________FilterString2',
          StrSubstNo('%1: %2: %3', ValueEntry.TableCaption(), ValueEntry.FieldCaption("Source No."), ValueEntry."Source No."));
        LibraryReportDataset.AssertElementWithValueExists(
          'TotalDays', (ValueEntry."Posting Date" - PurchInvHeader."Order Date") * ValueEntry."Invoiced Quantity");
        LibraryReportDataset.AssertElementWithValueExists(ItemDescriptionCap, Item.Description);
    end;

    [Test]
    [HandlerFunctions('VendorItemStatisticsRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordItemDescOthersVendorItemStatistics()
    var
        ValueEntry: Record "Value Entry";
        Vendor: Record Vendor;
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        // Purpose of the test is to validate OnAfterGetrecord - ValueEntry Trigger of Report ID - 10113  Vendor/Item Statistics for Value Entry without Item.
        // Setup.
        Initialize();
        CreateVendor(Vendor, '', Vendor.Blocked::" ");
        CreateValueEntry(ValueEntry, Vendor."No.", '');  // Value Entry without Item.
        CreatePurchaseInvoiceHeader(PurchInvHeader, ValueEntry."External Document No.", ValueEntry."Posting Date");

        // Exercise.
        LibraryLowerPermissions.SetPurchDocsCreate();
        REPORT.Run(REPORT::"Vendor/Item Statistics");  // Opens VendorItemStatisticsRequestPageHandler.

        // Verify: Verify Item Description is updated as Others on Report Vendor/Item Statistics.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(ItemDescriptionCap, 'Others');
    end;

    [Test]
    [HandlerFunctions('VendorItemStatByPurchaserRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordValueEntryVendItemStatByPurchaser()
    var
        Item: Record Item;
    begin
        // Purpose of the test is to validate OnAfterGetrecord - ValueEntry Trigger of Report ID - 10114 Vendor Item Stat. by Purchaser for Value Entry with Item.

        // Setup: Run report Vendor Item Stat. by Purchaser to verify Item Description of Item is is updated on the Report.
        Initialize();
        CreateItem(Item);
        OnAfterGetRecordVendItemStatByPurchaser(Item."No.", Item.Description);
    end;

    [Test]
    [HandlerFunctions('VendorItemStatByPurchaserRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordDescOthersVendItemStatByPurchaser()
    begin
        // Purpose of the test is to validate OnAfterGetrecord - ValueEntry Trigger of Report ID - 10114 Vendor Item Stat. by Purchaser for Value Entry without Item.

        // Setup: Run report Vendor Item Stat. by Purchaser to verify Item Description is updated as Others if no Item is present on Value Entry.
        Initialize();
        OnAfterGetRecordVendItemStatByPurchaser('', 'Others');
    end;

    local procedure OnAfterGetRecordVendItemStatByPurchaser(ItemNo: Code[20]; ItemDescription: Text[100])
    var
        ValueEntry: Record "Value Entry";
        Vendor: Record Vendor;
        PurchInvHeader: Record "Purch. Inv. Header";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        TotalDays: Integer;
    begin
        // Create Vendor, Value Entry and Purchase Invoice Header.
        CreateVendor(Vendor, '', Vendor.Blocked::" ");
        Vendor."Purchaser Code" := CreateSalespersonPurchaser();
        Vendor.Modify();
        CreateValueEntry(ValueEntry, Vendor."No.", ItemNo);
        CreatePurchaseInvoiceHeader(PurchInvHeader, ValueEntry."External Document No.", ValueEntry."Posting Date");
        LibraryVariableStorage.Enqueue(Vendor."Purchaser Code");  // Required inside VendorItemStatByPurchaserRequestPageHandler.

        // Exercise:
        LibraryLowerPermissions.SetPurchDocsCreate();
        REPORT.Run(REPORT::"Vendor Item Stat. by Purchaser");  // Opens VendorItemStatByPurchaserRequestPageHandler.

        // Verify: Verify Filters, AvgDays and Item Description on Report Vendor Item Stat. by Purchaser. Calculation is on the basis of OnAfterGetrecord - ValueEntry of Report Vendor Item Stat. by Purchaser.
        LibraryReportDataset.LoadDataSetFile();
        TotalDays := (ValueEntry."Posting Date" - PurchInvHeader."Order Date") * ValueEntry."Invoiced Quantity";
        LibraryReportDataset.AssertElementWithValueExists(
          FilterStringCap, StrSubstNo('%1: %2', SalespersonPurchaser.FieldCaption(Code), Vendor."Purchaser Code"));
        LibraryReportDataset.AssertElementWithValueExists(FilterString2Cap, StrSubstNo('%1: %2', Vendor.FieldCaption("No."), Vendor."No."));
        LibraryReportDataset.AssertElementWithValueExists(
          'FilterString3', StrSubstNo('%1: %2', ValueEntry.FieldCaption("Source No."), ValueEntry."Source No."));
        LibraryReportDataset.AssertElementWithValueExists('AvgDays', TotalDays / ValueEntry."Invoiced Quantity");
        LibraryReportDataset.AssertElementWithValueExists(ItemDescriptionCap, ItemDescription);
    end;

    [Test]
    [HandlerFunctions('VendorLabelsRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordVendorLabels()
    var
        Vendor: Record Vendor;
    begin
        // Purpose of the test is to validate OnAfteGetRecord - Vendor Trigger of Report ID - 10105 Vendor Labels.
        // Setup.
        Initialize();
        CreateVendor(Vendor, '', Vendor.Blocked::" ");
        LibraryVariableStorage.Enqueue(Vendor."No.");  // Required inside VendorLabelsRequestPageHandler

        // Exercise.
        LibraryLowerPermissions.SetVendorView();
        REPORT.Run(REPORT::"Vendor Labels");  // Opens VendorLabelsRequestPageHandler

        // Verify: Verify Address and Address2 of Vendor on Report Vendor Labels.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('Addr_1__1_', Vendor.Address);
        LibraryReportDataset.AssertElementWithValueExists('Addr_1__2_', Vendor."Address 2");
    end;

    [Test]
    [HandlerFunctions('VendorLabelsNoOfPrintLinesOnLabelRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordNoOfPrintLinesOnLabelVendorLabels()
    var
        Vendor: Record Vendor;
        NoOfPrintLinesOnLabel: Integer;
    begin
        // Purpose of the test is to validate OnAfteGetRecord - Vendor Trigger of Report ID - 10105 Vendor Labels.
        // Setup.
        Initialize();
        CreateVendor(Vendor, '', Vendor.Blocked::" ");
        NoOfPrintLinesOnLabel := 10 + LibraryRandom.RandInt(10);  // Value more than 10 Required.
        LibraryVariableStorage.Enqueue(NoOfPrintLinesOnLabel);  // Required inside VendorLabelsRequestPageHandler
        LibraryVariableStorage.Enqueue(Vendor."No.");  // Required inside VendorLabelsRequestPageHandler

        // Exercise.
        LibraryLowerPermissions.SetVendorView();
        REPORT.Run(REPORT::"Vendor Labels");  // Opens VendorLabelsRequestPageHandler

        // Verify: Verify Number of Blanks Labels for Vendor on Report Vendor Labels.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('NumOfBlanks', NoOfPrintLinesOnLabel - 9);  // Calculation is on the basis of OnAfteGetRecord - Vendor of Report Vendor Labels.
    end;

    [Test]
    [HandlerFunctions('APVendorRegisterRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordVendorLedgerEntryAPVendorRegister()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        Vendor: Record Vendor;
    begin
        // Purpose of the test is to validate OnAfterGetRecord -  VendorLedgerEntry Trigger of Repor ID -10108 AP - Vendor Register.
        // Setup.
        Initialize();
        CreateVendorLedgerEntry(VendorLedgerEntry, Vendor, '', '', WorkDate(), Vendor.Blocked::" ");  // Due Date - WORKDATE.
        UpdateVendorName(Vendor);
        CreateDetailedVendorLedgerEntry(VendorLedgerEntry."Entry No.", Vendor."No.");
        LibraryVariableStorage.Enqueue(Vendor."No.");  // Required inside APVendorRegisterRequestPageHandler.

        // Exercise.
        LibraryLowerPermissions.SetJournalsEdit();
        REPORT.Run(REPORT::"AP - Vendor Register");  // Opens APVendorRegisterRequestPageHandler.

        // Verify: Verify Filters, Vendor Name, Remaining Amount (LCY) and Amount (LCY) is updated on Report AP - Vendor Register.
        VendorLedgerEntry.CalcFields("Amount (LCY)", "Remaining Amt. (LCY)");
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(
          'FilterString2', StrSubstNo('%1: %2', VendorLedgerEntry.FieldCaption("Vendor No."), Vendor."No."));
        LibraryReportDataset.AssertElementWithValueExists('VendorName', Vendor.Name);
        LibraryReportDataset.AssertElementWithValueExists(
          'Vendor_Ledger_Entry__Remaining_Amt___LCY__', VendorLedgerEntry."Remaining Amt. (LCY)");
        LibraryReportDataset.AssertElementWithValueExists('Vendor_Ledger_Entry__Amount__LCY__', VendorLedgerEntry."Amount (LCY)");
    end;

    [Test]
    [HandlerFunctions('VendorPurchaseStatisticsStartingDateRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnOpenPageVendorPurchStatistics()
    begin
        // Purpose of the test is to validate OnOpenPage Trigger of Report ID - 10107 Vendor Purchase Statistics.
        // Setup.
        Initialize();

        // Exercise.
        LibraryLowerPermissions.SetVendorView();
        REPORT.Run(REPORT::"Vendor Purchase Statistics");  // Opens VendorPurchaseStatisticsStartingDateRequestPageHandler.

        // Verify: Verify default value of StartDate and Length Of Periods is WORKDATE and 1M respectively on OpenVendorEntriesEndingDateRequestPageHandler.
    end;

    [Test]
    [HandlerFunctions('VendorPurchaseStatisticsRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordDiscountTakenVendorPurchStatistics()
    var
        Vendor: Record Vendor;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        DetailedVendorLedgerEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        // Purpose of the test is to validate OnAfterGetRecord - Vendor Trigger on Report ID - 10107 Vendor Purchase Statistics.

        // Setup: Create Vendor Ledger Entry and Detailed Vendor Ledger Entry of Initial Document Type Payment.
        Initialize();
        CreateVendorLedgerEntry(VendorLedgerEntry, Vendor, '', '', WorkDate(), Vendor.Blocked::" ");  // Due Date - WORKDATE.
        UpdateVendLedgerEntryDiscounts(VendorLedgerEntry);
        CreateDetailedVendorLedgerEntry(VendorLedgerEntry."Entry No.", Vendor."No.");
        UpdateInitialDocumentTypeDetailedVendorLedgerEntry(
          VendorLedgerEntry."Entry No.", Vendor."No.", DetailedVendorLedgerEntry."Initial Document Type"::Payment);
        LibraryVariableStorage.Enqueue(Vendor."No.");  // Required inside VendorPurchaseStatisticsRequestPageHandler.

        // Exercise.
        LibraryLowerPermissions.SetVendorView();
        REPORT.Run(REPORT::"Vendor Purchase Statistics");  // Opens VendorPurchaseStatisticsRequestPageHandler.

        // Verify: Verify Purchases, Payments, Invoice Discount, Vendor Balance and Discounts Taken on Report Vendor Purchase Statistics.
        VendorLedgerEntry.CalcFields("Amount (LCY)");
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('Purchases___2_', -VendorLedgerEntry."Purchase (LCY)");
        LibraryReportDataset.AssertElementWithValueExists('Payments___2_', VendorLedgerEntry."Amount (LCY)");
        LibraryReportDataset.AssertElementWithValueExists('InvoiceDiscounts___2_', -VendorLedgerEntry."Inv. Discount (LCY)");
        LibraryReportDataset.AssertElementWithValueExists('VendorBalance___2_', -VendorLedgerEntry."Amount (LCY)");
        LibraryReportDataset.AssertElementWithValueExists('DiscountsTaken___2_', -VendorLedgerEntry."Pmt. Disc. Rcd.(LCY)");
    end;

    [Test]
    [HandlerFunctions('VendorPurchaseStatisticsRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordDiscountLostVendorPurchStatistics()
    var
        Vendor: Record Vendor;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        DetailedVendorLedgerEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        // Purpose of the test is to validate OnAfterGetRecord - Vendor Trigger on Report ID - 10107 Vendor Purchase Statistics.

        // Setup: Create VendorLedger Entry of Document Type Invoice and Detailed Vendor Ledger Entry of Initial Document Type Finance Charge Memo.
        Initialize();
        CreateVendorLedgerEntry(VendorLedgerEntry, Vendor, '', '', WorkDate(), Vendor.Blocked::" ");  // Due Date - WORKDATE.
        UpdateVendLedgerEntryDiscounts(VendorLedgerEntry);
        UpdateVendorLedgerEntry(VendorLedgerEntry);  // Update Document Type Invoice.
        CreateDetailedVendorLedgerEntry(VendorLedgerEntry."Entry No.", Vendor."No.");
        UpdateInitialDocumentTypeDetailedVendorLedgerEntry(
          VendorLedgerEntry."Entry No.", Vendor."No.", DetailedVendorLedgerEntry."Initial Document Type"::"Finance Charge Memo");

        // Exercise.
        LibraryVariableStorage.Enqueue(Vendor."No.");  // Required inside VendorPurchaseStatisticsRequestPageHandler.
        LibraryLowerPermissions.SetVendorView();
        REPORT.Run(REPORT::"Vendor Purchase Statistics");  // Opens VendorPurchaseStatisticsRequestPageHandler.

        // Verify: Verify Finance Charge Memo Amount (LCY) and Discounts Lost on Report Vendor Purchase Statistics. Calculation is on the basis of OnAfterGetRecord - Vendor of Report Vendor Purchase Statistics.
        VendorLedgerEntry.CalcFields(Amount, "Amount (LCY)");
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('FinanceCharges___2_', -VendorLedgerEntry."Amount (LCY)");
        LibraryReportDataset.AssertElementWithValueExists(
          'DiscountsLost___2_',
          -((VendorLedgerEntry."Original Pmt. Disc. Possible" * (VendorLedgerEntry."Amount (LCY)" / VendorLedgerEntry.Amount)) -
            VendorLedgerEntry."Pmt. Disc. Rcd.(LCY)"));
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
        LibraryLowerPermissions.SetOutsideO365Scope();

        if not IsInitialized then begin
            LibraryApplicationArea.EnableFoundationSetup();
            IsInitialized := true;
        end;
    end;

    local procedure CreateVendor(var Vendor: Record Vendor; CurrencyCode: Code[10]; Blocked: Enum "Vendor Blocked")
    begin
        Vendor."No." := LibraryUTUtility.GetNewCode();
        Vendor."Currency Code" := CurrencyCode;
        Vendor.Blocked := Blocked;
        Vendor.Address := LibraryUTUtility.GetNewCode();
        Vendor."Address 2" := LibraryUTUtility.GetNewCode();
        Vendor.Insert();
    end;

    local procedure CreateCurrency(): Code[10]
    var
        Currency: Record Currency;
    begin
        Currency.Code := LibraryUTUtility.GetNewCode10();
        Currency.Insert();
        exit(Currency.Code);
    end;

    local procedure CreateItem(var Item: Record Item)
    begin
        Item."No." := LibraryUTUtility.GetNewCode();
        Item.Description := LibraryUTUtility.GetNewCode();
        Item.Insert();
    end;

    local procedure CreateVendorLedgerEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry"; var Vendor: Record Vendor; CurrencyCode: Code[10]; CurrencyCode2: Code[10]; DueDate: Date; Blocked: Enum "Vendor Blocked")
    var
        VendorLedgerEntry2: Record "Vendor Ledger Entry";
    begin
        CreateVendor(Vendor, CurrencyCode, Blocked);
        VendorLedgerEntry2.FindLast();
        VendorLedgerEntry."Entry No." := VendorLedgerEntry2."Entry No." + 1;
        VendorLedgerEntry."Vendor No." := Vendor."No.";
        VendorLedgerEntry."Currency Code" := CurrencyCode2;
        VendorLedgerEntry."Posting Date" := WorkDate();
        VendorLedgerEntry."Due Date" := DueDate;
        VendorLedgerEntry."External Document No." := LibraryUTUtility.GetNewCode();
        VendorLedgerEntry.Open := true;
        VendorLedgerEntry."Purchase (LCY)" := LibraryRandom.RandDec(10, 2);
        VendorLedgerEntry.Insert();

        // Enqueue required inside OpenVendorEntriesRequestPageHandler, OpenVendorEntriesPrintAmountsinVendCurrRequestPageHandler and OpenVendorEntriesUseExternalDocumentNoRequestPageHandler.
        LibraryVariableStorage.Enqueue(VendorLedgerEntry."Vendor No.");
    end;

    local procedure CreateDetailedVendorLedgerEntry(VendorLedgerEntryNo: Integer; VendorNo: Code[20])
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        DetailedVendorLedgEntry2: Record "Detailed Vendor Ledg. Entry";
    begin
        DetailedVendorLedgEntry2.FindLast();
        DetailedVendorLedgEntry."Entry No." := DetailedVendorLedgEntry2."Entry No." + 1;
        DetailedVendorLedgEntry."Vendor Ledger Entry No." := VendorLedgerEntryNo;
        DetailedVendorLedgEntry.Amount := -LibraryRandom.RandDec(10, 2);  // Amount less than 0 required.
        DetailedVendorLedgEntry."Amount (LCY)" := -DetailedVendorLedgEntry.Amount;
        DetailedVendorLedgEntry."Posting Date" := WorkDate();
        DetailedVendorLedgEntry."Vendor No." := VendorNo;
        DetailedVendorLedgEntry."Entry Type" := DetailedVendorLedgEntry."Entry Type"::"Initial Entry";
        DetailedVendorLedgEntry.Insert(true);
    end;

    local procedure CreateCommentLine(var CommentLine: Record "Comment Line"; CommentLineNo: Code[20])
    begin
        CommentLine."Table Name" := CommentLine."Table Name"::Vendor;
        CommentLine."No." := CommentLineNo;
        CommentLine."Line No." := LibraryRandom.RandInt(10);
        CommentLine.Insert();
        LibraryVariableStorage.Enqueue(CommentLineNo);  // Required inside VendorCommentListRequestPageHandler.
    end;

    local procedure CreatePaymentTerms(var PaymentTerms: Record "Payment Terms")
    begin
        PaymentTerms.Code := LibraryUTUtility.GetNewCode10();
        Evaluate(PaymentTerms."Due Date Calculation", '<' + Format(LibraryRandom.RandInt(5)) + 'M>');
        PaymentTerms."Due Date Calculation" := PaymentTerms."Due Date Calculation";
        PaymentTerms.Insert();
    end;

    local procedure CreateValueEntry(var ValueEntry: Record "Value Entry"; VendorNo: Code[20]; ItemNo: Code[20])
    var
        ValueEntry2: Record "Value Entry";
    begin
        ValueEntry2.FindLast();
        ValueEntry."Entry No." := ValueEntry2."Entry No." + 1;
        ValueEntry."Source Type" := ValueEntry."Source Type"::Vendor;
        ValueEntry."Source No." := VendorNo;
        ValueEntry."Item Ledger Entry Type" := ValueEntry."Item Ledger Entry Type"::Purchase;
        ValueEntry."Item No." := ItemNo;
        ValueEntry."Posting Date" := WorkDate();
        ValueEntry."Invoiced Quantity" := LibraryRandom.RandDec(10, 2);
        ValueEntry."External Document No." := LibraryUTUtility.GetNewCode();
        ValueEntry.Insert();
        LibraryVariableStorage.Enqueue(ValueEntry."Source No.");  // Required inside VendorItemStatisticsRequestPageHandler and VendorItemStatByPurchaserRequestPageHandler..
    end;

    local procedure CreatePurchaseInvoiceHeader(var PurchInvHeader: Record "Purch. Inv. Header"; VendorInvoiceNo: Code[35]; PostingDate: Date)
    begin
        PurchInvHeader."No." := LibraryUTUtility.GetNewCode();
        PurchInvHeader."Vendor Invoice No." := VendorInvoiceNo;
        PurchInvHeader."Order Date" := WorkDate();
        PurchInvHeader."Posting Date" := PostingDate;
        PurchInvHeader.Insert();
    end;

    local procedure CreateSalespersonPurchaser(): Code[10]
    var
        SalespersonPurchaser: Record "Salesperson/Purchaser";
    begin
        SalespersonPurchaser.Code := LibraryUTUtility.GetNewCode10();
        SalespersonPurchaser.Insert();
        exit(SalespersonPurchaser.Code);
    end;

    local procedure RunTopVendorListReport(var Vendor: Record Vendor; TopType: Option)
    var
        TopVendorList: Report "Top __ Vendor List";
    begin
        LibraryVariableStorage.Enqueue(TopType);  // Enqueue TopType for use in TopVendorListRequestPageHandler.
        Vendor.SetRange("No.", Vendor."No.");
        TopVendorList.SetTableView(Vendor);
        TopVendorList.Run();  // Invokes TopVendorListRequestPageHandler.
    end;

    local procedure UpdateInitialDocumentTypeDetailedVendorLedgerEntry(VendorLedgerEntryNo: Integer; VendorNo: Code[20]; InitialDocumentType: Enum "Gen. Journal Document Type")
    var
        DetailedVendorLedgerEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        DetailedVendorLedgerEntry.SetRange("Vendor Ledger Entry No.", VendorLedgerEntryNo);
        DetailedVendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        DetailedVendorLedgerEntry.FindFirst();
        DetailedVendorLedgerEntry."Initial Document Type" := InitialDocumentType;
        DetailedVendorLedgerEntry.Modify();
    end;

    local procedure UpdateVendorLedgerEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
        VendorLedgerEntry."Document Type" := VendorLedgerEntry."Document Type"::Invoice;
        VendorLedgerEntry."Original Pmt. Disc. Possible" := LibraryRandom.RandDec(10, 2);
        VendorLedgerEntry.Open := false;
        VendorLedgerEntry.Modify();
    end;

    local procedure UpdateVendLedgerEntryDiscounts(var VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
        VendorLedgerEntry."Inv. Discount (LCY)" := LibraryRandom.RandDec(10, 2);
        VendorLedgerEntry."Pmt. Disc. Rcd.(LCY)" := LibraryRandom.RandDec(10, 2);
        VendorLedgerEntry.Modify();
    end;

    local procedure UpdateVendorName(var Vendor: Record Vendor)
    begin
        Vendor.Name := LibraryUTUtility.GetNewCode();
        Vendor.Modify();
    end;

    local procedure OpenVendorEntriesRequestPage(OpenVendorEntries: TestRequestPage "Open Vendor Entries")
    var
        VendorNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(VendorNo);
        OpenVendorEntries.Vendor.SetFilter("No.", VendorNo);
        OpenVendorEntries."Vendor Ledger Entry".SetFilter("Vendor No.", VendorNo);
        OpenVendorEntries.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    local procedure OpenVendorAccountDetailRequestPage(VendorAccountDetail: TestRequestPage "Vendor Account Detail")
    var
        VendorNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(VendorNo);
        VendorAccountDetail.Vendor.SetFilter("No.", VendorNo);
        VendorAccountDetail."Vendor Ledger Entry".SetFilter("Vendor No.", VendorNo);
        VendorAccountDetail.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    local procedure OpenVendorListingRequestPage(VendorListing: TestRequestPage "Vendor - Listing")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        VendorListing.Vendor.SetFilter("No.", No);
        VendorListing.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure OpenVendorEntriesEndingDateRequestPageHandler(var OpenVendorEntries: TestRequestPage "Open Vendor Entries")
    begin
        OpenVendorEntries.EndingDate.AssertEquals(WorkDate());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure OpenVendorEntriesRequestPageHandler(var OpenVendorEntries: TestRequestPage "Open Vendor Entries")
    begin
        OpenVendorEntriesRequestPage(OpenVendorEntries);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure OpenVendorEntriesPrintAmountsRequestPageHandler(var OpenVendorEntries: TestRequestPage "Open Vendor Entries")
    begin
        OpenVendorEntries.PrintAmountsInVendorsCurrency.SetValue(true);
        OpenVendorEntriesRequestPage(OpenVendorEntries);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure OpenVendorEntriesUseExternDocNoRequestPageHandler(var OpenVendorEntries: TestRequestPage "Open Vendor Entries")
    begin
        OpenVendorEntries.UseExternalDocNo.SetValue(true);
        OpenVendorEntriesRequestPage(OpenVendorEntries);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure TopVendorListRequestPageHandler(var TopVendorList: TestRequestPage "Top __ Vendor List")
    var
        TopType: Variant;
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        LibraryVariableStorage.Dequeue(TopType);
        TopVendorList.Vendor.SetFilter("No.", No);
        TopVendorList.Show.SetValue(TopType);
        TopVendorList.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VendorAccountDetailExternalDocRequestPageHandler(var VendorAccountDetail: TestRequestPage "Vendor Account Detail")
    begin
        VendorAccountDetail.UseExternalDocNo.SetValue(true);
        OpenVendorAccountDetailRequestPage(VendorAccountDetail);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VendorAccountDetailAccWithBalOnlyRequestPageHandler(var VendorAccountDetail: TestRequestPage "Vendor Account Detail")
    begin
        VendorAccountDetail.AccWithBalancesOnly.SetValue(true);
        OpenVendorAccountDetailRequestPage(VendorAccountDetail);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VendorAccountDetailRequestPageHandler(var VendorAccountDetail: TestRequestPage "Vendor Account Detail")
    begin
        OpenVendorAccountDetailRequestPage(VendorAccountDetail);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VendorAccountDetailPrintAmountsRequestPageHandler(var VendorAccountDetail: TestRequestPage "Vendor Account Detail")
    begin
        VendorAccountDetail.PrintAmountsInVendorCurrency.SetValue(true);
        OpenVendorAccountDetailRequestPage(VendorAccountDetail);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VendorCommentListRequestPageHandler(var VendorCommentList: TestRequestPage "Vendor Comment List")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        VendorCommentList."Comment Line".SetFilter("No.", No);
        VendorCommentList.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VendorListingRequestPageHandler(var VendorListing: TestRequestPage "Vendor - Listing")
    begin
        OpenVendorListingRequestPage(VendorListing);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VendorListingPrintAmountsRequestPageHandler(var VendorListing: TestRequestPage "Vendor - Listing")
    begin
        VendorListing.PrintAmountsinVendorsCurrency.SetValue(true);
        OpenVendorListingRequestPage(VendorListing);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VendorItemStatisticsRequestPageHandler(var VendorItemStatistics: TestRequestPage "Vendor/Item Statistics")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        VendorItemStatistics.Vendor.SetFilter("No.", No);
        VendorItemStatistics."Value Entry".SetFilter("Source No.", No);
        VendorItemStatistics.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VendorItemStatByPurchaserRequestPageHandler(var VendorItemStatByPurchaser: TestRequestPage "Vendor Item Stat. by Purchaser")
    var
        "Code": Variant;
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        LibraryVariableStorage.Dequeue(Code);
        VendorItemStatByPurchaser."Salesperson/Purchaser".SetFilter(Code, Code);
        VendorItemStatByPurchaser.Vendor.SetFilter("No.", No);
        VendorItemStatByPurchaser."Value Entry".SetFilter("Source No.", No);
        VendorItemStatByPurchaser.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VendorPurchaseStatisticsRequestPageHandler(var VendorPurchaseStatistics: TestRequestPage "Vendor Purchase Statistics")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        VendorPurchaseStatistics.Vendor.SetFilter("No.", No);
        VendorPurchaseStatistics.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VendorPurchaseStatisticsStartingDateRequestPageHandler(var VendorPurchaseStatistics: TestRequestPage "Vendor Purchase Statistics")
    begin
        VendorPurchaseStatistics.StartDate.AssertEquals(WorkDate());
        VendorPurchaseStatistics.LengthOfPeriods.AssertEquals('1M');  // Default value is 1 Month.
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure APVendorRegisterRequestPageHandler(var APVendorRegister: TestRequestPage "AP - Vendor Register")
    var
        VendorNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(VendorNo);
        APVendorRegister."Vendor Ledger Entry".SetFilter("Vendor No.", VendorNo);
        APVendorRegister.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VendorLabelsRequestPageHandler(var VendorLabels: TestRequestPage "Vendor Labels")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        VendorLabels.Vendor.SetFilter("No.", No);
        VendorLabels.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VendorLabelsNoOfPrintLinesOnLabelRequestPageHandler(var VendorLabels: TestRequestPage "Vendor Labels")
    var
        No: Variant;
        NoOfPrintLinesOnLabel: Variant;
    begin
        LibraryVariableStorage.Dequeue(NoOfPrintLinesOnLabel);
        LibraryVariableStorage.Dequeue(No);
        VendorLabels.NoOfPrintLinesOnLabel.SetValue(NoOfPrintLinesOnLabel);
        VendorLabels.Vendor.SetFilter("No.", No);
        VendorLabels.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}

