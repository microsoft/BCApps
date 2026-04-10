codeunit 144708 "ERM Act Items Receipt M-7"
{
    TestPermissions = NonRestrictive;
    Subtype = Test;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        LibraryReportValidation: Codeunit "Library - Report Validation";
        isInitialized: Boolean;
        ValueNotExistErr: Label 'Value %1 does not exist on worksheet %2';

    [Test]
    [Scope('OnPrem')]
    procedure M7_PurchaseOrderDocumentNo()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PrintM7PurchOrder(PurchaseHeader, 1);

        LibraryReportValidation.VerifyCellValue(12, 19, PurchaseHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure M7_PurchaseOrderAmounts()
    var
        PurchaseHeader: Record "Purchase Header";
        AmountArr: array[5] of Decimal;
        LineQty: Integer;
    begin
        LineQty := LibraryRandom.RandIntInRange(2, ArrayLen(AmountArr));
        PrintM7PurchOrder(PurchaseHeader, LineQty);

        GetPurchaseLineAmounts(AmountArr, PurchaseHeader."No.");
        VerifyLineAmounts(AmountArr, LineQty, 3);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure M7_ItemDocumentReceiptDocumentNo()
    var
        DocumentNo: Code[20];
    begin
        DocumentNo := PrintM7ItemDocumentReceipt(1);

        LibraryReportValidation.VerifyCellValue(12, 19, DocumentNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure M7_ItemDocumentReceiptAmounts()
    var
        DocumentNo: Code[20];
        AmountArr: array[5] of Decimal;
        LineQty: Integer;
    begin
        LineQty := LibraryRandom.RandIntInRange(2, ArrayLen(AmountArr));
        DocumentNo := PrintM7ItemDocumentReceipt(LineQty);

        GetDocumentLineAmounts(AmountArr, DocumentNo);
        VerifyLineAmounts(AmountArr, LineQty, 3);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure M7_ItemReceiptDocumentNo()
    var
        DocumentNo: Code[20];
    begin
        DocumentNo := PrintM7ItemReceipt(1);

        LibraryReportValidation.VerifyCellValue(12, 19, DocumentNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure M7_ItemReceiptAmounts()
    var
        DocumentNo: Code[20];
        AmountArr: array[5] of Decimal;
        LineQty: Integer;
    begin
        LineQty := LibraryRandom.RandIntInRange(2, ArrayLen(AmountArr));
        DocumentNo := PrintM7ItemReceipt(LineQty);

        GetReceiptLineAmounts(AmountArr, DocumentNo);
        VerifyLineAmounts(AmountArr, LineQty, 3);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        if isInitialized then
            exit;

        LibraryERMCountryData.UpdateGeneralPostingSetup();

        isInitialized := true;
        Commit();
    end;

    local procedure PrintM7PurchOrder(var PurchaseHeader: Record "Purchase Header"; LineQty: Integer)
    var
        ActItemsReceiptM7: Report "Act Items Receipt M-7";
    begin
        Initialize();

        CreatePurchDocument(PurchaseHeader, LineQty);

        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID());

        PurchaseHeader.SetRecFilter();
        ActItemsReceiptM7.SetTableView(PurchaseHeader);
        ActItemsReceiptM7.SetFileNameSilent(LibraryReportValidation.GetFileName());
        ActItemsReceiptM7.UseRequestPage(false);
        ActItemsReceiptM7.Run();
    end;

    local procedure PrintM7ItemDocumentReceipt(LineQty: Integer): Code[20]
    var
        InvtDocumentHeader: Record "Invt. Document Header";
        ActItemsReceiptM7: Report "Act Items Receipt M-7";
    begin
        Initialize();

        CreateItemDocumentReceipt(InvtDocumentHeader, LineQty);

        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID());

        InvtDocumentHeader.SetRecFilter();
        ActItemsReceiptM7.SetTableView(InvtDocumentHeader);
        ActItemsReceiptM7.SetFileNameSilent(LibraryReportValidation.GetFileName());
        ActItemsReceiptM7.UseRequestPage(false);
        ActItemsReceiptM7.Run();

        exit(InvtDocumentHeader."No.");
    end;

    local procedure PrintM7ItemReceipt(LineQty: Integer) DocumentNo: Code[20]
    var
        ItemReceiptHeader: Record "Invt. Receipt Header";
        ActItemsReceiptM7: Report "Act Items Receipt M-7";
    begin
        Initialize();

        DocumentNo := CreateAndPostItemDocument(LineQty);

        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID());

        ItemReceiptHeader.SetRange("No.", DocumentNo);
        ActItemsReceiptM7.SetTableView(ItemReceiptHeader);
        ActItemsReceiptM7.SetFileNameSilent(LibraryReportValidation.GetFileName());
        ActItemsReceiptM7.UseRequestPage(false);
        ActItemsReceiptM7.Run();
    end;

    local procedure CreatePurchDocument(var PurchaseHeader: Record "Purchase Header"; LineQty: Integer)
    var
        Vendor: Record Vendor;
        PurchaseLine: Record "Purchase Line";
        i: Integer;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        PurchaseHeader.Validate("Location Code", CreateLocation());
        PurchaseHeader.Modify(true);

        for i := 1 to LineQty do begin
            LibraryPurchase.CreatePurchaseLine(
              PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item,
              LibraryInventory.CreateItemNo(), LibraryRandom.RandDecInRange(5, 10, 2));
            PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(100, 1000, 2));
            PurchaseLine.Modify(true);
        end;
    end;

    local procedure CreateAndPostItemDocument(LineQty: Integer): Code[20]
    var
        InvtDocumentHeader: Record "Invt. Document Header";
    begin
        CreateItemDocumentReceipt(InvtDocumentHeader, LineQty);

        CODEUNIT.Run(CODEUNIT::"Invt. Doc.-Post Receipt", InvtDocumentHeader);

        exit(InvtDocumentHeader."Posting No.");
    end;

    local procedure CreateItemDocumentReceipt(var InvtDocumentHeader: Record "Invt. Document Header"; LineQty: Integer)
    var
        i: Integer;
    begin
        InvtDocumentHeader.Init();
        InvtDocumentHeader."Document Type" := InvtDocumentHeader."Document Type"::Receipt;
        InvtDocumentHeader.Validate("Location Code", CreateLocation());
        InvtDocumentHeader.Insert(true);

        for i := 1 to LineQty do
            CreateInvtDocumentLine(InvtDocumentHeader);
    end;

    local procedure CreateInvtDocumentLine(var InvtDocumentHeader: Record "Invt. Document Header")
    var
        InvtDocumentLine: Record "Invt. Document Line";
        RecRef: RecordRef;
    begin
        InvtDocumentLine.Init();
        InvtDocumentLine.Validate("Document Type", InvtDocumentHeader."Document Type");
        InvtDocumentLine.Validate("Document No.", InvtDocumentHeader."No.");
        RecRef.GetTable(InvtDocumentLine);
        InvtDocumentLine.Validate("Line No.", LibraryUtility.GetNewLineNo(RecRef, InvtDocumentLine.FieldNo("Line No.")));
        InvtDocumentLine.Validate("Item No.", LibraryInventory.CreateItemNo());
        InvtDocumentLine.Validate(Quantity, LibraryRandom.RandDecInRange(5, 10, 2));
        InvtDocumentLine.Validate("Unit Amount", LibraryRandom.RandDecInRange(10, 100, 2));
        InvtDocumentLine.Insert(true);
    end;

    local procedure CreateLocation(): Code[10]
    var
        Location: Record Location;
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        exit(Location.Code);
    end;

    local procedure GetPurchaseLineAmounts(var AmountArr: array[5] of Decimal; DocumentNo: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
        i: Integer;
    begin
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Document No.", DocumentNo);
        PurchaseLine.FindSet();
        repeat
            i += 1;
            AmountArr[i] := PurchaseLine.Amount;
        until PurchaseLine.Next() = 0;
    end;

    local procedure GetDocumentLineAmounts(var AmountArr: array[5] of Decimal; DocumentNo: Code[20])
    var
        InvtDocumentLine: Record "Invt. Document Line";
        i: Integer;
    begin
        InvtDocumentLine.SetRange("Document Type", InvtDocumentLine."Document Type"::Receipt);
        InvtDocumentLine.SetRange("Document No.", DocumentNo);
        InvtDocumentLine.FindSet();
        repeat
            i += 1;
            AmountArr[i] := InvtDocumentLine.Amount;
        until InvtDocumentLine.Next() = 0;
    end;

    local procedure GetReceiptLineAmounts(var AmountArr: array[5] of Decimal; DocumentNo: Code[20])
    var
        ItemReceiptLine: Record "Invt. Receipt Line";
        i: Integer;
    begin
        ItemReceiptLine.SetRange("Document No.", DocumentNo);
        ItemReceiptLine.FindSet();
        repeat
            i += 1;
            AmountArr[i] := ItemReceiptLine.Amount;
        until ItemReceiptLine.Next() = 0;
    end;

    local procedure VerifyLineAmounts(AmountArr: array[5] of Decimal; LineQty: Integer; WorksheetNo: Integer)
    var
        i: Integer;
    begin
        for i := 1 to LineQty do
            Assert.IsTrue(
              LibraryReportValidation.CheckIfValueExistsOnSpecifiedWorksheet(
                WorksheetNo, Format(AmountArr[i])), StrSubstNo(ValueNotExistErr, Format(AmountArr[i]), WorksheetNo));
    end;
}

