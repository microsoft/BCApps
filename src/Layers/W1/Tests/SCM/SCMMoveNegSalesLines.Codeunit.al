codeunit 137206 "SCM Move Neg. Sales Lines"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Move Negative Sales Lines] [Sales]
        isInitialized := false;
    end;

    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        LibraryInventory: Codeunit "Library - Inventory";
        LibrarySales: Codeunit "Library - Sales";
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        isInitialized: Boolean;
        FromDocType: Option Quote,"Blanket Order","Order",Invoice,"Return Order","Credit Memo";
        ErrorNoNegLines: Label 'There are no negative sales lines to move.';
        ToDocType: Option ,,"Order",Invoice,"Return Order","Credit Memo";
        SalesHeaderNo: Code[20];

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryApplicationArea: Codeunit "Library - Application Area";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Move Neg. Sales Lines");
        LibraryApplicationArea.EnableFoundationSetup();
        Clear(SalesHeaderNo);
        UpdateSalesReceivablesSetup();

        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Move Neg. Sales Lines");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Move Neg. Sales Lines");
    end;

    [Normal]
    local procedure MoveNegativeSalesLines(FromDocType: Enum "Sales Document Type"; ToDocType: Enum "Sales Document Type"; FromDocTypeRep: Option; ToDocTypeRep: Option; InitialSign: Integer)
    var
        SalesHeader: Record "Sales Header";
        TempSalesLine: Record "Sales Line" temporary;
    begin
        // Setup: Create a Purchase Return Order with negative lines.
        Initialize();
        CreateSalesDocWithMixedLines(SalesHeader, TempSalesLine, FromDocType, InitialSign);

        // Exercise: Run Move Negative Lines to generate a Purchase Order.
        MoveNegSalesLines(SalesHeader, FromDocTypeRep, ToDocTypeRep);

        // Verify: Examine the moved lines.
        VerifyNegSalesLines(TempSalesLine, ToDocType, SalesHeaderNo);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,SalesOrderPageHandler')]
    [Scope('OnPrem')]
    procedure SalesRetOrderToOrder()
    var
        SalesHeader: Record "Sales Header";
    begin
        MoveNegativeSalesLines(SalesHeader."Document Type"::"Return Order", SalesHeader."Document Type"::Order,
          FromDocType::"Return Order", ToDocType::Order, -1);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,SalesInvoicePageHandler')]
    [Scope('OnPrem')]
    procedure SalesCrMemoToInvoice()
    var
        SalesHeader: Record "Sales Header";
    begin
        MoveNegativeSalesLines(SalesHeader."Document Type"::"Credit Memo", SalesHeader."Document Type"::Invoice,
          FromDocType::"Credit Memo", ToDocType::Invoice, -1);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,SalesCrMemoPageHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceToCrMemo()
    var
        SalesHeader: Record "Sales Header";
    begin
        MoveNegativeSalesLines(SalesHeader."Document Type"::Invoice, SalesHeader."Document Type"::"Credit Memo",
          FromDocType::Invoice, ToDocType::"Credit Memo", -1);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,SalesRetOrderPageHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderToRetOrder()
    var
        SalesHeader: Record "Sales Header";
    begin
        MoveNegativeSalesLines(SalesHeader."Document Type"::Order, SalesHeader."Document Type"::"Return Order",
          FromDocType::Order, ToDocType::"Return Order", -1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NegTestSalesOrderToRetOrder()
    var
        SalesHeader: Record "Sales Header";
    begin
        asserterror
          MoveNegativeSalesLines(SalesHeader."Document Type"::Order, SalesHeader."Document Type"::"Return Order",
            FromDocType::Order, ToDocType::"Return Order", 1);

        // Verify: Error message.
        Assert.IsTrue(StrPos(GetLastErrorText, ErrorNoNegLines) > 0, 'Actual:' + GetLastErrorText + ';Expected:' + ErrorNoNegLines);
        ClearLastError();
    end;

    [Normal]
    local procedure UpdateSalesReceivablesSetup()
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Credit Warnings", SalesReceivablesSetup."Credit Warnings"::"No Warning");
        SalesReceivablesSetup.Validate("Stockout Warning", false);
        SalesReceivablesSetup.Modify(true);
    end;

    [Normal]
    local procedure CreateSalesDocWithMixedLines(var SalesHeader: Record "Sales Header"; var TempSalesLine: Record "Sales Line" temporary; DocumentType: Enum "Sales Document Type"; InitialSign: Integer)
    var
        SalesLine: Record "Sales Line";
        Item: Record Item;
        Customer: Record Customer;
        "Count": Integer;
        i: Integer;
    begin
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, Customer."No.");
        TempSalesLine.DeleteAll();

        // Create a Sales document with mixed lines: alternating positive and negative quantities.
        Count := 5 + LibraryRandom.RandInt(8);
        for i := 1 to Count do begin
            LibraryInventory.CreateItem(Item);
            LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.",
              Power(InitialSign, i) * LibraryRandom.RandDec(10, 2));
            if SalesLine.Quantity < 0 then begin
                TempSalesLine := SalesLine;
                TempSalesLine.Insert();
            end;
        end;
    end;

    [Normal]
    local procedure MoveNegSalesLines(SalesHeader: Record "Sales Header"; FromDocType: Option; ToDocType: Option)
    var
        MoveNegSalesLines: Report "Move Negative Sales Lines";
    begin
        Clear(MoveNegSalesLines);
        MoveNegSalesLines.SetSalesHeader(SalesHeader);
        MoveNegSalesLines.InitializeRequest(FromDocType, ToDocType, ToDocType);
        MoveNegSalesLines.UseRequestPage(false);
        MoveNegSalesLines.RunModal();
        MoveNegSalesLines.ShowDocument();
    end;

    [Normal]
    local procedure VerifyNegSalesLines(var TempSalesLine: Record "Sales Line" temporary; NewDocumentType: Enum "Sales Document Type"; NewSalesHeaderNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Get generated sales header and lines
        SalesHeader.Get(NewDocumentType, NewSalesHeaderNo);
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindSet();
        TempSalesLine.FindSet();

        // Verify migrated lines.
        repeat
            TempSalesLine.SetRange("Sell-to Customer No.", SalesLine."Sell-to Customer No.");
            TempSalesLine.SetRange(Type, SalesLine.Type);
            TempSalesLine.SetRange("No.", SalesLine."No.");
            TempSalesLine.SetRange(Description, SalesLine.Description);
            TempSalesLine.SetRange("Location Code", SalesLine."Location Code");
            TempSalesLine.SetRange(Quantity, -SalesLine.Quantity);
            TempSalesLine.SetRange("Unit of Measure", SalesLine."Unit of Measure");
            Assert.AreEqual(1, TempSalesLine.Count, 'Too many migrated negative lines!');
            TempSalesLine.FindFirst();
            TempSalesLine.Delete(true);
        until SalesLine.Next() = 0;

        // Check there are no un-migrated lines.
        TempSalesLine.Reset();
        Assert.AreEqual(0, TempSalesLine.Count, 'Remaining un-migrated lines.');
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure SalesOrderPageHandler(var SalesOrder: Page "Sales Order")
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.Init();
        SalesOrder.GetRecord(SalesHeader);
        SalesHeaderNo := SalesHeader."No.";
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure SalesRetOrderPageHandler(var SalesReturnOrder: Page "Sales Return Order")
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.Init();
        SalesReturnOrder.GetRecord(SalesHeader);
        SalesHeaderNo := SalesHeader."No.";
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure SalesInvoicePageHandler(var SalesInvoice: Page "Sales Invoice")
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.Init();
        SalesInvoice.GetRecord(SalesHeader);
        SalesHeaderNo := SalesHeader."No.";
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure SalesCrMemoPageHandler(var SalesCreditMemo: Page "Sales Credit Memo")
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.Init();
        SalesCreditMemo.GetRecord(SalesHeader);
        SalesHeaderNo := SalesHeader."No.";
    end;
}

