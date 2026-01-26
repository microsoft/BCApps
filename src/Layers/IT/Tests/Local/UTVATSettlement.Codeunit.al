codeunit 144186 "UT VAT Settlement"
{
    // 1. Purpose of the test is to validate VAT Period - OnValidate Trigger of Table ID - 12135 Periodic Settlement VAT Entry, Verify error 'VAT Period must be 7 characters, for example, YYYY/MM'
    // 2. Purpose of the test is to validate VAT Period - OnValidate Trigger of Table ID - 12135 Periodic Settlement VAT Entry, Verify error 'Please check the month number.'
    // 
    // Covers Test Cases for WI - 346255.
    // ---------------------------------------------------------------
    // Test Function Name                                       TFS ID
    // ---------------------------------------------------------------
    // OnValidateVATPeriodPeriodicVATSettlementEntryPeriodError 278492
    // OnValidateVATPeriodPeriodicSettlementVATEntryMonthError

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryUTUtility: Codeunit "Library UT Utility";
        VATPeriodTxt: Label '2014/13';
        LibraryERM: Codeunit "Library - ERM";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryReportValidation: Codeunit "Library - Report Validation";
        LibraryRandom: Codeunit "Library - Random";
        CellEmptyContentErr: Label 'Excel cell''s (row=%1, column=%2) content must not be empty', Comment = '%1 - row, %2 - column';
        PriorPeriodColumnNameTxt: Label 'Prior Period Input VAT';
        CellValueNotFoundErr: Label 'Excel cell (row=%1, column=%2) value is not found.', Comment = '%1 - row, %2 - column';
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        IsInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure OnValidateVATPeriodPeriodicVATSettlementEntryPeriodError()
    begin
        // Purpose of the test is to validate VAT Period - OnValidate Trigger of Table ID - 12135 Periodic Settlement VAT Entry.
        // Verify error 'VAT Period must be 7 characters, for example, YYYY/MM'
        OnValidateVATPeriodPeriodicSettlement(LibraryUTUtility.GetNewCode10());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnValidateVATPeriodPeriodicSettlementVATEntryMonthError()
    begin
        // Purpose of the test is to validate VAT Period - OnValidate Trigger of Table ID - 12135 Periodic Settlement VAT Entry.
        // Verify error 'Please check the month number.'
        OnValidateVATPeriodPeriodicSettlement(VATPeriodTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcAndPostVATSettlementReportWithSetPlafondPeriod()
    var
        GLAccount: Record "G/L Account";
        CalcAndPostVATSettlement: Report "Calc. and Post VAT Settlement";
        InitialDate: Date;
    begin
        // Initialize
        Initialize();
        InitialDate := DMY2Date(1, 1, Date2DMY(WorkDate(), 3) - 1); // 1/1/Y-1
        InitLastSettlementDate(CalcDate('<1M-1D>', InitialDate)); // 31/1/Y-1
        InitVATPlafondPeriod(InitialDate, 0); // 1/1/CY-1 (Year will be used)
        LibraryERM.CreateGLAccount(GLAccount);

        // Exercise
        CalcAndPostVATSettlement.InitializeRequest(
          CalcDate('<1M>', InitialDate),// 1/2/Y-1
          CalcDate('<2M-1D>', InitialDate),// 28/2/Y-1
          CalcDate('<2M-1D>', InitialDate),
          '',// DocNo is not used in test
          GLAccount."No.", GLAccount."No.", GLAccount."No.", true, false);
        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID());
        CalcAndPostVATSettlement.SaveAsExcel(LibraryReportValidation.GetFileName());

        // Verify and Tear down
        VerifyCalcAndPostVATSettlementReportContentExistence();
    end;

    local procedure Initialize()
    begin
        Clear(LibraryReportValidation);
        if IsInitialized then
            exit;

        LibraryERMCountryData.UpdateGeneralPostingSetup();
        IsInitialized := true;
        Commit();
    end;

    local procedure InitVATPlafondPeriod(InitialDate: Date; CalculatedAmount: Decimal)
    var
        VATPlafondPeriod: Record "VAT Plafond Period";
    begin
        VATPlafondPeriod.DeleteAll();
        VATPlafondPeriod.Init();
        VATPlafondPeriod.Year := Date2DMY(InitialDate, 3);
        VATPlafondPeriod.Amount := LibraryRandom.RandDecInRange(1, 10000, 2);
        VATPlafondPeriod."Calculated Amount" := CalculatedAmount;
        VATPlafondPeriod.Insert();
    end;

    local procedure InitLastSettlementDate(InitialDate: Date)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Last Settlement Date" := CalcDate('<1M>', InitialDate);
        GeneralLedgerSetup.Modify();
    end;

    local procedure OnValidateVATPeriodPeriodicSettlement(VATPeriod: Code[10])
    var
#if not CLEAN27
        PeriodicVATSettlementCard: TestPage "Periodic VAT Settlement Card";
#else
        PeriodicVATSettlementCard: TestPage "Periodic VAT Settl. Card";
#endif
    begin
        // Setup.
        PeriodicVATSettlementCard.OpenNew();

        // Exercise.
        asserterror PeriodicVATSettlementCard."VAT Period".SetValue(VATPeriod);

        // Verify: Verify actual error 'VAT Period must be 7 characters, for example, YYYY/MM' and 'Please check the month number.'
        Assert.ExpectedErrorCode('TestValidation');
    end;

    [Test]
    [HandlerFunctions('CalcAndPostVATSettlementHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure RunReportCalcAndPostVATSettlementWithActivityCode()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        Vendor: Record Vendor;
        Customer: Record Customer;
        DummyGLAccount: Record "G/L Account";
#if not CLEAN27
        PeriodicSettlementVATEntry: Record "Periodic Settlement VAT Entry";
#else
        PeriodicSettlementVATEntry: Record "Periodic VAT Settlement Entry";
#endif
        GLAccountNo: Code[20];
        ActivityCode: Code[6];
        UnitPrice: Decimal;
        UnitCost: Decimal;
        PostingDate: Date;
    begin
        // [SCENARIO 615821] When Use Activity Code is enabled in General Setup, calc and post vat settlement works
        Initialize();
        // [GIVEN] Use Activity Code enabled
        SetUseActivityCode(true);
        ActivityCode := CreateActivityCode();
        PeriodicSettlementVATEntry.DeleteAll();
        // [GIVEN] Prepare setup for posting of a sales and purchase invoices
        PostingDate := GetPostingDate();
        FindAndUpdateVATPostingSetup(VATPostingSetup);
        GLAccountNo := LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, DummyGLAccount."Gen. Posting Type"::Sale);
        Vendor.Get(LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        Customer.Get(LibrarySales.CreateCustomerWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));

        // [GIVEN] Create and Post Purchase and Sales Invoices.
        UnitPrice := LibraryRandom.RandInt(100);
        UnitCost := UnitPrice + LibraryRandom.RandIntInRange(5, 10); // Make sure Input VAT is greater than Output VAT to trigger this bug.
        CreateAndPostPurchInvoice(LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"),
          PostingDate, GLAccountNo, UnitCost, ActivityCode);
        CreateAndPostSalesInvoice(Customer, PostingDate, UnitPrice, GLAccountNo, ActivityCode);

        // [WHEN] Run the report "Calc. and Post VAT Settlement"
        LibraryVariableStorage.Enqueue(PostingDate);
        VATPostingSetup.SetRecFilter();
        REPORT.Run(REPORT::"Calc. and Post VAT Settlement", true, false, VATPostingSetup);

        // Clean up.
        SetUseActivityCode(false);
    end;

    local procedure SetUseActivityCode(NewValue: Boolean)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Use Activity Code", NewValue);
        GeneralLedgerSetup.Modify();
    end;

    local procedure CreateAndPostPurchInvoice(VendorNo: Code[20]; PostingDate: Date; GLAccountNo: Code[20]; UnitCost: Decimal; ActivityCode: Code[6]) VATAmount: Decimal
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);
        PurchaseHeader.Validate("Posting Date", PostingDate);
        PurchaseHeader.Validate("Document Date", PostingDate);
        PurchaseHeader.Validate("Operation Occurred Date", PostingDate);
        PurchaseHeader.Validate("Activity Code", ActivityCode);
        PurchaseHeader."Posting No. Series" := LibraryERM.CreateNoSeriesPurchaseCode();
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", GLAccountNo, 1);
        PurchaseLine.Validate("Direct Unit Cost", UnitCost);
        PurchaseLine.Modify();
        PurchaseHeader.Validate("Check Total", PurchaseLine."Amount Including VAT");
        PurchaseHeader.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        VATAmount := PurchaseLine."Amount Including VAT" - PurchaseLine.Amount;
    end;

    local procedure CreateAndPostSalesInvoice(Customer: Record Customer; PostingDate: Date; UnitPrice: Decimal; GLAccountNo: Code[20]; ActivityCode: Code[6]) VATAmount: Decimal
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        NoSeries: Record "No. Series";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        SalesHeader.Validate("Document Date", PostingDate);
        SalesHeader.Validate("Operation Occurred Date", PostingDate);
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Validate("Activity Code", ActivityCode);
        NoSeries.Init();
        SalesHeader.Validate("Operation Type", LibraryERM.FindOperationType(NoSeries."No. Series Type"::Sales));
        SalesHeader."Posting No. Series" := LibraryERM.CreateNoSeriesSalesCode();
        SalesHeader.Modify();

        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account", GLAccountNo, 1);
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Modify();
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        VATAmount := SalesLine."Amount Including VAT" - SalesLine.Amount;
    end;

    local procedure FindAndUpdateVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup")
    begin
        VATPostingSetup.SetRange("Deductible %", 100);
        VATPostingSetup.FindLast();
        if VATPostingSetup."VAT %" = 0 then begin
            VATPostingSetup.Validate("VAT %", LibraryRandom.RandInt(10));
            VATPostingSetup.Modify(true);
        end;
    end;

    local procedure CreateActivityCode(): Code[10]
    var
        ActivityCode: Record "Activity Code";
    begin
        ActivityCode.Init();
        ActivityCode.Validate(
          Code,
          CopyStr(LibraryUtility.GenerateRandomCode(ActivityCode.FieldNo(Code), DATABASE::"Activity Code"),
            1, LibraryUtility.GetFieldLength(DATABASE::"Activity Code", ActivityCode.FieldNo(Code))));
        ActivityCode.Insert(true);
        ActivityCode.Validate(Description, ActivityCode.Code); // Validating description with code as value is not important.
        ActivityCode.Modify(true);
        exit(ActivityCode.Code);
    end;

    local procedure GetPostingDate() PostingDate: Date
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        PostingDate := CalcDate('<+1D>', GeneralLedgerSetup."Last Settlement Date");
        if PostingDate = 0D then
            PostingDate := WorkDate();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CalcAndPostVATSettlementHandler(var CalcAndPostVATSettlement: TestRequestPage "Calc. and Post VAT Settlement")
    begin
        CalcAndPostVATSettlement.StartingDate.SetValue := LibraryVariableStorage.DequeueDate();
        CalcAndPostVATSettlement.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;

    local procedure VerifyCalcAndPostVATSettlementReportContentExistence()
    var
        Row: Integer;
        Column: Integer;
        CellContent: Text;
        ValueFound: Boolean;
    begin
        // Verify Saved Report's Data.
        LibraryReportValidation.DownloadFile();
        LibraryReportValidation.OpenExcelFile();

        Row := LibraryReportValidation.FindRowNoFromColumnCaption(PriorPeriodColumnNameTxt);
        Column := LibraryReportValidation.FindColumnNoFromColumnCaption(PriorPeriodColumnNameTxt) + 31;
        CellContent := LibraryReportValidation.GetValueAt(ValueFound, Row, Column);
        Assert.IsTrue(ValueFound, StrSubstNo(CellValueNotFoundErr, Row, Column));
        Assert.AreNotEqual(0, StrLen(CellContent), CellEmptyContentErr);
    end;
}

