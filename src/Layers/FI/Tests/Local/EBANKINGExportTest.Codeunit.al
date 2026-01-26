codeunit 144009 "E-BANKING Export Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        DomesticBankAccount: Record "Bank Account";
        ForeignBankAccount: Record "Bank Account";
        CompanyInformation: Record "Company Information";
        DomesticBankRefFileSetup: Record "Reference File Setup";
        ForeignBankRefFileSetup: Record "Reference File Setup";
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        Assert: Codeunit Assert;
        Initialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure TestDomesticPaymentFileLongVendorName()
    var
        Vendor: Record Vendor;
        ServerFileName: Text;
    begin
        Initialize();

        // Setup
        CreateDomesticVendorWithBankSetup(Vendor, 'Domestic Vendor name longer than 30', 'Bank1', '229018-72095');
        CreateAndPostPurchaseOrder(Vendor);

        // Exercise
        ServerFileName := CreateDomesticPaymentFile(Vendor);

        // Validate
        ValidateDomesticPaymentFile(Vendor, ServerFileName);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDomesticPaymentFileShortVendorName()
    var
        Vendor: Record Vendor;
        ServerFileName: Text;
    begin
        Initialize();

        // Setup
        CreateDomesticVendorWithBankSetup(Vendor, 'Domestic Vendor less than 30', 'Bank2', '229018-02332');
        CreateAndPostPurchaseOrder(Vendor);

        // Exercise
        ServerFileName := CreateDomesticPaymentFile(Vendor);

        // Validate
        ValidateDomesticPaymentFile(Vendor, ServerFileName);
    end;

    [Test]
    [HandlerFunctions('PageHandler')]
    [Scope('OnPrem')]
    procedure TestForeignPaymentFileLongVendorName()
    var
        Vendor: Record Vendor;
        ServerFileName: Text;
    begin
        Initialize();

        // Setup
        CreateForeignVendorWithBankSetup(Vendor, 'Vendor with Name longer than 35 characters', 'Bank3', '229018-72091');
        CreateAndPostPurchaseOrder(Vendor);

        // Exercise
        ServerFileName := CreateForeignPaymentFile(Vendor);

        // Validate
        ValidateForeignPaymentFile(Vendor, ServerFileName);
    end;

    [Test]
    [HandlerFunctions('PageHandler')]
    [Scope('OnPrem')]
    procedure TestForeignPaymentFileShortVendorName()
    var
        Vendor: Record Vendor;
        ServerFileName: Text;
    begin
        Initialize();

        // Setup
        CreateForeignVendorWithBankSetup(Vendor, 'Foreign Vendor name less than 35', 'Bank3', '229018-72091');
        CreateAndPostPurchaseOrder(Vendor);

        // Exercise
        ServerFileName := CreateForeignPaymentFile(Vendor);

        // Validate
        ValidateForeignPaymentFile(Vendor, ServerFileName);
    end;

    local procedure Initialize()
    begin
        if not Initialized then begin
            CompanyInformation.Get();
            Setup();
            Initialized := true;
        end;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PageHandler(var InputDialog: Page "Input Dialog"; var Response: Action)
    begin
        Response := ACTION::OK;
    end;

    local procedure CreateDomesticPaymentFile(Vendor: Record Vendor): Text
    var
        RefPaymentExported: Record "Ref. Payment - Exported";
        SuggestBankPayments: Report "Suggest Bank Payments";
        ExportRefPaymentLMP: Report "Export Ref. Payment -  LMP";
    begin
        RefPaymentExported.DeleteAll(true);

        Vendor.SetRecFilter();
        SuggestBankPayments.SetTableView(Vendor);
        SuggestBankPayments.InitializeRequest(CalcDate('<1M>', WorkDate()), false, 0);
        SuggestBankPayments.UseRequestPage := false;
        SuggestBankPayments.RunModal();

        RefPaymentExported.SetRange("Vendor No.", Vendor."No.");
        RefPaymentExported.ModifyAll("Payment Account", DomesticBankAccount."No.");

        DomesticBankAccount.SetRecFilter();
        ExportRefPaymentLMP.InitializeRequest(true);
        ExportRefPaymentLMP.SetTableView(DomesticBankAccount);
        ExportRefPaymentLMP.UseRequestPage := false;
        ExportRefPaymentLMP.RunModal();
        exit(ExportRefPaymentLMP.GetFileName());
    end;

    local procedure CreateForeignPaymentFile(Vendor: Record Vendor): Text
    var
        RefPaymentExported: Record "Ref. Payment - Exported";
        SuggestBankPayments: Report "Suggest Bank Payments";
        ExportRefPaymentLUM: Report "Export Ref. Payment -  LUM";
    begin
        RefPaymentExported.DeleteAll(true);

        Vendor.SetRecFilter();
        SuggestBankPayments.SetTableView(Vendor);
        SuggestBankPayments.InitializeRequest(CalcDate('<1M>', WorkDate()), false, 0);
        SuggestBankPayments.UseRequestPage := false;
        SuggestBankPayments.RunModal();

        RefPaymentExported.SetRange("Vendor No.", Vendor."No.");
        RefPaymentExported.ModifyAll("Payment Account", ForeignBankAccount."No.");
        RefPaymentExported.ModifyAll("Foreign Payment Method", ForeignBankRefFileSetup."Default Payment Method");
        RefPaymentExported.ModifyAll("Foreign Banks Service Fee", ForeignBankRefFileSetup."Default Service Fee Code");

        ForeignBankAccount.SetRecFilter();
        ExportRefPaymentLUM.InitializeRequest(true);
        ExportRefPaymentLUM.SetTableView(ForeignBankAccount);
        ExportRefPaymentLUM.UseRequestPage := false;
        ExportRefPaymentLUM.RunModal();
        exit(ExportRefPaymentLUM.GetFileName());
    end;

    local procedure ValidateDomesticPaymentFile(Vendor: Record Vendor; FileName: Text)
    var
        FileReader: File;
        Str: Text[1024];
        ExpectedVendorName: Text;
    begin
        FileReader.TextMode := true;
        FileReader.Open(FileName);
        FileReader.Read(Str);
        Assert.AreEqual(300, StrLen(Str), 'Header should be 300 chars long');
        Assert.IsTrue(StrPos(Str, CompanyInformation.Name) > 0,
          StrSubstNo('Line 1 does not have contain %1: %2', CompanyInformation.Name, Str));

        FileReader.Read(Str);
        Assert.AreEqual(300, StrLen(Str), 'Data lines should be 300 chars long');

        ExpectedVendorName := Vendor.Name;
        if StrLen(Vendor.Name) > 30 then begin
            ExpectedVendorName := CopyStr(Vendor.Name, 1, 30);
            Assert.IsTrue(StrPos(Str, Vendor.Name) = 0,
              StrSubstNo('Line 2 contains full vendor name %1: %2', Vendor.Name, Str));
        end;

        Assert.IsTrue(StrPos(Str, ExpectedVendorName) > 0,
          StrSubstNo('Line 2 does not contain the expected vendor name %1: %2', ExpectedVendorName, Str));

        Assert.IsTrue(FileReader.Read(Str) > 0, 'Fotter line should exist');
        Assert.AreEqual(300, StrLen(Str), 'Footer should be 300 chars long');
        Assert.IsTrue(FileReader.Read(Str) = 0, 'The file should only have 3 lines');

        FileReader.Close();
    end;

    local procedure ValidateForeignPaymentFile(Vendor: Record Vendor; FileName: Text)
    var
        FileReader: File;
        Str: Text[1024];
        ExpectedVendorName: Text;
    begin
        FileReader.TextMode := true;
        FileReader.Open(FileName);
        FileReader.Read(Str);
        FileReader.Read(Str);

        ExpectedVendorName := Vendor.Name;
        if StrLen(Vendor.Name) > 35 then begin
            ExpectedVendorName := CopyStr(Vendor.Name, 1, 35);
            Assert.IsTrue(StrPos(Str, Vendor.Name) = 0,
              StrSubstNo('Line 2 contains full vendor name %1: %2', Vendor.Name, Str));
        end;

        Assert.IsTrue(StrPos(Str, ExpectedVendorName) > 0,
          StrSubstNo('Line 2 does not contain the expected vendor name %1: %2', ExpectedVendorName, Str));

        Assert.IsTrue(FileReader.Read(Str) > 0, 'Fotter line should exist');
        Assert.IsTrue(FileReader.Read(Str) = 0, 'The file should only have 3 lines');

        FileReader.Close();
    end;

    local procedure Setup()
    var
        PurchaseAndPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchaseAndPayablesSetup.Get();
        PurchaseAndPayablesSetup."Bank Batch Nos." := 'BANK';
        PurchaseAndPayablesSetup.Modify(true);

        CreateBankAccounts();
        SetupPaymentRef('Domestic', DomesticBankAccount, DomesticBankRefFileSetup);
        SetupPaymentRef('Foreign', ForeignBankAccount, ForeignBankRefFileSetup);
    end;

    local procedure CreateBankAccounts()
    begin
        LibraryERM.CreateBankAccount(DomesticBankAccount);
        DomesticBankAccount."Country/Region Code" := '';
        DomesticBankAccount."Bank Branch No." := '12321';
        DomesticBankAccount."Bank Account No." := '2229018-7205';
        DomesticBankAccount.Modify(true);

        LibraryERM.CreateBankAccount(ForeignBankAccount);
        ForeignBankAccount."Country/Region Code" := 'FI';
        ForeignBankAccount."Bank Branch No." := '12321';
        ForeignBankAccount."Bank Account No." := '2229018-7206';
        ForeignBankAccount.Modify(true);
    end;

    local procedure SetupPaymentRef(Type: Text; BankAccount: Record "Bank Account"; var BankRefFileSetup: Record "Reference File Setup")
    var
        ForeignPaymentTypes: Record "Foreign Payment Types";
        Code1: Code[1];
        Code2: Code[1];
    begin
        if Type = 'Domestic' then begin
            Code1 := 'A';
            Code2 := 'B';
        end else begin
            Code1 := 'X';
            Code2 := 'Y';
        end;

        ForeignPaymentTypes.Init();
        ForeignPaymentTypes.Code := Code1;
        ForeignPaymentTypes.Banks := BankAccount."No.";
        ForeignPaymentTypes.Insert(true);

        ForeignPaymentTypes.Init();
        ForeignPaymentTypes.Code := Code2;
        ForeignPaymentTypes.Banks := BankAccount."No.";
        ForeignPaymentTypes.Insert(true);

        BankRefFileSetup.Init();
        BankRefFileSetup."No." := BankAccount."No.";
        BankRefFileSetup."Default Payment Method" := Code1;
        BankRefFileSetup."Default Service Fee Code" := Code2;
        BankRefFileSetup.Insert(true);
    end;

    local procedure CreateDomesticVendorWithBankSetup(var Vendor: Record Vendor; Name: Text[50]; BankAccountName: Text[50]; BankAccountNo: Text[30])
    var
        VendorBankAccount: Record "Vendor Bank Account";
    begin
        LibraryPurchase.CreateVendor(Vendor);

        LibraryPurchase.CreateVendorBankAccount(VendorBankAccount, Vendor."No.");
        VendorBankAccount.Name := BankAccountName;
        VendorBankAccount."Bank Account No." := BankAccountNo;
        VendorBankAccount.Modify(true);

        Vendor.Name := Name;
        Vendor."Country/Region Code" := CompanyInformation."Country/Region Code";
        Vendor."Gen. Bus. Posting Group" := 'DOMESTIC';
        Vendor."VAT Bus. Posting Group" := 'DOMESTIC';
        Vendor."Vendor Posting Group" := 'DOMESTIC';
        Vendor."Preferred Bank Account Code" := VendorBankAccount.Code;
        Vendor.Modify(true);
    end;

    local procedure CreateForeignVendorWithBankSetup(var Vendor: Record Vendor; Name: Text[50]; BankAccountName: Text[50]; BankAccountNo: Text[30])
    var
        VendorBankAccount: Record "Vendor Bank Account";
    begin
        LibraryPurchase.CreateVendor(Vendor);

        LibraryPurchase.CreateVendorBankAccount(VendorBankAccount, Vendor."No.");
        VendorBankAccount.Name := BankAccountName;
        VendorBankAccount."Bank Account No." := BankAccountNo;
        VendorBankAccount."Country/Region Code" := 'HU';
        VendorBankAccount.Modify(true);

        Vendor.Name := Name;
        Vendor."Country/Region Code" := 'HU';
        Vendor."Gen. Bus. Posting Group" := 'EU';
        Vendor."VAT Bus. Posting Group" := 'EU';
        Vendor."Vendor Posting Group" := 'EU';
        Vendor."Preferred Bank Account Code" := VendorBankAccount.Code;
        Vendor.Modify(true);
    end;

    local procedure CreateAndPostPurchaseOrder(var Vendor: Record Vendor)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        PurchaseHeader."Message Type" := PurchaseHeader."Message Type"::Message;
        PurchaseHeader."Invoice Message" := Vendor.Name;
        PurchaseHeader.Modify(true);

        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine."Document Type"::Invoice, '1000', 1);
        PurchaseLine.Validate("VAT Prod. Posting Group", 'NO VAT');
        PurchaseLine.Validate("Direct Unit Cost", 1000.0);
        PurchaseLine.Modify(true);

        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;
}

