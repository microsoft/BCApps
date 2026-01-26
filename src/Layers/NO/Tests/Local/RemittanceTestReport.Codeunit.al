codeunit 144130 "Remittance - Test Report"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Remittance] [Test Report]
    end;

    var
        LibraryUtility: Codeunit "Library - Utility";
        Assert: Codeunit Assert;
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryERM: Codeunit "Library - ERM";
        LibraryRemittance: Codeunit "Library - Remittance";
        LibraryRandom: Codeunit "Library - Random";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        isInitialized: Boolean;
        NoErrorsExpected: Integer;
        LineErrorElementName: Text;
        TransactionErrorElementName: Text;
        DomesticPaymentNoteTxt: Label 'Note:Field %1 is filled in, but can not be used for domestic payments.';
        ForeignPaymentNoteTxt: Label 'Note:Field %1 is filled in, but can not be used for payments abroad.';
        AnyShortString: Text[2];

    [Test]
    [HandlerFunctions('RemittanceTestReportHandler')]
    [Scope('OnPrem')]
    procedure RemittanceTestReportPaymentLinesStructuredNoWarningsRaised()
    var
        RemittanceAgreement: Record "Remittance Agreement";
    begin
        // [FEATURE] [Domestic Account] [BANK]
        AnyRemittanceTestReportPaymentLinesStructuredNoWarningsRaised(RemittanceAgreement."Payment System"::"DnB Telebank");
    end;

    [Test]
    [HandlerFunctions('RemittanceTestReportHandler')]
    [Scope('OnPrem')]
    procedure RemittanceTestReportPaymentLinesUnstructuredNoWarningsRaised()
    var
        RemittanceAgreement: Record "Remittance Agreement";
        RemittanceAccount: Record "Remittance Account";
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [Domestic Account] [BANK]
        Initialize();
        LibraryRemittance.SetupDomesticRemittancePayment(
          RemittanceAgreement."Payment System"::"DnB Telebank", RemittanceAgreement, RemittanceAccount, Vendor, GenJournalLine);

        UpdateLineToUnStructuredLineWithoutErrors(GenJournalLine, RemittanceAccount.Code);
        InvokeRemittanceTestReport(GenJournalLine."Journal Batch Name");

        VerifyNoOfErrorsInTestReport(NoErrorsExpected);
    end;

    [Test]
    [HandlerFunctions('RemittanceTestReportHandler')]
    [Scope('OnPrem')]
    procedure ForeignPaymentRemittanceTestReportPaymentLinesStructuredNoWarningsRaised()
    var
        RemittanceAgreement: Record "Remittance Agreement";
        RemittanceAccount: Record "Remittance Account";
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalLine2: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        // [FEATURE] [Foreign Account] [BANK]
        Initialize();
        LibraryRemittance.SetupForeignRemittancePayment(
          RemittanceAgreement."Payment System"::"DnB Telebank", RemittanceAgreement, RemittanceAccount, Vendor, GenJournalLine, false);

        GenJournalBatch.Get(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name");
        LibraryRemittance.CreateGenJournalLine(
          GenJournalLine2, GenJournalBatch, Vendor, RemittanceAgreement, RemittanceAccount."Currency Code");

        UpdateLineToStructuredLineWithKIDWithoutErrors(GenJournalLine, RemittanceAccount.Code);
        UpdateLineToStructuredLineWithExternalDocNoWithoutErrors(GenJournalLine2, RemittanceAccount.Code);

        InvokeRemittanceTestReport(GenJournalLine."Journal Batch Name");
        VerifyNoOfErrorsInTestReport(NoErrorsExpected);
    end;

    [Test]
    [HandlerFunctions('RemittanceTestReportHandler')]
    [Scope('OnPrem')]
    procedure ForeignPaymentTestReportPaymentLinesUnstructuredNoWarningsRaised()
    var
        RemittanceAgreement: Record "Remittance Agreement";
        RemittanceAccount: Record "Remittance Account";
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [Foreign Account] [BANK]
        Initialize();
        LibraryRemittance.SetupForeignRemittancePayment(
          RemittanceAgreement."Payment System"::"DnB Telebank", RemittanceAgreement, RemittanceAccount, Vendor, GenJournalLine, false);

        UpdateLineToUnStructuredLineWithoutErrorsForeign(GenJournalLine, RemittanceAccount.Code);
        InvokeRemittanceTestReport(GenJournalLine."Journal Batch Name");

        VerifyNoOfErrorsInTestReport(NoErrorsExpected);
    end;

    [Scope('OnPrem')]
    procedure AnyRemittanceTestReportPaymentLinesStructuredNoWarningsRaised(PaymentSystem: Integer)
    var
        RemittanceAgreement: Record "Remittance Agreement";
        RemittanceAccount: Record "Remittance Account";
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalLine2: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        Initialize();
        LibraryRemittance.SetupDomesticRemittancePayment(
          PaymentSystem, RemittanceAgreement, RemittanceAccount, Vendor, GenJournalLine);

        GenJournalBatch.Get(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name");
        LibraryRemittance.CreateGenJournalLine(GenJournalLine2, GenJournalBatch, Vendor, RemittanceAgreement, '');

        UpdateLineToStructuredLineWithKIDWithoutErrors(GenJournalLine, RemittanceAccount.Code);
        UpdateLineToStructuredLineWithExternalDocNoWithoutErrors(GenJournalLine2, RemittanceAccount.Code);

        InvokeRemittanceTestReport(GenJournalLine."Journal Batch Name");
        VerifyNoOfErrorsInTestReport(NoErrorsExpected);
    end;

    [Test]
    [HandlerFunctions('RemittanceTestReportHandler')]
    [Scope('OnPrem')]
    procedure BBSRemittanceTestReportPaymentLinesStructuredNoWarningsRaised()
    var
        RemittanceAgreement: Record "Remittance Agreement";
    begin
        // [FEATURE] [Domestic Account] [BBS]
        AnyRemittanceTestReportPaymentLinesStructuredNoWarningsRaised(RemittanceAgreement."Payment System"::BBS);
    end;

    [Test]
    [HandlerFunctions('RemittanceTestReportHandler')]
    [Scope('OnPrem')]
    procedure BBSRemittanceTestReportPaymentLinesUnstructuredNoWarningsRaised()
    var
        RemittanceAgreement: Record "Remittance Agreement";
        RemittanceAccount: Record "Remittance Account";
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [Domestic Account] [BBS]
        Initialize();
        LibraryRemittance.SetupDomesticRemittancePayment(
          RemittanceAgreement."Payment System"::BBS, RemittanceAgreement, RemittanceAccount, Vendor, GenJournalLine);

        UpdateLineToUnStructuredLineWithoutErrors(GenJournalLine, RemittanceAccount.Code);
        InvokeRemittanceTestReport(GenJournalLine."Journal Batch Name");

        VerifyNoOfErrorsInTestReport(NoErrorsExpected);
    end;

    [Test]
    [HandlerFunctions('RemittanceTestReportHandler')]
    [Scope('OnPrem')]
    procedure DetectDomesticGenJournalLineErrors()
    var
        RemittanceAgreement: Record "Remittance Agreement";
        RemittanceAccount: Record "Remittance Account";
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalLine2: Record "Gen. Journal Line";
        Currency: Record Currency;
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        // [FEATURE] [Domestic Account] [Bank]
        Initialize();
        LibraryRemittance.SetupDomesticRemittancePayment(
          RemittanceAgreement."Payment System"::"DnB Telebank", RemittanceAgreement, RemittanceAccount, Vendor, GenJournalLine);

        GenJournalBatch.Get(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name");

        UpdateLineToStructuredLineWithKIDWithoutErrors(GenJournalLine, RemittanceAccount.Code);

        // Error 1 - KID should not have Recipient Ref. fiels specified
        GenJournalLine."Recipient Ref. 1" :=
          LibraryUtility.GenerateRandomCode(GenJournalLine.FieldNo("Recipient Ref. 1"), DATABASE::"Gen. Journal Line");
        GenJournalLine."Recipient Ref. 2" :=
          LibraryUtility.GenerateRandomCode(GenJournalLine.FieldNo("Recipient Ref. 2"), DATABASE::"Gen. Journal Line");
        GenJournalLine."Recipient Ref. 3" :=
          LibraryUtility.GenerateRandomCode(GenJournalLine.FieldNo("Recipient Ref. 3"), DATABASE::"Gen. Journal Line");

        // Error 2 - UnStrucutred line should not have KID specified
        LibraryRemittance.CreateGenJournalLine(GenJournalLine2, GenJournalBatch, Vendor, RemittanceAgreement, '');
        UpdateLineToUnStructuredLineWithoutErrorsForeign(GenJournalLine2, RemittanceAccount.Code);
        GenJournalLine2.Modify(true);

        // Domestic line specific errors 3 - 12
        LibraryERM.FindCurrency(Currency);
        GenJournalLine."Currency Code" := Currency.Code;
        GenJournalLine.Urgent := true;
        GenJournalLine."Agreed Exch. Rate" := LibraryRandom.RandInt(100);
        GenJournalLine."Agreed With" := AnyShortString;
        GenJournalLine."Futures Contract No." := AnyShortString;
        GenJournalLine."Futures Contract Exch. Rate" := LibraryRandom.RandInt(100);
        GenJournalLine.Check := GenJournalLine.Check::"Send to employer";
        GenJournalLine."Recipient Ref. Abroad" :=
          LibraryUtility.GenerateRandomCode(GenJournalLine.FieldNo("Recipient Ref. Abroad"), DATABASE::"Gen. Journal Line");
        GenJournalLine."Payment Type Code Abroad" := AnyShortString;
        GenJournalLine."Specification (Norges Bank)" :=
          LibraryUtility.GenerateRandomCode(GenJournalLine.FieldNo("Specification (Norges Bank)"), DATABASE::"Gen. Journal Line");
        GenJournalLine.Modify();

        // Invoke report
        InvokeRemittanceTestReport(GenJournalLine."Journal Batch Name");

        // Verify
        VerifyNoOfErrorsInTestReport(12);

        LibraryReportDataset.Reset();
        LibraryReportDataset.AssertElementWithValueExists(
          LineErrorElementName,
          'Warning!Both Recipient ref. and KID/External Document No. are filled in. They cannot be used both at the same time.');

        LibraryReportDataset.Reset();
        LibraryReportDataset.AssertElementWithValueExists(
          LineErrorElementName, 'Warning!There are no messages for beneficiary. You have to fill in Recipient ref., External Document No., or KID.');

        LibraryReportDataset.Reset();
        LibraryReportDataset.AssertElementWithValueExists(
          LineErrorElementName, 'Note:Currency payments are not used for domestic payments. Use Amount (LCY) for payments.');

        // Verify fileds that should not have been filled in
        LibraryReportDataset.Reset();
        VerifyWarningForFieldExist(LineErrorElementName, DomesticPaymentNoteTxt, GenJournalLine.FieldCaption(Urgent));
        VerifyWarningForFieldExist(LineErrorElementName, DomesticPaymentNoteTxt, GenJournalLine.FieldCaption("Agreed Exch. Rate"));
        VerifyWarningForFieldExist(LineErrorElementName, DomesticPaymentNoteTxt, GenJournalLine.FieldCaption("Agreed With"));
        VerifyWarningForFieldExist(LineErrorElementName, DomesticPaymentNoteTxt, GenJournalLine.FieldCaption("Futures Contract No."));
        VerifyWarningForFieldExist(
          LineErrorElementName, DomesticPaymentNoteTxt, GenJournalLine.FieldCaption("Futures Contract Exch. Rate"));
        VerifyWarningForFieldExist(LineErrorElementName, DomesticPaymentNoteTxt, GenJournalLine.FieldCaption(Check));
        VerifyWarningForFieldExist(LineErrorElementName, DomesticPaymentNoteTxt, GenJournalLine.FieldCaption("Recipient Ref. Abroad"));
        VerifyWarningForFieldExist(LineErrorElementName, DomesticPaymentNoteTxt, GenJournalLine.FieldCaption("Payment Type Code Abroad"));
        VerifyWarningForFieldExist(
          LineErrorElementName, DomesticPaymentNoteTxt, GenJournalLine.FieldCaption("Specification (Norges Bank)"));
    end;

    [Test]
    [HandlerFunctions('RemittanceTestReportHandler')]
    [Scope('OnPrem')]
    procedure DetectForeignGenJournalLineErrors()
    var
        RemittanceAgreement: Record "Remittance Agreement";
        RemittanceAccount: Record "Remittance Account";
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
        Currency: Record Currency;
        GenJournalBatch: Record "Gen. Journal Batch";
        PurchasesAndPayablesSetup: Record "Purchases & Payables Setup";
        AmountTxt: Text;
    begin
        // [FEATURE] [Foreign Account] [Bank]
        Initialize();
        LibraryRemittance.SetupForeignRemittancePayment(
          RemittanceAgreement."Payment System"::"DnB Telebank", RemittanceAgreement, RemittanceAccount, Vendor, GenJournalLine, false);

        GenJournalBatch.Get(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name");

        UpdateLineToStructuredLineWithKIDWithoutErrors(GenJournalLine, RemittanceAccount.Code);

        // Errors 1-3 No Recipient Refs should not be used for Foreign Payment
        GenJournalLine."Recipient Ref. 1" :=
          LibraryUtility.GenerateRandomCode(GenJournalLine.FieldNo("Recipient Ref. 1"), DATABASE::"Gen. Journal Line");
        GenJournalLine."Recipient Ref. 2" :=
          LibraryUtility.GenerateRandomCode(GenJournalLine.FieldNo("Recipient Ref. 2"), DATABASE::"Gen. Journal Line");
        GenJournalLine."Recipient Ref. 3" :=
          LibraryUtility.GenerateRandomCode(GenJournalLine.FieldNo("Recipient Ref. 3"), DATABASE::"Gen. Journal Line");

        // Errors 3 - 11
        GenJournalLine."BOLS Text Code" := GenJournalLine."BOLS Text Code"::"KID transfer";
        GenJournalLine."Agreed Exch. Rate" := LibraryRandom.RandInt(100);
        GenJournalLine."Payment Type Code Domestic" := AnyShortString;
        GenJournalLine."Payment Type Code Abroad" := '';
        GenJournalLine."Specification (Norges Bank)" := '';
        GenJournalLine.Modify();

        PurchasesAndPayablesSetup.Get();
        PurchasesAndPayablesSetup."Amt. Spec limit to Norges Bank" :=
          LibraryRandom.RandDecInDecimalRange(1, Round(GenJournalLine."Amount (LCY)", 2, '<') - 1, 2);
        PurchasesAndPayablesSetup.Modify();

        Vendor."Country/Region Code" := '';
        Vendor.SWIFT := '';
        Vendor."Rcpt. Bank Country/Region Code" := '';
        Vendor."Recipient Bank Account No." :=
          LibraryUtility.GenerateRandomCode(Vendor.FieldNo("Recipient Bank Account No."), DATABASE::Vendor);
        Vendor."Rcpt. Bank Country/Region Code" := '';
        Vendor.Modify();

        Currency.Get(GenJournalLine."Currency Code");
        Currency."EMU Currency" := true;
        Currency.Modify();

        // Excercise
        InvokeRemittanceTestReport(GenJournalLine."Journal Batch Name");

        // Verify
        VerifyNoOfErrorsInTestReport(11);

        LibraryReportDataset.Reset();
        LibraryReportDataset.AssertElementWithValueExists(
          LineErrorElementName, 'Note:Swift address should always be filled out and must be filled out for payments within EU.');

        LibraryReportDataset.Reset();
        LibraryReportDataset.AssertElementWithValueExists(
          LineErrorElementName, 'Note:Field Country/Region Code is mandatory for payments abroad.');

        LibraryReportDataset.Reset();
        LibraryReportDataset.AssertElementWithValueExists(
          LineErrorElementName, 'Note:Recipients bank country/region code is mandatory if the swift address is not used.');

        LibraryReportDataset.Reset();
        LibraryReportDataset.AssertElementWithValueExists(LineErrorElementName,
          'Note:Bank Code is used only if IBAN is not used, and recipient country/region is one of the following countries/regions: ''AU'',''CA'',''IE'',''GB'',''CH'',''ZA'',''DE'',''US'',''AT''');

        LibraryReportDataset.Reset();
        LibraryReportDataset.AssertElementWithValueExists(LineErrorElementName,
          'Note:Field Payment Type Code Abroad is mandatory for payments abroad.');

        LibraryReportDataset.Reset();
        AmountTxt := Format(PurchasesAndPayablesSetup."Amt. Spec limit to Norges Bank");
        LibraryReportDataset.AssertElementWithValueExists(LineErrorElementName,
          StrSubstNo(
            'Warning!Specification (Norges Bank) is missing.' +
            ' This field is required because Amount (LCY) on line 10000 is higher then %1.',
            AmountTxt));

        // Verify warnings for fields that should not  have been filled in
        LibraryReportDataset.Reset();
        VerifyWarningForFieldExist(LineErrorElementName, ForeignPaymentNoteTxt, GenJournalLine.FieldCaption("BOLS Text Code"));
        VerifyWarningForFieldExist(LineErrorElementName, ForeignPaymentNoteTxt, GenJournalLine.FieldCaption("Payment Type Code Domestic"));
        VerifyWarningForFieldExist(LineErrorElementName, ForeignPaymentNoteTxt, GenJournalLine.FieldCaption("Recipient Ref. 1"));
        VerifyWarningForFieldExist(LineErrorElementName, ForeignPaymentNoteTxt, GenJournalLine.FieldCaption("Recipient Ref. 2"));
        VerifyWarningForFieldExist(LineErrorElementName, ForeignPaymentNoteTxt, GenJournalLine.FieldCaption("Recipient Ref. 3"));
    end;

    [Test]
    [HandlerFunctions('RemittanceTestReportHandler')]
    [Scope('OnPrem')]
    procedure DetectGenJournalLineErrorsCommonForBothForeingAndDomesticPayments()
    var
        RemittanceAgreement: Record "Remittance Agreement";
        RemittanceAccount: Record "Remittance Account";
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        // [FEATURE] [Domestic Account] [Bank]
        Initialize();
        LibraryRemittance.SetupDomesticRemittancePayment(
          RemittanceAgreement."Payment System"::Postbanken, RemittanceAgreement, RemittanceAccount, Vendor, GenJournalLine);

        GenJournalBatch.Get(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name");

        UpdateLineToStructuredLineWithKIDWithoutErrors(GenJournalLine, RemittanceAccount.Code);

        // Common errors (for both domestic and foreign)
        GenJournalLine."Account Type" := GenJournalLine."Account Type"::Customer;
        GenJournalLine."Bal. Account No." :=
          LibraryUtility.GenerateRandomCode(GenJournalLine.FieldNo("Bal. Account No."), DATABASE::"Gen. Journal Line");
        GenJournalLine."Document No." :=
          LibraryUtility.GenerateRandomCode(GenJournalLine.FieldNo("Document No."), DATABASE::"Gen. Journal Line");
        GenJournalLine.Amount := -LibraryRandom.RandDecInRange(10, 1000, 2);
        GenJournalLine."Posting Date" := CalcDate('<-1D>', Today);
        GenJournalLine.Modify();

        InvokeRemittanceTestReport(GenJournalLine."Journal Batch Name");

        VerifyNoOfErrorsInTestReport(5);

        LibraryReportDataset.Reset();
        LibraryReportDataset.AssertElementWithValueExists(
          TransactionErrorElementName, 'Warning!Transaction amount can not be negative.');

        LibraryReportDataset.Reset();
        LibraryReportDataset.AssertElementWithValueExists(
          LineErrorElementName, 'Warning!Account Type should be Customer. Only the vendors are remitted.');

        LibraryReportDataset.Reset();
        LibraryReportDataset.AssertElementWithValueExists(
          LineErrorElementName, 'Warning!The Bal. Account No. field must be empty because it is not used for remittance.');

        LibraryReportDataset.Reset();
        LibraryReportDataset.AssertElementWithValueExists(
          LineErrorElementName, 'Warning!Field Document No. is used for settlement return and should be left empty.');
    end;

    [Test]
    [HandlerFunctions('RemittanceTestReportHandler')]
    [Scope('OnPrem')]
    procedure BBSDetectPayingTooEarlyTransactionError()
    var
        RemittanceAgreement: Record "Remittance Agreement";
        RemittanceAccount: Record "Remittance Account";
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        MaxDate: Date;
    begin
        // [FEATURE] [Domestic Account] [BBS]
        Initialize();
        LibraryRemittance.SetupDomesticRemittancePayment(
          RemittanceAgreement."Payment System"::BBS, RemittanceAgreement, RemittanceAccount, Vendor, GenJournalLine);

        GenJournalBatch.Get(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name");

        UpdateLineToStructuredLineWithKIDWithoutErrors(GenJournalLine, RemittanceAccount.Code);

        MaxDate := CalcDate('<+12M-1D>', Today);
        GenJournalLine."Posting Date" := CalcDate('<+12M + 1D>', Today);
        GenJournalLine.Modify();

        InvokeRemittanceTestReport(GenJournalLine."Journal Batch Name");

        VerifyNoOfErrorsInTestReport(1);

        LibraryReportDataset.Reset();
        LibraryReportDataset.AssertElementWithValueExists(LineErrorElementName,
          StrSubstNo('Warning!Payment must be made within 12 months, and should not be due after %1.', MaxDate));
    end;

    [Test]
    [HandlerFunctions('RemittanceTestReportHandler')]
    [Scope('OnPrem')]
    procedure DetectPayingTooEarlyTransactionError()
    var
        RemittanceAgreement: Record "Remittance Agreement";
        RemittanceAccount: Record "Remittance Account";
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        MaxDate: Date;
    begin
        // [FEATURE] [Domestic Account] [Bank]
        Initialize();
        LibraryRemittance.SetupDomesticRemittancePayment(
          RemittanceAgreement."Payment System"::Postbanken, RemittanceAgreement, RemittanceAccount, Vendor, GenJournalLine);

        GenJournalBatch.Get(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name");

        UpdateLineToStructuredLineWithKIDWithoutErrors(GenJournalLine, RemittanceAccount.Code);

        MaxDate := CalcDate('<+13M-1D>', Today);
        GenJournalLine."Posting Date" := CalcDate('<+13M + 1D>', Today);
        GenJournalLine.Modify();

        InvokeRemittanceTestReport(GenJournalLine."Journal Batch Name");

        VerifyNoOfErrorsInTestReport(1);

        LibraryReportDataset.Reset();
        LibraryReportDataset.AssertElementWithValueExists(LineErrorElementName,
          StrSubstNo('Warning!Payment must be made within 13 months, and should not be due after %1.', MaxDate));
    end;

    [Test]
    [HandlerFunctions('RemittanceTestReportHandler')]
    [Scope('OnPrem')]
    procedure DetectPayingTooLateTransactionError()
    var
        RemittanceAgreement: Record "Remittance Agreement";
        RemittanceAccount: Record "Remittance Account";
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        MinDate: Date;
    begin
        // [FEATURE] [Domestic Account] [Bank]
        Initialize();
        LibraryRemittance.SetupDomesticRemittancePayment(
          RemittanceAgreement."Payment System"::Postbanken, RemittanceAgreement, RemittanceAccount, Vendor, GenJournalLine);

        GenJournalBatch.Get(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name");
        UpdateLineToStructuredLineWithKIDWithoutErrors(GenJournalLine, RemittanceAccount.Code);

        MinDate := CalcDate('<-12M>', Today);

        GenJournalLine."Posting Date" := CalcDate('<-12M - 2D>', Today);
        GenJournalLine.Modify();

        InvokeRemittanceTestReport(GenJournalLine."Journal Batch Name");

        VerifyNoOfErrorsInTestReport(1);

        LibraryReportDataset.Reset();
        LibraryReportDataset.AssertElementWithValueExists(LineErrorElementName,
          StrSubstNo('Warning!Payment must be made up to one year in arrears, and should not be due before %1.', MinDate));
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
        LibraryReportDataset.Reset();

        if isInitialized then
            exit;

        LibraryERM.SetEnableDataCheck(false);
        isInitialized := true;
        NoErrorsExpected := 0;
        LineErrorElementName := 'ErrorTextNumber_ErrorLoopPayment';
        TransactionErrorElementName := 'ErrorTextNumber_ErrorLoopTransaction';

        // Needed since some of the table fields are shorter than 10 characters
        // Cannot use Library Utility for these since precal will complain
        AnyShortString := 'XX';
    end;

    local procedure UpdateLineToStructuredLineWithKIDWithoutErrors(var GenJournalLine: Record "Gen. Journal Line"; RemittanceAccountCode: Code[10])
    begin
        UpdateGenJournalLineWithExpectedValues(GenJournalLine, RemittanceAccountCode);

        // Either specifying KID or Ext. Document No will make the line structure
        GenJournalLine.Validate(KID, '647576537');
        GenJournalLine.Modify(true);
    end;

    local procedure UpdateLineToStructuredLineWithExternalDocNoWithoutErrors(var GenJournalLine: Record "Gen. Journal Line"; RemittanceAccountCode: Code[10])
    begin
        UpdateGenJournalLineWithExpectedValues(GenJournalLine, RemittanceAccountCode);

        // Either specifying KID or Ext. Document No will make the line structured
        GenJournalLine.Validate(
          "External Document No.",
          LibraryUtility.GenerateRandomCode(GenJournalLine.FieldNo("External Document No."), DATABASE::"Gen. Journal Line"));
        GenJournalLine.Modify(true);
    end;

    local procedure UpdateLineToUnStructuredLineWithoutErrors(var GenJournalLine: Record "Gen. Journal Line"; RemittanceAccountCode: Code[10])
    begin
        UpdateGenJournalLineWithExpectedValues(GenJournalLine, RemittanceAccountCode);

        GenJournalLine.Validate(KID, '');
        GenJournalLine.Validate("External Document No.", '');

        // When line is unstructured we need to provide Recipient Refs
        GenJournalLine.Validate(
          "Recipient Ref. 1", LibraryUtility.GenerateRandomCode(GenJournalLine.FieldNo("Recipient Ref. 1"), DATABASE::"Gen. Journal Line"));
        GenJournalLine.Validate(
          "Recipient Ref. 2", LibraryUtility.GenerateRandomCode(GenJournalLine.FieldNo("Recipient Ref. 2"), DATABASE::"Gen. Journal Line"));
        GenJournalLine.Validate(
          "Recipient Ref. 3", LibraryUtility.GenerateRandomCode(GenJournalLine.FieldNo("Recipient Ref. 3"), DATABASE::"Gen. Journal Line"));
        GenJournalLine.Modify(true);
    end;

    local procedure UpdateLineToUnStructuredLineWithoutErrorsForeign(var GenJournalLine: Record "Gen. Journal Line"; RemittanceAccountCode: Code[10])
    begin
        UpdateGenJournalLineWithExpectedValues(GenJournalLine, RemittanceAccountCode);

        GenJournalLine.Validate(KID, '');
        GenJournalLine.Validate("External Document No.", '');

        // For foreign customer recipent refs need to be blank
        GenJournalLine.Validate("Recipient Ref. 1", '');
        GenJournalLine.Validate("Recipient Ref. 2", '');
        GenJournalLine.Validate("Recipient Ref. 3", '');
        GenJournalLine.Modify(true);
    end;

    local procedure UpdateGenJournalLineWithExpectedValues(var GenJournalLine: Record "Gen. Journal Line"; RemittanceAccountCode: Code[10])
    var
        CorrectDate: Date;
    begin
        GenJournalLine.Validate("Remittance Account Code", RemittanceAccountCode);
        GenJournalLine.Validate(Amount, LibraryRandom.RandDecInRange(10, 10000, 2));
        CorrectDate := CalcDate('<+10M-1D>', Today); // Product is using TODAY to calculate allowed posting date
        GenJournalLine.Validate("Posting Date", CorrectDate);

        // These fields must be blanks since they will be filled out latter
        GenJournalLine.Validate("Bal. Account No.", '');
        GenJournalLine.Validate("Document No.", '');
        GenJournalLine.Validate("Document Type", GenJournalLine."Document Type"::" ");
    end;

    local procedure InvokeRemittanceTestReport(JournalBatchName: Code[20])
    var
        PaymentJournal: TestPage "Payment Journal";
    begin
        // Cannot run report if there are transactions pending        
        Commit();

        PaymentJournal.OpenEdit();
        PaymentJournal.CurrentJnlBatchName.SetValue(JournalBatchName);

        // Invoke test action
        PaymentJournal.TestReport.Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RemittanceTestReportHandler(var RemittanceTestReport: TestRequestPage "Remittance Test Report")
    begin
        RemittanceTestReport.ShowPaymentInfo.SetValue(true);
        RemittanceTestReport.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    local procedure VerifyNoOfErrorsInTestReport(ExpectedNumberOfErrors: Integer)
    var
        ErrorsCount: Integer;
    begin
        LibraryReportDataset.LoadDataSetFile();
        ErrorsCount :=
          CountErrorsInTestReportDataset(LineErrorElementName) + CountErrorsInTestReportDataset(TransactionErrorElementName);
        Assert.AreEqual(ExpectedNumberOfErrors, ErrorsCount, 'Wrong nubmer of errors found');
    end;

    local procedure VerifyWarningForFieldExist(ElementName: Text; MessagePlaceHolder: Text; FieldCaption: Text)
    begin
        LibraryReportDataset.Reset();
        LibraryReportDataset.AssertElementWithValueExists(ElementName, StrSubstNo(MessagePlaceHolder, FieldCaption));
    end;

    local procedure CountErrorsInTestReportDataset(ElementName: Text): Integer
    var
        NotificationTextVariant: Variant;
        NotificationText: Text;
        "Count": Integer;
    begin
        Count := 0;
        LibraryReportDataset.Reset();

        while LibraryReportDataset.GetNextRow() do
            if LibraryReportDataset.CurrentRowHasElement(ElementName) then begin
                LibraryReportDataset.GetElementValueInCurrentRow(ElementName, NotificationTextVariant);
                NotificationText := NotificationTextVariant;

                // We are entering errors with value 1 for each Journal Line - not an actual error
                if (NotificationText <> '') and
                   (NotificationText <> '1')
                then
                    Count := Count + 1;
            end;

        exit(Count);
    end;
}

