codeunit 138050 "O365 Test Name Nearness"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Name Auto-correction] [UT]
    end;

    var
        Assert: Codeunit Assert;
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryInventory: Codeunit "Library - Inventory";

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesHeader()
    var
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
        CorrectName: Text[50];
        WrongName: Text[50];
    begin
        Initialize();

        // [GIVEN] We have customer named '<some guid>'
        LibrarySales.CreateCustomer(Customer);
        CreateNames(CorrectName, WrongName);
        Customer.Name := CorrectName;
        Customer.Modify();

        // [WHEN] User enters a slightly wrongly typed name
        SalesHeader.Init();
        SalesHeader.Validate("Sell-to Customer Name", WrongName);

        // [THEN] The system returns the correct customer no.
        Assert.AreEqual(Customer."No.", SalesHeader."Sell-to Customer No.", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesLine()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        O365TestNameNearness: Codeunit "O365 Test Name Nearness";
        CorrectName: Text[50];
        WrongName: Text[50];
    begin
        Initialize();

        // [GIVEN] We have item named '<some guid>'
        LibrarySales.CreateCustomer(Customer);
        BindSubscription(O365TestNameNearness);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        UnbindSubscription(O365TestNameNearness);
        LibraryInventory.CreateItem(Item);
        CreateNames(CorrectName, WrongName);
        Item.Description := CorrectName;
        Item.Modify();

        // [WHEN] User enters a slightly wrongly typed name
        SalesLine.Init();
        SalesLine."Document Type" := SalesHeader."Document Type";
        SalesLine."Document No." := SalesHeader."No.";
        SalesLine."Line No." := 10000;
        SalesLine.Type := SalesLine.Type::Item;
        SalesLine.Insert();
        SalesLine.Validate(Description, WrongName);

        // [THEN] The system returns the correct item no.
        Assert.AreEqual(Item."No.", SalesLine."No.", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchaseHeader()
    var
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        CorrectName: Text[50];
        WrongName: Text[50];
    begin
        Initialize();

        // [GIVEN] We have vendor named '<some guid>'
        LibraryPurchase.CreateVendor(Vendor);
        CreateNames(CorrectName, WrongName);
        Vendor.Name := CorrectName;
        Vendor.Modify();

        // [WHEN] User enters a slightly wrongly typed name
        PurchaseHeader.Init();
        PurchaseHeader.Validate("Buy-from Vendor Name", WrongName);

        // [THEN] The system returns the correct vendor no.
        Assert.AreEqual(Vendor."No.", PurchaseHeader."Buy-from Vendor No.", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchaseLine()
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
        CorrectName: Text[50];
        WrongName: Text[50];
    begin
        Initialize();

        // [GIVEN] We have item named '<some guid>'
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        LibraryInventory.CreateItem(Item);
        CreateNames(CorrectName, WrongName);
        Item.Description := CorrectName;
        Item.Modify();

        // [WHEN] User enters a slightly wrongly typed name
        PurchaseLine.Init();
        PurchaseLine."Document Type" := PurchaseHeader."Document Type";
        PurchaseLine."Document No." := PurchaseHeader."No.";
        PurchaseLine."Line No." := 10000;
        PurchaseLine.Type := PurchaseLine.Type::Item;
        PurchaseLine.Insert();
        PurchaseLine.Validate(Description, WrongName);

        // [THEN] The system returns the correct item no.
        Assert.AreEqual(Item."No.", PurchaseLine."No.", '');
    end;

    local procedure Initialize()
    var
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"O365 Test Name Nearness");
    end;

    local procedure CreateNames(var CorrectName: Text[50]; var WrongName: Text[50])
    begin
        CorrectName := Format(CreateGuid());
        WrongName := CorrectName;
        WrongName[1] := 'X';
        WrongName[10] := ' ';
        WrongName[15] := '@';
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Job Queue - Enqueue", 'OnBeforeJobQueueScheduleTask', '', false, false)]
    local procedure DoNotScheduleTasks(var JobQueueEntry: Record "Job Queue Entry"; var DoNotScheduleTask: Boolean)
    begin
        DoNotScheduleTask := true;
    end;
}
