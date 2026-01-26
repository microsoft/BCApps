codeunit 144026 "SEPA Bank Payment Export"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        IsInitialized := false;
    end;

    var
        CountryRegion: Record "Country/Region";
        TempBlobGlobal: Codeunit "Temp Blob";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        LibraryXPathXMLReader: Codeunit "Library - XPath XML Reader";
        IsInitialized: Boolean;
        FullPathErr: Label 'File full path ''%1'' exceeds length (%3) of field ''%2'' ', Comment = '.';
        SEPAXmlDocNamespaceTxt: Label 'urn:iso:std:iso:20022:tech:xsd:pain.001.001.02', Locked = true;

    [Test]
    [HandlerFunctions('RPHSuggestBankPayments,MessageHandler')]
    [Scope('OnPrem')]
    procedure SEPAV2PaymentCanBeExported()
    var
        PurchaseHeader: Record "Purchase Header";
        RefPaymentExported: Record "Ref. Payment - Exported";
        RefFileSetup: Record "Reference File Setup";
        BankAccountNo: Code[20];
        VendorNo: Code[20];
    begin
        // Initialize
        Initialize();
        BankAccountNo := CreateBankAccount(CountryRegion.Code, 'FI9780RBOS16173241116737', 'SEPACT V02', '');
        CreateBankAccountReferenceFileSetup(RefFileSetup, BankAccountNo);
        VendorNo := CreateVendor(CountryRegion.Code, 'FI9780RBOS16173241116737', true, 1);

        CreateReferancePaymentExportLines(BankAccountNo, VendorNo, PurchaseHeader);

        // Excercise
        RefPaymentExported.SetRange(Transferred, false);
        RefPaymentExported.SetRange("Applied Payments", false);
        RefPaymentExported.SetRange("SEPA Payment", true);
        RefPaymentExported.FindFirst();
        RefPaymentExported.ExportToFile();

        // Verify
        // No erros occur!
    end;

    [Test]
    [HandlerFunctions('RPHSuggestBankPayments')]
    procedure ProcessSEPAPaymentsWorksOnWebclient()
    var
        PurchaseHeader: Record "Purchase Header";
        RefPaymentExported: Record "Ref. Payment - Exported";
        ReferenceFileSetup: Record "Reference File Setup";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        SEPABankPaymentExport: Codeunit "SEPA Bank Payment Export";
        TempBlob: Codeunit "Temp Blob";
        BlobInStream: InStream;
        XmlFirstByte: Byte;
        BOMFirstByte: Byte;
        BankAccountNo: Code[20];
        VendorNo: Code[20];
        ValidIBANCode: Code[50];
    begin
        // [SCENARIO 278682] Process SEPA payments action works on webclient
        // [SCENARIO 494956] Exported XML file does not contain UTF-8 BOM characters.
        Initialize();

        // [GIVEN] Client type was webclient
        BindSubscription(TestClientTypeSubscriber);
        TestClientTypeSubscriber.SetClientType(CLIENTTYPE::Web);
        // [GIVEN] Full setup was available for SEPA Payment report to run
        ValidIBANCode := 'FI9780RBOS16173241116737';
        BankAccountNo := CreateBankAccount(CountryRegion.Code, ValidIBANCode, 'SEPACT V02', '');
        CreateBankAccountReferenceFileSetup(ReferenceFileSetup, BankAccountNo);
        VendorNo := CreateVendor(CountryRegion.Code, ValidIBANCode, true, 1);
        CreateReferancePaymentExportLines(BankAccountNo, VendorNo, PurchaseHeader);

        // [WHEN] Run Process SEPA payments report
        BindSubscription(SEPABankPaymentExport);
        RefPaymentExported.FindFirst();
        RefPaymentExported.ExportToFile();
        // RequestPage handled by RPHSuggestBankPayments handler

        // [THEN] The report runs with no errors
        SEPABankPaymentExport.GetBlobWithXmlDocContent(TempBlob);
        LibraryXPathXMLReader.InitializeWithBlob(TempBlob, SEPAXmlDocNamespaceTxt);
        LibraryXPathXMLReader.VerifyNodeValueByXPath('/Document/pain.001.001.02/PmtInf/DbtrAcct/Id/IBAN', ValidIBANCode);

        // [THEN] The exported XML file does not contain UTF-8 BOM characters.
        BOMFirstByte := 239;    // 0xEF
        TempBlob.CreateInStream(BlobInStream);
        BlobInStream.Read(XmlFirstByte, 1);
        Assert.AreNotEqual(BOMFirstByte, XmlFirstByte, 'The exported XML file contains UTF-8 BOM characters.');
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SEPA Bank Payment Export");
        LibraryVariableStorage.Clear();
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SEPA Bank Payment Export");

        IsInitialized := true;

        CountryRegion.Get('FI');
        InitCompanyInformation(CountryRegion.Code);
        SetupNoSeries(true, false, false, '', '');
        InitGeneralLedgerSetup('EUR');
        InitCountryRegion(CountryRegion.Code, true);
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SEPA Bank Payment Export");
    end;

    local procedure InitCompanyInformation(CountryCode: Code[10])
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        CompanyInformation."Country/Region Code" := CountryCode;
        CompanyInformation.Modify();
    end;

    local procedure InitGeneralLedgerSetup(LCYCode: Code[10])
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

    local procedure CreateBankAccount(CountryCode: Code[10]; IBANCode: Code[50]; PmtExpFormat: Code[20]; SEPACTNoSeries: Code[20]): Code[20]
    var
        BankAccount: Record "Bank Account";
    begin
        BankAccount.Init();
        BankAccount."No." := LibraryUtility.GenerateRandomCode(BankAccount.FieldNo("No."), DATABASE::"Bank Account");
        BankAccount.Name := LibraryUtility.GenerateRandomCode(BankAccount.FieldNo(Name), DATABASE::"Bank Account");
        BankAccount."SWIFT Code" := LibraryUtility.GenerateRandomCode(BankAccount.FieldNo("SWIFT Code"), DATABASE::"Bank Account");
        BankAccount."Country/Region Code" := CountryCode;
        BankAccount.Validate("Post Code", FindPostCode(CountryCode));
        BankAccount."Bank Branch No." := LibraryUtility.GenerateRandomCode(BankAccount.FieldNo("Bank Branch No."), DATABASE::"Bank Account");
        BankAccount."Bank Account No." := CreateGLAccount();
        BankAccount."Bank Acc. Posting Group" := CreateBankAccountPostingGroup();
        BankAccount."Transit No." := LibraryUtility.GenerateRandomCode(BankAccount.FieldNo("Transit No."), DATABASE::"Bank Account");
        BankAccount.Validate(IBAN, IBANCode);
        BankAccount."Payment Export Format" := PmtExpFormat;
        BankAccount."Credit Transfer Msg. Nos." := SEPACTNoSeries;
        BankAccount.Insert();
        exit(BankAccount."No.");
    end;

    local procedure FindPostCode(CountryCode: Code[10]): Code[20]
    var
        PostCode: Record "Post Code";
    begin
        PostCode.SetRange("Country/Region Code", CountryCode);
        PostCode.FindFirst();
        exit(PostCode.Code);
    end;

    local procedure CreateGLAccount(): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        exit(GLAccount."No.");
    end;

    local procedure CreateBankAccountPostingGroup(): Code[20]
    var
        BankAccountPostingGroup: Record "Bank Account Posting Group";
    begin
        BankAccountPostingGroup.Init();
        BankAccountPostingGroup.Code := LibraryUtility.GenerateRandomCode(BankAccountPostingGroup.FieldNo(Code), DATABASE::"Bank Account Posting Group");
        BankAccountPostingGroup."G/L Account No." := CreateGLAccount();
        BankAccountPostingGroup.Insert();
        exit(BankAccountPostingGroup.Code);
    end;

    local procedure CreateBankAccountReferenceFileSetup(var ReferenceFileSetup: Record "Reference File Setup"; BankAccountNo: Code[20])
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

    local procedure CreateVendorBankAccount(VendorNo: Code[20]; CountryCode: Code[10]; IBANCode: Code[50]; SEPAPayment: Boolean): Code[10]
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

    local procedure CreateReferancePaymentExportLines(BankAccountNo: Code[20]; VendorNo: Code[20]; var PurchaseHeader: Record "Purchase Header"): Code[20]
    var
        RefPaymentExported: Record "Ref. Payment - Exported";
        SuggestBankPayments: Report "Suggest Bank Payments";
        DocNo: Code[20];
    begin
        LibraryVariableStorage.Enqueue(BankAccountNo);
        LibraryVariableStorage.Enqueue(VendorNo);
        DocNo :=
          CreateAndPostPurchaseDocumentWithRandomAmounts(
            PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo, false, true);
        RefPaymentExported.DeleteAll();
        Commit();
        SuggestBankPayments.InitializeRequest(CalcDate('<30D>', PurchaseHeader."Posting Date"), false, 0);
        SuggestBankPayments.RunModal();

        exit(DocNo);
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

    procedure GetBlobWithXmlDocContent(var TempBlob: Codeunit "Temp Blob")
    begin
        TempBlob := TempBlobGlobal;
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

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        // Dummy message handler.
    end;

    [EventSubscriber(ObjectType::Report, Report::"Export SEPA Payment File", 'OnBeforeDownloadFromBlob', '', false, false)]
    local procedure CancelDownloadOnBeforeDownloadFromBlob(var TempBlob: Codeunit "Temp Blob"; var CancelDownload: Boolean)
    begin
        CancelDownload := true;
        TempBlobGlobal := TempBlob;
    end;
}

