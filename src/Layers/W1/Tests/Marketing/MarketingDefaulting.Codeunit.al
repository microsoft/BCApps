codeunit 136217 "Marketing Defaulting"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Marketing] [User Setup]
    end;

    var
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure CreateContact()
    var
        UserSetup: Record "User Setup";
        Contact: Record Contact;
    begin
        Initialize();
        // [GIVEN] Salesperson Code field filled in User Setup with current User ID
        CreateUserSetup(UserSetup);

        // [WHEN]  New Contact is created
        Contact."No." := '';
        Contact.Insert(true);

        // [THEN]  Salesperson Code field for new Contact is the same as in User Setup
        Assert.AreEqual(UserSetup."Salespers./Purch. Code", Contact."Salesperson Code", 'Salesperson code should be same.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateOpportunity()
    var
        UserSetup: Record "User Setup";
        Opportunity: Record Opportunity;
    begin
        Initialize();
        // [GIVEN] Salesperson Code field filled in User Setup with current User ID
        CreateUserSetup(UserSetup);

        // [WHEN]  New Opportunity is created
        Opportunity."No." := '';
        Opportunity.Insert(true);

        // [THEN]  Salesperson Code field for new Opportunity is the same as in User Setup
        Assert.AreEqual(UserSetup."Salespers./Purch. Code", Opportunity."Salesperson Code", 'Salesperson code should be same.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateSegment()
    var
        UserSetup: Record "User Setup";
        SegmentHeader: Record "Segment Header";
    begin
        Initialize();
        // [GIVEN] Salesperson Code field filled in User Setup with current User ID
        CreateUserSetup(UserSetup);

        // [WHEN]  New Segment is created
        SegmentHeader."No." := '';
        SegmentHeader.Insert(true);

        // [THEN]  Salesperson Code field for new Segment is the same as in User Setup
        Assert.AreEqual(UserSetup."Salespers./Purch. Code", SegmentHeader."Salesperson Code", 'Salesperson code should be same.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateCustomer()
    var
        UserSetup: Record "User Setup";
        Customer: Record Customer;
    begin
        Initialize();
        // [GIVEN] Salesperson Code field filled in User Setup with current User ID
        CreateUserSetup(UserSetup);

        // [WHEN]  New Customer is created
        Customer."No." := '';
        Customer.Insert(true);

        // [THEN]  Salesperson Code field for new Customer is the same as in User Setup
        Assert.AreEqual(UserSetup."Salespers./Purch. Code", Customer."Salesperson Code", 'Salesperson code should be same.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateVendor()
    var
        UserSetup: Record "User Setup";
        Vendor: Record Vendor;
    begin
        Initialize();
        // [GIVEN] Salesperson Code field filled in User Setup with current User ID
        CreateUserSetup(UserSetup);

        // [WHEN]  New Vendor is created
        Vendor."No." := '';
        Vendor.Insert(true);

        // [THEN]  Salesperson Code field for new Vendor is the same as in User Setup
        Assert.AreEqual(UserSetup."Salespers./Purch. Code", Vendor."Purchaser Code", 'Salesperson code should be same.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreatePurchQuote()
    var
        UserSetup: Record "User Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        Initialize();
        // [GIVEN] Salesperson Code field filled in User Setup with current User ID
        CreateUserSetup(UserSetup);
        PurchasesPayablesSetup.Get();
        if PurchasesPayablesSetup."Quote Nos." = '' then begin
            PurchasesPayablesSetup."Quote Nos." := LibraryUtility.GetGlobalNoSeriesCode();
            PurchasesPayablesSetup.Modify();
        end;

        // [WHEN]  New Purchase Quote is created
        PurchaseHeader."Document Type" := PurchaseHeader."Document Type"::Quote;
        PurchaseHeader."No." := '';
        PurchaseHeader.Insert(true);

        // [THEN]  Salesperson Code field for new Quote is the same as in User Setup
        Assert.AreEqual(UserSetup."Salespers./Purch. Code", PurchaseHeader."Purchaser Code", 'Purchaser code should be same.');
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Marketing Defaulting");
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Marketing Defaulting");

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Marketing Defaulting");
    end;

    local procedure CreateUserSetup(var UserSetup: Record "User Setup")
    var
        SalespersonPurchaser: Record "Salesperson/Purchaser";
    begin
        UserSetup.Init();
        UserSetup."User ID" := UserId;
        LibrarySales.CreateSalesperson(SalespersonPurchaser);
        UserSetup."Salespers./Purch. Code" := SalespersonPurchaser.Code;
        if not UserSetup.Insert() then
            UserSetup.Modify();
    end;
}

