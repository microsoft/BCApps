codeunit 134850 "Test General Document Lookup"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [ERM]
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryFixedAsset: Codeunit "Library - Fixed Asset";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryERM: Codeunit "Library - ERM";
        LibraryUtility: Codeunit "Library - Utility";
        IsInitialized: Boolean;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Test General Document Lookup");
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Test General Document Lookup");

        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Test General Document Lookup");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFixedAssetLookupOnSales()
    var
        FixedAsset: Record "Fixed Asset";
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
    begin
        Initialize();
        // [FEATURE] [Sales] [Fixed Asset]
        // [SCENARIO] Create a Sales Invoice, add a Line of type Fixed Asset and verify that Line has correct description.
        // [GIVEN] Fixed Asset, where "No." = 'X'
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        // [GIVEN] Invoice Line, where "Type" = "Fixed Asset"
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        LibrarySales.CreateSalesLineSimple(SalesLine, SalesHeader);
        SalesLine.Validate(Type, SalesLine.Type::"Fixed Asset");
        // [WHEN] Enter 'X' to "Description" in Invoice Line
        SalesLine.Validate(Description, FixedAsset."No.");
        // [THEN] Invoice Line gets "No." = 'X'
        Assert.AreEqual(FixedAsset."No.", SalesLine."No.", 'No should get the value of the description');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFixedAssetLookupOnPurchase()
    var
        Vendor: Record Vendor;
        FixedAsset: Record "Fixed Asset";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        Initialize();
        // [FEATURE] [Purchase] [Fixed Asset]
        // [SCENARIO] Create a Purchase Invoice, add a Line of type Fixed Asset and verify that Line has correct description.
        // [GIVEN] Fixed Asset, where "No." = 'X'
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        // [GIVEN] Invoice Line, where "Type" = "Fixed Asset"
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        LibraryPurchase.CreatePurchaseLineSimple(PurchaseLine, PurchaseHeader);
        PurchaseLine.Validate(Type, PurchaseLine.Type::"Fixed Asset");
        // [WHEN] Enter 'X' to "Description" in Invoice Line
        PurchaseLine.Validate(Description, FixedAsset."No.");
        // [THEN] Invoice Line gets "No." = 'X'
        Assert.AreEqual(FixedAsset."No.", PurchaseLine."No.", 'No should get the value of the description');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseLineNoForGLAccountDescriptionCannotBeChanged()
    var
        GLAccount: array[2] of Record "G/L Account";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [UT] [G/L Account] [Purchase] [Find Record By Description]
        // [SCENARIO 288426] Existing No. in Purchase Line with G/L Account type won't be updated from validation of Description with another "No." value

        // [GIVEN] G/L Accounts X1 and X2
        GLAccount[1].Get(LibraryERM.CreateGLAccountWithPurchSetup());
        GLAccount[2].Get(LibraryERM.CreateGLAccountWithPurchSetup());

        // [GIVEN] Purchase order with one line
        CreatePurchaseOrderWithLine(PurchaseHeader, PurchaseLine);

        // [GIVEN] Line validated with "No." of X1
        PurchaseLine.Validate(Type, PurchaseLine.Type::"G/L Account");
        PurchaseLine.Validate("No.", GLAccount[1]."No.");
        PurchaseLine.Modify(true);

        // [WHEN] Line validated with "Description" of X2
        PurchaseLine.Validate(Description, GLAccount[2].Name);
        PurchaseLine.Modify(true);

        // [THEN] "No." in line stays unchanged
        PurchaseLine.TestField("No.", GLAccount[1]."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesLineNoForGLAccountDescriptionCannotBeChanged()
    var
        GLAccount: array[2] of Record "G/L Account";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [UT] [G/L Account] [Sales] [Find Record By Description]
        // [SCENARIO 296402] Existing No. in Sales Line with G/L Account type won't be updated from validation of Description with another "No." value

        // [GIVEN] G/L Account with No = 8310 and Name 'Software'
        GLAccount[1].Get(LibraryERM.CreateGLAccountWithSalesSetup());

        // [GIVEN] Other G/L Account with Name = 'Postage'
        GLAccount[2].Get(LibraryERM.CreateGLAccountWithSalesSetup());

        // [GIVEN] Sales Line with Type G/L Account and <blank> No
        CreateSalesInvoiceWithLineTypeGLAccountAndBlankNo(SalesLine);

        // [GIVEN] Line validated with "No." = 8310
        SalesLine.Validate("No.", GLAccount[1]."No.");

        // [WHEN] Validate Description = 'Postage' in Sales Line
        SalesLine.Validate(Description, GLAccount[2].Name);

        // [THEN] Sales Line has Description = 'Postage'
        SalesLine.TestField(Description, GLAccount[2].Name);

        // [THEN] Sales Line has "No." = 8310
        SalesLine.TestField("No.", GLAccount[1]."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseLineGLAccDescriptionValidateWhenGLAccountsHaveSameName()
    var
        PurchaseLine: Record "Purchase Line";
        GLAccountName: Text[100];
        GLAccountNo: Code[20];
        AccountType: Option Posting,Heading,Total,"Begin-Total","End-Total";
    begin
        // [FEATURE] [UT] [G/L Account] [Purchase] [Find Record By Description]
        // [SCENARIO 296402] When validate Description in G/L Account type Purchase Line with <blank> No then first Non-blocked G/L Account is found
        // [SCENARIO 296402] having Account Type = Posting and Direct Posting enabled.
        GLAccountName := LibraryUtility.GenerateGUID();

        // [GIVEN] G/L Accounts with same Name = 'Software' were created as follows:
        // [GIVEN] Heading, Total, Begin-Total, End-Total G/L Accounts with Nos = 8306, 8307, 8308, 8309
        CreateGLAccountWithNameAndAccountType(GLAccountName, AccountType::Heading);
        CreateGLAccountWithNameAndAccountType(GLAccountName, AccountType::Total);
        CreateGLAccountWithNameAndAccountType(GLAccountName, AccountType::"Begin-Total");
        CreateGLAccountWithNameAndAccountType(GLAccountName, AccountType::"End-Total");

        // [GIVEN] Blocked Posting G/L Account with No = 8310
        // [GIVEN] Posting G/L Account with Direct Posting disabled and No = 8311
        CreatePurchPostingGLAccountWithName(GLAccountName, true, true);
        CreatePurchPostingGLAccountWithName(GLAccountName, false, false);

        // [GIVEN] Two Non-blocked Direct Posting G/L Accounts with Nos = 8312, 8313
        GLAccountNo := CreatePurchPostingGLAccountWithName(GLAccountName, false, true);
        CreatePurchPostingGLAccountWithName(GLAccountName, false, true);

        // [GIVEN] Purchase Line with Type G/L Account and <blank> No
        CreatePurchInvoiceWithLineTypeGLAccountAndBlankNo(PurchaseLine);

        // [WHEN] Validate Description = 'Software' in Purchase Line
        PurchaseLine.Validate(Description, GLAccountName);

        // [THEN] Purchase Line has No = 8312
        PurchaseLine.TestField("No.", GLAccountNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesLineGLAccDescriptionValidateWhenGLAccountsHaveSameName()
    var
        SalesLine: Record "Sales Line";
        GLAccountName: Text[100];
        GLAccountNo: Code[20];
        AccountType: Option Posting,Heading,Total,"Begin-Total","End-Total";
    begin
        // [FEATURE] [UT] [G/L Account] [Sales] [Find Record By Description]
        // [SCENARIO 296402] When validate Description in G/L Account type Sales Line with <blank> No then first Non-blocked G/L Account is found
        // [SCENARIO 296402] having Account Type = Posting and Direct Posting enabled.
        GLAccountName := LibraryUtility.GenerateGUID();

        // [GIVEN] G/L Accounts with same Name = 'Software' were created as follows:
        // [GIVEN] Heading, Total, Begin-Total, End-Total G/L Accounts with Nos = 8306, 8307, 8308, 8309
        CreateGLAccountWithNameAndAccountType(GLAccountName, AccountType::Heading);
        CreateGLAccountWithNameAndAccountType(GLAccountName, AccountType::Total);
        CreateGLAccountWithNameAndAccountType(GLAccountName, AccountType::"Begin-Total");
        CreateGLAccountWithNameAndAccountType(GLAccountName, AccountType::"End-Total");

        // [GIVEN] Blocked Posting G/L Account with No = 8310
        // [GIVEN] Posting G/L Account with Direct Posting disabled and No = 8311
        CreateSalesPostingGLAccountWithName(GLAccountName, true, true);
        CreateSalesPostingGLAccountWithName(GLAccountName, false, false);

        // [GIVEN] Two Non-blocked Direct Posting G/L Accounts with Nos = 8312, 8313
        GLAccountNo := CreateSalesPostingGLAccountWithName(GLAccountName, false, true);
        CreateSalesPostingGLAccountWithName(GLAccountName, false, true);

        // [GIVEN] Sales Line with Type G/L Account and <blank> No
        CreateSalesInvoiceWithLineTypeGLAccountAndBlankNo(SalesLine);

        // [WHEN] Validate Description = 'Software' in Purchase Line
        SalesLine.Validate(Description, GLAccountName);

        // [THEN] Sales Line has No = 8312
        SalesLine.TestField("No.", GLAccountNo);
    end;

    local procedure CreateGLAccountWithNameAndAccountType(GLAccountName: Text[100]; AccountType: Integer)
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate(Name, GLAccountName);
        GLAccount.Validate("Account Type", AccountType);
        GLAccount.Modify(true);
    end;

    local procedure CreatePurchPostingGLAccountWithName(GLAccountName: Text[100]; Blocked: Boolean; DirectPosting: Boolean): Code[20]
    begin
        exit(UpdateGLAccountNameDirectPostingAndBlocked(LibraryERM.CreateGLAccountWithPurchSetup(), GLAccountName, Blocked, DirectPosting));
    end;

    local procedure CreateSalesPostingGLAccountWithName(GLAccountName: Text[100]; Blocked: Boolean; DirectPosting: Boolean): Code[20]
    begin
        exit(UpdateGLAccountNameDirectPostingAndBlocked(LibraryERM.CreateGLAccountWithSalesSetup(), GLAccountName, Blocked, DirectPosting));
    end;

    local procedure UpdateGLAccountNameDirectPostingAndBlocked(GLAccountNo: Code[20]; GLAccountName: Text[100]; Blocked: Boolean; DirectPosting: Boolean): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount.Get(GLAccountNo);
        GLAccount.Validate(Name, GLAccountName);
        GLAccount.Validate("Direct Posting", DirectPosting);
        GLAccount.Validate(Blocked, Blocked);
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure CreatePurchInvoiceWithLineTypeGLAccountAndBlankNo(var PurchaseLine: Record "Purchase Line")
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", '', 0);
        PurchaseLine.Validate("No.", '');
        PurchaseLine.Modify(true);
    end;

    local procedure CreateSalesInvoiceWithLineTypeGLAccountAndBlankNo(var SalesLine: Record "Sales Line")
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account", '', 0);
        SalesLine.Validate("No.", '');
        SalesLine.Modify(true);
    end;

    local procedure CreatePurchaseOrderWithLine(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line")
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLineSimple(PurchaseLine, PurchaseHeader);
        PurchaseLine.Validate(Type, PurchaseLine.Type::"G/L Account");
        PurchaseLine.Modify(true);
    end;
}

