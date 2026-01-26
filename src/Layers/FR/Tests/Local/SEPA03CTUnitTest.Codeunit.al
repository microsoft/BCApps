codeunit 144075 "SEPA.03 CT Unit Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [UT]
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryFRLocalization: Codeunit "Library - FR Localization";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        AmountMustBePositiveErr: Label 'The amount must be positive.';
        AppliedDocNoListErr: Label 'Wrong list of applied document numbers.';
        BufferEntryCountErr: Label 'Wrong count of export buffer entries.';
        PaymentExportSetupCode: Code[20];
        isInitialized: Boolean;
        EditableFieldErr: Label 'Wrong property Editable on Field %1.';
        ExportErrorTextErr: Label 'Wrong export error text. Expected:<%1> Actual:<%2>. ';
        FieldValueErr: Label 'Wrong value in <%1>.';
        JnlLinesHaveErrorsErr: Label 'The file export has one or more errors.';
        TransInEURAllowedErr: Label 'Only transactions in euro (EUR) are allowed';
        VisibleFieldErr: Label 'Wrong property Visible on Field %1.';

    [Test]
    [Scope('OnPrem')]
    procedure AppliedDocListCust()
    var
        PaymentLine: Record "Payment Line";
        CustLedgEntry: Record "Cust. Ledger Entry";
        DocumentNo: array[2] of Code[20];
    begin
        PaymentLine.Init();
        PaymentLine."Account Type" := PaymentLine."Account Type"::Customer;
        PaymentLine."Account No." := LibrarySales.CreateCustomerNo();
        PaymentLine."Applies-to ID" := LibraryUtility.GenerateGUID();

        DocumentNo[1] := InsertCustLedgEntry(CustLedgEntry, PaymentLine."Account No.", PaymentLine."Applies-to ID");
        DocumentNo[2] := InsertCustLedgEntry(CustLedgEntry, PaymentLine."Account No.", PaymentLine."Applies-to ID");

        VerifyAppliedDocNoList(PaymentLine, DocumentNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AppliedDocListVend()
    var
        PaymentLine: Record "Payment Line";
        VendLedgEntry: Record "Vendor Ledger Entry";
        DocumentNo: array[2] of Code[35];
    begin
        PaymentLine.Init();
        PaymentLine."Account Type" := PaymentLine."Account Type"::Vendor;
        PaymentLine."Account No." := LibraryPurchase.CreateVendorNo();
        PaymentLine."Applies-to ID" := LibraryUtility.GenerateGUID();

        DocumentNo[1] := InsertVendLedgEntry(VendLedgEntry, PaymentLine."Account No.", PaymentLine."Applies-to ID");
        DocumentNo[2] := InsertVendLedgEntry(VendLedgEntry, PaymentLine."Account No.", PaymentLine."Applies-to ID");

        VerifyAppliedDocNoList(PaymentLine, DocumentNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AppliedDocListEmptyCust()
    var
        PaymentLine: Record "Payment Line";
        CustLedgEntry: Record "Cust. Ledger Entry";
        DocumentNo: array[2] of Code[20];
    begin
        PaymentLine.Init();
        PaymentLine."Account Type" := PaymentLine."Account Type"::Customer;
        PaymentLine."Account No." := LibrarySales.CreateCustomerNo();
        PaymentLine."Applies-to ID" := '';
        PaymentLine."Applies-to Doc. No." := '';

        DocumentNo[1] := InsertCustLedgEntry(CustLedgEntry, PaymentLine."Account No.", PaymentLine."Applies-to ID");
        DocumentNo[2] := InsertCustLedgEntry(CustLedgEntry, PaymentLine."Account No.", PaymentLine."Applies-to ID");

        Assert.AreEqual('', PaymentLine.GetAppliedDocNoList(MaxStrLen(CustLedgEntry."Document No.")), AppliedDocNoListErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AppliedDocListEmptyVend()
    var
        PaymentLine: Record "Payment Line";
        VendLedgEntry: Record "Vendor Ledger Entry";
        DocumentNo: array[2] of Code[35];
    begin
        PaymentLine.Init();
        PaymentLine."Account Type" := PaymentLine."Account Type"::Vendor;
        PaymentLine."Account No." := LibraryPurchase.CreateVendorNo();
        PaymentLine."Applies-to ID" := '';
        PaymentLine."Applies-to Doc. No." := '';

        DocumentNo[1] := InsertVendLedgEntry(VendLedgEntry, PaymentLine."Account No.", PaymentLine."Applies-to ID");
        DocumentNo[2] := InsertVendLedgEntry(VendLedgEntry, PaymentLine."Account No.", PaymentLine."Applies-to ID");

        Assert.AreEqual('', PaymentLine.GetAppliedDocNoList(MaxStrLen(VendLedgEntry."Document No.")), AppliedDocNoListErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AppliedDocNoListCust()
    var
        PaymentLine: Record "Payment Line";
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        PaymentLine.Init();
        PaymentLine."Account Type" := PaymentLine."Account Type"::Customer;
        PaymentLine."Account No." := LibrarySales.CreateCustomerNo();

        InsertCustLedgEntry(CustLedgEntry, PaymentLine."Account No.", '');

        PaymentLine."Applies-to Doc. Type" := PaymentLine."Applies-to Doc. Type"::"Credit Memo";
        PaymentLine."Applies-to Doc. No." := CustLedgEntry."Document No.";

        Assert.AreEqual(
          CustLedgEntry."Document No.", PaymentLine.GetAppliedDocNoList(MaxStrLen(CustLedgEntry."Document No.")), AppliedDocNoListErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AppliedDocNoListVend()
    var
        PaymentLine: Record "Payment Line";
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 227892] Purchase invoice's "External Document No." is used as an applied Document No. for export (generate) payment slip file
        PaymentLine.Init();
        PaymentLine."Account Type" := PaymentLine."Account Type"::Vendor;
        PaymentLine."Account No." := LibraryPurchase.CreateVendorNo();

        InsertVendLedgEntry(VendLedgEntry, PaymentLine."Account No.", '');

        PaymentLine."Applies-to Doc. Type" := PaymentLine."Applies-to Doc. Type"::Invoice;
        PaymentLine."Applies-to Doc. No." := VendLedgEntry."Document No.";

        Assert.AreEqual(
          VendLedgEntry."External Document No.", PaymentLine.GetAppliedDocNoList(MaxStrLen(VendLedgEntry."External Document No.")),
          AppliedDocNoListErr);
    end;

    [Test]
    [HandlerFunctions('PaymentClassHandler')]
    [Scope('OnPrem')]
    procedure BankInfoEditableForGLAccount()
    var
        PaymentHeader: Record "Payment Header";
        PaymentLine: Record "Payment Line";
        Vendor: Record Vendor;
    begin
        Initialize();

        CreatePaymentHeader(PaymentHeader);
        CreatePaymentLineVend(PaymentLine, PaymentHeader."No.", Vendor);
        PaymentLine.Validate("Account Type", PaymentLine."Account Type"::"G/L Account");
        PaymentLine.Modify();

        VerifyBankInfoEditable(PaymentHeader, true);
    end;

    [Test]
    [HandlerFunctions('PaymentClassHandler')]
    [Scope('OnPrem')]
    procedure BankInfoNotEditableForCustomer()
    var
        Customer: Record Customer;
        PaymentHeader: Record "Payment Header";
        PaymentLine: Record "Payment Line";
    begin
        Initialize();

        CreatePaymentHeader(PaymentHeader);
        CreatePaymentLineCust(PaymentLine, PaymentHeader."No.", Customer);

        VerifyBankInfoEditable(PaymentHeader, false);
    end;

    [Test]
    [HandlerFunctions('PaymentClassHandler')]
    [Scope('OnPrem')]
    procedure BankInfoNotEditableForVendor()
    var
        PaymentHeader: Record "Payment Header";
        PaymentLine: Record "Payment Line";
        Vendor: Record Vendor;
    begin
        Initialize();

        CreatePaymentHeader(PaymentHeader);
        CreatePaymentLineVend(PaymentLine, PaymentHeader."No.", Vendor);

        VerifyBankInfoEditable(PaymentHeader, false);
    end;

    [Test]
    [HandlerFunctions('PaymentClassHandler')]
    [Scope('OnPrem')]
    procedure BankInfoNotVisibleWithNoRIBOnStatus()
    begin
        Initialize();

        BankInfoVisibleDependsOnRIB(false);
    end;

    [Test]
    [HandlerFunctions('PaymentClassHandler')]
    [Scope('OnPrem')]
    procedure BankInfoVisibleWithRIBOnStatus()
    begin
        Initialize();

        BankInfoVisibleDependsOnRIB(true);
    end;

    [Test]
    [HandlerFunctions('PaymentClassHandler')]
    [Scope('OnPrem')]
    procedure CustVendLinesInBuffer()
    var
        Customer: Record Customer;
        PaymentHeader: Record "Payment Header";
        PaymentLineCust: Record "Payment Line";
        PaymentLineVend: Record "Payment Line";
        TempPaymentExportData: Record "Payment Export Data" temporary;
        Vendor: Record Vendor;
    begin
        Initialize();

        CreatePaymentHeader(PaymentHeader);
        CreatePaymentLineCust(PaymentLineCust, PaymentHeader."No.", Customer);
        CreatePaymentLineVend(PaymentLineVend, PaymentHeader."No.", Vendor);

        FillExportBuffer(PaymentHeader."No.", TempPaymentExportData);

        Assert.AreEqual(2, TempPaymentExportData.Count, BufferEntryCountErr);
        TempPaymentExportData.FindFirst();
        Assert.AreEqual(
          Customer.Name, TempPaymentExportData."Recipient Name",
          StrSubstNo(FieldValueErr, TempPaymentExportData.FieldName("Recipient Name")));
        Assert.AreEqual(
          PaymentLineCust.Amount, TempPaymentExportData.Amount,
          StrSubstNo(FieldValueErr, TempPaymentExportData.FieldName(Amount)));
        TempPaymentExportData.FindLast();
        Assert.AreEqual(
          Vendor.Name, TempPaymentExportData."Recipient Name",
          StrSubstNo(FieldValueErr, TempPaymentExportData.FieldName("Recipient Name")));
        Assert.AreEqual(
          PaymentLineVend.Amount, TempPaymentExportData.Amount,
          StrSubstNo(FieldValueErr, TempPaymentExportData.FieldName(Amount)));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeletePaymentLineWithExportErrors()
    var
        PaymentLine: Record "Payment Line";
        PaymentJnlExportErrorText: Record "Payment Jnl. Export Error Text";
    begin
        Initialize();

        InsertPaymentLinesWithExportErrors(PaymentLine, LibraryUtility.GenerateGUID(), 3);

        PaymentJnlExportErrorText.SetRange("Journal Template Name", '');
        PaymentJnlExportErrorText.SetRange("Journal Batch Name", Format(DATABASE::"Payment Header"));
        PaymentJnlExportErrorText.SetRange("Document No.", PaymentLine."No.");
        PaymentJnlExportErrorText.SetRange("Journal Line No.", PaymentLine."Line No.");
        Assert.AreEqual(3, PaymentJnlExportErrorText.Count, 'Wrong Error Text count');

        PaymentLine.Delete(true);
        Assert.AreEqual(0, PaymentJnlExportErrorText.Count, 'Should not be Error Text records');

        PaymentJnlExportErrorText.SetRange("Journal Line No.");
        Assert.AreEqual(6, PaymentJnlExportErrorText.Count, 'Wrong remaining Error Text count');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeletePaymentSlipWithExportErrors()
    var
        PaymentHeader: Record "Payment Header";
        PaymentLine: Record "Payment Line";
        PaymentJnlExportErrorText: Record "Payment Jnl. Export Error Text";
        NotDeletedDocumentNo: Code[20];
    begin
        Initialize();

        InsertPaymentLinesWithExportErrors(PaymentLine, LibraryUtility.GenerateGUID(), 1);
        NotDeletedDocumentNo := PaymentLine."No.";

        PaymentHeader."No." := LibraryUtility.GenerateGUID();
        PaymentHeader.Insert();
        InsertPaymentLinesWithExportErrors(PaymentLine, PaymentHeader."No.", 2);

        PaymentJnlExportErrorText.SetRange("Journal Template Name", '');
        PaymentJnlExportErrorText.SetRange("Journal Batch Name", Format(DATABASE::"Payment Header"));
        PaymentJnlExportErrorText.SetRange("Document No.", PaymentHeader."No.");
        Assert.AreEqual(6, PaymentJnlExportErrorText.Count, 'Wrong Error Text count');

        PaymentHeader.Delete(true);
        Assert.AreEqual(0, PaymentJnlExportErrorText.Count, 'Should not be Error Text records');

        PaymentJnlExportErrorText.SetRange("Document No.", NotDeletedDocumentNo);
        Assert.AreEqual(3, PaymentJnlExportErrorText.Count, 'Wrong not deleted Error Text count');
    end;

    [Test]
    [HandlerFunctions('PaymentClassHandler')]
    [Scope('OnPrem')]
    procedure ExportErrorOnPaymentSlipPage()
    var
        PaymentHeader: Record "Payment Header";
        PaymentLine: Record "Payment Line";
        TempPaymentExportData: Record "Payment Export Data" temporary;
        Vendor: Record Vendor;
        PaymentSlip: TestPage "Payment Slip";
    begin
        Initialize();

        CreatePaymentHeader(PaymentHeader);
        CreatePaymentLineVend(PaymentLine, PaymentHeader."No.", Vendor);
        PaymentLine.Amount := -PaymentLine.Amount;
        PaymentLine.Modify();

        asserterror FillExportBuffer(PaymentHeader."No.", TempPaymentExportData);
        Assert.ExpectedError(JnlLinesHaveErrorsErr);

        PaymentSlip.OpenEdit();
        PaymentSlip.GotoKey(PaymentHeader."No.");
        PaymentSlip.Lines.First();
        PaymentSlip.Lines."Has Payment Export Error".AssertEquals(true);
        PaymentSlip."Payment Journal Errors".First();
        PaymentSlip."Payment Journal Errors"."Error Text".AssertEquals(AmountMustBePositiveErr);
        Assert.IsFalse(PaymentSlip."Payment Journal Errors".Next(), 'Just one error expected');
        PaymentSlip.Close();
    end;

    [Test]
    [HandlerFunctions('PaymentClassHandler')]
    [Scope('OnPrem')]
    procedure NonEURPmtLineInBuffer()
    var
        PaymentHeader: Record "Payment Header";
        PaymentLine: Record "Payment Line";
        PaymentJnlExportErrorText: Record "Payment Jnl. Export Error Text";
        TempPaymentExportData: Record "Payment Export Data" temporary;
        Vendor: Record Vendor;
    begin
        Initialize();

        CreatePaymentHeader(PaymentHeader);
        PaymentHeader.Validate("Currency Code", FindCurrency());
        PaymentHeader.Modify(true);
        CreatePaymentLineVend(PaymentLine, PaymentHeader."No.", Vendor);

        asserterror FillExportBuffer(PaymentHeader."No.", TempPaymentExportData);
        Assert.ExpectedError(JnlLinesHaveErrorsErr);

        PaymentJnlExportErrorText.SetRange("Journal Template Name", '');
        PaymentJnlExportErrorText.SetRange("Journal Batch Name", Format(DATABASE::"Payment Header"));
        PaymentJnlExportErrorText.SetRange("Document No.", PaymentLine."No.");
        PaymentJnlExportErrorText.SetRange("Journal Line No.", PaymentLine."Line No.");
        Assert.AreEqual(1, PaymentJnlExportErrorText.Count, BufferEntryCountErr);
        PaymentJnlExportErrorText.FindFirst();
        Assert.IsTrue(
          StrPos(PaymentJnlExportErrorText."Error Text", TransInEURAllowedErr) <> 0,
          StrSubstNo(ExportErrorTextErr, TransInEURAllowedErr, PaymentJnlExportErrorText."Error Text"));
    end;

    [Test]
    [HandlerFunctions('PaymentClassHandler')]
    [Scope('OnPrem')]
    procedure OnePmtLineInBuffer()
    var
        PaymentHeader: Record "Payment Header";
        PaymentLine: Record "Payment Line";
        Vendor: Record Vendor;
        TempPaymentExportData: Record "Payment Export Data" temporary;
    begin
        Initialize();

        CreatePaymentHeader(PaymentHeader);
        CreatePaymentLineVend(PaymentLine, PaymentHeader."No.", Vendor);

        FillExportBuffer(PaymentHeader."No.", TempPaymentExportData);

        Assert.AreEqual(1, TempPaymentExportData.Count, BufferEntryCountErr);
        Assert.AreEqual(
          PaymentLine.Amount, TempPaymentExportData.Amount,
          StrSubstNo(FieldValueErr, TempPaymentExportData.FieldName(Amount)));
        Assert.AreEqual(
          'EUR', TempPaymentExportData."Currency Code",
          StrSubstNo(FieldValueErr, TempPaymentExportData.FieldName("Currency Code")));
    end;

    [Test]
    [HandlerFunctions('PaymentStepsLookupHandler,ConfirmationNoHandler')]
    [Scope('OnPrem')]
    procedure PickOneOfManyPaymentSteps()
    var
        PaymentHeader: Record "Payment Header";
        PaymentStep: Record "Payment Step";
        PaymentMgt: Codeunit "Payment Management";
        ExpectedPickedLine: Integer;
    begin
        Initialize();

        PrepareHeaderWithNoReportSteps(PaymentHeader, PaymentStep);

        AddPaymentStep(PaymentHeader, PaymentStep."Action Type"::Report, PaymentStep);
        ExpectedPickedLine := PaymentStep.Line;

        PaymentStep.SetRange("Action Type", PaymentStep."Action Type"::Report);
        Assert.IsFalse(PaymentMgt.PickPaymentStep(PaymentHeader, PaymentStep), '1 Step. Not confirmed');

        AddPaymentStep(PaymentHeader, PaymentStep."Action Type"::Report, PaymentStep);

        PaymentStep.SetRange("Action Type", PaymentStep."Action Type"::Report);
        Assert.IsTrue(PaymentMgt.PickPaymentStep(PaymentHeader, PaymentStep), '2 Steps. Pick first');
        Assert.AreEqual(ExpectedPickedLine, PaymentStep.Line, 'Wrong pick');
    end;

    [Test]
    [HandlerFunctions('ConfirmationYesHandler')]
    [Scope('OnPrem')]
    procedure PickOnePaymentStep()
    var
        PaymentHeader: Record "Payment Header";
        PaymentStep: Record "Payment Step";
        PaymentMgt: Codeunit "Payment Management";
        ExpectedPickedLine: Integer;
    begin
        Initialize();

        PrepareHeaderWithNoReportSteps(PaymentHeader, PaymentStep);

        PaymentStep.SetRange("Action Type", PaymentStep."Action Type"::Report);
        Assert.IsFalse(PaymentMgt.PickPaymentStep(PaymentHeader, PaymentStep), 'No Steps to pick');

        AddPaymentStep(PaymentHeader, PaymentStep."Action Type"::Report, PaymentStep);
        ExpectedPickedLine := PaymentStep.Line;

        PaymentStep.SetRange("Action Type", PaymentStep."Action Type"::Report);
        Assert.IsTrue(PaymentMgt.PickPaymentStep(PaymentHeader, PaymentStep), '1 Step. Confirmed');
        Assert.AreEqual(ExpectedPickedLine, PaymentStep.Line, 'Wrong pick');
    end;

    [Test]
    [HandlerFunctions('PaymentClassHandler')]
    [Scope('OnPrem')]
    procedure ThreePmtLinesInBuffer()
    var
        PaymentHeader: Record "Payment Header";
        PaymentLine: Record "Payment Line";
        Vendor: Record Vendor;
        TempPaymentExportData: Record "Payment Export Data" temporary;
    begin
        Initialize();

        CreatePaymentHeader(PaymentHeader);
        CreatePaymentLineVend(PaymentLine, PaymentHeader."No.", Vendor);
        CreatePaymentLineVend(PaymentLine, PaymentHeader."No.", Vendor);
        CreatePaymentLineVend(PaymentLine, PaymentHeader."No.", Vendor);

        FillExportBuffer(PaymentHeader."No.", TempPaymentExportData);

        Assert.AreEqual(3, TempPaymentExportData.Count, BufferEntryCountErr);
        TempPaymentExportData.FindLast();
        Assert.AreEqual(
          Vendor.Name, TempPaymentExportData."Recipient Name",
          StrSubstNo(FieldValueErr, TempPaymentExportData.FieldName("Recipient Name")));
        Assert.AreEqual(
          PaymentLine.Amount, TempPaymentExportData.Amount,
          StrSubstNo(FieldValueErr, TempPaymentExportData.FieldName(Amount)));
    end;

    [Test]
    [HandlerFunctions('PaymentClassHandler')]
    [Scope('OnPrem')]
    procedure RecipientIsPassedToBuffer()
    var
        PaymentHeader: Record "Payment Header";
        PaymentLine: Record "Payment Line";
        Vendor: Record Vendor;
        TempPaymentExportData: Record "Payment Export Data" temporary;
    begin
        Initialize();

        CreatePaymentHeader(PaymentHeader);
        CreatePaymentLineVend(PaymentLine, PaymentHeader."No.", Vendor);

        FillExportBuffer(PaymentHeader."No.", TempPaymentExportData);

        TempPaymentExportData.FindFirst();
        // Recipient
        Assert.AreEqual(
          Vendor.Name, TempPaymentExportData."Recipient Name",
          StrSubstNo(FieldValueErr, TempPaymentExportData.FieldName("Recipient Name")));
        Assert.AreEqual(
          Vendor.Address, TempPaymentExportData."Recipient Address",
          StrSubstNo(FieldValueErr, TempPaymentExportData.FieldName("Recipient Address")));
        Assert.AreEqual(
          Vendor."Post Code", TempPaymentExportData."Recipient Post Code",
          StrSubstNo(FieldValueErr, TempPaymentExportData.FieldName("Recipient Post Code")));
        Assert.AreEqual(
          Vendor.City, TempPaymentExportData."Recipient City",
          StrSubstNo(FieldValueErr, TempPaymentExportData.FieldName("Recipient City")));
        Assert.AreEqual(
          Vendor."Country/Region Code", TempPaymentExportData."Recipient Country/Region Code",
          StrSubstNo(FieldValueErr, TempPaymentExportData.FieldName("Recipient Country/Region Code")));
        // Recipient Bank
        Assert.AreEqual(
          DelChr(PaymentLine."SWIFT Code"), TempPaymentExportData."Recipient Bank BIC",
          StrSubstNo(FieldValueErr, TempPaymentExportData.FieldName("Recipient Bank BIC")));
        Assert.AreEqual(
          DelChr(PaymentLine.IBAN), TempPaymentExportData."Recipient Bank Acc. No.",
          StrSubstNo(FieldValueErr, TempPaymentExportData.FieldName("Recipient Bank Acc. No.")));
    end;

    [Test]
    [HandlerFunctions('PaymentClassHandler')]
    [Scope('OnPrem')]
    procedure SenderIsPassedToBuffer()
    var
        PaymentHeader: Record "Payment Header";
        PaymentLine: Record "Payment Line";
        Vendor: Record Vendor;
        TempPaymentExportData: Record "Payment Export Data" temporary;
    begin
        Initialize();

        CreatePaymentHeader(PaymentHeader);
        CreatePaymentLineVend(PaymentLine, PaymentHeader."No.", Vendor);

        FillExportBuffer(PaymentHeader."No.", TempPaymentExportData);

        TempPaymentExportData.FindFirst();
        // Sender Bank
        Assert.AreEqual(
          DelChr(PaymentHeader."SWIFT Code"), TempPaymentExportData."Sender Bank BIC",
          StrSubstNo(FieldValueErr, TempPaymentExportData.FieldName("Recipient Bank BIC")));
        Assert.AreEqual(
          DelChr(PaymentHeader.IBAN), TempPaymentExportData."Sender Bank Account No.",
          StrSubstNo(FieldValueErr, TempPaymentExportData.FieldName("Recipient Bank Acc. No.")));
    end;

    [Test]
    [HandlerFunctions('PaymentClassHandler')]
    [Scope('OnPrem')]
    procedure TransferDateWhenNoAppliesTo()
    var
        PaymentHeader: Record "Payment Header";
        PaymentLine: Record "Payment Line";
        Vendor: Record Vendor;
        TempPaymentExportData: Record "Payment Export Data" temporary;
    begin
        Initialize();

        CreatePaymentHeader(PaymentHeader);
        CreatePaymentLineVend(PaymentLine, PaymentHeader."No.", Vendor);

        FillExportBuffer(PaymentHeader."No.", TempPaymentExportData);

        TempPaymentExportData.FindFirst();
        Assert.AreEqual(
          PaymentLine."Posting Date", TempPaymentExportData."Transfer Date",
          StrSubstNo(FieldValueErr, TempPaymentExportData.FieldName("Transfer Date")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PaymentStepsNewActionAvailable()
    var
        PaymentStep: Record "Payment Step";
        PaymentSteps: TestPage "Payment Steps";
        "Code": Code[20];
    begin
        // [FEATURE] [UI] [Payment Step]
        // [SCENARIO 263818] New action must be available at Payment Steps page
        Initialize();

        // [GIVEN] Payment Steps page
        PaymentSteps.OpenEdit();

        // [WHEN] Click New
        PaymentSteps.New();

        // [THEN] New Payment Step record created
        Code := LibraryUtility.GenerateGUID();
        PaymentSteps.Name.Value := Code;
        PaymentSteps.OK().Invoke();

        PaymentStep.SetRange(Name, Code);
        PaymentStep.FindFirst();
    end;

    local procedure Initialize()
    var
        BankExportImportSetup: Record "Bank Export/Import Setup";
    begin
        if not isInitialized then begin
            PaymentExportSetupCode := 'SEPA exp setup';
            BankExportImportSetup.Init();
            BankExportImportSetup.Code := PaymentExportSetupCode;
            BankExportImportSetup."Preserve Non-Latin Characters" := true;
            BankExportImportSetup."Check Export Codeunit" := CODEUNIT::"SEPA CT-Check Line";
            BankExportImportSetup.Insert();
            isInitialized := true;
        end;
    end;

    local procedure AddPaymentStep(PaymentHeader: Record "Payment Header"; ActionType: Enum "Payment Step Action Type"; var PaymentStep: Record "Payment Step")
    begin
        PaymentStep."Payment Class" := PaymentHeader."Payment Class";
        PaymentStep."Previous Status" := PaymentHeader."Status No.";
        PaymentStep."Action Type" := ActionType;
        PaymentStep.Line += 1;
        PaymentStep.Insert();
    end;

    local procedure BankInfoVisibleDependsOnRIB(RIB: Boolean)
    var
        PaymentHeader: Record "Payment Header";
        PaymentLine: Record "Payment Line";
        PaymentStatus: Record "Payment Status";
        Vendor: Record Vendor;
    begin
        CreatePaymentHeader(PaymentHeader);
        CreatePaymentLineVend(PaymentLine, PaymentHeader."No.", Vendor);
        PaymentStatus.Get(PaymentHeader."Payment Class", PaymentHeader."Status No.");
        PaymentStatus.RIB := RIB;
        PaymentStatus.Modify();

        VerifyBankInfoVisible(PaymentHeader, RIB);
    end;

    local procedure CreateBankAccount(): Code[20]
    var
        BankAccount: Record "Bank Account";
        NoSeries: Record "No. Series";
    begin
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount.Validate(IBAN, 'FR14 2004 1010 0505 0001 3M02 606');
        BankAccount.Validate("SWIFT Code", LibraryUtility.GenerateGUID());
        BankAccount.Validate("Bank Account No.", LibraryUtility.GenerateGUID());
        BankAccount."Payment Export Format" := PaymentExportSetupCode;
        NoSeries.FindFirst();
        BankAccount.Validate("Credit Transfer Msg. Nos.", NoSeries.Code);
        BankAccount.Modify(true);
        exit(BankAccount."No.");
    end;

    local procedure CreatePaymentClass(var PaymentClass: Record "Payment Class")
    var
        NoSeries: Record "No. Series";
        PaymentStatus: Record "Payment Status";
    begin
        NoSeries.FindFirst();
        LibraryFRLocalization.CreatePaymentClass(PaymentClass);
        PaymentClass.Validate(Name, '');
        PaymentClass.Validate("Header No. Series", NoSeries.Code);
        PaymentClass.Validate(Enable, true);
        PaymentClass.Validate(Suggestions, PaymentClass.Suggestions::Vendor);
        PaymentClass.Validate("SEPA Transfer Type", PaymentClass."SEPA Transfer Type"::"Credit Transfer");
        PaymentClass.Modify(true);

        LibraryFRLocalization.CreatePaymentStatus(PaymentStatus, PaymentClass.Code);
    end;

    local procedure CreatePaymentHeader(var PaymentHeader: Record "Payment Header")
    var
        PaymentClass: Record "Payment Class";
    begin
        CreatePaymentClass(PaymentClass);
        LibraryVariableStorage.Enqueue(PaymentClass.Code);
        LibraryFRLocalization.CreatePaymentHeader(PaymentHeader);
        PaymentHeader."Account Type" := PaymentHeader."Account Type"::"Bank Account";
        PaymentHeader.Validate("Account No.", CreateBankAccount());
        PaymentHeader.Modify(true);
    end;

    local procedure CreatePaymentLineCust(var PaymentLine: Record "Payment Line"; PaymentDocNo: Code[20]; var Customer: Record Customer)
    begin
        LibraryFRLocalization.CreatePaymentLine(PaymentLine, PaymentDocNo);
        PaymentLine."Account Type" := PaymentLine."Account Type"::Customer;
        LibrarySales.CreateCustomer(Customer);
        PaymentLine.Validate("Account No.", Customer."No.");
        CreateCustomerBankAccount(Customer."No."); // create two bank accounts and pick the second one
        PaymentLine.Validate("Bank Account Code", CreateCustomerBankAccount(Customer."No."));
        PaymentLine.Validate(Amount, LibraryRandom.RandDec(1000, 2));
        PaymentLine.Modify();
    end;

    local procedure CreatePaymentLineVend(var PaymentLine: Record "Payment Line"; PaymentDocNo: Code[20]; var Vendor: Record Vendor)
    begin
        LibraryFRLocalization.CreatePaymentLine(PaymentLine, PaymentDocNo);
        PaymentLine."Account Type" := PaymentLine."Account Type"::Vendor;
        Clear(Vendor);
        LibraryPurchase.CreateVendor(Vendor);
        PaymentLine.Validate("Account No.", Vendor."No.");
        CreateVendorBankAccount(Vendor."No."); // create two bank accounts and pick the second one
        PaymentLine.Validate("Bank Account Code", CreateVendorBankAccount(Vendor."No."));
        PaymentLine.Validate(Amount, LibraryRandom.RandDec(1000, 2));
        PaymentLine.Modify();
    end;

    local procedure CreateCustomerBankAccount(CustomerNo: Code[20]): Code[10]
    var
        CustomerBankAccount: Record "Customer Bank Account";
    begin
        LibrarySales.CreateCustomerBankAccount(CustomerBankAccount, CustomerNo);
        CustomerBankAccount.Validate(IBAN, 'FR29 4515 9000 053J 1300 0000 051');
        CustomerBankAccount."SWIFT Code" := LibraryUtility.GenerateGUID();
        CustomerBankAccount.Name := 'CustomerBankAcc';
        CustomerBankAccount.Modify(true);
        exit(CustomerBankAccount.Code);
    end;

    local procedure CreateVendorBankAccount(VendorNo: Code[20]): Code[10]
    var
        VendorBankAccount: Record "Vendor Bank Account";
    begin
        LibraryPurchase.CreateVendorBankAccount(VendorBankAccount, VendorNo);
        VendorBankAccount.Validate(IBAN, 'FR29 4515 9000 053J 1300 0000 051');
        VendorBankAccount."SWIFT Code" := LibraryUtility.GenerateGUID();
        VendorBankAccount.Name := 'VendorBankAcc';
        VendorBankAccount.Modify(true);
        exit(VendorBankAccount.Code);
    end;

    local procedure FillExportBuffer(PaymentDocNo: Code[20]; var PaymentExportData: Record "Payment Export Data")
    var
        GenJnlLine: Record "Gen. Journal Line";
        SEPACTFillExportBuffer: Codeunit "SEPA CT-Fill Export Buffer";
    begin
        GenJnlLine.SetRange("Document No.", PaymentDocNo);
        SEPACTFillExportBuffer.FillExportBuffer(GenJnlLine, PaymentExportData);
    end;

    local procedure FindCurrency(): Code[10]
    var
        Currency: Record Currency;
    begin
        LibraryERM.FindCurrency(Currency);
        exit(Currency.Code);
    end;

    local procedure InsertCustLedgEntry(var CustLedgEntry: Record "Cust. Ledger Entry"; CustomerNo: Code[20]; AppliesToID: Code[20]): Code[20]
    begin
        PostSalesCreditMemo(CustLedgEntry, CustomerNo, LibraryRandom.RandDec(1000, 2));
        CustLedgEntry."Applies-to ID" := AppliesToID;
        CustLedgEntry.Modify();
        exit(CustLedgEntry."Document No.");
    end;

    local procedure InsertVendLedgEntry(var VendLedgEntry: Record "Vendor Ledger Entry"; VendorNo: Code[20]; AppliesToID: Code[20]): Code[35]
    begin
        PostPurchaseInvoice(VendLedgEntry, VendorNo, LibraryRandom.RandDec(1000, 2));
        VendLedgEntry."Applies-to ID" := AppliesToID;
        VendLedgEntry.Modify();
        exit(VendLedgEntry."External Document No.");
    end;

    local procedure InsertPaymentLinesWithExportErrors(var PaymentLine: Record "Payment Line"; DocumentNo: Code[20]; NoOfLines: Integer)
    var
        PaymentJnlExportErrorText: Record "Payment Jnl. Export Error Text";
        I: Integer;
        ErrorLineNo: Integer;
    begin
        for I := 1 to NoOfLines do begin
            PaymentLine.Init();
            PaymentLine."No." := DocumentNo;
            PaymentLine."Line No." += 10000;
            PaymentLine.Insert();

            PaymentJnlExportErrorText.Init();
            PaymentJnlExportErrorText."Journal Template Name" := '';
            PaymentJnlExportErrorText."Journal Batch Name" := Format(DATABASE::"Payment Header");
            PaymentJnlExportErrorText."Document No." := PaymentLine."No.";
            PaymentJnlExportErrorText."Journal Line No." := PaymentLine."Line No.";
            for ErrorLineNo := 1 to 3 do begin
                PaymentJnlExportErrorText."Line No." := ErrorLineNo;
                PaymentJnlExportErrorText.Insert();
            end;
        end;
    end;

    local procedure PostDocument(DocumentType: Enum "Gen. Journal Document Type"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; LineAmount: Decimal): Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
        GLAccount: Record "G/L Account";
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
    begin
        GenJournalLine.Init();
        GenJournalLine.Validate("Posting Date", Today);
        GenJournalLine.Validate("Document Type", DocumentType);
        GenJournalLine.Validate("Account Type", AccountType);
        GenJournalLine.Validate("Account No.", AccountNo);
        GenJournalLine.Validate(Amount, -LineAmount);
        GenJournalLine.Validate(
          "Document No.", LibraryUtility.GenerateRandomCode(GenJournalLine.FieldNo("Document No."), DATABASE::"Gen. Journal Line"));
        GenJournalLine.Validate(
          "External Document No.",
          CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(GenJournalLine."External Document No.")), 1, MaxStrLen(GenJournalLine."External Document No.")));
        GenJournalLine.Validate("Source Code", LibraryERM.FindGeneralJournalSourceCode());
        // Unused but required for AU, NZ builds
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"G/L Account");
        if GenJournalLine."Account Type" = GenJournalLine."Account Type"::Customer then
            GLAccount.SetRange("Gen. Posting Type", GLAccount."Gen. Posting Type"::Sale)
        else
            GLAccount.SetRange("Gen. Posting Type", GLAccount."Gen. Posting Type"::Purchase);
        LibraryERM.FindGLAccount(GLAccount);
        GenJournalLine.Validate("Bal. Account No.", GLAccount."No.");

        GenJnlPostLine.RunWithCheck(GenJournalLine);
        exit(GenJournalLine."Document No.");
    end;

    local procedure PostPurchaseInvoice(var VendLedgEntry: Record "Vendor Ledger Entry"; VendorNo: Code[20]; Amount: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
        DocumentNo: Code[20];
    begin
        DocumentNo := PostDocument(GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Vendor, VendorNo, Amount);
        VendLedgEntry.SetRange("Document No.", DocumentNo);
        VendLedgEntry.FindLast();
    end;

    local procedure PostSalesCreditMemo(var CustLedgEntry: Record "Cust. Ledger Entry"; CustomerNo: Code[20]; Amount: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
        DocumentNo: Code[20];
    begin
        DocumentNo :=
          PostDocument(GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Account Type"::Customer, CustomerNo, Amount);
        CustLedgEntry.SetRange("Document No.", DocumentNo);
        CustLedgEntry.FindLast();
    end;

    local procedure PrepareHeaderWithNoReportSteps(var PaymentHeader: Record "Payment Header"; var PaymentStep: Record "Payment Step")
    begin
        PaymentHeader."Payment Class" := LibraryUtility.GenerateGUID();
        PaymentHeader."Status No." := 0;

        PaymentStep.SetRange("Payment Class", PaymentHeader."Payment Class");
        PaymentStep.DeleteAll();

        AddPaymentStep(PaymentHeader, PaymentStep."Action Type"::None, PaymentStep);
        AddPaymentStep(PaymentHeader, PaymentStep."Action Type"::File, PaymentStep);
        AddPaymentStep(PaymentHeader, PaymentStep."Action Type"::Ledger, PaymentStep);
        AddPaymentStep(PaymentHeader, PaymentStep."Action Type"::"Create New Document", PaymentStep);
    end;

    local procedure VerifyAppliedDocNoList(PaymentLine: Record "Payment Line"; DocumentNo: array[2] of Code[35])
    var
        Delimiter: Text[2];
        ExpectedList: Text;
        List: Text;
        TotalLen: Integer;
    begin
        Delimiter := ', ';
        ExpectedList := DocumentNo[1] + Delimiter + DocumentNo[2];
        TotalLen := StrLen(ExpectedList);

        List := PaymentLine.GetAppliedDocNoList(TotalLen);
        // 'docno000001, docno000002|'
        Assert.AreEqual(ExpectedList, List, AppliedDocNoListErr);

        List := PaymentLine.GetAppliedDocNoList(TotalLen + 1);
        // 'docno000001, docno000002 |'
        Assert.AreEqual(ExpectedList, List, AppliedDocNoListErr);

        List := PaymentLine.GetAppliedDocNoList(0);
        // '|docno000001, docno000002'
        Assert.AreEqual(ExpectedList, List, AppliedDocNoListErr);

        List := PaymentLine.GetAppliedDocNoList(-1);
        // | 'docno000001, docno000002'
        Assert.AreEqual(ExpectedList, List, AppliedDocNoListErr);

        List := PaymentLine.GetAppliedDocNoList(1);
        // ' |docno000001, docno000002'
        Assert.AreEqual(' ' + ExpectedList, List, AppliedDocNoListErr);

        List := PaymentLine.GetAppliedDocNoList(TotalLen - 1);
        // 'docno000001           |docno000002'
        Assert.AreEqual(DocumentNo[1], DelChr(CopyStr(List, 1, TotalLen - 1)), AppliedDocNoListErr);
        Assert.AreEqual(DocumentNo[2], DelChr(CopyStr(List, TotalLen)), AppliedDocNoListErr);
    end;

    local procedure VerifyBankInfoEditable(PaymentHeader: Record "Payment Header"; Editable: Boolean)
    var
        PaymentLine: Record "Payment Line";
        PaymentSlip: TestPage "Payment Slip";
    begin
        PaymentSlip.OpenEdit();
        PaymentSlip.GotoRecord(PaymentHeader);
        PaymentSlip.Lines.First();
        Assert.IsTrue(
          PaymentSlip.Lines."Bank Account Code".Editable(), StrSubstNo(EditableFieldErr, PaymentLine.FieldCaption("Bank Account Code")));
        Assert.AreEqual(Editable, PaymentSlip.Lines.IBAN.Editable(), StrSubstNo(EditableFieldErr, PaymentLine.FieldCaption(IBAN)));
        Assert.AreEqual(
          Editable, PaymentSlip.Lines."SWIFT Code".Editable(), StrSubstNo(EditableFieldErr, PaymentLine.FieldCaption("SWIFT Code")));
        Assert.AreEqual(
          Editable, PaymentSlip.Lines."Bank Account Name".Editable(),
          StrSubstNo(EditableFieldErr, PaymentLine.FieldCaption("Bank Account Name")));
        Assert.AreEqual(
          Editable, PaymentSlip.Lines."Bank Account No.".Editable(), StrSubstNo(EditableFieldErr, PaymentLine.FieldCaption("Bank Account No.")));
        Assert.AreEqual(
          Editable, PaymentSlip.Lines."Bank Branch No.".Editable(), StrSubstNo(EditableFieldErr, PaymentLine.FieldCaption("Bank Branch No.")));
        Assert.AreEqual(
          Editable, PaymentSlip.Lines."Agency Code".Editable(), StrSubstNo(EditableFieldErr, PaymentLine.FieldCaption("Agency Code")));
        Assert.AreEqual(Editable, PaymentSlip.Lines."RIB Key".Editable(), StrSubstNo(EditableFieldErr, PaymentLine.FieldCaption("RIB Key")));
        // "Bank City" is not visible by default, so "Bank City".EDITABLE is not supported.
        // Assert.AreEqual(Editable,PaymentSlip.Lines."Bank City".Editable(),STRSUBSTNO(NotEditableFieldErr,PaymentLine.FIELDCAPTION("Bank City")));
    end;

    local procedure VerifyBankInfoVisible(PaymentHeader: Record "Payment Header"; RIB: Boolean)
    var
        PaymentLine: Record "Payment Line";
        PaymentSlip: TestPage "Payment Slip";
    begin
        PaymentSlip.OpenEdit();
        PaymentSlip.GotoRecord(PaymentHeader);
        PaymentSlip.Lines.First();
        Assert.AreEqual(
          RIB, PaymentSlip.Lines."Bank Account Name".Visible(), StrSubstNo(VisibleFieldErr, PaymentLine.FieldCaption("Bank Account Name")));
        Assert.AreEqual(
          RIB, PaymentSlip.Lines."Bank Account No.".Visible(), StrSubstNo(VisibleFieldErr, PaymentLine.FieldCaption("Bank Account No.")));
        Assert.AreEqual(
          RIB, PaymentSlip.Lines."Bank Branch No.".Visible(), StrSubstNo(VisibleFieldErr, PaymentLine.FieldCaption("Bank Branch No.")));
        Assert.AreEqual(RIB, PaymentSlip.Lines."Agency Code".Visible(), StrSubstNo(VisibleFieldErr, PaymentLine.FieldCaption("Agency Code")));
        Assert.AreEqual(RIB, PaymentSlip.Lines."RIB Key".Visible(), StrSubstNo(VisibleFieldErr, PaymentLine.FieldCaption("RIB Key")));
        Assert.AreEqual(RIB, PaymentSlip.Lines."RIB Checked".Visible(), StrSubstNo(VisibleFieldErr, PaymentLine.FieldCaption("RIB Checked")));
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PaymentClassHandler(var PaymentClassList: TestPage "Payment Class List")
    var
        "Code": Variant;
    begin
        LibraryVariableStorage.Dequeue(Code);
        PaymentClassList.GotoKey(Code);
        PaymentClassList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PaymentStepsLookupHandler(var PaymentSteps: Page "Payment Steps"; var Response: Action)
    begin
        Response := ACTION::LookupOK;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmationNoHandler(Question: Text; var Reply: Boolean)
    begin
        Reply := false;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmationYesHandler(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;
}

