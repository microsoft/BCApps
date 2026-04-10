codeunit 144720 "SCM Torg-13 Test"
{
    // // [FEATURE] [Report]

    TestPermissions = NonRestrictive;
    Subtype = Test;

    trigger OnRun()
    begin
    end;

    var
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryReportValidation: Codeunit "Library - Report Validation";
        LibraryRUReports: Codeunit "Library RU Reports";
        LibraryRandom: Codeunit "Library - Random";
        LibraryERM: Codeunit "Library - ERM";
        LibraryUtility: Codeunit "Library - Utility";
        isInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure Torg13Print_JlnLine_DocNoValid()
    var
        ReclassificationItemJournalBatch: Record "Item Journal Batch";
        JournalNo: Code[20];
    begin
        // [FEATURE] [Item Reclass. TORG-13]
        Initialize();
        CreateReclassificationItemJournalBatch(ReclassificationItemJournalBatch);
        JournalNo := LibraryUtility.GenerateGUID();

        CreateReclassJnlLine(ReclassificationItemJournalBatch, JournalNo);

        PrintTorg13ForReclassJnlLine(JournalNo);

        LibraryReportValidation.VerifyCellValue(11, 16, JournalNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Torg13Print_MultipleJnlLines_TotalAmountValid()
    var
        ReclassificationItemJournalBatch: Record "Item Journal Batch";
        JournalNo: Code[20];
        TotalAmount: Decimal;
    begin
        // [FEATURE] [Item Reclass. TORG-13]
        Initialize();
        CreateReclassificationItemJournalBatch(ReclassificationItemJournalBatch);
        JournalNo := LibraryUtility.GenerateGUID();

        CreateReclassJnlLine(ReclassificationItemJournalBatch, JournalNo);
        CreateReclassJnlLine(ReclassificationItemJournalBatch, JournalNo);

        PrintTorg13ForReclassJnlLine(JournalNo);

        TotalAmount := RoundAmount(GetReclassJnlLineAmount(ReclassificationItemJournalBatch));
        LibraryReportValidation.VerifyCellValueByRef('W', 24, 1, Format(TotalAmount));
        LibraryReportValidation.VerifyCellValueByRef('X', 28, 1, Format(GetDecimals(TotalAmount)));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Torg13Print_TransferOrder_DocNoValid()
    var
        HeaderNo: Code[20];
    begin
        // [FEATURE] [Transfer Order TORG-13]
        Initialize();

        HeaderNo := CreateTransferOrder();

        PrintTorg13ForTransferOrder(HeaderNo);

        LibraryReportValidation.VerifyCellValue(11, 16, HeaderNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Torg13Print_TransferOrder_TotalAmountValid()
    var
        TransferLine: Record "Transfer Line";
        HeaderNo: Code[20];
        TotalAmount: Decimal;
    begin
        // [FEATURE] [Transfer Order TORG-13]
        Initialize();

        HeaderNo := CreateTransferOrder();

        PrintTorg13ForTransferOrder(HeaderNo);

        TransferLine.SetRange("Document No.", HeaderNo);

        TotalAmount := RoundAmount(GetTransferOrderAmount(HeaderNo));
        LibraryReportValidation.VerifyCellValueByRef('W', 22 + TransferLine.Count, 1, Format(TotalAmount));
        LibraryReportValidation.VerifyCellValueByRef('X', 26 + TransferLine.Count, 1, Format(GetDecimals(TotalAmount)));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Torg13Print_TransferReceipt_DocNoValid()
    begin
        // [FEATURE] [Transfer Receipt TORG-13]
        Initialize();

        LibraryReportValidation.VerifyCellValue(
          11, 16, PostTransferAndPrintTorg13ForTransferReceipt(CreateTransferOrder()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Torg13Print_TransferReceipt_TotalAmountValid()
    var
        TransferReceiptLine: Record "Transfer Receipt Line";
        HeaderNo: Code[20];
        TotalAmount: Decimal;
    begin
        // [FEATURE] [Transfer Receipt TORG-13]
        Initialize();

        HeaderNo := PostTransferAndPrintTorg13ForTransferReceipt(CreateTransferOrder());
        TransferReceiptLine.SetRange("Document No.", HeaderNo);

        TotalAmount := RoundAmount(GetTransferReceiptAmount(HeaderNo));
        LibraryReportValidation.VerifyCellValueByRef('W', 22 + TransferReceiptLine.Count, 1, Format(TotalAmount));
        LibraryReportValidation.VerifyCellValueByRef('X', 26 + TransferReceiptLine.Count, 1, Format(GetDecimals(TotalAmount)));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Torg13Print_TransferShipment_DocNoValid()
    begin
        // [FEATURE] [Transfer Shipment TORG-13]
        Initialize();

        LibraryReportValidation.VerifyCellValue(
          11, 16, PostTransferAndPrintTorg13ForTransferShipment(CreateTransferOrder()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Torg13Print_TransferShipment_TotalAmountValid()
    var
        TransferShipmentLine: Record "Transfer Shipment Line";
        HeaderNo: Code[20];
        TotalAmount: Decimal;
    begin
        // [FEATURE] [Transfer Shipment TORG-13]
        Initialize();

        HeaderNo := PostTransferAndPrintTorg13ForTransferShipment(CreateTransferOrder());
        TransferShipmentLine.SetRange("Document No.", HeaderNo);

        TotalAmount := RoundAmount(GetTransferShipmentAmount(HeaderNo));
        LibraryReportValidation.VerifyCellValueByRef('W', 22 + TransferShipmentLine.Count, 1, Format(TotalAmount));
        LibraryReportValidation.VerifyCellValueByRef('X', 26 + TransferShipmentLine.Count, 1, Format(GetDecimals(TotalAmount)));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Torg13Print_TransferOrder_RoundedAmounts()
    var
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
    begin
        // [FEATURE] [Transfer Order TORG-13]
        // [SCENARIO 377543] "Transfer Order TORG-13" report prints rounded Total Price values
        Initialize();

        // [GIVEN] Transfer Order with two lines:
        // [GIVEN] Line1: Quantity = 1, Unit Cost = 3.33333
        // [GIVEN] Line2: Quantity = 2, Unit Cost = 3.33333
        LibraryInventory.CreateTransferHeader(
          TransferHeader, LibraryRUReports.CreateLocation(false),
          LibraryRUReports.CreateLocation(false), LibraryRUReports.CreateLocation(true));
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, CreateItemWithCost(3.33333), 1);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, CreateItemWithCost(3.33333), 2);

        // [WHEN] Print "Transfer Order TORG-13" report
        PrintTorg13ForTransferOrder(TransferHeader."No.");

        // [THEN] Line1: Cost = 3.33333, Price = 3.33
        // [THEN] Line2: Cost = 3.33333, Price = 6.67
        // [THEN] Total Price = 10
        // [THEN] Total Price Cent = 0
        LibraryReportValidation.VerifyCellValueByRef('U', 22, 1, Format(3.33333)); // Cost
        LibraryReportValidation.VerifyCellValueByRef('W', 22, 1, Format(3.33)); // Price

        LibraryReportValidation.VerifyCellValueByRef('U', 23, 1, Format(3.33333)); // Cost
        LibraryReportValidation.VerifyCellValueByRef('W', 23, 1, Format(6.67)); // Price

        LibraryReportValidation.VerifyCellValueByRef('W', 24, 1, Format(10)); // Total Price
        LibraryReportValidation.VerifyCellValueByRef('X', 28, 1, Format(0)); // Total Price Cent
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

    local procedure PrintTorg13ForReclassJnlLine(JournalNo: Code[20])
    var
        ReclassificationItemJournalLine: Record "Item Journal Line";
        ItemReclassTORG13: Report "Item Reclass. TORG-13";
    begin
        LibraryReportValidation.SetFileName(JournalNo);

        ReclassificationItemJournalLine.SetRange("No.", JournalNo);

        ItemReclassTORG13.InitializeRequest(LibraryReportValidation.GetFileName());
        ItemReclassTORG13.SetTableView(ReclassificationItemJournalLine);
        ItemReclassTORG13.UseRequestPage(false);
        ItemReclassTORG13.Run();
    end;

    local procedure PrintTorg13ForTransferOrder(HeaderNo: Code[20])
    var
        TransferHeader: Record "Transfer Header";
        TransferOrderTORG13: Report "Transfer Order TORG-13";
    begin
        LibraryReportValidation.SetFileName(HeaderNo);
        TransferHeader.SetRange("No.", HeaderNo);
        TransferOrderTORG13.InitializeRequest(LibraryReportValidation.GetFileName());
        TransferOrderTORG13.SetTableView(TransferHeader);
        TransferOrderTORG13.UseRequestPage(false);
        TransferOrderTORG13.Run();
    end;

    local procedure PostTransferAndPrintTorg13ForTransferReceipt(HeaderNo: Code[20]): Code[20]
    var
        TransferHeader: Record "Transfer Header";
        TransferReceiptHeader: Record "Transfer Receipt Header";
        TransferReceiptTORG13: Report "Transfer Receipt TORG-13";
    begin
        TransferHeader.Get(HeaderNo);
        LibraryInventory.PostTransferHeader(TransferHeader, true, true);

        LibraryReportValidation.SetFileName(HeaderNo);
        TransferReceiptHeader.SetRange("Transfer-from Code", TransferHeader."Transfer-from Code");
        TransferReceiptTORG13.InitializeRequest(LibraryReportValidation.GetFileName());
        TransferReceiptTORG13.SetTableView(TransferReceiptHeader);
        TransferReceiptTORG13.UseRequestPage(false);
        TransferReceiptTORG13.Run();

        TransferReceiptHeader.FindFirst();
        exit(TransferReceiptHeader."No.");
    end;

    local procedure PostTransferAndPrintTorg13ForTransferShipment(HeaderNo: Code[20]): Code[20]
    var
        TransferHeader: Record "Transfer Header";
        TransferShipmentHeader: Record "Transfer Shipment Header";
        TransferShipmentTORG13: Report "Transfer Shipment TORG-13";
    begin
        TransferHeader.Get(HeaderNo);
        LibraryInventory.PostTransferHeader(TransferHeader, true, true);

        LibraryReportValidation.SetFileName(HeaderNo);
        TransferShipmentHeader.SetRange("Transfer-from Code", TransferHeader."Transfer-from Code");
        TransferShipmentTORG13.InitializeRequest(LibraryReportValidation.GetFileName());
        TransferShipmentTORG13.SetTableView(TransferShipmentHeader);
        TransferShipmentTORG13.UseRequestPage(false);
        TransferShipmentTORG13.Run();

        TransferShipmentHeader.FindFirst();
        exit(TransferShipmentHeader."No.");
    end;

    local procedure CreateTransferOrder(): Code[20]
    var
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        I: Integer;
        LocationCode: Code[10];
        ItemNo: Code[20];
        Quantity: Decimal;
    begin
        LocationCode := LibraryRUReports.CreateLocation(false);
        LibraryInventory.CreateTransferHeader(
          TransferHeader, LocationCode,
          LibraryRUReports.CreateLocation(false), LibraryRUReports.CreateLocation(true));

        for I := 0 to LibraryRandom.RandInt(10) do begin
            ItemNo := LibraryRUReports.CreateItemWithCost();
            Quantity := LibraryRandom.RandDecInRange(5, 10, 2);

            LibraryRUReports.CreateAndPostItemJournalLine(LocationCode, ItemNo, Quantity, true);
            LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, ItemNo, Quantity);
        end;

        exit(TransferHeader."No.");
    end;

    local procedure CreateReclassificationItemJournalBatch(var ReclassificationItemJournalBatch: Record "Item Journal Batch")
    var
        ReclassificationItemJournalTemplate: Record "Item Journal Template";
    begin
        LibraryInventory.CreateItemJournalBatchByType(
          ReclassificationItemJournalBatch, ReclassificationItemJournalTemplate.Type::Transfer);
    end;

    local procedure CreateReclassJnlLine(ReclassificationItemJournalBatch: Record "Item Journal Batch"; JournalNo: Code[20])
    var
        ReclassificationItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.CreateItemJournalLine(
          ReclassificationItemJournalLine, ReclassificationItemJournalBatch."Journal Template Name",
          ReclassificationItemJournalBatch.Name, ReclassificationItemJournalLine."Entry Type"::Transfer,
          LibraryRUReports.CreateItemWithCost(), LibraryRandom.RandInt(10));

        ReclassificationItemJournalLine."No." := JournalNo;
        ReclassificationItemJournalLine.Modify();
    end;

    local procedure CreateItemWithCost(NewUnitCost: Decimal): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Unit Cost", NewUnitCost);
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure GetReclassJnlLineAmount(ReclassificationItemJournalBatch: Record "Item Journal Batch") TotalAmount: Decimal
    var
        ReclassificationItemJournalLine: Record "Item Journal Line";
        Item: Record Item;
    begin
        TotalAmount := 0;
        ReclassificationItemJournalLine.SetRange("Journal Template Name", ReclassificationItemJournalBatch."Journal Template Name");
        ReclassificationItemJournalLine.SetRange("Journal Batch Name", ReclassificationItemJournalBatch.Name);
        if ReclassificationItemJournalLine.FindSet() then
            repeat
                Item.Get(ReclassificationItemJournalLine."Item No.");
                TotalAmount += ReclassificationItemJournalLine.Quantity * Item."Unit Cost";
            until ReclassificationItemJournalLine.Next() = 0;
    end;

    local procedure GetTransferOrderAmount(HeaderNo: Code[20]) TotalAmount: Decimal
    var
        TransferLine: Record "Transfer Line";
        Item: Record Item;
    begin
        TotalAmount := 0;

        TransferLine.SetRange("Document No.", HeaderNo);
        if TransferLine.FindSet() then
            repeat
                Item.Get(TransferLine."Item No.");
                TotalAmount += TransferLine.Quantity * Item."Unit Cost";
            until TransferLine.Next() = 0;
    end;

    local procedure GetTransferReceiptAmount(HeaderNo: Code[20]) TotalAmount: Decimal
    var
        TransferReceiptLine: Record "Transfer Receipt Line";
        Item: Record Item;
    begin
        TotalAmount := 0;

        TransferReceiptLine.SetRange("Document No.", HeaderNo);
        if TransferReceiptLine.FindSet() then
            repeat
                Item.Get(TransferReceiptLine."Item No.");
                TotalAmount += TransferReceiptLine.Quantity * Item."Unit Cost";
            until TransferReceiptLine.Next() = 0;
    end;

    local procedure GetTransferShipmentAmount(HeaderNo: Code[20]) TotalAmount: Decimal
    var
        TransferShipmentLine: Record "Transfer Shipment Line";
        Item: Record Item;
    begin
        TotalAmount := 0;

        TransferShipmentLine.SetRange("Document No.", HeaderNo);
        if TransferShipmentLine.FindSet() then
            repeat
                Item.Get(TransferShipmentLine."Item No.");
                TotalAmount += TransferShipmentLine.Quantity * Item."Unit Cost";
            until TransferShipmentLine.Next() = 0;
    end;

    local procedure GetDecimals(Value: Decimal): Decimal
    begin
        exit((Value mod 1) * 100);
    end;

    local procedure RoundAmount(Value: Decimal): Decimal
    begin
        exit(Round(Value, LibraryERM.GetAmountRoundingPrecision()));
    end;
}

