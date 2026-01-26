codeunit 144001 EU3Trade
{
    // Test suite 109170S10116: EU3 - Sales Invoice - EU 3-Party Trade field
    // 
    // Purpose:
    // 1. Check that EU 3-Party Trade field exists on Sales Invoice
    // 2. Test whether the value of EU 3-Party Trade field is copied from Sales Invoice to the Posted Sales Invoice after posting the Sales
    // 
    // Covers Test cases:
    //         TC_TFS_ID = 101776: EU3 - Sales Invoice - EU 3-Party Trade field = No
    //         TC_TFS_ID = 101777: EU3 - Sales Invoice - EU 3-Party Trade field = Yes

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        LibraryInventory: Codeunit "Library - Inventory";
        LibrarySales: Codeunit "Library - Sales";
        LibraryRandom: Codeunit "Library - Random";

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesInvoiceEU3()
    begin
        // Setup: Setup Demo Database.
        // TFS ID 101777: EU3 - Sales Invoice - EU 3-Party Trade field = Yes
        TestSalesInvoiceEU3Steps(true);
        // TFS ID 101776: EU3 - Sales Invoice - EU 3-Party Trade field = No
        TestSalesInvoiceEU3Steps(false);
    end;

    [Normal]
    [Scope('OnPrem')]
    procedure TestSalesInvoiceEU3Steps(EU3Trade: Boolean)
    var
        SalesHeader: Record "Sales Header";
    begin
        // 1. Create and Sales Invoice with concrete "EU 3-Party Trade" value
        // 2. Post SalesInvoice
        // 3. Check that posted Sales Invoice has the same "EU 3-Party Trade" as in first step

        CreateSalesInvoice(SalesHeader, EU3Trade);
        PostSalesInvoice(SalesHeader);
        VerifyPostedSalesInvoice(EU3Trade);
    end;

    local procedure CreateSalesHeader(var SalesHeader: Record "Sales Header"; EU3Trade: Boolean)
    begin
        // Create a Sales Invoice Header using Library Tables.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, '');

        // Enter EU 3-Party Trade in Sales Invoice Header.
        SalesHeader.Validate("EU 3-Party Trade", EU3Trade);
        SalesHeader.Modify(true);
    end;

    local procedure CreateSalesLine(SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
    begin
        // Create a Sales Invoice Line using Library Sales.
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10));
    end;

    local procedure PostSalesInvoice(SalesHeader: Record "Sales Header")
    begin
        // Post Sales Invoice Line using Library Sales.
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure VerifyPostedSalesInvoice(EU3Trade: Boolean)
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        // Find Posted Sales Invoice
        SalesInvoiceHeader.FindLast();

        // Check that posted Sales Invoice has correct "EU 3-Party Trade"
        SalesInvoiceHeader.TestField("EU 3-Party Trade", EU3Trade);
    end;

    [Scope('OnPrem')]
    procedure CreateSalesInvoice(var SalesHeader: Record "Sales Header"; EU3Trade: Boolean)
    begin
        CreateSalesHeader(SalesHeader, EU3Trade);
        CreateSalesLine(SalesHeader);
    end;
}

