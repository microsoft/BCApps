codeunit 137205 "SCM Move Neg. Purch. Lines"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Move Negative Purchase Lines] [Purchase]
        isInitialized := false;
    end;

    var
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        isInitialized: Boolean;
        FromDocType: Option Quote,"Blanket Order","Order",Invoice,"Return Order","Credit Memo";
        ToDocType: Option ,,"Order",Invoice,"Return Order","Credit Memo";
        PurchaseHeaderNo: Code[20];
        ErrorNoNegLines: Label 'There are no negative purchase lines to move.';

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryApplicationArea: Codeunit "Library - Application Area";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Move Neg. Purch. Lines");
        LibraryApplicationArea.EnableFoundationSetup();
        Clear(PurchaseHeaderNo);

        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Move Neg. Purch. Lines");

        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.CreateVATData();
        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Move Neg. Purch. Lines");
    end;

    [Normal]
    local procedure MoveNegativePurchLines(FromDocType: Enum "Purchase Document Type"; ToDocType: Enum "Purchase Document Type"; FromDocTypeRep: Option; ToDocTypeRep: Option; InitialSign: Integer)
    var
        PurchaseHeader: Record "Purchase Header";
        TempPurchaseLine: Record "Purchase Line" temporary;
    begin
        // Setup: Create a Purchase Return Order with negative lines.
        Initialize();
        CreatePurchDocWithMixedLines(PurchaseHeader, TempPurchaseLine, FromDocType, InitialSign);

        // Exercise: Run Move Negative Lines to generate a Purchase Order.
        MoveNegPurchaseLines(PurchaseHeader, FromDocTypeRep, ToDocTypeRep);

        // Verify: Examine the moved lines.
        VerifyNegPurchaseLines(TempPurchaseLine, ToDocType, PurchaseHeaderNo);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,PurchOrderPageHandler')]
    [Scope('OnPrem')]
    procedure PurchRetOrderToOrder()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        MoveNegativePurchLines(PurchaseHeader."Document Type"::"Return Order", PurchaseHeader."Document Type"::Order,
          FromDocType::"Return Order", ToDocType::Order, -1);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,PurchInvoicePageHandler')]
    [Scope('OnPrem')]
    procedure PurchCrMemoToInvoice()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        MoveNegativePurchLines(PurchaseHeader."Document Type"::"Credit Memo", PurchaseHeader."Document Type"::Invoice,
          FromDocType::"Credit Memo", ToDocType::Invoice, -1);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,PurchCrMemoPageHandler')]
    [Scope('OnPrem')]
    procedure PurchInvoiceToCrMemo()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        MoveNegativePurchLines(PurchaseHeader."Document Type"::Invoice, PurchaseHeader."Document Type"::"Credit Memo",
          FromDocType::Invoice, ToDocType::"Credit Memo", -1);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,PurchRetOrderPageHandler')]
    [Scope('OnPrem')]
    procedure PurchOrderToRetOrder()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        MoveNegativePurchLines(PurchaseHeader."Document Type"::Order, PurchaseHeader."Document Type"::"Return Order",
          FromDocType::Order, ToDocType::"Return Order", -1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NegTestPurchOrderToRetOrder()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        asserterror
          MoveNegativePurchLines(PurchaseHeader."Document Type"::Order, PurchaseHeader."Document Type"::"Return Order",
            FromDocType::Order, ToDocType::"Return Order", 1);

        // Verify: Error message.
        Assert.IsTrue(StrPos(GetLastErrorText, ErrorNoNegLines) > 0, 'Actual:' + GetLastErrorText + ';Expected:' + ErrorNoNegLines);
        ClearLastError();
    end;

    [Normal]
    local procedure CreatePurchDocWithMixedLines(var PurchaseHeader: Record "Purchase Header"; var TempPurchaseLine: Record "Purchase Line" temporary; DocumentType: Enum "Purchase Document Type"; InitialSign: Integer)
    var
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
        "Count": Integer;
        i: Integer;
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, '');
        TempPurchaseLine.DeleteAll();

        // Create a Purchase document with mixed lines: alternating positive and negative quantities.
        Count := 5 + LibraryRandom.RandInt(8);
        for i := 1 to Count do begin
            LibraryInventory.CreateItem(Item);
            LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.",
              Power(InitialSign, i) * LibraryRandom.RandDec(10, 2));
            if PurchaseLine.Quantity < 0 then begin
                TempPurchaseLine := PurchaseLine;
                TempPurchaseLine.Insert();
            end;
        end;
    end;

    [Normal]
    local procedure MoveNegPurchaseLines(PurchaseHeader: Record "Purchase Header"; FromDocType: Option; ToDocType: Option)
    var
        MoveNegPurchaseLines: Report "Move Negative Purchase Lines";
    begin
        Clear(MoveNegPurchaseLines);
        MoveNegPurchaseLines.SetPurchHeader(PurchaseHeader);
        MoveNegPurchaseLines.InitializeRequest(FromDocType, ToDocType, ToDocType);
        MoveNegPurchaseLines.UseRequestPage(false);
        MoveNegPurchaseLines.RunModal();
        MoveNegPurchaseLines.ShowDocument();
    end;

    [Normal]
    local procedure VerifyNegPurchaseLines(var TempPurchaseLine: Record "Purchase Line" temporary; NewDocumentType: Enum "Purchase Document Type"; NewPurchaseHeaderNo: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // Get the newly created purchase header and lines.
        PurchaseHeader.Get(NewDocumentType, NewPurchaseHeaderNo);
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.FindSet();
        TempPurchaseLine.FindSet();

        // Examine the migrated lines.
        repeat
            TempPurchaseLine.SetRange("Buy-from Vendor No.", PurchaseLine."Buy-from Vendor No.");
            TempPurchaseLine.SetRange(Type, PurchaseLine.Type);
            TempPurchaseLine.SetRange("No.", PurchaseLine."No.");
            TempPurchaseLine.SetRange(Description, PurchaseLine.Description);
            TempPurchaseLine.SetRange("Location Code", PurchaseLine."Location Code");
            TempPurchaseLine.SetRange(Quantity, -PurchaseLine.Quantity);
            TempPurchaseLine.SetRange("Unit of Measure", PurchaseLine."Unit of Measure");
            Assert.AreEqual(1, TempPurchaseLine.Count, 'Too many migrated negative lines!');
            TempPurchaseLine.FindFirst();
            TempPurchaseLine.Delete(true);
        until PurchaseLine.Next() = 0;

        // Check there are no un-migrated lines.
        TempPurchaseLine.Reset();
        Assert.AreEqual(0, TempPurchaseLine.Count, 'Remaining un-migrated lines.');
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure PurchOrderPageHandler(var PurchaseOrder: Page "Purchase Order")
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseHeader.Init();
        PurchaseOrder.GetRecord(PurchaseHeader);
        PurchaseHeaderNo := PurchaseHeader."No.";
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure PurchRetOrderPageHandler(var PurchaseReturnOrder: Page "Purchase Return Order")
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseHeader.Init();
        PurchaseReturnOrder.GetRecord(PurchaseHeader);
        PurchaseHeaderNo := PurchaseHeader."No.";
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure PurchInvoicePageHandler(var PurchaseInvoice: Page "Purchase Invoice")
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseHeader.Init();
        PurchaseInvoice.GetRecord(PurchaseHeader);
        PurchaseHeaderNo := PurchaseHeader."No.";
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure PurchCrMemoPageHandler(var PurchaseCreditMemo: Page "Purchase Credit Memo")
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseHeader.Init();
        PurchaseCreditMemo.GetRecord(PurchaseHeader);
        PurchaseHeaderNo := PurchaseHeader."No.";
    end;
}

