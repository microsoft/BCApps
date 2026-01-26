codeunit 144114 "ERM Transport Method"
{
    //  1. Test to verify Port/Airport field can be checked on Transport Method.
    //  2. Test to verify Port/Airport field can be unchecked on Transport Method.
    //  3. Test to verify error on posting Sales Invoice with Blank Exit Point when Port/Airport on Transport Method is True.
    //  4. Test to verify Sales Invoice can be posted with Blank Exit Point when Port/Airport on Transport Method is False.
    //  5. Test to verify Sales Invoice can be posted with Exit Point when Port/Airport on Transport Method is True.
    //  6. Test to verify error on posting Purchase Invoice with Blank Entry Point when Port/Airport on Transport Method is True.
    //  7. Test to verify Purchase Invoice can be posted with Blank Entry Point when Port/Airport on Transport Method is False.
    //  8. Test to verify Purchase Invoice can be posted with Entry Point when Port/Airport on Transport Method is True.
    //  9. Test to verify error on posting Item Journal line with Blank Entry/Exit Point when Port/Airport on Transport Method is True.
    // 10. Test to verify Item Journal line can be posted with Blank Entry/Exit Point when Port/Airport on Transport Method is False.
    // 11. Test to verify error on posting Service Invoice with Blank Exit Point when Port/Airport on Transport Method is True.
    // 12. Test to verify Service Invoice can be posted with Blank Exit Point when Port/Airport on Transport Method is False.
    // 13. Test to verify Service Invoice can be posted with Exit Point when Port/Airport on Transport Method is True.
    // 
    // Covers Test Cases for WI - 351289
    // ------------------------------------------------------------------------------------------
    // Test Function Name                                                                  TFS ID
    // ------------------------------------------------------------------------------------------
    // TransportMethodWithPortAirport,TransportMethodWithoutPortAirport                    151073
    // PostSalesInvoiceWithPortAirportError                                                151074
    // PostSalesInvWithoutPortAirportAndBlankExitPoint                                     152205
    // PostSalesInvoiceWithPortAirportAndExitPoint                                         152206
    // PostPurchaseInvoiceWithPortAirportError                                             152207
    // PostPurchInvWithoutPortAirportAndBlankEntryPoint                                    152208
    // PostPurchInvoiceWithPortAirportAndEntryPoint                                        152209
    // PostItemJournalLineWithPortAirportError                                             152210
    // PostItemJnlWithoutPortAirportAndBlankEntryPoint                                     152211
    // PostServiceInvoiceWithPortAirportError                                              280896
    // PostServInvWithoutPortAirportAndBlankExitPoint                                      280897
    // PostServiceInvoiceWithPortAirportAndExitPoint                                       280898

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryESLocalization: Codeunit "Library - ES Localization";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryService: Codeunit "Library - Service";
        LibraryRandom: Codeunit "Library - Random";
        MustHaveValueErr: Label '%1 must have a value in %2';

    [Test]
    [Scope('OnPrem')]
    procedure TransportMethodWithPortAirport()
    begin
        // Test to verify Port/Airport field can be checked on Transport Method.
        PortAirportOnTransportMethod(true);  // True used for Port/Airport.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransportMethodWithoutPortAirport()
    begin
        // Test to verify Port/Airport field can be unchecked on Transport Method.
        PortAirportOnTransportMethod(false);  // False used for Port/Airport.
    end;

    local procedure PortAirportOnTransportMethod(PortAirport: Boolean)
    var
        TransportMethods: TestPage "Transport Methods";
        TransportMethodCode: Code[10];
    begin
        // Setup.
        TransportMethodCode := CreateTransportMethod(PortAirport);
        TransportMethods.OpenEdit();

        // Exercise.
        TransportMethods.FILTER.SetFilter(Code, TransportMethodCode);

        // Verify.
        TransportMethods."Port/Airport".AssertEquals(PortAirport);
        TransportMethods.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesInvoiceWithPortAirportError()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Test to verify error on posting Sales Invoice with Blank Exit Point when Port/Airport on Transport Method is True.

        // Setup.
        CreateSalesInvoice(SalesHeader, '', CreateTransportMethod(true));  // Blank used for Exit Point and True used for Port/Airport.

        // Exercise.
        asserterror LibrarySales.PostSalesDocument(SalesHeader, true, true);  // True used for Ship and Invoice.

        // Verify: Error 'Exit Point must have a value in Sales Header'.
        Assert.ExpectedError(StrSubstNo(MustHaveValueErr, SalesHeader.FieldCaption("Exit Point"), SalesHeader.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesInvWithoutPortAirportAndBlankExitPoint()
    begin
        // Test to verify Sales Invoice can be posted with Blank Exit Point when Port/Airport on Transport Method is False.
        PortAirportAndExitPointOnPostedSalesInvoice('', false);  // Blank used for Exit Point and False used for Port/Airport.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesInvoiceWithPortAirportAndExitPoint()
    begin
        // Test to verify Sales Invoice can be posted with Exit Point when Port/Airport on Transport Method is True.
        PortAirportAndExitPointOnPostedSalesInvoice(CreateEntryExitPoint(), true);  // True used for Port/Airport.
    end;

    local procedure PortAirportAndExitPointOnPostedSalesInvoice(ExitPoint: Code[10]; PortAirport: Boolean)
    var
        SalesHeader: Record "Sales Header";
        DocumentNo: Code[20];
    begin
        // Setup.
        CreateSalesInvoice(SalesHeader, ExitPoint, CreateTransportMethod(PortAirport));

        // Exercise.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);  // True used for Ship and Invoice.

        // Verify.
        VerifyPostedSalesInvoice(DocumentNo, SalesHeader."Exit Point", SalesHeader."Transport Method");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchaseInvoiceWithPortAirportError()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Test to verify error on posting Purchase Invoice with Blank Entry Point when Port/Airport on Transport Method is True.

        // Setup.
        CreatePurchaseInvoice(PurchaseHeader, '', CreateTransportMethod(true));  // Blank used for Entry Point and True used for Port/Airport.

        // Exercise.
        asserterror LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);  // True used for Receive and Invoice.

        // Verify: Error 'Entry Point must have a value in Purchase Header'.
        Assert.ExpectedError(StrSubstNo(MustHaveValueErr, PurchaseHeader.FieldCaption("Entry Point"), PurchaseHeader.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchInvWithoutPortAirportAndBlankEntryPoint()
    begin
        // Test to verify Purchase Invoice can be posted with Blank Entry Point when Port/Airport on Transport Method is False.
        PortAirportAndExitPointOnPostedPurchaseInvoice('', false);  // Blank used for Entry Point and False used for Port/Airport.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchInvoiceWithPortAirportAndEntryPoint()
    begin
        // Test to verify Purchase Invoice can be posted with Entry Point when Port/Airport on Transport Method is True.
        PortAirportAndExitPointOnPostedPurchaseInvoice(CreateEntryExitPoint(), true);  // True used for Port/Airport.
    end;

    local procedure PortAirportAndExitPointOnPostedPurchaseInvoice(EntryPoint: Code[10]; PortAirport: Boolean)
    var
        PurchaseHeader: Record "Purchase Header";
        DocumentNo: Code[20];
    begin
        // Setup.
        CreatePurchaseInvoice(PurchaseHeader, EntryPoint, CreateTransportMethod(PortAirport));

        // Exercise.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);  // True used for Receive and Invoice.

        // Verify.
        VerifyPostedPurchaseInvoice(DocumentNo, PurchaseHeader."Entry Point", PurchaseHeader."Transport Method");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostItemJournalLineWithPortAirportError()
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        // Test to verify error on posting Item Journal line with Blank Entry/Exit Point when Port/Airport on Transport Method is True.

        // Setup.
        CreateItemJournalLine(ItemJournalLine, CreateTransportMethod(true));  // True used for Port/Airport.

        // Exercise.
        asserterror LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // Verify: Error 'Entry/Exit Point must have a value in Item Journal Line'.
        Assert.ExpectedError(StrSubstNo(MustHaveValueErr, ItemJournalLine.FieldCaption("Entry/Exit Point"), ItemJournalLine.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostItemJnlWithoutPortAirportAndBlankEntryPoint()
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        // Test to verify Item Journal line can be posted with Blank Entry/Exit Point when Port/Airport on Transport Method is False.

        // Setup.
        CreateItemJournalLine(ItemJournalLine, CreateTransportMethod(false));  // False used for Port/Airport.

        // Exercise.
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // Verify.
        VerifyItemLedgerEntry(ItemJournalLine."Document No.", ItemJournalLine."Transport Method");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostServiceInvoiceWithPortAirportError()
    var
        ServiceHeader: Record "Service Header";
    begin
        // Test to verify error on posting Service Invoice with Blank Exit Point when Port/Airport on Transport Method is True.

        // Setup.
        CreateServiceInvoice(ServiceHeader, '', CreateTransportMethod(true));  // Blank used for Exit Point and True used for Port/Airport.

        // Exercise.
        asserterror LibraryService.PostServiceOrder(ServiceHeader, true, false, true);  // True used for Ship and Invoice. False used for Consume.

        // Verify: Error 'Exit Point must have a value in Service Header'.
        Assert.ExpectedError(StrSubstNo(MustHaveValueErr, ServiceHeader.FieldCaption("Exit Point"), ServiceHeader.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostServInvWithoutPortAirportAndBlankExitPoint()
    begin
        // Test to verify Service Invoice can be posted with Blank Exit Point when Port/Airport on Transport Method is False.
        PortAirportAndExitPointOnPostedServiceInvoice('', false);  // Blank used for Exit Point and False used for Port/Airport.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostServiceInvoiceWithPortAirportAndExitPoint()
    begin
        // Test to verify Service Invoice can be posted with Exit Point when Port/Airport on Transport Method is True.
        PortAirportAndExitPointOnPostedServiceInvoice(CreateEntryExitPoint(), true);  // True used for Port/Airport.
    end;

    local procedure PortAirportAndExitPointOnPostedServiceInvoice(ExitPoint: Code[10]; PortAirport: Boolean)
    var
        ServiceHeader: Record "Service Header";
    begin
        // Setup.
        CreateServiceInvoice(ServiceHeader, ExitPoint, CreateTransportMethod(PortAirport));

        // Exercise.
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);  // True used for Ship and Invoice. False used for Consume.

        // Verify.
        VerifyPostedServiceInvoice(ServiceHeader);
    end;

    local procedure CreateEntryExitPoint(): Code[10]
    var
        EntryExitPoint: Record "Entry/Exit Point";
    begin
        LibraryESLocalization.CreateEntryExitPoint(EntryExitPoint);
        exit(EntryExitPoint.Code);
    end;

    local procedure CreateItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; TransportMethod: Code[10])
    var
        Item: Record Item;
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        LibraryInventory.FindItemJournalTemplate(ItemJournalTemplate);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name, ItemJournalLine."Entry Type"::Purchase,
          LibraryInventory.CreateItem(Item), LibraryRandom.RandDec(10, 2));  // Random value used for Quantity.
        ItemJournalLine.Validate("Transport Method", TransportMethod);
        ItemJournalLine.Modify(true);
    end;

    local procedure CreatePurchaseInvoice(var PurchaseHeader: Record "Purchase Header"; EntryPoint: Code[10]; TransportMethod: Code[10])
    var
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        PurchaseHeader.Validate("Entry Point", EntryPoint);
        PurchaseHeader.Validate("Transport Method", TransportMethod);
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItem(Item), LibraryRandom.RandDec(10, 2));  // Random value used for Quantity.
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Modify(true);
    end;

    local procedure CreateSalesInvoice(var SalesHeader: Record "Sales Header"; ExitPoint: Code[10]; TransportMethod: Code[10])
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        SalesHeader.Validate("Exit Point", ExitPoint);
        SalesHeader.Validate("Transport Method", TransportMethod);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItem(Item), LibraryRandom.RandDec(10, 2));  // Random value used for Quantity.
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);
    end;

    local procedure CreateServiceInvoice(var ServiceHeader: Record "Service Header"; ExitPoint: Code[10]; TransportMethod: Code[10])
    var
        Customer: Record Customer;
        Item: Record Item;
        ServiceLine: Record "Service Line";
    begin
        LibrarySales.CreateCustomer(Customer);
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Invoice, Customer."No.");
        ServiceHeader.Validate("Exit Point", ExitPoint);
        ServiceHeader.Validate("Transport Method", TransportMethod);
        ServiceHeader.Modify(true);
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, LibraryInventory.CreateItem(Item));
        ServiceLine.Validate(Quantity, LibraryRandom.RandDec(10, 2));
        ServiceLine.Modify(true);
    end;

    local procedure CreateTransportMethod(PortAirport: Boolean): Code[10]
    var
        TransportMethod: Record "Transport Method";
    begin
        LibraryESLocalization.CreateTransportMethod(TransportMethod);
        TransportMethod.Validate("Port/Airport", PortAirport);
        TransportMethod.Modify(true);
        exit(TransportMethod.Code);
    end;

    local procedure VerifyItemLedgerEntry(DocumentNo: Code[20]; TransportMethod: Code[10])
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Document No.", DocumentNo);
        ItemLedgerEntry.FindFirst();
        ItemLedgerEntry.TestField("Transport Method", TransportMethod);
    end;

    local procedure VerifyPostedPurchaseInvoice(No: Code[20]; EntryPoint: Code[10]; TransportMethod: Code[10])
    var
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        PurchInvHeader.SetRange("No.", No);
        PurchInvHeader.FindFirst();
        PurchInvHeader.TestField("Entry Point", EntryPoint);
        PurchInvHeader.TestField("Transport Method", TransportMethod);
    end;

    local procedure VerifyPostedSalesInvoice(No: Code[20]; ExitPoint: Code[10]; TransportMethod: Code[10])
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        SalesInvoiceHeader.SetRange("No.", No);
        SalesInvoiceHeader.FindFirst();
        SalesInvoiceHeader.TestField("Exit Point", ExitPoint);
        SalesInvoiceHeader.TestField("Transport Method", TransportMethod);
    end;

    local procedure VerifyPostedServiceInvoice(ServiceHeader: Record "Service Header")
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
    begin
        ServiceInvoiceHeader.SetRange("Pre-Assigned No.", ServiceHeader."No.");
        ServiceInvoiceHeader.FindFirst();
        ServiceInvoiceHeader.TestField("Exit Point", ServiceHeader."Exit Point");
        ServiceInvoiceHeader.TestField("Transport Method", ServiceHeader."Transport Method");
    end;
}

