codeunit 139444 "Test Manual Release"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    procedure PerformManualReleasePurchase()
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        Initialize();
        // [SCENARIO ] Using select all from the Purchase Order list, the record will apply the selected filter (current will be filtered by a given vendor and status = Open). 

        // [GIVEN] There is a certain amount of Purchase Orders in the system that fill the criteria
        // Create test Vendor
        LibraryPurchase.CreateVendor(Vendor);

        // Add orders with different statuses
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, Vendor."No.", "Purchase Document Status"::Open);
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, Vendor."No.", "Purchase Document Status"::Open);
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, Vendor."No.", "Purchase Document Status"::Released);
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, Vendor."No.", "Purchase Document Status"::"Pending Approval");

        // [WHEN] Filter is applied to "Status" field
        Clear(PurchaseHeader);
        PurchaseHeader.SetRange("Buy-from Vendor No.", Vendor."No.");
        PurchaseHeader.SetRange(Status, "Purchase Document Status"::Open);

        // [THEN] Only the selected orders are released
        PurchaseHeader.PerformManualRelease(PurchaseHeader);

        // Assert - if the Handler was answered with false, documents outside of "Open" status were included in the filter
        Assert.IsTrue(LibraryVariableStorage.PeekBoolean(2), 'Only Open documents should be released.');
        Assert.IsTrue(LibraryVariableStorage.PeekText(1).Contains('Selected 2'), 'There should be only 2 orders selected for release.');
        Assert.IsTrue(LibraryVariableStorage.PeekText(1).Contains('Skipping 0'), 'There should be 0 skipped orders.');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    procedure PerformManualReleaseSales()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        Initialize();
        // [SCENARIO ] Using select all from the Sales Order list, the record will apply the selected filter (current will be filtered by a given customer and status = Open). 

        // [GIVEN] There is a certain amount of Sales Orders in the system that fill the criteria
        // Create test Customer
        LibrarySales.CreateCustomer(Customer);

        // Add orders with different statuses
        CreateSalesOrder(SalesHeader, SalesLine, Customer."No.", "Sales Document Status"::Open);
        CreateSalesOrder(SalesHeader, SalesLine, Customer."No.", "Sales Document Status"::Open);
        CreateSalesOrder(SalesHeader, SalesLine, Customer."No.", "Sales Document Status"::Released);
        CreateSalesOrder(SalesHeader, SalesLine, Customer."No.", "Sales Document Status"::"Pending Approval");

        // [WHEN] Filter is applied to "Status" field
        Clear(SalesHeader);
        SalesHeader.SetRange("Sell-to Customer No.", Customer."No.");
        SalesHeader.SetRange(Status, "Purchase Document Status"::Open);

        // [THEN] Only the selected orders are released
        SalesHeader.PerformManualRelease(SalesHeader);

        // Assert - if the Handler was answered with false, documents outside of "Open" status were included in the filter
        Assert.IsTrue(LibraryVariableStorage.PeekBoolean(2), 'Only Open documents should be released.');
        Assert.IsTrue(LibraryVariableStorage.PeekText(1).Contains('Selected 2'), 'There should be only 2 orders selected for release.');
        Assert.IsTrue(LibraryVariableStorage.PeekText(1).Contains('Skipping 0'), 'There should be 0 skipped orders.');
    end;

    [ConfirmHandler()]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := CheckPrompt(Question);
    end;

    [MessageHandler()]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;

    local procedure CheckPrompt(Question: Text[1024]): Boolean
    var
        SkippedDocsSubstringTxt: Label 'Some of the documents are not available and will be skipped';
    begin
        LibraryVariableStorage.Enqueue(Question);
        LibraryVariableStorage.Enqueue(StrPos(Question, SkippedDocsSubstringTxt) <= 0);

        exit(StrPos(Question, SkippedDocsSubstringTxt) <= 0);
    end;

    local procedure CreatePurchaseOrder(PurchaseHeader: Record "Purchase Header"; PurchaseLine: Record "Purchase Line"; VendorNo: Code[20]; Status: Enum "Purchase Document Status")
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, VendorNo);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, '', 1);
        PurchaseHeader.Status := Status;
        PurchaseHeader.Modify();
    end;

    local procedure CreateSalesOrder(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; CustomerNo: Code[20]; Status: Enum "Sales Document Status")
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, '', 1);
        SalesHeader.Status := Status;
        SalesHeader.Modify();
    end;
}