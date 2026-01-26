codeunit 144002 "Single VAT Code UT"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [VAT] [VAT Code]
    end;

    var
        Assert: Codeunit Assert;
        LibrarySales: Codeunit "Library - Sales";
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryUtility: Codeunit "Library - Utility";
        IsInitialized: Boolean;

    local procedure Initialize()
    begin
        if IsInitialized then
            exit;

        IsInitialized := true;
        Commit();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenJnlLine_InitVATCode()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        Initialize();

        CreateVATPostingSetup(VATPostingSetup);

        GenJournalLine.Init();
        GenJournalLine.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        GenJournalLine.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");

        Assert.AreEqual(VATPostingSetup."VAT Number", GenJournalLine."VAT Number", 'The VATCode should be assigned to General journal');

        GenJournalLine.Validate("VAT Prod. Posting Group", '');
        Assert.AreEqual('', GenJournalLine."VAT Number", 'The VATCode should be empty');

        GenJournalLine.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        Assert.AreEqual(VATPostingSetup."VAT Number", GenJournalLine."VAT Number", 'The VATCode should be assigned to General journal');

        GenJournalLine.Validate("VAT Bus. Posting Group", '');
        Assert.AreEqual('', GenJournalLine."VAT Number", 'The VATCode should be empty');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenJnlLine_InitBalVATCode()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        Initialize();

        CreateVATPostingSetup(VATPostingSetup);

        GenJournalLine.Init();
        GenJournalLine.Validate("Bal. VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        GenJournalLine.Validate("Bal. VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");

        Assert.AreEqual(VATPostingSetup."VAT Number", GenJournalLine."Bal. VAT Number", 'The VATCode should be assigned to General journal');

        GenJournalLine.Validate("Bal. VAT Prod. Posting Group", '');
        Assert.AreEqual('', GenJournalLine."Bal. VAT Number", 'The VATCode should be empty');

        GenJournalLine.Validate("Bal. VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        Assert.AreEqual(VATPostingSetup."VAT Number", GenJournalLine."Bal. VAT Number", 'The VATCode should be assigned to General journal');

        GenJournalLine.Validate("Bal. VAT Bus. Posting Group", '');
        Assert.AreEqual('', GenJournalLine."Bal. VAT Number", 'The VATCode should be empty');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenJnlLine_InitVATPostingSetup()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        Initialize();

        CreateVATPostingSetup(VATPostingSetup);

        GenJournalLine.Init();
        GenJournalLine.Validate("VAT Number", VATPostingSetup."VAT Number");

        Assert.AreEqual(VATPostingSetup."VAT Prod. Posting Group", GenJournalLine."VAT Prod. Posting Group",
          'The VAT prod posting group should be assigned to General journal');
        Assert.AreEqual(VATPostingSetup."VAT Prod. Posting Group", GenJournalLine."VAT Prod. Posting Group",
          'The VAT Bus. posting group should be assigned to General journal');

        GenJournalLine.Validate("VAT Number", '');
        Assert.AreEqual('', GenJournalLine."VAT Prod. Posting Group",
          'The VAT prod posting group should be empty');
        Assert.AreEqual('', GenJournalLine."VAT Bus. Posting Group",
          'The VAT Bus. posting group should be empty');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenJnlLine_InitBalVATPostingSetup()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        Initialize();

        CreateVATPostingSetup(VATPostingSetup);

        GenJournalLine.Init();
        GenJournalLine.Validate("Bal. VAT Number", VATPostingSetup."VAT Number");

        Assert.AreEqual(VATPostingSetup."VAT Prod. Posting Group", GenJournalLine."Bal. VAT Prod. Posting Group",
          'The Bal. VAT prod posting group should be assigned to General journal');
        Assert.AreEqual(VATPostingSetup."VAT Prod. Posting Group", GenJournalLine."Bal. VAT Prod. Posting Group",
          'The Bal. VAT Bus. posting group should be assigned to General journal');

        GenJournalLine.Validate("Bal. VAT Number", '');
        Assert.AreEqual('', GenJournalLine."Bal. VAT Prod. Posting Group",
          'The Bal. VAT prod posting group should be empty');
        Assert.AreEqual('', GenJournalLine."Bal. VAT Bus. Posting Group",
          'The Bal. VAT Bus. posting group should be empty');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchLine_InitVATPostingSetup()
    var
        PurchLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        PurchHeader: Record "Purchase Header";
        Vendor: Record Vendor;
    begin
        // [FEATURE] [Purchase]
        Initialize();

        CreateVATPostingSetup(VATPostingSetup);
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(
          PurchHeader, PurchHeader."Document Type"::Invoice, Vendor."No.");

        LibraryPurchase.CreatePurchaseLine(
          PurchLine, PurchHeader, PurchHeader."Document Type", '1000', 1);
        PurchLine.Validate("VAT Number", VATPostingSetup."VAT Number");

        Assert.AreEqual(VATPostingSetup."VAT Prod. Posting Group", PurchLine."VAT Prod. Posting Group",
          'The VAT prod posting group should be assigned to Purhcase line');
        Assert.AreEqual(VATPostingSetup."VAT Prod. Posting Group", PurchLine."VAT Prod. Posting Group",
          'The VAT Bus. posting group should be assigned to Purhcase line');

        // Known failure
        asserterror
        begin
            PurchLine.Validate("VAT Number", '');
            Assert.AreEqual('', PurchLine."VAT Prod. Posting Group",
              'The VAT prod posting group should be empty');
            Assert.AreEqual('', PurchLine."VAT Bus. Posting Group",
              'The VAT Bus. posting group should be empty');
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesLine_InitVATPostingSetup()
    var
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Sales]
        Initialize();

        CreateVATPostingSetup(VATPostingSetup);
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesHeader."Document Type", '1000', 1);
        SalesLine.Validate("VAT Number", VATPostingSetup."VAT Number");

        Assert.AreEqual(VATPostingSetup."VAT Prod. Posting Group", SalesLine."VAT Prod. Posting Group",
          'The prod posting group should be assigned to General journal');
        Assert.AreEqual(VATPostingSetup."VAT Prod. Posting Group", SalesLine."VAT Prod. Posting Group",
          'The Bus. posting group should be assigned to General journal');

        // Known failure
        asserterror
        begin
            SalesLine.Validate("VAT Number", '');
            Assert.AreEqual('', SalesLine."VAT Prod. Posting Group",
              'The VAT prod posting group should be empty');
            Assert.AreEqual('', SalesLine."VAT Bus. Posting Group",
              'The VAT Bus. posting group should be empty');
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValVATCodeUniquePostingSetup()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SameVATReportingCode: Record "VAT Reporting Code";
    begin
        SameVATReportingCode.Init();
        SameVATReportingCode.Code := LibraryUtility.GenerateRandomCode(SameVATReportingCode.FieldNo(Code), DATABASE::"VAT Reporting Code");
        SameVATReportingCode.Insert(true);

        CreateVATPostingSetupWithCode(VATPostingSetup, SameVATReportingCode.Code);
        asserterror CreateVATPostingSetupWithCode(VATPostingSetup, SameVATReportingCode.Code);
        Assert.ExpectedError(VATPostingSetup.TableCaption());
    end;

    local procedure CreateVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup")
    var
        VATReportingCode: Record "VAT Reporting Code";
    begin
        VATReportingCode.Init();
        VATReportingCode.Code := LibraryUtility.GenerateRandomCode(VATReportingCode.FieldNo(Code), DATABASE::"VAT Reporting Code");
        VATReportingCode.Insert(true);

        CreateVATPostingSetupWithCode(VATPostingSetup, VATReportingCode.Code);
    end;

    local procedure CreateVATPostingSetupWithCode(var VATPostingSetup: Record "VAT Posting Setup"; VATCodeCode: Code[10])
    var
        VATBusPostingGroup: Record "VAT Business Posting Group";
        VATProdPostingGroup: Record "VAT Product Posting Group";
    begin
        LibraryERM.FindVATBusinessPostingGroup(VATBusPostingGroup);
        LibraryERM.CreateVATProductPostingGroup(VATProdPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusPostingGroup.Code, VATProdPostingGroup.Code);
        VATPostingSetup.Validate("VAT Number", VATCodeCode);
        VATPostingSetup.Modify(true);
    end;
}

