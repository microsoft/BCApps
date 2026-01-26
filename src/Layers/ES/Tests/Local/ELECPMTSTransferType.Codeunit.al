codeunit 144010 "ELECPMTS Transfer Type"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        LocalCountryRegion: Record "Country/Region";
        OutsideCountryRegion: Record "Country/Region";
        GenBusPostingGroup: Record "Gen. Business Posting Group";
        PaymentMethod: Record "Payment Method";
        LibraryRandom: Codeunit "Library - Random";
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        Assert: Codeunit Assert;
        LibraryUtility: Codeunit "Library - Utility";
        LibraryCarteraPayables: Codeunit "Library - Cartera Payables";

    [Test]
    [Scope('OnPrem')]
    procedure TransferTypeSpeciaLocalVendorBankAccountCarteraDoc()
    var
        BankAccount: Record "Bank Account";
        PurchaseHeader: Record "Purchase Header";
        CarteraDoc: Record "Cartera Doc.";
        Vendor: Record Vendor;
        DocNo: Code[20];
        ActualTransferType: Option;
        UnitCost: Decimal;
    begin
        Initialize();
        CreateLocalCompany();

        // Setup
        CreateLocalCompanyBankAccount(BankAccount);

        LibraryCarteraPayables.CreateBillToCarteraPaymentMethod(PaymentMethod);

        CreateForeignVendor(Vendor, PaymentMethod.Code);

        CreateVendorBankAccountWithEpay(Vendor."No.", LocalCountryRegion.Code);
        CreateVendorBankAccountWithoutEpay(Vendor."No.", OutsideCountryRegion.Code);

        // Exercise
        UnitCost := LibraryRandom.RandDecInRange(12500, 50000, 2);
        CreatePurchaseInvoice(PurchaseHeader, Vendor."No.", UnitCost);
        DocNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Get document to verify
        CarteraDoc.SetFilter("Document No.", DocNo);
        CarteraDoc.FindFirst();

        // Verify
        ActualTransferType := CarteraDoc."Transfer Type";
        Assert.AreEqual(CarteraDoc."Transfer Type"::Special, ActualTransferType, 'Value of Transfer Type should be Special');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferTypeSpeciaForeignVendorBankAccountCarteraDoc()
    var
        BankAccount: Record "Bank Account";
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        CarteraDoc: Record "Cartera Doc.";
        DocNo: Code[20];
        ActualTransferType: Option;
        UnitCost: Decimal;
    begin
        Initialize();
        CreateLocalCompany();

        // Setup
        CreateLocalCompanyBankAccount(BankAccount);

        LibraryCarteraPayables.CreateBillToCarteraPaymentMethod(PaymentMethod);

        CreateForeignVendor(Vendor, PaymentMethod.Code);

        CreateVendorBankAccountWithEpay(Vendor."No.", OutsideCountryRegion.Code);
        CreateVendorBankAccountWithoutEpay(Vendor."No.", LocalCountryRegion.Code);

        UnitCost := LibraryRandom.RandDecInRange(12500, 50000, 2);
        CreatePurchaseInvoice(PurchaseHeader, Vendor."No.", UnitCost);
        DocNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Get document to verify
        CarteraDoc.SetFilter("Document No.", DocNo);
        CarteraDoc.FindFirst();

        // Verify
        ActualTransferType := CarteraDoc."Transfer Type";
        Assert.AreEqual(CarteraDoc."Transfer Type"::Special, ActualTransferType, 'Value of Transfer Type should be Special');
    end;

    [Test]
    [HandlerFunctions('MsgHandler')]
    [Scope('OnPrem')]
    procedure TransferTypeSpecialForeignVendorBankAccount()
    var
        BankAccount: Record "Bank Account";
        PurchaseHeader: Record "Purchase Header";
        GenJnlLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
        ActualTransferType: Option;
        UnitCost: Decimal;
    begin
        Initialize();
        CreateLocalCompany();

        // Setup
        CreateLocalCompanyBankAccount(BankAccount);

        LibraryERM.CreatePaymentMethod(PaymentMethod);

        CreateForeignVendor(Vendor, PaymentMethod.Code);

        CreateVendorBankAccountWithEpay(Vendor."No.", OutsideCountryRegion.Code);
        CreateVendorBankAccountWithoutEpay(Vendor."No.", LocalCountryRegion.Code);

        UnitCost := LibraryRandom.RandDecInRange(12500, 50000, 2);
        CreatePurchaseInvoice(PurchaseHeader, Vendor."No.", UnitCost);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Exercise
        RunSuggestVendorPayments(BankAccount."No.", Vendor."No.");

        GenJnlLine.SetRange("Account No.", Vendor."No.");
        GenJnlLine.FindFirst();

        // Verify
        ActualTransferType := GenJnlLine."Transfer Type";
        Assert.AreEqual(GenJnlLine."Transfer Type"::Special, ActualTransferType, 'Value of Transfer Type should be Special');
    end;

    [Test]
    [HandlerFunctions('MsgHandler')]
    [Scope('OnPrem')]
    procedure TransferTypeSpecialLocalVendorBankAccount()
    var
        BankAccount: Record "Bank Account";
        PurchaseHeader: Record "Purchase Header";
        GenJnlLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
        ActualTransferType: Option;
        UnitCost: Decimal;
    begin
        Initialize();
        CreateLocalCompany();

        // Setup
        CreateLocalCompanyBankAccount(BankAccount);

        LibraryERM.CreatePaymentMethod(PaymentMethod);

        CreateForeignVendor(Vendor, PaymentMethod.Code);

        CreateVendorBankAccountWithEpay(Vendor."No.", LocalCountryRegion.Code);
        CreateVendorBankAccountWithoutEpay(Vendor."No.", OutsideCountryRegion.Code);

        UnitCost := LibraryRandom.RandDecInRange(12500, 50000, 2);
        CreatePurchaseInvoice(PurchaseHeader, Vendor."No.", UnitCost);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Exercise
        RunSuggestVendorPayments(BankAccount."No.", Vendor."No.");

        GenJnlLine.SetRange("Account No.", Vendor."No.");
        GenJnlLine.FindFirst();

        // Verify
        ActualTransferType := GenJnlLine."Transfer Type";
        Assert.AreEqual(GenJnlLine."Transfer Type"::Special, ActualTransferType, 'Value of Transfer Type should be Special');
    end;

    [Test]
    [HandlerFunctions('MsgHandler')]
    [Scope('OnPrem')]
    procedure TransferTypeInternationalForeignCoLocalBankAccountForeignVendorBankAccountHighAmount()
    var
        BankAccount: Record "Bank Account";
        PurchaseHeader: Record "Purchase Header";
        GenJnlLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
        ActualTransferType: Option;
        UnitCost: Decimal;
    begin
        Initialize();
        CreateForeignCompany();

        // Setup
        CreateLocalCompanyBankAccount(BankAccount);

        LibraryERM.CreatePaymentMethod(PaymentMethod);

        CreateForeignVendor(Vendor, PaymentMethod.Code);

        CreateVendorBankAccountWithEpay(Vendor."No.", OutsideCountryRegion.Code);
        CreateVendorBankAccountWithoutEpay(Vendor."No.", LocalCountryRegion.Code);

        UnitCost := LibraryRandom.RandDecInRange(12500, 50000, 2);
        CreatePurchaseInvoice(PurchaseHeader, Vendor."No.", UnitCost);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Exercise
        RunSuggestVendorPayments(BankAccount."No.", Vendor."No.");

        GenJnlLine.SetRange("Account No.", Vendor."No.");
        GenJnlLine.FindFirst();

        // Verify
        ActualTransferType := GenJnlLine."Transfer Type";
        Assert.AreEqual(GenJnlLine."Transfer Type"::International, ActualTransferType, 'Value of Transfer Type should be International');
    end;

    [Test]
    [HandlerFunctions('MsgHandler')]
    [Scope('OnPrem')]
    procedure TransferTypeInternationalForeignCoLocalBankAccountForeignVendorBankAccountLowAmount()
    var
        BankAccount: Record "Bank Account";
        PurchaseHeader: Record "Purchase Header";
        GenJnlLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
        ActualTransferType: Option;
        UnitCost: Decimal;
    begin
        Initialize();
        CreateForeignCompany();

        // Setup
        CreateLocalCompanyBankAccount(BankAccount);

        LibraryERM.CreatePaymentMethod(PaymentMethod);

        CreateForeignVendor(Vendor, PaymentMethod.Code);

        CreateVendorBankAccountWithEpay(Vendor."No.", OutsideCountryRegion.Code);
        CreateVendorBankAccountWithoutEpay(Vendor."No.", LocalCountryRegion.Code);

        UnitCost := LibraryRandom.RandDec(12500, 2);
        CreatePurchaseInvoice(PurchaseHeader, Vendor."No.", UnitCost);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Exercise
        RunSuggestVendorPayments(BankAccount."No.", Vendor."No.");

        GenJnlLine.SetRange("Account No.", Vendor."No.");
        GenJnlLine.FindFirst();

        // Verify
        ActualTransferType := GenJnlLine."Transfer Type";
        Assert.AreEqual(GenJnlLine."Transfer Type"::International, ActualTransferType, 'Value of Transfer Type should be International');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferTypeInternationalForeignCoLocalBankAccountForeignVendorBankAccountCarteraDocHighAmount()
    var
        BankAccount: Record "Bank Account";
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        CarteraDoc: Record "Cartera Doc.";
        ActualTransferType: Option;
        UnitCost: Decimal;
        DocNo: Code[20];
    begin
        Initialize();
        CreateForeignCompany();

        // Setup
        CreateLocalCompanyBankAccount(BankAccount);

        LibraryCarteraPayables.CreateBillToCarteraPaymentMethod(PaymentMethod);

        CreateForeignVendor(Vendor, PaymentMethod.Code);

        CreateVendorBankAccountWithEpay(Vendor."No.", OutsideCountryRegion.Code);
        CreateVendorBankAccountWithoutEpay(Vendor."No.", LocalCountryRegion.Code);

        // Exercise
        UnitCost := LibraryRandom.RandDecInRange(12500, 50000, 2);
        CreatePurchaseInvoice(PurchaseHeader, Vendor."No.", UnitCost);
        DocNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Get document to verify
        CarteraDoc.SetFilter("Document No.", DocNo);
        CarteraDoc.FindFirst();

        // Verify
        ActualTransferType := CarteraDoc."Transfer Type";
        Assert.AreEqual(CarteraDoc."Transfer Type"::International, ActualTransferType, 'Value of Transfer Type should be International');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferTypeInternationallForeignCoLocalBankAccountForeignVendorBankAccountCarteraDocLowAmount()
    var
        BankAccount: Record "Bank Account";
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        CarteraDoc: Record "Cartera Doc.";
        ActualTransferType: Option;
        UnitCost: Decimal;
        DocNo: Code[20];
    begin
        Initialize();
        CreateForeignCompany();

        // Setup
        CreateLocalCompanyBankAccount(BankAccount);

        LibraryCarteraPayables.CreateBillToCarteraPaymentMethod(PaymentMethod);

        CreateForeignVendor(Vendor, PaymentMethod.Code);

        CreateVendorBankAccountWithEpay(Vendor."No.", OutsideCountryRegion.Code);
        CreateVendorBankAccountWithoutEpay(Vendor."No.", LocalCountryRegion.Code);

        // Exercise
        UnitCost := LibraryRandom.RandDec(12500, 2);
        CreatePurchaseInvoice(PurchaseHeader, Vendor."No.", UnitCost);
        DocNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Get document to verify
        CarteraDoc.SetFilter("Document No.", DocNo);
        CarteraDoc.FindFirst();

        // Verify
        ActualTransferType := CarteraDoc."Transfer Type";
        Assert.AreEqual(CarteraDoc."Transfer Type"::International, ActualTransferType, 'Value of Transfer Type should be International');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferTypeInternationalLocalCoLocalBankAccountForeignVendorBankAccountCarteraDoc()
    var
        BankAccount: Record "Bank Account";
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        CarteraDoc: Record "Cartera Doc.";
        ActualTransferType: Option;
        UnitCost: Decimal;
        DocNo: Code[20];
    begin
        Initialize();
        CreateLocalCompany();

        // Setup
        CreateLocalCompanyBankAccount(BankAccount);

        LibraryCarteraPayables.CreateBillToCarteraPaymentMethod(PaymentMethod);

        CreateForeignVendor(Vendor, PaymentMethod.Code);

        CreateVendorBankAccountWithEpay(Vendor."No.", OutsideCountryRegion.Code);
        CreateVendorBankAccountWithoutEpay(Vendor."No.", LocalCountryRegion.Code);

        // Exercise
        UnitCost := LibraryRandom.RandDec(9000, 2);
        CreatePurchaseInvoice(PurchaseHeader, Vendor."No.", UnitCost);
        DocNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Get document to verify
        CarteraDoc.SetFilter("Document No.", DocNo);
        CarteraDoc.FindFirst();

        // Verify
        ActualTransferType := CarteraDoc."Transfer Type";
        Assert.AreEqual(CarteraDoc."Transfer Type"::International, ActualTransferType, 'Value of Transfer Type should be International');
    end;

    [Test]
    [HandlerFunctions('MsgHandler')]
    [Scope('OnPrem')]
    procedure TransferTypeNationalLocalBankAccountLowAmount()
    var
        BankAccount: Record "Bank Account";
        PurchaseHeader: Record "Purchase Header";
        GenJnlLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
        ActualTransferType: Option;
        UnitCost: Decimal;
    begin
        Initialize();
        CreateLocalCompany();

        // Setup
        CreateLocalCompanyBankAccount(BankAccount);

        LibraryERM.CreatePaymentMethod(PaymentMethod);

        CreateForeignVendor(Vendor, PaymentMethod.Code);

        CreateVendorBankAccountWithEpay(Vendor."No.", LocalCountryRegion.Code);
        CreateVendorBankAccountWithoutEpay(Vendor."No.", OutsideCountryRegion.Code);

        UnitCost := LibraryRandom.RandDec(9000, 2);
        CreatePurchaseInvoice(PurchaseHeader, Vendor."No.", UnitCost);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Exercise
        RunSuggestVendorPayments(BankAccount."No.", Vendor."No.");

        GenJnlLine.SetRange("Account No.", Vendor."No.");
        GenJnlLine.FindFirst();

        // Verify
        ActualTransferType := GenJnlLine."Transfer Type";
        Assert.AreEqual(GenJnlLine."Transfer Type"::National, ActualTransferType, 'Value of Transfer Type should be National');
    end;

    local procedure Initialize()
    begin
        LocalCountryRegion.Get('ES');
        OutsideCountryRegion.SetFilter(Code, '<>ES');
        OutsideCountryRegion.FindFirst();
        GenBusPostingGroup.Get('EU');
    end;

    local procedure CreateForeignCompany()
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        CompanyInformation."Country/Region Code" := OutsideCountryRegion.Code;
        CompanyInformation.Modify();
    end;

    local procedure CreateLocalCompany()
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        CompanyInformation."Country/Region Code" := LocalCountryRegion.Code;
        CompanyInformation.Modify();
    end;

    local procedure CreateCompanyBankAccount(var BankAccount: Record "Bank Account"; CountryRegionCode: Code[10])
    begin
        LibraryCarteraPayables.CreateBankAccount(BankAccount, '');
        BankAccount.Validate("Country/Region Code", CountryRegionCode);
        BankAccount.Modify(true);
    end;

    local procedure CreateLocalCompanyBankAccount(var BankAccount: Record "Bank Account")
    begin
        CreateCompanyBankAccount(BankAccount, LocalCountryRegion.Code);
    end;

    local procedure CreateForeignVendor(var Vendor: Record Vendor; PaymentMethodCode: Code[10])
    begin
        LibraryCarteraPayables.CreateCarteraVendor(Vendor, '', PaymentMethodCode);
        Vendor.Validate("Country/Region Code", OutsideCountryRegion.Code);
        Vendor.Modify(true);
    end;

    local procedure CreateVendorBankAccountWithEpay(VendorNo: Code[20]; CountryCode: Code[10])
    begin
        CreateVendorBankAccount(VendorNo, CountryCode, true);
    end;

    local procedure CreateVendorBankAccountWithoutEpay(VendorNo: Code[20]; CountryCode: Code[10])
    begin
        CreateVendorBankAccount(VendorNo, CountryCode, false);
    end;

    local procedure CreateVendorBankAccount(VendorNo: Code[20]; CountryCode: Code[10]; UseForEpay: Boolean): Code[10]
    var
        VendorBankAccount: Record "Vendor Bank Account";
    begin
        LibraryPurchase.CreateVendorBankAccount(VendorBankAccount, VendorNo);
        VendorBankAccount.Validate("Country/Region Code", CountryCode);
        VendorBankAccount.Validate("Use For Electronic Payments", UseForEpay);
        VendorBankAccount.Validate("CCC Bank No.",
          LibraryUtility.GenerateRandomCode(VendorBankAccount.FieldNo("CCC Bank No."), DATABASE::"Vendor Bank Account"));
        VendorBankAccount.Validate("CCC Bank Branch No.",
          LibraryUtility.GenerateRandomCode(VendorBankAccount.FieldNo("CCC Bank Branch No."), DATABASE::"Vendor Bank Account"));
        VendorBankAccount.Validate("CCC Control Digits",
          LibraryUtility.GenerateRandomCode(VendorBankAccount.FieldNo("CCC Control Digits"), DATABASE::"Vendor Bank Account"));
        VendorBankAccount.Validate("CCC Bank Account No.",
          LibraryUtility.GenerateRandomCode(VendorBankAccount.FieldNo("CCC Bank Account No."), DATABASE::"Vendor Bank Account"));
        VendorBankAccount.Modify();
        exit(VendorBankAccount.Code);
    end;

    local procedure CreatePurchaseInvoice(var PurchaseHeader: Record "Purchase Header"; VendorNo: Code[20]; UnitCost: Decimal)
    var
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
    begin
        LibrarySales.FindItem(Item);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 1);
        PurchaseLine.Validate("Direct Unit Cost", UnitCost);
        PurchaseLine.Modify(true);
    end;

    local procedure RunSuggestVendorPayments(BankAccountNo: Code[20]; VendorNo: Code[20])
    var
        GenJnlTemplate: Record "Gen. Journal Template";
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
        SuggestVendorPayments: Report "Suggest Vendor Payments";
    begin
        GenJnlTemplate.SetRange(Type, GenJnlTemplate.Type::Payments);
        LibraryERM.FindGenJournalTemplate(GenJnlTemplate);
        LibraryERM.CreateGenJournalBatch(GenJnlBatch, GenJnlTemplate.Name);

        GenJnlLine.Init();
        GenJnlLine.Validate("Journal Template Name", GenJnlBatch."Journal Template Name");
        GenJnlLine.Validate("Journal Batch Name", GenJnlBatch.Name);
        SuggestVendorPayments.SetGenJnlLine(GenJnlLine);

        Vendor.SetRange("No.", VendorNo);
        SuggestVendorPayments.SetTableView(Vendor);

        SuggestVendorPayments.InitializeRequest(CalcDate('<30D>', WorkDate()), false, 0, false, WorkDate(), '0', true,
          GenJnlLine."Bal. Account Type"::"Bank Account", BankAccountNo, GenJnlLine."Bank Payment Type"::"Electronic Payment");
        Commit();
        SuggestVendorPayments.UseRequestPage(false);
        SuggestVendorPayments.Run();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MsgHandler(Message: Text[1024])
    begin
    end;
}

