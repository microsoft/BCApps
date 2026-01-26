codeunit 144002 "Bank Payments"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        MessageTypeErr: Label 'Ref. Payment in document %1 for Vendor %2 has incorrect Message Type';
        InvoiceMessageErr: Label 'Ref. Payment in document %1 for Vendor %2 has incorrect Invoice Message';
        FullPathErr: Label 'File full path ''%1'' exceeds length (%3) of field ''%2'' ';
        CountryRegion: Record "Country/Region";
        IsInitialized: Boolean;
        FileExportHasErrorsErr: Label 'The file export has one or more errors';
        NotAppliedErr: Label 'Entries not applied';

    [Test]
    [HandlerFunctions('RPHSuggestBankPayments')]
    [Scope('OnPrem')]
    procedure SuggestVendorPaymentsWithInvoiceMessage()
    var
        PurchaseHeader: Record "Purchase Header";
        RefFileSetup: Record "Reference File Setup";
        BankAccountNo: Code[20];
        VendorNo: Code[20];
        PostedDocNo: Code[20];
    begin
        // Initialize
        Initialize();
        BankAccountNo := CreateBankAccount(CountryRegion.Code, 'FI9780RBOS16173241116737', '');
        CreateBankAccountReferenceFileSetup(RefFileSetup, BankAccountNo);
        VendorNo := CreateVendor(CountryRegion.Code, 'FI9780RBOS16173241116737', true, 1);

        // Excercise
        PostedDocNo := CreateReferancePaymentExportLines(BankAccountNo, VendorNo, PurchaseHeader);

        // Verify
        VerifySuggestedVendorPaymentsWithInvoiceMessage(VendorNo, PostedDocNo, PurchaseHeader."Invoice Message");
    end;

    [Test]
    [HandlerFunctions('RPHSuggestBankPayments')]
    [Scope('OnPrem')]
    procedure SEPAV3PaymentExported()
    var
        PurchaseHeader: Record "Purchase Header";
        RefPmtExp: Record "Ref. Payment - Exported";
        RefFileSetup: Record "Reference File Setup";
        PaymentExportData: Record "Payment Export Data";
        GenJnlLine: Record "Gen. Journal Line";
        SEPACreatePayment: Codeunit "SEPA CT-Fill Export Buffer";
        BankAccountNo: Code[20];
        VendorNo: Code[20];
    begin
        // Initialize
        Initialize();
        BankAccountNo := CreateBankAccount(CountryRegion.Code, 'FI9780RBOS16173241116737', 'SEPACT');
        CreateBankAccountReferenceFileSetup(RefFileSetup, BankAccountNo);
        VendorNo := CreateVendor(CountryRegion.Code, 'FI9780RBOS16173241116737', true, 1);

        CreateReferancePaymentExportLines(BankAccountNo, VendorNo, PurchaseHeader);

        // Excercise
        PaymentExportData.DeleteAll();
        GenJnlLine.SetRange("Account Type", GenJnlLine."Account Type"::Vendor);
        GenJnlLine.SetRange("Account No.", VendorNo);
        SEPACreatePayment.FillExportBuffer(GenJnlLine, PaymentExportData);

        // Verify
        VerifyPaymentLine(PaymentExportData, RefPmtExp);
    end;

    [Test]
    [HandlerFunctions('RPHSuggestBankPayments')]
    [Scope('OnPrem')]
    procedure SEPAV3PaymentExportWithErrors()
    var
        PurchaseHeader: Record "Purchase Header";
        RefPmtExp: Record "Ref. Payment - Exported";
        RefFileSetup: Record "Reference File Setup";
        GenJnlLine: Record "Gen. Journal Line";
        PaymentExportData: Record "Payment Export Data";
        PmtJnlExpErrTxt: Record "Payment Jnl. Export Error Text";
        SEPACreatePayment: Codeunit "SEPA CT-Fill Export Buffer";
        BankAccountNo: Code[20];
        VendorNo: Code[20];
    begin
        // Initialize
        Initialize();
        BankAccountNo := CreateBankAccount(CountryRegion.Code, 'FI9780RBOS16173241116737', 'SEPACT');
        CreateBankAccountReferenceFileSetup(RefFileSetup, BankAccountNo);
        VendorNo := CreateVendor(CountryRegion.Code, '', true, 1);

        CreateReferancePaymentExportLines(BankAccountNo, VendorNo, PurchaseHeader);

        // Excercise
        PaymentExportData.DeleteAll();
        GenJnlLine.SetRange("Account Type", GenJnlLine."Account Type"::Vendor);
        GenJnlLine.SetRange("Account No.", VendorNo);
        asserterror SEPACreatePayment.FillExportBuffer(GenJnlLine, PaymentExportData);

        // Verify
        RefPmtExp.SetRange(Transferred, false);
        RefPmtExp.SetRange("SEPA Payment", true);
        RefPmtExp.FindFirst();

        Assert.AreEqual(1, RefPmtExp.Count, 'Only one record expected');
        Assert.AreEqual(0D, RefPmtExp."Payment Execution Date", 'Incorrect Payment Execution Date');

        PmtJnlExpErrTxt.SetRange("Document No.", RefPmtExp."Document No.");
        PmtJnlExpErrTxt.FindFirst();

        Assert.AreEqual(1, PmtJnlExpErrTxt.Count, 'Only one error expected');
        Assert.AreEqual(
          StrSubstNo('Vendor Bank Account %1 must have a value in IBAN.', RefPmtExp."Vendor Account"), PmtJnlExpErrTxt."Error Text", '');
    end;

    [Test]
    [HandlerFunctions('RPHSuggestBankPayments')]
    [Scope('OnPrem')]
    procedure SEPAV3PaymentExportsLocalData()
    var
        PurchaseHeader: Record "Purchase Header";
        RefFileSetup: Record "Reference File Setup";
        GenJnlLine: Record "Gen. Journal Line";
        RefPaymentExported: Record "Ref. Payment - Exported";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
        BankAccountNo: Code[20];
        VendorNo: Code[20];
    begin
        // Initialize
        Initialize();
        BankAccountNo := CreateBankAccount(CountryRegion.Code, 'FI9780RBOS16173241116737', 'SEPACT');
        CreateBankAccountReferenceFileSetup(RefFileSetup, BankAccountNo);
        VendorNo := CreateVendor(CountryRegion.Code, 'FI9780RBOS16173241116737', true, 1);

        CreateReferancePaymentExportLines(BankAccountNo, VendorNo, PurchaseHeader);

        // Must be at least one record in Tab81
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        LibraryERM.FindGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        LibraryERM.CreateGeneralJnlLine(
            GenJnlLine, GenJournalTemplate.Name, GenJournalBatch.Name, "Gen. Journal Document Type"::" ",
            "Gen. Journal Account Type"::"G/L Account", '', 0);

        // Excercise
        RefPaymentExported.SetRange(Transferred, false);
        RefPaymentExported.SetRange("SEPA Payment", true);
        RefPaymentExported.FindFirst();
        RefPaymentExported."Vendor Account" := ''; // Inject an error
        RefPaymentExported.Modify();

        asserterror RefPaymentExported.ExportToFile();
        // Verify. Error message is about File Export Errors
        Assert.ExpectedError(FileExportHasErrorsErr);
    end;

    [Test]
    [HandlerFunctions('RPHSuggestBankPayments')]
    [Scope('OnPrem')]
    procedure VerifyApplicationOnCreditTransferEntry()
    var
        PurchaseHeader: Record "Purchase Header";
        RefPmtExp: Record "Ref. Payment - Exported";
        RefFileSetup: Record "Reference File Setup";
        PaymentExportData: Record "Payment Export Data";
        GenJnlLine: Record "Gen. Journal Line";
        SEPACreatePayment: Codeunit "SEPA CT-Fill Export Buffer";
        CreditTransferEntry: Record "Credit Transfer Entry";
        BankAccountNo: Code[20];
        VendorNo: Code[20];
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // [SCENARIO 448616] Verify the Application after creating Payment Export Lines on Credit Tarnsfer Entry.
        Initialize();

        // [GIVEN] Create Bank account and Venor with IBAN Code
        BankAccountNo := CreateBankAccount(CountryRegion.Code, 'FI9780RBOS16173241116737', 'SEPACT');
        CreateBankAccountReferenceFileSetup(RefFileSetup, BankAccountNo);
        VendorNo := CreateVendor(CountryRegion.Code, 'FI9780RBOS16173241116737', true, 1);

        // [THEN] Post Purchase invoice with payment method code.
        CreateReferancePaymentExportLines(BankAccountNo, VendorNo, PurchaseHeader);

        // [THEN] Fill export Buffer in Payment export data.
        PaymentExportData.DeleteAll();
        GenJnlLine.SetRange("Account Type", GenJnlLine."Account Type"::Vendor);
        GenJnlLine.SetRange("Account No.", VendorNo);
        SEPACreatePayment.FillExportBuffer(GenJnlLine, PaymentExportData);

        // [THEN] Find Posted Vendor Ledger Entry
        VendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        VendorLedgerEntry.Findfirst();

        // [THEN] Find Credit transfer entry after Ref. Payment Exported have data.
        CreditTransferEntry.SetRange("Account Type", CreditTransferEntry."Account Type"::Vendor);
        CreditTransferEntry.SetRange("Account No.", VendorNo);
        CreditTransferEntry.FindFirst();

        // [THEN] Find Ref. Payment Exported entry.
        RefPmtExp.SetRange(Transferred, true);
        RefPmtExp.SetRange("SEPA Payment", true);
        RefPmtExp.SetRange("Batch Code", PaymentExportData."Message ID");
        RefPmtExp.FindFirst();

        // [VERIFY] Verified Credit transfer entry has correct Applies to entry no. as on Vendor Ledger entry.
        Assert.AreEqual(VendorLedgerEntry."Entry No.", CreditTransferEntry."Applies-to Entry No.", NotAppliedErr);
    end;

    [Test]
    [HandlerFunctions('RPHSuggestBankPayments')]
    procedure SuggestVendorPaymentsWithMessageTypeAndInvoiceMessage()
    var
        PurchaseHeader: Record "Purchase Header";
        RefFileSetup: Record "Reference File Setup";
        RefPmtExported: Record "Ref. Payment - Exported";
        BankAccountNo: Code[20];
        VendorNo: Code[20];
        PostedDocNo: Code[20];
    begin
        // [SCENARIO 567323] Verify that when a prepayment invoice is created and Suggest Vendor Payments is run, 
        // the Message Type and Invoice Message fields are correctly populated in the suggested vendor payment line.
        Initialize();

        // [GIVEN] Create Bank Account and Vendor.
        BankAccountNo := CreateBankAccount(CountryRegion.Code, 'FI9780RBOS16173241116737', '');
        CreateBankAccountReferenceFileSetup(RefFileSetup, BankAccountNo);
        VendorNo := CreateVendor(CountryRegion.Code, 'FI9780RBOS16173241116737', true, 1);

        // [GIVEN] Create purchase order and post prepayment invoice.
        PostedDocNo := CreateAndPostPurchasePrepayments(PurchaseHeader, PurchaseHeader."Document Type"::Order, VendorNo);
        RefPmtExported.DeleteAll();
        Commit();

        // [WHEN] Run Suggest Bank Payments for vendor
        RunSuggestBankPayments(BankAccountNo, VendorNo, CalcDate('<30D>', PurchaseHeader."Posting Date"));

        // [THEN] Verify suggested vendor payment line has message type and invoice message
        VerifySuggestedVendorPaymentsWithMessageTypeAndInvoiceMessage(VendorNo, PostedDocNo, PurchaseHeader);
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Bank Payments");
        LibraryVariableStorage.Clear();
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Bank Payments");
        IsInitialized := true;

        CountryRegion.Get('FI');
        InitCompanyInformation(CountryRegion.Code);
        SetupNoSeries(true, false, false, '', '');
        InitGeneralLedgerSetup('EUR');
        InitCountryRegion(CountryRegion.Code, true);
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Bank Payments");
    end;

    local procedure InitCompanyInformation(CountryCode: Code[10])
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        CompanyInformation."Country/Region Code" := CountryCode;
        CompanyInformation.Modify();
    end;

    local procedure InitGeneralLedgerSetup(LCYCode: Code[20])
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."LCY Code" := LCYCode;
        GeneralLedgerSetup.Modify();
    end;

    local procedure InitCountryRegion(CountryCode: Code[10]; SepaAllowed: Boolean)
    var
        CountryRegion: Record "Country/Region";
    begin
        CountryRegion.Get(CountryCode);
        CountryRegion."SEPA Allowed" := SepaAllowed;
        CountryRegion.Modify();
    end;

    local procedure SetupNoSeries(Default: Boolean; Manual: Boolean; DateOrder: Boolean; StartingNo: Code[20]; EndingNo: Code[20])
    var
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        LibraryUtility.CreateNoSeries(NoSeries, Default, Manual, DateOrder);
        LibraryUtility.CreateNoSeriesLine(NoSeriesLine, NoSeries.Code, StartingNo, EndingNo);

        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup."Bank Batch Nos." := NoSeries.Code;
        PurchasesPayablesSetup.Modify();
    end;

    local procedure CreateAndPostPurchaseDocument(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; VendorNo: Code[20]; LineType: Enum "Purchase Line Type"; No: Code[20]; Quantity: Decimal; Cost: Decimal; ToShipReceive: Boolean; ToInvoice: Boolean; InvoiceMessage: Text[250]; InvoiceMessage2: Text[250]): Code[20]
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, VendorNo);
        PurchaseHeader.Validate("Invoice Message", InvoiceMessage);
        PurchaseHeader.Validate("Invoice Message 2", InvoiceMessage2);
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, LineType, No, Quantity);
        PurchaseLine.Validate("Direct Unit Cost", Cost);
        PurchaseLine.Modify(true);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, ToShipReceive, ToInvoice));
    end;

    local procedure CreateAndPostPurchaseDocumentWithRandomAmounts(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; VendorNo: Code[20]; ToShipReceive: Boolean; ToInvoice: Boolean) DocumentNo: Code[20]
    var
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
        Precision: Integer;
        InvoiceMessage: Text[250];
        InvoiceMessage2: Text[250];
    begin
        Precision := LibraryRandom.RandIntInRange(2, 5);
        InvoiceMessage :=
          LibraryUtility.GenerateRandomCode(PurchaseHeader.FieldNo("Invoice Message"), DATABASE::"Purchase Header");
        InvoiceMessage2 :=
          LibraryUtility.GenerateRandomCode(PurchaseHeader.FieldNo("Invoice Message 2"), DATABASE::"Purchase Header");
        LibraryInventory.CreateItem(Item);

        DocumentNo :=
          CreateAndPostPurchaseDocument(
            PurchaseHeader, DocumentType, VendorNo,
            PurchaseLine.Type::Item, Item."No.",
            LibraryRandom.RandDec(1000, Precision), LibraryRandom.RandDec(1000, Precision),
            ToShipReceive, ToInvoice,
            InvoiceMessage, InvoiceMessage2);

        exit(DocumentNo);
    end;

    local procedure CreateBankAccount(CountryCode: Code[10]; IBANCode: Code[50]; PmtExpFormat: Code[20]): Code[20]
    var
        BankAccount: Record "Bank Account";
    begin
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount."SWIFT Code" := LibraryUtility.GenerateRandomCode(BankAccount.FieldNo("SWIFT Code"), DATABASE::"Bank Account");
        BankAccount."Country/Region Code" := CountryCode;
        BankAccount.Validate("Post Code", FindPostCode(CountryCode));
        BankAccount."Bank Branch No." := LibraryUtility.GenerateRandomCode(BankAccount.FieldNo("Bank Branch No."), DATABASE::"Bank Account");
        BankAccount."Bank Account No." := CreateGLAccount();
        BankAccount."Transit No." := LibraryUtility.GenerateRandomCode(BankAccount.FieldNo("Transit No."), DATABASE::"Bank Account");
        BankAccount.Validate(IBAN, IBANCode);
        BankAccount."Payment Export Format" := PmtExpFormat;
        BankAccount."Credit Transfer Msg. Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        BankAccount.Modify(true);
        exit(BankAccount."No.");
    end;

    local procedure CreateBankAccountReferenceFileSetup(var ReferenceFileSetup: Record "Reference File Setup"; BankAccountNo: Code[10])
    var
        FieldLength: Integer;
    begin
        ReferenceFileSetup.Init();
        ReferenceFileSetup."No." := BankAccountNo;
        ReferenceFileSetup.Validate("Bank Party ID", LibraryUtility.GenerateRandomCode(ReferenceFileSetup.FieldNo("Bank Party ID"), DATABASE::"Reference File Setup"));
        ReferenceFileSetup."File Name" :=
          CopyStr(GenerateFileName(ReferenceFileSetup.FieldNo("File Name"), DATABASE::"Reference File Setup", 'xml', FieldLength), 1, FieldLength);
        ReferenceFileSetup.Insert();
    end;

    local procedure CreateGLAccount(): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        exit(GLAccount."No.");
    end;

    local procedure CreateVendor(CountryCode: Code[10]; IBANCode: Code[50]; SEPAPayment: Boolean; VendorPriority: Integer): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor."Country/Region Code" := CountryCode;
        Vendor.Validate("Post Code", FindPostCode(CountryCode));
        Vendor."Business Identity Code" :=
          LibraryUtility.GenerateRandomCode(Vendor.FieldNo("Business Identity Code"), DATABASE::Vendor);
        Vendor."Our Account No." := CreateGLAccount();
        Vendor.Priority := VendorPriority;
        Vendor."Preferred Bank Account Code" := CreateVendorBankAccount(Vendor."No.", CountryCode, IBANCode, SEPAPayment);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateVendorBankAccount(VendorNo: Code[20]; CountryCode: Code[10]; IBANCode: Code[50]; SEPAPayment: Boolean): Code[20]
    var
        VendorBankAccount: Record "Vendor Bank Account";
    begin
        VendorBankAccount.Init();
        VendorBankAccount."Vendor No." := VendorNo;
        VendorBankAccount.Code := LibraryUtility.GenerateRandomCode(VendorBankAccount.FieldNo(Code), DATABASE::"Vendor Bank Account");
        VendorBankAccount.Name := LibraryUtility.GenerateRandomCode(VendorBankAccount.FieldNo(Name), DATABASE::"Vendor Bank Account");
        VendorBankAccount."SWIFT Code" := LibraryUtility.GenerateRandomCode(VendorBankAccount.FieldNo("SWIFT Code"), DATABASE::"Vendor Bank Account");
        VendorBankAccount."Country/Region Code" := CountryCode;
        VendorBankAccount."Post Code" := FindPostCode(CountryCode);
        VendorBankAccount."Bank Branch No." := LibraryUtility.GenerateRandomCode(VendorBankAccount.FieldNo("Bank Branch No."), DATABASE::"Vendor Bank Account");
        VendorBankAccount."Bank Account No." := CreateGLAccount();
        VendorBankAccount."Transit No." := LibraryUtility.GenerateRandomCode(VendorBankAccount.FieldNo("Transit No."), DATABASE::"Vendor Bank Account");
        VendorBankAccount.IBAN := IBANCode;
        VendorBankAccount."SEPA Payment" := SEPAPayment;
        VendorBankAccount."Clearing Code" := LibraryUtility.GenerateRandomCode(VendorBankAccount.FieldNo("Clearing Code"), DATABASE::"Vendor Bank Account");
        VendorBankAccount.Insert();
        exit(VendorBankAccount.Code);
    end;

    local procedure GenerateFileName(FieldNo: Integer; TableNo: Integer; Extension: Text; var FieldLength: Integer): Text
    var
        RecRef: RecordRef;
        FieldRef: FieldRef;
        FullPath: Text;
    begin
        RecRef.Open(TableNo);
        FieldRef := RecRef.Field(FieldNo);
        FieldLength := FieldRef.Length;
        FullPath := TemporaryPath + LibraryUtility.GenerateRandomCode(FieldNo, TableNo) + '.' + Extension;

        Assert.IsTrue(
          FieldLength >= StrLen(FullPath),
          StrSubstNo(FullPathErr, FullPath, FieldRef.Caption, FieldLength));

        exit(FullPath);
    end;

    local procedure FindPostCode(CountryCode: Code[10]): Code[20]
    var
        PostCode: Record "Post Code";
    begin
        PostCode.SetRange("Country/Region Code", CountryCode);
        PostCode.FindFirst();
        exit(PostCode.Code);
    end;

    local procedure CreateReferancePaymentExportLines(BankAccountNo: Code[20]; VendorNo: Code[20]; var PurchaseHeader: Record "Purchase Header"): Code[20]
    var
        RefPmtExp: Record "Ref. Payment - Exported";
        SuggestBankPayments: Report "Suggest Bank Payments";
        DocNo: Code[20];
    begin
        LibraryVariableStorage.Enqueue(BankAccountNo);
        LibraryVariableStorage.Enqueue(VendorNo);
        DocNo :=
          CreateAndPostPurchaseDocumentWithRandomAmounts(
            PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo, false, true);
        RefPmtExp.DeleteAll();
        Commit();
        SuggestBankPayments.InitializeRequest(CalcDate('<30D>', PurchaseHeader."Posting Date"), false, 0);
        SuggestBankPayments.RunModal();

        exit(DocNo);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RPHSuggestBankPayments(var RequestPage: TestRequestPage "Suggest Bank Payments")
    var
        Vendor: Record Vendor;
        BankAccountNo: Variant;
        VendorNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(BankAccountNo);
        LibraryVariableStorage.Dequeue(VendorNo);
        Vendor.Get(VendorNo);

        RequestPage."Payment Account".SetValue(BankAccountNo);
        RequestPage.Vendor.SetFilter("No.", VendorNo);
        RequestPage.Vendor.SetFilter("Payment Method Code", Vendor."Payment Method Code");
        RequestPage.OK().Invoke();
    end;

    local procedure VerifySuggestedVendorPaymentsWithInvoiceMessage(VendorNo: Code[20]; DocNo: Code[20]; InvoiceMessage: Text)
    var
        RefPaymentExported: Record "Ref. Payment - Exported";
    begin
        RefPaymentExported.SetRange("Vendor No.", VendorNo);
        RefPaymentExported.SetRange("Document No.", DocNo);
        RefPaymentExported.FindFirst();
        Assert.AreEqual(
          InvoiceMessage,
          RefPaymentExported."Invoice Message",
          StrSubstNo(InvoiceMessageErr, DocNo, VendorNo));
    end;

    local procedure VerifyPaymentLine(PmtExpData: Record "Payment Export Data"; RefPmtExp: Record "Ref. Payment - Exported")
    var
        VendorBankAccount: Record "Vendor Bank Account";
        BankAccount: Record "Bank Account";
    begin
        RefPmtExp.SetRange(Transferred, true);
        RefPmtExp.SetRange("SEPA Payment", true);
        RefPmtExp.SetRange("Batch Code", PmtExpData."Message ID");
        RefPmtExp.FindFirst();

        Assert.AreEqual(1, RefPmtExp.Count, 'Only one record expected');

        Assert.AreEqual(RefPmtExp."Payment Date", RefPmtExp."Payment Execution Date", 'Incorrect Payment Execution Date');

        // Essential
        Assert.AreEqual(RefPmtExp."Payment Date", PmtExpData."Transfer Date", 'Incorrect Transfer Date');
        Assert.AreEqual(RefPmtExp.Amount, PmtExpData.Amount, 'Incorrect Amount');
        Assert.AreEqual('EUR', PmtExpData."Currency Code", 'Incorrect Currency Code');

        // Sender Account
        BankAccount.Get(RefPmtExp."Payment Account");
        Assert.AreEqual(BankAccount.IBAN, PmtExpData."Sender Bank Account No.", 'Incorrect Sender Bank Account No.');
        Assert.AreEqual(BankAccount."SWIFT Code", PmtExpData."Sender Bank BIC", 'Incorrect Sender Bank BIC');

        // Recipient Account
        VendorBankAccount.Get(RefPmtExp."Vendor No.", RefPmtExp."Vendor Account");
        Assert.AreEqual(VendorBankAccount.IBAN, PmtExpData."Recipient Bank Acc. No.", 'Incorrect Recipient Bank Acc. No.');
        Assert.AreEqual(VendorBankAccount."SWIFT Code", PmtExpData."Recipient Bank BIC", 'Incorrect Recipient Bank BIC');

        // Extra Info
        Assert.AreEqual(RefPmtExp."Description 2", PmtExpData."Recipient Name", 'Incorrect Recipient Name');
        Assert.AreEqual(RefPmtExp."Document No.", PmtExpData."Document No.", 'Incorrect Document No.');
    end;

    local procedure CreateAndPostPurchasePrepayments(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; VendorNo: Code[20]): Code[20]
    var
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, VendorNo);
        PurchaseHeader.Validate("Prepayment %", LibraryRandom.RandIntInRange(1, 99));
        PurchaseHeader.Validate("Message Type", PurchaseHeader."Message Type"::Message);
        PurchaseHeader.Validate("Invoice Message", LibraryRandom.RandText(6));
        PurchaseHeader.Validate("Invoice Message 2", LibraryRandom.RandText(6));
        PurchaseHeader.Modify(true);
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandIntInRange(1, 99));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(1000, 2));
        PurchaseLine.Modify(true);
        exit(LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader));
    end;

    local procedure RunSuggestBankPayments(BankAccountNo: Code[20]; VendorNo: Code[20]; PaymentDate: Date)
    var
        SuggestBankPayments: Report "Suggest Bank Payments";
    begin
        LibraryVariableStorage.Enqueue(BankAccountNo);
        LibraryVariableStorage.Enqueue(VendorNo);
        SuggestBankPayments.InitializeRequest(PaymentDate, false, 0);
        SuggestBankPayments.Run();

        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure VerifySuggestedVendorPaymentsWithMessageTypeAndInvoiceMessage(VendorNo: Code[20]; DocNo: Code[20]; PurchaseHeader: Record "Purchase Header")
    var
        RefPaymentExported: Record "Ref. Payment - Exported";
    begin
        RefPaymentExported.SetRange("Vendor No.", VendorNo);
        RefPaymentExported.SetRange("Document No.", DocNo);
        RefPaymentExported.FindFirst();
        Assert.AreEqual(
            PurchaseHeader."Message Type",
            RefPaymentExported."Message Type",
            StrSubstNo(MessageTypeErr, DocNo, VendorNo));
        Assert.AreEqual(
            PurchaseHeader."Invoice Message",
            RefPaymentExported."Invoice Message",
            StrSubstNo(InvoiceMessageErr, DocNo, VendorNo));
        Assert.AreEqual(
            PurchaseHeader."Invoice Message 2",
            RefPaymentExported."Invoice Message 2",
            StrSubstNo(InvoiceMessageErr, DocNo, VendorNo));
    end;
}

