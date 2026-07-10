codeunit 144712 "ERM TORG-29 Report"
{
    TestPermissions = NonRestrictive;
    Subtype = Test;
    Permissions = tabledata "Item Ledger Entry" = i,
                  tabledata "Value Entry" = i;

    var
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryPriceCalculation: Codeunit "Library - Price Calculation";
        LibraryReportValidation: Codeunit "Library - Report Validation";
        TORG29Helper: Codeunit "TORG-29 Helper";
        isInitialized: Boolean;
        ReceiptsDetailing: Option Document,Item,Operation;
        ShipmentDetailing: Option "Sum",Document,Item,Operation;
        AmountType: Option Cost,Price;
        WrongResidOnStartErr: Label 'Wrong residual on start.';
        WrongErrorsCountErr: Label 'Wrong errors count.';
        NoPriceFoundTxt: Label 'No price found';
        WrongEntriesCountErr: Label 'Wrong count of entries.';
        WrongValueErr: Label 'Wrong value in field %1.';

    [Test]
    [Scope('OnPrem')]
    procedure MultipleReceiptsAndShipmentPrinting()
    var
        TempValueEntryRcpt: Record "Value Entry" temporary;
        TempValueEntryShpt: Record "Value Entry" temporary;
        TempValueEntryResid: Record "Value Entry" temporary;
        ItemNo: Code[20];
        LocationCode: Code[10];
        PostingDate: Date;
    begin
        Initialize();
        PostingDate := GetLastValueEntryDate();
        ItemNo := MockItem();
        LocationCode := MockSimpleLocation();
        MockCostAmountValueEntries(TempValueEntryResid, ItemNo, LocationCode, PostingDate, 1);
        PostingDate := CalcDate('<1M>', PostingDate);
        MockCostAmountValueEntries(TempValueEntryRcpt, ItemNo, LocationCode, PostingDate, 1);
        MockCostAmountValueEntries(TempValueEntryShpt, ItemNo, LocationCode, PostingDate, -1);
        RunTORG29Report(TempValueEntryRcpt."Location Code", PostingDate);
        VerifyReportLineValuesFromBuffer(
          TempValueEntryResid, TempValueEntryRcpt, TempValueEntryShpt);
    end;


    [Test]
    [Scope('OnPrem')]
    procedure ResidOnStartWithPriceAmountTypeV16()
    var
        TempValueEntry: Record "Value Entry" temporary;
        ErrorBuffer: Record "Value Entry" temporary;
        ItemNo: Code[20];
        LocationCode: Code[10];
        PostingDate: Date;
        ResidOnstart: Decimal;
        SalesPrice: Decimal;
        EntriesCount: Integer;
        ErrorsCount: Integer;
    begin
        InitData(PostingDate, ItemNo, LocationCode);
        EnableNewPricing();
        SalesPrice := MockSalesPriceListLine(ItemNo, PostingDate);
        MockCostAmountValueEntries(TempValueEntry, ItemNo, LocationCode, PostingDate, 1);
        PostingDate := CalcDate('<1M>', PostingDate);
        TORG29Helper.CreateTempReceipts(
          TempValueEntry, ErrorBuffer, EntriesCount, ErrorsCount, ResidOnstart, PostingDate, PostingDate,
          LocationCode, AmountType::Price, ReceiptsDetailing::Document, "Sales Price Type"::"All Customers", '', false);
        TempValueEntry.CalcSums("Item Ledger Entry Quantity");
        Assert.AreEqual(
          Round(SalesPrice * TempValueEntry."Item Ledger Entry Quantity"), ResidOnstart, WrongResidOnStartErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorsOnRcptWithPriceAmountType()
    var
        TempValueEntry: Record "Value Entry" temporary;
        ErrorBuffer: Record "Value Entry" temporary;
        ItemNo: Code[20];
        LocationCode: Code[10];
        InitialPostingDate: Date;
        PostingDate: Date;
        ResidOnstart: Decimal;
        EntriesCount: Integer;
        ErrorsCount: Integer;
    begin
        InitData(InitialPostingDate, ItemNo, LocationCode);
        MockCostAmountValueEntries(TempValueEntry, ItemNo, LocationCode, InitialPostingDate, 1);
        PostingDate := CalcDate('<1M>', InitialPostingDate);
        TORG29Helper.CreateTempReceipts(
          TempValueEntry, ErrorBuffer, EntriesCount, ErrorsCount, ResidOnstart, PostingDate, PostingDate,
          LocationCode, AmountType::Price, ReceiptsDetailing::Document, "Sales Price Type"::"All Customers", '', false);
        VerifyErrors(TempValueEntry, ErrorBuffer, ErrorsCount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReceiptsItemDetailing()
    var
        TempValueEntry: Record "Value Entry" temporary;
        TempRcptValueEntry: Record "Value Entry" temporary;
        ErrorBuffer: Record "Value Entry" temporary;
        ItemNo: Code[20];
        LocationCode: Code[10];
        PostingDate: Date;
        ResidOnstart: Decimal;
        EntriesCount: Integer;
        ErrorsCount: Integer;
    begin
        InitData(PostingDate, ItemNo, LocationCode);
        MockCostAmountValueEntries(TempValueEntry, ItemNo, LocationCode, PostingDate, 1);
        TORG29Helper.CreateTempReceipts(
          TempRcptValueEntry, ErrorBuffer, EntriesCount, ErrorsCount, ResidOnstart, PostingDate, PostingDate,
          LocationCode, AmountType::Cost, ReceiptsDetailing::Item, "Sales Price Type"::"All Customers", '', false);
        TempValueEntry.CalcSums("Cost Amount (Actual)");
        Assert.AreEqual(1, TempRcptValueEntry.Count, WrongEntriesCountErr);
        Assert.AreEqual(
          TempRcptValueEntry."Valued Quantity", TempValueEntry."Cost Amount (Actual)",
          StrSubstNo(WrongValueErr, TempRcptValueEntry.FieldCaption("Valued Quantity")));
    end;


    [Test]
    [Scope('OnPrem')]
    procedure ReceiptsWithPriceAmountTypeV16()
    var
        TempValueEntry: Record "Value Entry" temporary;
        TempRcptValueEntry: Record "Value Entry" temporary;
        ErrorBuffer: Record "Value Entry" temporary;
        ItemNo: Code[20];
        LocationCode: Code[10];
        PostingDate: Date;
        ResidOnstart: Decimal;
        SalesPrice: Decimal;
        EntriesCount: Integer;
        ErrorsCount: Integer;
    begin
        InitData(PostingDate, ItemNo, LocationCode);
        EnableNewPricing();
        SalesPrice := MockSalesPriceListLine(ItemNo, PostingDate);
        MockCostAmountValueEntries(TempValueEntry, ItemNo, LocationCode, PostingDate, 1);
        TORG29Helper.CreateTempReceipts(
          TempRcptValueEntry, ErrorBuffer, EntriesCount, ErrorsCount, ResidOnstart, PostingDate, PostingDate,
          LocationCode, AmountType::Price, ReceiptsDetailing::Document, "Sales Price Type"::"All Customers", '', false);
        TempValueEntry.CalcSums("Item Ledger Entry Quantity");
        TempRcptValueEntry.CalcSums("Valued Quantity");
        Assert.AreEqual(
          TempRcptValueEntry."Valued Quantity", Round(SalesPrice * TempValueEntry."Item Ledger Entry Quantity"),
          StrSubstNo(WrongValueErr, TempRcptValueEntry.FieldCaption("Valued Quantity")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorsOnShptWithPriceAmountType()
    var
        TempValueEntry: Record "Value Entry" temporary;
        TempShptValueEntry: Record "Value Entry" temporary;
        ErrorBuffer: Record "Value Entry" temporary;
        ItemNo: Code[20];
        LocationCode: Code[10];
        PostingDate: Date;
        EntriesCount: Integer;
        ErrorsCount: Integer;
    begin
        InitData(PostingDate, ItemNo, LocationCode);
        MockCostAmountValueEntries(TempValueEntry, ItemNo, LocationCode, PostingDate, -1);
        TORG29Helper.CreateTempShipment(
          TempShptValueEntry, ErrorBuffer, EntriesCount, ErrorsCount, PostingDate, PostingDate,
          LocationCode, AmountType::Price, ShipmentDetailing::Document, "Sales Price Type"::"All Customers", '', false);
        VerifyErrors(TempValueEntry, ErrorBuffer, ErrorsCount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShipmentItemDetailing()
    var
        TempValueEntry: Record "Value Entry" temporary;
        TempShptValueEntry: Record "Value Entry" temporary;
        ErrorBuffer: Record "Value Entry" temporary;
        ItemNo: Code[20];
        LocationCode: Code[10];
        PostingDate: Date;
        EntriesCount: Integer;
        ErrorsCount: Integer;
    begin
        InitData(PostingDate, ItemNo, LocationCode);
        MockCostAmountValueEntries(TempValueEntry, ItemNo, LocationCode, PostingDate, -1);
        TORG29Helper.CreateTempShipment(
          TempShptValueEntry, ErrorBuffer, EntriesCount, ErrorsCount, PostingDate, PostingDate,
          LocationCode, AmountType::Cost, ShipmentDetailing::Item, "Sales Price Type"::"All Customers", '', false);
        TempValueEntry.CalcSums("Cost Amount (Actual)");
        Assert.AreEqual(1, TempShptValueEntry.Count, WrongEntriesCountErr);
        Assert.AreEqual(
          TempShptValueEntry."Valued Quantity", -TempValueEntry."Cost Amount (Actual)",
          StrSubstNo(WrongValueErr, TempShptValueEntry.FieldCaption("Valued Quantity")));
    end;


    [Test]
    [Scope('OnPrem')]
    procedure ShptsWithPriceAmountTypeV16()
    var
        TempValueEntry: Record "Value Entry" temporary;
        TempShptValueEntry: Record "Value Entry" temporary;
        ErrorBuffer: Record "Value Entry" temporary;
        ItemNo: Code[20];
        LocationCode: Code[10];
        PostingDate: Date;
        SalesPrice: Decimal;
        EntriesCount: Integer;
        ErrorsCount: Integer;
    begin
        InitData(PostingDate, ItemNo, LocationCode);
        EnableNewPricing();
        SalesPrice := MockSalesPriceListLine(ItemNo, PostingDate);
        MockCostAmountValueEntries(TempValueEntry, ItemNo, LocationCode, PostingDate, -1);
        TORG29Helper.CreateTempShipment(
          TempShptValueEntry, ErrorBuffer, EntriesCount, ErrorsCount, PostingDate, PostingDate,
          LocationCode, AmountType::Price, ShipmentDetailing::Document, "Sales Price Type"::"All Customers", '', false);
        TempValueEntry.CalcSums("Item Ledger Entry Quantity");
        TempShptValueEntry.CalcSums("Valued Quantity");
        Assert.AreEqual(
          TempShptValueEntry."Valued Quantity", -Round(SalesPrice * TempValueEntry."Item Ledger Entry Quantity"),
          StrSubstNo(WrongValueErr, TempShptValueEntry.FieldCaption("Valued Quantity")));
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        Clear(LibraryReportValidation);
        Clear(TORG29Helper);
        LibraryPriceCalculation.DisableExtendedPriceCalculation();

        if isInitialized then
            exit;

        LibraryERMCountryData.UpdateGeneralPostingSetup();

        isInitialized := true;
        Commit();
    end;

    local procedure InitData(var PostingDate: Date; var ItemNo: Code[20]; var LocationCode: Code[10])
    begin
        Initialize();
        PostingDate := CalcDate('<1M>', GetLastValueEntryDate());
        ItemNo := MockItem();
        LocationCode := MockSimpleLocation();
    end;

    local procedure MockItem(): Code[20]
    var
        Item: Record Item;
    begin
        Item.Init();
        Item.Insert(true);
        exit(Item."No.");
    end;

    local procedure MockSalesPriceListLine(ItemNo: Code[20]; PostingDate: Date): Decimal
    var
        PriceListLine: Record "Price List Line";
    begin
        LibraryPriceCalculation.CreateSalesPriceLine(
            PriceListLine, '', "Price Source Type"::"All Customers", '', "Price Asset Type"::Item, ItemNo);
        PriceListLine.Validate("Starting Date", PostingDate);
        PriceListLine."Ending Date" := PostingDate;
        PriceListLine."Unit Price" := LibraryRandom.RandDec(100, 2);
        PriceListLine.Status := PriceListLine.Status::Active;
        PriceListLine.Modify();
        exit(PriceListLine."Unit Price");
    end;


    local procedure MockEmployee(): Code[20]
    var
        Employee: Record Employee;
    begin
        Employee.Init();
        Employee."No." := LibraryUtility.GenerateGUID();
        Employee.Insert();
        exit(Employee."No.");
    end;

    local procedure MockSimpleLocation(): Code[10]
    var
        Location: Record Location;
    begin
        Location.Init();
        Location.Code := LibraryUtility.GenerateGUID();
        Location.Insert();
        exit(Location.Code);
    end;

    local procedure MockCostAmountValueEntries(var TempValueEntry: Record "Value Entry"; ItemNo: Code[20]; LocationCode: Code[10]; PostingDate: Date; Sign: Integer)
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        ValueEntry: Record "Value Entry";
        ItemEntryNo: Integer;
        ValueEntryNo: Integer;
        i: Integer;
    begin
        ValueEntry.FindLast();
        ValueEntryNo := ValueEntry."Entry No.";
        ItemLedgEntry.FindLast();
        ItemEntryNo := ItemLedgEntry."Entry No.";

        for i := 1 to 2 do begin
            MockValueEntry(ValueEntry, ItemEntryNo, ValueEntryNo, ItemNo, PostingDate, LocationCode, Sign);
            CopyFromValueEntryToValueEntry(TempValueEntry, ValueEntry);
        end;
    end;

    local procedure MockValueEntry(var ValueEntry: Record "Value Entry"; var ItemEntryNo: Integer; var ValueEntryNo: Integer; ItemNo: Code[20]; PostingDate: Date; LocationCode: Code[10]; Sign: Integer)
    begin
        ValueEntryNo += 1;
        ValueEntry.Init();
        ValueEntry."Entry No." := ValueEntryNo;
        ValueEntry."Document Type" := ValueEntry."Document Type"::"Sales Invoice";
        ValueEntry."Document No." := LibraryUtility.GenerateGUID();
        ValueEntry."Item No." := ItemNo;
        ValueEntry."Posting Date" := PostingDate;
        ValueEntry."Location Code" := LocationCode;
        ValueEntry."Item Ledger Entry Quantity" := Sign * LibraryRandom.RandInt(100);
        ValueEntry."Cost Amount (Actual)" := Sign * LibraryRandom.RandDec(100, 2);
        ValueEntry."Sales Amount (Actual)" := Round(ValueEntry."Cost Amount (Actual)" * LibraryRandom.RandInt(10));
        ValueEntry."Item Ledger Entry No." := MockItemLedgEntry(ItemEntryNo);
        ValueEntry.Positive := Sign > 0;
        ValueEntry.Insert();
    end;

    local procedure MockItemLedgEntry(var EntryNo: Integer): Integer
    var
        ItemLedgEntry: Record "Item Ledger Entry";
    begin
        EntryNo += 1;
        ItemLedgEntry.Init();
        ItemLedgEntry."Entry No." := EntryNo;
        ItemLedgEntry.Insert();
        exit(ItemLedgEntry."Entry No.");
    end;

    local procedure EnableNewPricing()
    begin
        LibraryPriceCalculation.EnableExtendedPriceCalculation();
        LibraryPriceCalculation.SetupDefaultHandler("Price Calculation Handler"::"Business Central (Version 16.0)");
    end;

    local procedure CopyFromValueEntryToValueEntry(var ToValueEntry: Record "Value Entry"; FromValueEntry: Record "Value Entry")
    begin
        ToValueEntry := FromValueEntry;
        ToValueEntry.Insert();
    end;

    local procedure RunTORG29Report(LocationCode: Code[10]; PostingDate: Date)
    var
        TORG29Rep: Report "Item Report TORG-29";
        SalesType: Option "Customer Price Group","All Customers",Campaign;
    begin
        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID());
        TORG29Rep.SetFileNameSilent(LibraryReportValidation.GetFileName());
        TORG29Rep.InitializeRequest(
          LocationCode, '', MockEmployee(), MockEmployee(), PostingDate, PostingDate, '', 0, ReceiptsDetailing::Document, ShipmentDetailing::Document,
          AmountType::Cost, SalesType::"All Customers", '', true, true);
        TORG29Rep.UseRequestPage(false);
        TORG29Rep.RunModal();
    end;

    local procedure GetLastValueEntryDate(): Date
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.SetCurrentKey("Posting Date", "Item No.");
        ValueEntry.FindLast();
        exit(ValueEntry."Posting Date");
    end;

    local procedure VerifyReportLineValuesFromBuffer(var TempValueEntryResid: Record "Value Entry" temporary; var TempValueEntryRcpt: Record "Value Entry" temporary; var TempValueEntryShpt: Record "Value Entry" temporary)
    var
        ResidOnStart: Decimal;
        LineRowId: Integer;
        RowShift: Integer;
    begin
        TempValueEntryResid.CalcSums("Cost Amount (Actual)");
        ResidOnStart := TempValueEntryResid."Cost Amount (Actual)";
        LibraryReportValidation.VerifyCellValue(25, 13, Format(TempValueEntryResid."Cost Amount (Actual)"));
        RowShift := 0;

        TempValueEntryRcpt.FindSet();
        repeat
            VerifyLineValue(
              RowShift, Format(TempValueEntryRcpt."Posting Date"), TempValueEntryRcpt."Document No.", Format(TempValueEntryRcpt."Cost Amount (Actual)"), Format(-TempValueEntryRcpt."Cost Amount (Actual)"));
        until TempValueEntryRcpt.Next() = 0;
        LineRowId := 28 + RowShift;
        TempValueEntryRcpt.CalcSums("Cost Amount (Actual)");
        LibraryReportValidation.VerifyCellValue(LineRowId, 13, Format(TempValueEntryRcpt."Cost Amount (Actual)"));
        LibraryReportValidation.VerifyCellValue(LineRowId + 1, 13, Format(-TempValueEntryRcpt."Cost Amount (Actual)"));
        LibraryReportValidation.VerifyCellValue(LineRowId + 2, 13, Format(ResidOnStart));

        RowShift += 9;
        TempValueEntryShpt.FindSet();
        repeat
            VerifyLineValue(
              RowShift, Format(TempValueEntryShpt."Posting Date"), TempValueEntryShpt."Document No.", Format(-TempValueEntryShpt."Cost Amount (Actual)"), Format(-TempValueEntryShpt."Cost Amount (Actual)"));
        until TempValueEntryShpt.Next() = 0;
        LineRowId := 28 + RowShift;
        TempValueEntryShpt.CalcSums("Cost Amount (Actual)");
        LibraryReportValidation.VerifyCellValue(LineRowId, 13, Format(-TempValueEntryShpt."Cost Amount (Actual)"));
        LibraryReportValidation.VerifyCellValue(LineRowId + 1, 13, Format(ResidOnStart));
    end;

    local procedure VerifyLineValue(var RowShift: Integer; PostingDate: Text; DocNo: Text; LineAmount: Text; LineAmountWithCosts: Text)
    var
        LineRowId: Integer;
    begin
        LineRowId := 28 + RowShift;
        LibraryReportValidation.VerifyCellValue(LineRowId, 9, PostingDate);
        LibraryReportValidation.VerifyCellValue(LineRowId, 10, DocNo);
        LibraryReportValidation.VerifyCellValue(LineRowId, 13, LineAmount);
        LibraryReportValidation.VerifyCellValue(LineRowId + 1, 13, LineAmountWithCosts);
        RowShift += 2;
    end;

    local procedure VerifyErrors(var ValueEntry: Record "Value Entry"; var ErrorBuffer: Record "Value Entry" temporary; ErrorsCount: Integer)
    var
        i: Integer;
    begin
        Assert.AreEqual(2, ErrorsCount, WrongErrorsCountErr);
        i := 0;
        ValueEntry.FindSet();
        repeat
            i += 1;
            ErrorBuffer.Get(i);
            ErrorBuffer.TestField("Item No.", ValueEntry."Item No.");
            ErrorBuffer.TestField("Posting Date", ValueEntry."Posting Date");
            ErrorBuffer.TestField(Description, NoPriceFoundTxt);
        until ValueEntry.Next() = 0;
    end;
}
