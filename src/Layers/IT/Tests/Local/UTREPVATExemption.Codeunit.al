codeunit 144073 "UT REP VAT Exemption"
{
    // // [FEATURE] [VAT Exemption] [Reports]
    // Test for feature VATEXEMP - VAT Exemption.

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        DialogErr: Label 'Dialog';
        LibraryRandom: Codeunit "Library - Random";
        GLAccSettlementNumberCap: Label 'GLAccSettleNo';
        PostSettlementCap: Label 'PostSettlement';
        PreviousPlafondAmountCap: Label 'PrevPlafondAmount';
        RemainingVATPlafondAmountCap: Label 'RemainingVATPlafondAmount';
        SalesHeaderBillToCustomerNoCap: Label 'Sales_Header___Bill_to_Customer_No__';
        ServiceCrMemoHeaderVATRegNoCap: Label 'VATRegNo_ServiceCrMemoHeader';
        ServiceCrMemoHeaderYourRefCap: Label 'YourRef_ServiceCrMemoHeader';
        ServiceHeaderBillToCustomerNoCap: Label 'Service_Header___Bill_to_Customer_No__';
        ServInvHeaderVATRegNoCap: Label 'VATRegNo_ServInvHeader';
        ServInvHeaderYourRefCap: Label 'YourRef_ServInvHeader';
        TotalSubstituteStr: Label 'Total %1';
        TotalTxt: Label 'TotalText';
        UsedPlafondAmountCap: Label 'UsedPlafondAmount';
        VATExemptionCap: Label 'VATExemptNo_VATExempt';
        VATExemptionDateCap: Label 'VATExemption__VAT_Exempt__Date_';
        VATExemptionNoCap: Label 'VATExemptionVATExemptNo';
        VATExemptionNumberCap: Label 'VATExemption__VAT_Exempt__No__';
        VATExemptionTypeCap: Label 'VATExemptionType';
        VATExemptionTypeTxt: Label '%1..%2';
        VATExemptionPeriodLbl: Label 'VATExemptionPeriod';
        VATExemptionEndingDateLbl: Label 'VATExemptionEndingDate';
        VATExemptionOurProtocolNoLbl: Label 'VATExemptionOurProtocolNo';
        LibraryUtility: Codeunit "Library - Utility";
        PrintTypeRef: Option "Test Print","Final Print",Reprint;
        NameVendLbl: Label 'Name_Vend';
        VATRegistrationNoVendLbl: Label 'VATRegistrationNoVend';
        VATExemptIntRegistryNoVendLbl: Label 'VATExemptIntRegistryNoVend';

    [Test]
    [HandlerFunctions('VATExemptionRegisterRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportBlankEndingDateVATExemptionRegisterError()
    var
        VATExemption: Record "VAT Exemption";
    begin
        // Purpose of the test is to validate OnPreReport Trigger of Report ID - 12181 VAT Exemption Register.

        // Setup: Test to verify error - Ending Date must not be blank on Report VAT Exemption Register.
        Initialize();
        OnPreReportVATExemptionRegister(
          WorkDate(), 0D, LibraryRandom.RandInt(10),
          StrSubstNo(VATExemptionTypeTxt, VATExemption.Type::Customer, VATExemption.Type::Customer));  // Start Date - WorkDate(), Blank End Date and Random Starting Page.
    end;

    [Test]
    [HandlerFunctions('VATExemptionRegisterRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportHigherStartDateVATExemptionRegisterError()
    var
        VATExemption: Record "VAT Exemption";
    begin
        // Purpose of the test is to validate OnPreReport Trigger of Report ID - 12181 VAT Exemption Register.

        // Setup: Test to verify error - Start Date cannot be greater than End Date on Report VAT Exemption Register.
        Initialize();
        OnPreReportVATExemptionRegister(
          CalcDate('<' + Format(LibraryRandom.RandInt(10)) + 'D>', WorkDate()), WorkDate(), LibraryRandom.RandInt(10),
          StrSubstNo(VATExemptionTypeTxt, VATExemption.Type::Customer, VATExemption.Type::Customer));  // Calculated Start Date greater than End Date with Random Starting Page.
    end;

    [Test]
    [HandlerFunctions('VATExemptionRegisterRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportBlankStartingPageVATExemptionRegisterError()
    var
        VATExemption: Record "VAT Exemption";
    begin
        // Purpose of the test is to validate OnPreReport Trigger of Report - 12181 VAT Exemption Register.

        // Setup: Test to verify error - Starting Page must not be blank on Report VAT Exemption Register.
        Initialize();
        OnPreReportVATExemptionRegister(
          WorkDate(), WorkDate(), 0, StrSubstNo(VATExemptionTypeTxt, VATExemption.Type::Customer, VATExemption.Type::Customer));  // Start Date - WorkDate(), End Date - WORKDATE and Blank Starting Page.
    end;

    [Test]
    [HandlerFunctions('VATExemptionRegisterRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportVATExemptionTypeVATExemptionRegisterError()
    var
        VATExemption: Record "VAT Exemption";
    begin
        // Purpose of the test is to validate OnPreReport Trigger of Report ID - 12181 VAT Exemption Register.

        // Setup: Test to verify error - You can only print report for one type at a time on Report VAT Exemption Register.
        Initialize();
        OnPreReportVATExemptionRegister(
          WorkDate(), WorkDate(), LibraryRandom.RandInt(10),
          StrSubstNo(VATExemptionTypeTxt, VATExemption.Type::Customer, VATExemption.Type::Vendor));  // Start Date - WorkDate(), End Date - WORKDATE and Random Starting Page.
    end;

    [Test]
    [HandlerFunctions('VATExemptionRegisterRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportRegistryDateVATExemptionRegisterError()
    var
        VATExemption: Record "VAT Exemption";
    begin
        // Purpose of the test is to validate VAT Exemption - OnPreReport Trigger of Report ID - 12181 VAT Exemption Register.

        // Setup: Test to verify error - VAT Exemption Int. Registry Date of the previous period has not been printed on Report VAT Exemption Register.
        Initialize();
        OnPreReportVATExemptionRegister(
          WorkDate(), WorkDate(), LibraryRandom.RandInt(10),
          StrSubstNo(VATExemptionTypeTxt, VATExemption.Type::Customer, VATExemption.Type::Customer));  // Start Date - WorkDate(), End Date - WORKDATE and Random Starting Page.
    end;

    local procedure OnPreReportVATExemptionRegister(StartDate: Date; EndDate: Date; StartingPage: Integer; VATExemptionType: Text[30])
    var
        VATExemption: Record "VAT Exemption";
    begin
        // Create VAT Exemption.
        CreateVATExemption(
          VATExemption.Type::Customer, '', false, CalcDate('<' + Format(-LibraryRandom.RandInt(10)) + 'D>', WorkDate()));  // Blank Number, Printed as FALSE and calculate VAT Exempt, Int. Registry Date lesser than Start date.
        EnqueueVATExemptionDetail(StartDate, EndDate, StartingPage, VATExemptionType, PrintTypeRef::Reprint);  // Enqueue Values for VATExemptionRegisterRequestPageHandler.

        // Exercise.
        asserterror REPORT.Run(REPORT::"VAT Exemption Register");  // Opens handler - VATExemptionRegisterRequestPageHandler.

        // Verify: Verify expected error code, with different actual error.
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [HandlerFunctions('VATExemptionRegisterRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordCustomerReprintVATExemptionRegister()
    var
        VATExemption: Record "VAT Exemption";
    begin
        // Purpose of the test is to validate Customer - OnAfterGetRecord Trigger of Report ID - 12181 VAT Exemption Register for VAT Exemption Type Customer.
        OnAfterGetRecordVATExemptPrintTypeVATExemptionRegister(
          VATExemption.Type::Customer, PrintTypeRef::Reprint, true, Format(VATExemption.Type::Customer));  // Printed as TRUE.
    end;

    [Test]
    [HandlerFunctions('VATExemptionRegisterRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordVendorReprintVATExemptionRegister()
    var
        VATExemption: Record "VAT Exemption";
    begin
        // Purpose of the test is to validate Vendor - OnAfterGetRecord Trigger of Report ID - 12181 VAT Exemption Register for VAT Exemption Type Vendor.
        OnAfterGetRecordVATExemptPrintTypeVATExemptionRegister(
          VATExemption.Type::Vendor, PrintTypeRef::Reprint, true, Format(VATExemption.Type::Vendor));  // Printed as TRUE.
    end;

    [Test]
    [HandlerFunctions('VATExemptionRegisterRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordVendorTestPrintVATExemptionRegister()
    var
        VATExemption: Record "VAT Exemption";
    begin
        // Purpose of the test is to validate Vendor - OnAfterGetRecord Trigger of Report ID - 12181 VAT Exemption Register for Print Type Test Print.
        OnAfterGetRecordVATExemptPrintTypeVATExemptionRegister(
          VATExemption.Type::Vendor, PrintTypeRef::"Test Print", false, Format(VATExemption.Type::Vendor));  // Printed as FALSE.
    end;

    local procedure OnAfterGetRecordVATExemptPrintTypeVATExemptionRegister(VATExemptionType: Option; PrintType: Option; Printed: Boolean; VATExemptNoTxt: Text[30])
    var
        VATExemptNo: Code[20];
    begin
        // Setup: Create VAT Exemption and enqueue values for handler - VATExemptionRegisterRequestPageHandler.
        Initialize();
        VATExemptNo := CreateVATExemption(VATExemptionType, '', Printed, WorkDate());  // Blank Number, VAT Exempt. Int. Registry Date - WORKDATE.
        EnqueueVATExemptionDetail(
          WorkDate(), WorkDate(), LibraryRandom.RandInt(10),
          StrSubstNo(VATExemptionTypeTxt, VATExemptionType, VATExemptionType), PrintType);  // Start Date - WorkDate(), End Date - WORKDATE and Random Starting Page.

        // Exercise.
        REPORT.Run(REPORT::"VAT Exemption Register");  // Opens handler - VATExemptionRegisterRequestPageHandler.

        // Verify: Verify VAT Exemption Type and VAT Exempt No on genereted XML of Report - VAT Exemption Register.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(VATExemptionTypeCap, VATExemptNoTxt);
        LibraryReportDataset.AssertElementWithValueExists(VATExemptionCap, VATExemptNo);
        LibraryReportDataset.AssertElementWithValueExists('CustVATExemptionType', 0); // TFS 378866
        LibraryReportDataset.AssertElementWithValueExists('VendVATExemptionType', 1);
        LibraryReportDataset.AssertElementWithValueExists('VATExemptionTypeFilter', VATExemptionType);
    end;

    [Test]
    [HandlerFunctions('VATExemptionRegisterRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordPrintTypeFinalPrintVATExemptionRegister()
    var
        VATExemption: Record "VAT Exemption";
        VATExemptNo: Code[20];
    begin
        // Purpose of the test is to validate VAT Exemption - OnAfterGetRecord Trigger of Report - 12181 VAT Exemption Register.

        // Setup: Create VAT Exemption and Enqueue values for VATExemptionRegisterRequestPageHandler.
        Initialize();
        VATExemptNo := CreateVATExemption(VATExemption.Type::Vendor, '', false, WorkDate());  // Blank Number, Printed as FALSE and VAT Exempt. Int. Registry Date - WORKDATE.
        EnqueueVATExemptionDetail(
          WorkDate(), WorkDate(), LibraryRandom.RandInt(10),
          StrSubstNo(VATExemptionTypeTxt, VATExemption.Type::Vendor, VATExemption.Type::Vendor), PrintTypeRef::"Final Print");  // Start Date - WorkDate(), End Date - WORKDATE and Random Starting Page.

        // Exercise.
        REPORT.Run(REPORT::"VAT Exemption Register");  // Opens handler - VATExemptionRegisterRequestPageHandler.

        // Verify: Verify VAT Exemption - Printed as TRUE.
        VATExemption.SetRange("VAT Exempt. No.", VATExemptNo);
        VATExemption.FindFirst();
        VATExemption.TestField(Printed, true);
    end;

    [Test]
    [HandlerFunctions('ServiceCreditMemoRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordYourReferenceServiceCreditMemo()
    begin
        // Purpose of the test is to validate Service Credit Memo Header - OnAfterGetRecord Trigger of Report ID 5912 Service - Credit Memo.
        OnAfterGetRecordServiceCreditMemo(CreateCurrency(), LibraryUTUtility.GetNewCode(), LibraryUTUtility.GetNewCode());  // Your Reference and VAT Registration Number.
    end;

    [Test]
    [HandlerFunctions('ServiceCreditMemoRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordBlankYourReferenceServiceCreditMemo()
    begin
        // Purpose of the test is to validate Service Credit Memo Header - OnAfterGetRecord Trigger of Report ID 5912 Service - Credit Memo.
        OnAfterGetRecordServiceCreditMemo(CreateCurrency(), '', LibraryUTUtility.GetNewCode());  // Your Reference - blank and VAT Registration Number.
    end;

    [Test]
    [HandlerFunctions('ServiceCreditMemoRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordVATRegNoServiceCreditMemo()
    begin
        // Purpose of the test is to validate Service Credit Memo Header - OnAfterGetRecord Trigger of Report ID 5912 Service - Credit Memo.
        OnAfterGetRecordServiceCreditMemo(CreateCurrency(), LibraryUTUtility.GetNewCode(), LibraryUTUtility.GetNewCode());  // Your Reference and VAT Registration Number.
    end;

    [Test]
    [HandlerFunctions('ServiceCreditMemoRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordBlankVATRegNoServiceCreditMemo()
    begin
        // Purpose of the test is to validate Service Credit Memo Header - OnAfterGetRecord Trigger of Report ID 5912 Service - Credit Memo.
        OnAfterGetRecordServiceCreditMemo(CreateCurrency(), LibraryUTUtility.GetNewCode(), '');  // Your Reference and blank VAT Registration Number.
    end;

    [Test]
    [HandlerFunctions('ServiceCreditMemoRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordWithCurrencyServiceCreditMemo()
    begin
        // Purpose of the test is to validate Service Credit Memo Header - OnAfterGetRecord Trigger of Report ID 5912 Service - Credit Memo.
        OnAfterGetRecordServiceCreditMemo(CreateCurrency(), LibraryUTUtility.GetNewCode(), LibraryUTUtility.GetNewCode());  // Your Reference and VAT Registration Number.
    end;

    [Test]
    [HandlerFunctions('ServiceCreditMemoRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordWithoutCurrencyServiceCreditMemo()
    begin
        // Purpose of the test is to validate Service Credit Memo Header - OnAfterGetRecord Trigger of Report ID 5912 Service - Credit Memo.
        OnAfterGetRecordServiceCreditMemo('', LibraryUTUtility.GetNewCode(), LibraryUTUtility.GetNewCode());  // Currency code - blank, Your Reference and VAT Registration Number.
    end;

    local procedure OnAfterGetRecordServiceCreditMemo(CurrencyCode: Code[10]; YourReference: Code[20]; VATRegistrationNumber: Code[20])
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        VATExemption: Record "VAT Exemption";
        VATExemptionNumber: Code[20];
    begin
        // Setup: Create Service Credit Memo and VAT Exemption.
        Initialize();
        CreateServiceCreditMemoHeader(ServiceCrMemoHeader, CurrencyCode, YourReference, VATRegistrationNumber);
        CreateServiceCreditMemoLine(ServiceCrMemoHeader."No.");
        VATExemptionNumber :=
          CreateVATExemption(VATExemption.Type::Customer, ServiceCrMemoHeader."Customer No.", false, WorkDate());  // Printed as False and VAT Exempt Int. Registry Date - Workdate.
        LibraryVariableStorage.Enqueue(ServiceCrMemoHeader."No.");  // Enqueue value in handler - ServiceCreditMemoRequestPageHandler.
        Commit();  // Commit is explicitly using on OnRun Trigger of Codeunit - 5904 Service Cr. Memo-Printed.

        // Exercise.
        REPORT.Run(REPORT::"Service - Credit Memo");  // Opens handler - ServiceCreditMemoRequestPageHandler.

        // Verify: Verify Service Credit Memo Header - Currency Code, VAT Registration No, Your Reference and VAT Exemption Number on XML of Report Service - Credit Memo.
        VerifyDocumentDetailAndVATExemptionOnReport(
          ServiceCrMemoHeader."Currency Code", ServiceCrMemoHeaderVATRegNoCap, ServiceCrMemoHeader."VAT Registration No.",
          ServiceCrMemoHeaderYourRefCap, ServiceCrMemoHeader."Your Reference", VATExemptionNumber);
    end;

    [Test]
    [HandlerFunctions('ServiceInvoiceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordYourReferenceServiceInvoice()
    begin
        // Purpose of the test is to validate Service Invoice Header - OnAfterGetRecord Trigger of Report ID 5911 Service - Invoice.
        OnAfterGetRecordServiceInvoice(CreateCurrency(), LibraryUTUtility.GetNewCode(), LibraryUTUtility.GetNewCode());  // Your Reference and VAT Registration Number.
    end;

    [Test]
    [HandlerFunctions('ServiceInvoiceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordBlankYourReferenceServiceInvoice()
    begin
        // Purpose of the test is to validate Service Invoice Header - OnAfterGetRecord Trigger of Report ID 5911 Service - Invoice.
        OnAfterGetRecordServiceInvoice(CreateCurrency(), '', LibraryUTUtility.GetNewCode());  // Blank Your Reference and VAT Registration Number.
    end;

    [Test]
    [HandlerFunctions('ServiceInvoiceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordVATRegNoServiceInvoice()
    begin
        // Purpose of the test is to validate Service Invoice Header - OnAfterGetRecord Trigger of Report ID 5911 Service - Invoice.
        OnAfterGetRecordServiceInvoice(CreateCurrency(), LibraryUTUtility.GetNewCode(), LibraryUTUtility.GetNewCode());  // Your Reference and VAT Registration Number.
    end;

    [Test]
    [HandlerFunctions('ServiceInvoiceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordBlankVATRegNoServiceInvoice()
    begin
        // Purpose of the test is to validate Service Invoice Header - OnAfterGetRecord Trigger of Report ID 5911 Service - Invoice.
        OnAfterGetRecordServiceInvoice(CreateCurrency(), LibraryUTUtility.GetNewCode(), '');  // Your Reference and blank VAT Registration Number.
    end;

    [Test]
    [HandlerFunctions('ServiceInvoiceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordWithCurrencyServiceInvoice()
    begin
        // Purpose of the test is to validate Service Invoice Header - OnAfterGetRecord Trigger of Report ID 5911 Service - Invoice.
        OnAfterGetRecordServiceInvoice(CreateCurrency(), LibraryUTUtility.GetNewCode(), LibraryUTUtility.GetNewCode());  // Your Reference and VAT Registration Number.
    end;

    [Test]
    [HandlerFunctions('ServiceInvoiceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordWithoutCurrencyServiceInvoice()
    begin
        // Purpose of the test is to validate Service Invoice Header - OnAfterGetRecord Trigger of Report ID 5911 Service - Invoice.
        OnAfterGetRecordServiceInvoice('', LibraryUTUtility.GetNewCode(), LibraryUTUtility.GetNewCode());  // Blank Currency code, Your Reference and VAT Registration Number.
    end;

    local procedure OnAfterGetRecordServiceInvoice(CurrencyCode: Code[10]; YourReference: Code[20]; VATRegistrationNumber: Code[20])
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        VATExemption: Record "VAT Exemption";
        VATExemptionNumber: Code[20];
    begin
        // Setup: Create Service Invoice and VAT Exemption.
        Initialize();
        CreateServiceInvoiceHeader(ServiceInvoiceHeader, CurrencyCode, YourReference, VATRegistrationNumber);
        CreateServiceInvoiceLine(ServiceInvoiceHeader."No.");
        VATExemptionNumber :=
          CreateVATExemption(VATExemption.Type::Customer, ServiceInvoiceHeader."Customer No.", false, WorkDate());  // Printed as False and VAT Exempt Int. Registry Date - Workdate.
        LibraryVariableStorage.Enqueue(ServiceInvoiceHeader."No.");  // Enqueue value in handler - ServiceInvoiceRequestPageHandler.
        Commit();  // Commit is explicitly using on OnRun Trigger of Codeunit - 5902 Service Inv.-Printed.

        // Exercise.
        REPORT.Run(REPORT::"Service - Invoice");  // Opens handler - ServiceInvoiceRequestPageHandler.

        // Verify: Verify Service Invoice Header - Currency Code, VAT Registration No, Your Reference and VAT Exemption Number on XML of Report Service - Invoice.
        VerifyDocumentDetailAndVATExemptionOnReport(
          ServiceInvoiceHeader."Currency Code", ServInvHeaderVATRegNoCap, ServiceInvoiceHeader."VAT Registration No.",
          ServInvHeaderYourRefCap, ServiceInvoiceHeader."Your Reference", VATExemptionNumber);
        VerifyPeriodProtocolNoEndingDate(VATExemptionNumber, ServiceInvoiceHeader."Posting Date");
    end;

    [Test]
    [HandlerFunctions('CalcAndPostVATSettlementRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordWithoutCalcAndPostVATSettlement()
    begin
        // Purpose of the test is to validate VATPlafondPeriod - OnAfterGetRecord Trigger of Report ID 20 Calc. and Post VAT Settlement.
        OnAfterGetRecordCalcAndPostVATSettlement('', false);  // GL Settlement Account Number - blank and Post as False.
    end;

    [Test]
    [HandlerFunctions('CalcAndPostVATSettlementRequestPageHandler,ConfirmHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordWithPostCalcAndPostVATSettlement()
    begin
        // Purpose of the test is to validate VATPlafondPeriod - OnAfterGetRecord Trigger of Report ID 20 Calc. and Post VAT Settlement.
        OnAfterGetRecordCalcAndPostVATSettlement(CreateGLAccount(), true);  // Post as True.
    end;

    local procedure OnAfterGetRecordCalcAndPostVATSettlement(GLSettlementAccountNo: Code[20]; Post: Boolean)
    var
        VATEntry: Record "VAT Entry";
        Amount: Decimal;
    begin
        // Setup:  Update General Ledger Setup - Last Settlement Date, Create VAT Entry and VAT Plafond Period.
        Initialize();
        UpdateGeneralLedgerSetupLastSettlementDate();
        CreateVATEntry(VATEntry);
        Amount := CreateVATPlafondPeriod();

        // Enqueue Values for handler - CalcAndPostVATSettlementRequestPageHandler.
        LibraryVariableStorage.Enqueue(GLSettlementAccountNo);
        LibraryVariableStorage.Enqueue(Post);

        // Exercise.
        REPORT.Run(REPORT::"Calc. and Post VAT Settlement");  // Opens handler - CalcAndPostVATSettlementRequestPageHandler.

        // Verify: Verify G/L Settlement Account Number, Post, Remaining VAT Plafond Amount, Used Plafond Amount and Previous Plafond Amount on created XML of Report Calc. and Post VAT Settlement.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(GLAccSettlementNumberCap, GLSettlementAccountNo);
        LibraryReportDataset.AssertElementWithValueExists(PostSettlementCap, Post);
        LibraryReportDataset.AssertElementWithValueExists(RemainingVATPlafondAmountCap, Amount - VATEntry.Base);
        LibraryReportDataset.AssertElementWithValueExists(UsedPlafondAmountCap, VATEntry.Base);
        LibraryReportDataset.AssertElementWithValueExists(PreviousPlafondAmountCap, Amount);
    end;

    [Test]
    [HandlerFunctions('SalesDocumentTestRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordSalesDocumentTest()
    var
        SalesHeader: Record "Sales Header";
        VATExemption: Record "VAT Exemption";
        VATExemptionNumber: Code[20];
    begin
        // Purpose of the test is to validate Sales Header - OnAfterGetRecord Trigger of Report ID - 202 Sales Document - Test.

        // Setup: Create Sales Order and VAT Exemption.
        Initialize();
        CreateSalesHeader(SalesHeader);
        CreateSalesLine(SalesHeader."No.");
        VATExemptionNumber := CreateVATExemption(VATExemption.Type::Customer, SalesHeader."Bill-to Customer No.", false, WorkDate());  // Printed as False and VAT Exempt Int. Registry Date - Workdate.
        LibraryVariableStorage.Enqueue(SalesHeader."No.");  // Enqueue Values for SalesDocumentTestRequestPageHandler.

        // Exercise.
        REPORT.Run(REPORT::"Sales Document - Test");  // Opens handler - SalesDocumentTestRequestPageHandler.

        // Verify: Verify Exemption - VAT Exemption Number, VAT Exemption Date and Sales Header - Bill To Customer Number on generated XML of Report Sales Document - Test.
        VerifyVATExemptionNumberAndDate(VATExemptionNumber, SalesHeaderBillToCustomerNoCap, SalesHeader."Bill-to Customer No.");
    end;

    [Test]
    [HandlerFunctions('ServiceDocumentTestRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordServiceDocumentTest()
    var
        ServiceHeader: Record "Service Header";
        VATExemption: Record "VAT Exemption";
        VATExemptionNumber: Code[20];
    begin
        // Purpose of the test is to validate Service Header - OnAfterGetRecord Trigger of Report ID - 5915 Service Document - Test.

        // Setup: Create Service Order and VAT Exemption.
        Initialize();
        CreateServiceHeader(ServiceHeader);
        CreateServiceLine(ServiceHeader."No.");
        VATExemptionNumber := CreateVATExemption(VATExemption.Type::Customer, ServiceHeader."Bill-to Customer No.", false, WorkDate());  // Printed as False and VAT Exempt Int. Registry Date - Workdate.
        LibraryVariableStorage.Enqueue(ServiceHeader."No.");  // Enqueue Values for ServiceDocumentTestRequestPageHandler.

        // Exercise.
        REPORT.Run(REPORT::"Service Document - Test");  // Opens handler - ServiceDocumentTestRequestPageHandler.

        // Verify: Verify Exemption - VAT Exemption Number, VAT Exemption Date and Service Header - Bill To Customer Number on generated XML of Report Service Document - Test.
        VerifyVATExemptionNumberAndDate(VATExemptionNumber, ServiceHeaderBillToCustomerNoCap, ServiceHeader."Bill-to Customer No.");
    end;

    [Test]
    [HandlerFunctions('VATExemptionRegisterRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VATExemptionRegisterReportSorting()
    var
        VATExemption: Record "VAT Exemption";
        Vendor1: Code[20];
        Vendor2: Code[20];
        IntRegNo1: Code[20];
        IntRegNo2: Code[20];
    begin
        // [SCENARIO 378202] The VAT Exemption Register report should order the information by Int. Registry No. field and not by Vendor
        Initialize();
        // [GIVEN] Code of Vendor2 is more than Code of Vendor1
        Vendor1 := LibraryUTUtility.GetNewCode();
        Vendor2 := LibraryUTUtility.GetNewCode();
        MockVendor(Vendor1, Vendor1);
        MockVendor(Vendor2, Vendor1);

        // [GIVEN] "VAT Exempt. Int. Registry No." is less for Vendor2: "I2" < "I1"
        IntRegNo2 := CreateVATExemptionWithIntRegNo(VATExemption.Type::Vendor, Vendor2, WorkDate());
        IntRegNo1 := CreateVATExemptionWithIntRegNo(VATExemption.Type::Vendor, Vendor1, WorkDate());

        EnqueueVATExemptionDetail(WorkDate(), WorkDate(), 1, Format(VATExemption.Type::Vendor), PrintTypeRef::"Test Print");  // used in VATExemptionRegisterRequestPageHandler
        Commit();

        // [WHEN] Run VAT Exemption Register
        REPORT.Run(REPORT::"VAT Exemption Register");

        // [THEN] First row has 'VATExemptIntRegistryNoVend' = "I2" for Vendor2
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange(NameVendLbl, Vendor1);
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals(VATRegistrationNoVendLbl, Vendor2);
        LibraryReportDataset.AssertCurrentRowValueEquals(VATExemptIntRegistryNoVendLbl, IntRegNo2);
        // [THEN] Second row has 'VATExemptIntRegistryNoVend' = "I1" for Vendor1
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals(VATRegistrationNoVendLbl, Vendor1);
        LibraryReportDataset.AssertCurrentRowValueEquals(VATExemptIntRegistryNoVendLbl, IntRegNo1);
        // [THEN] Starting Year and Page are in dataset
        LibraryReportDataset.AssertCurrentRowValueEquals('StartingYear', Date2DMY(WorkDate(), 3));
        LibraryReportDataset.AssertCurrentRowValueEquals('StartingPage', 1);
    end;

    [Test]
    [HandlerFunctions('SalesDocumentTestRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalesDocumentTestReportPrintVATExemptNoWithConsecutiveNo()
    var
        SalesHeader: Record "Sales Header";
        VATExemption: Record "VAT Exemption";
        VATExemptionNumber: Text;
    begin
        // [FEATURE] [Sales] [Invoice] [Report]
        // [SCENARIO 341871] Sales Document Test report prints VAT Exemption Number with Consecutive VAT Exempt. No.

        Initialize();

        // [GIVEN] VAT Exemption with "VAT Exempt. No." = "1234" and "Consecutive VAT Exempt. No." = "001"
        // [GIVEN] Sales Invoice with customer related to above VAT Exemption
        CreateSalesHeader(SalesHeader);
        CreateSalesLine(SalesHeader."No.");
        VATExemptionNumber :=
          CreateVATExemptionWithConsecutiveNo(VATExemption.Type::Customer, SalesHeader."Bill-to Customer No.", false, WorkDate());
        LibraryVariableStorage.Enqueue(SalesHeader."No.");  // Enqueue Values for SalesDocumentTestRequestPageHandler.
        Commit();

        // [WHEN] Print Sales Document - Test
        REPORT.Run(REPORT::"Sales Document - Test");

        // [THEN] VAT Exemption value in the report is "1234-001"
        VerifyDocumentVATExemptionOnReport(VATExemptionNumberCap, VATExemptionNumber);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ServiceInvoiceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ServiceInvoiceReportPrintVATExemptNoWithConsecutiveNo()
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        VATExemption: Record "VAT Exemption";
        VATExemptionNumber: Text;
    begin
        // [FEATURE] [Service] [Invoice] [Report]
        // [SCENARIO 341871] Servicve Invoice report pints VAT Exemption Number with Consecutive VAT Exempt. No.

        Initialize();

        // [GIVEN] VAT Exemption with "VAT Exempt. No." = "1234" and "Consecutive VAT Exempt. No." = "001"
        // [GIVEN] Service invoice with customer related to above VAT Exemption
        CreateServiceInvoiceHeader(ServiceInvoiceHeader, '', '', '');
        CreateServiceInvoiceLine(ServiceInvoiceHeader."No.");
        VATExemptionNumber :=
          CreateVATExemptionWithConsecutiveNo(VATExemption.Type::Customer, ServiceInvoiceHeader."Customer No.", false, WorkDate());
        LibraryVariableStorage.Enqueue(ServiceInvoiceHeader."No.");  // Enqueue value in handler - ServiceInvoiceRequestPageHandler.
        Commit();

        // [WHEN] Print Service Invoice
        REPORT.Run(REPORT::"Service - Invoice");  // Opens handler - ServiceInvoiceRequestPageHandler.

        // [THEN] VAT Exemption value in the report is "1234-001"
        VerifyDocumentVATExemptionOnReport(VATExemptionNoCap, VATExemptionNumber);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ServiceCreditMemoRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ServiceCrMemoReportPrintVATExemptNoWithConsecutiveNo()
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        VATExemption: Record "VAT Exemption";
        VATExemptionNumber: Text;
    begin
        // [FEATURE] [Service] [Credit Memo] [Report]
        // [SCENARIO 341871] Servicve Credit Memo report pints VAT Exemption Number with Consecutive VAT Exempt. No.

        Initialize();

        // [GIVEN] VAT Exemption with "VAT Exempt. No." = "1234" and "Consecutive VAT Exempt. No." = "001"
        // [GIVEN] Service Credit Memo with customer related to above VAT Exemption
        CreateServiceCreditMemoHeader(ServiceCrMemoHeader, '', '', '');
        CreateServiceCreditMemoLine(ServiceCrMemoHeader."No.");
        VATExemptionNumber :=
          CreateVATExemptionWithConsecutiveNo(VATExemption.Type::Customer, ServiceCrMemoHeader."Customer No.", false, WorkDate());
        LibraryVariableStorage.Enqueue(ServiceCrMemoHeader."No.");  // Enqueue value in handler - ServiceCreditMemoRequestPageHandler.
        Commit();

        // [WHEN] Print Service Credit Memo
        REPORT.Run(REPORT::"Service - Credit Memo");

        // [THEN] VAT Exemption value in the report is "1234-001"
        VerifyDocumentVATExemptionOnReport(VATExemptionNoCap, VATExemptionNumber);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ServiceDocumentTestRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ServiceDocumentTestReportPrintVATExemptNoWithConsecutiveNo()
    var
        ServiceHeader: Record "Service Header";
        VATExemption: Record "VAT Exemption";
        VATExemptionNumber: Text;
    begin
        // [FEATURE] [Service] [Invoice] [Report]
        // [SCENARIO 341871] Servicve Document Test report pints VAT Exemption Number with Consecutive No.

        Initialize();

        // [GIVEN] VAT Exemption with "VAT Exempt. No." = "1234" and "Consecutive VAT Exempt. No." = "001"
        // [GIVEN] Service Invoice with customer related to above VAT Exemption
        CreateServiceHeader(ServiceHeader);
        CreateServiceLine(ServiceHeader."No.");
        VATExemptionNumber :=
          CreateVATExemptionWithConsecutiveNo(VATExemption.Type::Customer, ServiceHeader."Bill-to Customer No.", false, WorkDate());
        LibraryVariableStorage.Enqueue(ServiceHeader."No.");  // Enqueue value in handler - ServiceDocumentTestRequestPageHandler.
        Commit();

        // [WHEN] Print Service Document - Test
        REPORT.Run(REPORT::"Service Document - Test");

        // [THEN] VAT Exemption value in the report is "1234-001"
        VerifyDocumentVATExemptionOnReport(VATExemptionNumberCap, VATExemptionNumber);

        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
    begin
        Customer."No." := LibraryUTUtility.GetNewCode();
        Customer."Customer Posting Group" := CreateCustomerPostingGroup();
        Customer.Insert();
        exit(Customer."No.");
    end;

    local procedure CreateCustomerPostingGroup(): Code[20]
    var
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        CustomerPostingGroup.Code := LibraryUTUtility.GetNewCode10();
        CustomerPostingGroup.Insert();
        exit(CustomerPostingGroup.Code);
    end;

    local procedure CreateCurrency(): Code[10]
    var
        Currency: Record Currency;
    begin
        Currency.Code := LibraryUTUtility.GetNewCode10();
        Currency.Insert();
        exit(Currency.Code);
    end;

    local procedure CreateGLAccount(): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount."No." := LibraryUTUtility.GetNewCode();
        GLAccount.Insert();
        exit(GLAccount."No.");
    end;

    local procedure CreateSalesHeader(var SalesHeader: Record "Sales Header")
    begin
        SalesHeader."Document Type" := SalesHeader."Document Type"::Order;
        SalesHeader."No." := LibraryUTUtility.GetNewCode();
        SalesHeader."Document Date" := WorkDate();
        SalesHeader."Bill-to Customer No." := CreateCustomer();
        SalesHeader."VAT Bus. Posting Group" := CreateVATBusinessPostingGroup();
        SalesHeader.Insert();
    end;

    local procedure CreateSalesLine(DocumentNo: Code[20])
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine."Document Type" := SalesLine."Document Type"::Order;
        SalesLine."Document No." := DocumentNo;
        SalesLine.Quantity := LibraryRandom.RandDec(10, 2);
        SalesLine."Qty. to Invoice" := SalesLine.Quantity;
        SalesLine.Insert();
    end;

    local procedure CreateServiceHeader(var ServiceHeader: Record "Service Header")
    begin
        ServiceHeader."No." := LibraryUTUtility.GetNewCode();
        ServiceHeader."Document Type" := ServiceHeader."Document Type"::Order;
        ServiceHeader."Bill-to Customer No." := CreateCustomer();
        ServiceHeader."VAT Bus. Posting Group" := CreateVATBusinessPostingGroup();
        ServiceHeader."Document Date" := WorkDate();
        ServiceHeader.Insert();
    end;

    local procedure CreateServiceInvoiceHeader(var ServiceInvoiceHeader: Record "Service Invoice Header"; CurrencyCode: Code[10]; YourReference: Text[35]; VATRegistrationNo: Code[20])
    begin
        ServiceInvoiceHeader."No." := LibraryUTUtility.GetNewCode();
        ServiceInvoiceHeader."Customer No." := CreateCustomer();
        ServiceInvoiceHeader."Bill-to Customer No." := ServiceInvoiceHeader."Customer No.";
        ServiceInvoiceHeader."Document Date" := WorkDate();
        ServiceInvoiceHeader."Posting Date" := WorkDate();
        ServiceInvoiceHeader."VAT Bus. Posting Group" := CreateVATBusinessPostingGroup();
        ServiceInvoiceHeader."Currency Code" := CurrencyCode;
        ServiceInvoiceHeader."Your Reference" := YourReference;
        ServiceInvoiceHeader."VAT Registration No." := VATRegistrationNo;
        ServiceInvoiceHeader.Insert();
    end;

    local procedure CreateServiceInvoiceLine(DocumentNo: Code[20])
    var
        ServiceInvoiceLine: Record "Service Invoice Line";
    begin
        ServiceInvoiceLine."Document No." := DocumentNo;
        ServiceInvoiceLine.Description := LibraryUTUtility.GetNewCode();
        ServiceInvoiceLine.Quantity := LibraryRandom.RandDec(10, 2);
        ServiceInvoiceLine."No." := LibraryUTUtility.GetNewCode();
        ServiceInvoiceLine.Amount := LibraryRandom.RandDec(10, 2);
        ServiceInvoiceLine.Insert();
    end;

    local procedure CreateServiceLine(DocumentNo: Code[20])
    var
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
    begin
        ServiceItemLine."Document Type" := ServiceItemLine."Document Type"::Order;
        ServiceItemLine."Document No." := DocumentNo;
        ServiceItemLine.Insert();

        ServiceLine."Document Type" := ServiceItemLine."Document Type";
        ServiceLine."Document No." := DocumentNo;
        ServiceLine.Quantity := LibraryRandom.RandDec(10, 2);
        ServiceLine."Qty. to Invoice" := ServiceLine.Quantity;
        ServiceLine.Insert();
    end;

    local procedure CreateServiceCreditMemoHeader(var ServiceCrMemoHeader: Record "Service Cr.Memo Header"; CurrencyCode: Code[10]; YourReference: Text[35]; VATRegistrationNo: Code[20])
    begin
        ServiceCrMemoHeader."No." := LibraryUTUtility.GetNewCode();
        ServiceCrMemoHeader."Customer No." := CreateCustomer();
        ServiceCrMemoHeader."Bill-to Customer No." := ServiceCrMemoHeader."Customer No.";
        ServiceCrMemoHeader."Document Date" := WorkDate();
        ServiceCrMemoHeader."VAT Bus. Posting Group" := CreateVATBusinessPostingGroup();
        ServiceCrMemoHeader."Currency Code" := CurrencyCode;
        ServiceCrMemoHeader."Your Reference" := YourReference;
        ServiceCrMemoHeader."VAT Registration No." := VATRegistrationNo;
        ServiceCrMemoHeader.Insert();
    end;

    local procedure CreateServiceCreditMemoLine(DocumentNo: Code[20])
    var
        ServiceCrMemoLine: Record "Service Cr.Memo Line";
    begin
        ServiceCrMemoLine."Document No." := DocumentNo;
        ServiceCrMemoLine.Description := LibraryUTUtility.GetNewCode();
        ServiceCrMemoLine.Quantity := LibraryRandom.RandDec(10, 2);
        ServiceCrMemoLine."No." := LibraryUTUtility.GetNewCode();
        ServiceCrMemoLine.Amount := LibraryRandom.RandDec(10, 2);
        ServiceCrMemoLine.Insert();
    end;

    local procedure CreateVATBusinessPostingGroup(): Code[20]
    var
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
    begin
        VATBusinessPostingGroup.Code := LibraryUTUtility.GetNewCode10();
        VATBusinessPostingGroup."Check VAT Exemption" := true;
        VATBusinessPostingGroup.Insert();
        exit(VATBusinessPostingGroup.Code);
    end;

    local procedure CreateVATEntry(var VATEntry: Record "VAT Entry")
    var
        VATEntry2: Record "VAT Entry";
    begin
        VATEntry2.FindLast();
        VATEntry."Entry No." := VATEntry2."Entry No." + 1;
        VATEntry.Type := VATEntry.Type::Purchase;
        VATEntry."Operation Occurred Date" := WorkDate();
        VATEntry."Document Date" := WorkDate();
        VATEntry."VAT Bus. Posting Group" := LibraryUTUtility.GetNewCode10();
        VATEntry."VAT Prod. Posting Group" := LibraryUTUtility.GetNewCode10();
        VATEntry.Base := LibraryRandom.RandDec(10, 2);
        VATEntry."Plafond Entry" := true;
        VATEntry.Insert();
    end;

    local procedure CreateVATExemption(Type: Option; No: Code[20]; Printed: Boolean; VATExemptIntRegistryDate: Date): Code[20]
    var
        VATExemption: Record "VAT Exemption";
    begin
        CreateVATExemptionRec(VATExemption, Type, No, Printed, VATExemptIntRegistryDate);
        exit(VATExemption."VAT Exempt. No.");
    end;

    local procedure CreateVATExemptionWithIntRegNo(Type: Option; No: Code[20]; VATExemptIntRegistryDate: Date): Code[20]
    var
        VATExemption: Record "VAT Exemption";
    begin
        CreateVATExemptionRec(VATExemption, Type, No, false, VATExemptIntRegistryDate);
        exit(VATExemption."VAT Exempt. Int. Registry No.");
    end;

    local procedure CreateVATExemptionRec(var VATExemption: Record "VAT Exemption"; Type: Option; No: Code[20]; Printed: Boolean; VATExemptIntRegistryDate: Date)
    begin
        VATExemption.Type := Type;
        VATExemption."No." := No;
        VATExemption."VAT Exempt. Starting Date" := WorkDate();
        VATExemption."VAT Exempt. Ending Date" := WorkDate();
        VATExemption."VAT Exempt. Date" := WorkDate();
        VATExemption."VAT Exempt. Int. Registry No." := LibraryUTUtility.GetNewCode();
        VATExemption."VAT Exempt. Int. Registry Date" := VATExemptIntRegistryDate;
        VATExemption."VAT Exempt. No." := LibraryUTUtility.GetNewCode();
        VATExemption.Printed := Printed;
        VATExemption.Insert();
    end;

    local procedure CreateVATExemptionWithConsecutiveNo(Type: Option; No: Code[20]; Printed: Boolean; VATExemptIntRegistryDate: Date): Text
    var
        VATExemption: Record "VAT Exemption";
    begin
        CreateVATExemptionRec(VATExemption, Type, No, Printed, VATExemptIntRegistryDate);
        VATExemption.Validate("Consecutive VAT Exempt. No.", LibraryUtility.GenerateGUID());
        VATExemption.Modify(true);
        exit(VATExemption.GetVATExemptNo());
    end;

    local procedure CreateVATPlafondPeriod(): Decimal
    var
        VATPlafondPeriod: Record "VAT Plafond Period";
    begin
        VATPlafondPeriod.Year := Date2DMY(WorkDate(), 3);
        VATPlafondPeriod.Amount := LibraryRandom.RandDec(10, 2);
        VATPlafondPeriod.Insert();
        exit(VATPlafondPeriod.Amount);
    end;

    local procedure MockVendor(VendorNo: Code[20]; VendorName: Text[50])
    var
        Vendor: Record Vendor;
    begin
        Vendor.Init();
        Vendor."No." := VendorNo;
        Vendor.Name := VendorName;
        Vendor."VAT Registration No." := VendorNo;
        Vendor.Insert();
    end;

    local procedure FindCurrencyCode(CurrencyCode: Code[10]): Code[10]
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        if CurrencyCode = '' then
            exit(GeneralLedgerSetup."LCY Code");
        exit(CurrencyCode);
    end;

    local procedure EnqueueVATExemptionDetail(StartDate: Date; EndDate: Date; StartingPage: Integer; VATExemptionType: Text[30]; PrintType: Option)
    begin
        LibraryVariableStorage.Enqueue(StartDate);
        LibraryVariableStorage.Enqueue(EndDate);
        LibraryVariableStorage.Enqueue(StartingPage);
        LibraryVariableStorage.Enqueue(VATExemptionType);
        LibraryVariableStorage.Enqueue(PrintType);
    end;

    local procedure UpdateGeneralLedgerSetupLastSettlementDate()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Last Settlement Date" := CalcDate('<-1M+CM>', WorkDate());  // Last Settlement Date before Workdate.
        GeneralLedgerSetup.Modify();
    end;

    local procedure VerifyDocumentDetailAndVATExemptionOnReport(CurrencyCode: Code[10]; VATRegistrationNumberCap: Text; VATRegistrationNumber: Code[20]; YourReferenceCap: Text; YourReference: Code[20]; VATExemptionNumber: Code[20])
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(TotalTxt, StrSubstNo(TotalSubstituteStr, FindCurrencyCode(CurrencyCode)));
        LibraryReportDataset.AssertElementWithValueExists(VATRegistrationNumberCap, VATRegistrationNumber);
        LibraryReportDataset.AssertElementWithValueExists(YourReferenceCap, YourReference);
        LibraryReportDataset.AssertElementWithValueExists(VATExemptionNoCap, VATExemptionNumber);
    end;

    local procedure VerifyVATExemptionNumberAndDate(VATExemptNo: Code[20]; BillToCustomerNoCap: Text[50]; BillToCustomerNumber: Code[20])
    var
        VATExemption: Record "VAT Exemption";
    begin
        VATExemption.SetRange("VAT Exempt. No.", VATExemptNo);
        VATExemption.FindFirst();
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(BillToCustomerNoCap, BillToCustomerNumber);
        LibraryReportDataset.AssertElementWithValueExists(VATExemptionNumberCap, VATExemption."VAT Exempt. No.");
        LibraryReportDataset.AssertElementWithValueExists(VATExemptionDateCap, Format(VATExemption."VAT Exempt. Date"));
    end;

    local procedure VerifyDocumentVATExemptionOnReport(ElementName: Text; VATExemptionNumber: Text)
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(ElementName, VATExemptionNumber);
    end;

    local procedure VerifyPeriodProtocolNoEndingDate(VATExemptionNumber: Code[20]; PostingDate: Date)
    var
        VATExemption: Record "VAT Exemption";
    begin
        VATExemption.SetRange("VAT Exempt. No.", VATExemptionNumber);
        VATExemption.FindFirst();

        LibraryReportDataset.AssertElementWithValueExists(
          VATExemptionPeriodLbl,
          StrSubstNo(VATExemptionTypeTxt, VATExemption."VAT Exempt. Starting Date", VATExemption."VAT Exempt. Ending Date"));
        LibraryReportDataset.AssertElementWithValueExists(
          VATExemptionEndingDateLbl,
          Format(VATExemption."VAT Exempt. Ending Date"));
        LibraryReportDataset.AssertElementWithValueExists(
          VATExemptionOurProtocolNoLbl,
          StrSubstNo('%1 %2', VATExemption."VAT Exempt. Int. Registry No.", Format(PostingDate)));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CalcAndPostVATSettlementRequestPageHandler(var CalcAndPostVATSettlement: TestRequestPage "Calc. and Post VAT Settlement")
    var
        Post: Variant;
        SettlementAccount: Variant;
    begin
        LibraryVariableStorage.Dequeue(SettlementAccount);
        LibraryVariableStorage.Dequeue(Post);
        CalcAndPostVATSettlement.PostingDt.SetValue(CalcAndPostVATSettlement.EndingDate.Value);
        CalcAndPostVATSettlement.DocumentNo.SetValue(LibraryUTUtility.GetNewCode());
        CalcAndPostVATSettlement.SettlementAcc.SetValue(SettlementAccount);
        CalcAndPostVATSettlement.GLGainsAccount.SetValue(CreateGLAccount());
        CalcAndPostVATSettlement.GLLossesAccount.SetValue(CreateGLAccount());
        CalcAndPostVATSettlement.Post.SetValue(Post);
        CalcAndPostVATSettlement.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalesDocumentTestRequestPageHandler(var SalesDocumentTest: TestRequestPage "Sales Document - Test")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        SalesDocumentTest."Sales Header".SetFilter("No.", No);
        SalesDocumentTest.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ServiceCreditMemoRequestPageHandler(var ServiceCreditMemo: TestRequestPage "Service - Credit Memo")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        ServiceCreditMemo."Service Cr.Memo Header".SetFilter("No.", No);
        ServiceCreditMemo.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ServiceInvoiceRequestPageHandler(var ServiceInvoice: TestRequestPage "Service - Invoice")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        ServiceInvoice."Service Invoice Header".SetFilter("No.", No);
        ServiceInvoice.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ServiceDocumentTestRequestPageHandler(var ServiceDocumentTest: TestRequestPage "Service Document - Test")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        ServiceDocumentTest."Service Header".SetFilter("No.", No);
        ServiceDocumentTest.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VATExemptionRegisterRequestPageHandler(var VATExemptionRegister: TestRequestPage "VAT Exemption Register")
    var
        StartDate: Variant;
        EndDate: Variant;
        StartingPage: Variant;
        Type: Variant;
        PrintType: Variant;
    begin
        LibraryVariableStorage.Dequeue(StartDate);
        LibraryVariableStorage.Dequeue(EndDate);
        LibraryVariableStorage.Dequeue(StartingPage);
        LibraryVariableStorage.Dequeue(Type);
        LibraryVariableStorage.Dequeue(PrintType);
        VATExemptionRegister.ReportType.SetValue(PrintType);
        VATExemptionRegister.StartingDate.SetValue(StartDate);
        VATExemptionRegister.EndingDate.SetValue(EndDate);
        VATExemptionRegister.StartingYear.SetValue(Date2DMY(StartDate, 3));  // Set Starting Year.
        VATExemptionRegister.StartingPage.SetValue(StartingPage);
        VATExemptionRegister."VAT Exemption".SetFilter(Type, Type);
        VATExemptionRegister.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;
}
