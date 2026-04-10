#pragma warning disable AA0247
codeunit 14949 "TORG-29 Helper"
{

    trigger OnRun()
    begin
    end;

    var
        ExcelReportBuilderManager: Codeunit "Excel Report Builder Manager";
        StdRepMgt: Codeunit "Local Report Management";
        LocMgt: Codeunit "Localisation Management";
        EntryType: Option " ",Shipment,Receipt;
        ReceiptsDetailing: Option Document,Item,Operation;
        ShipmentDetailing: Option "Sum",Document,Item,Operation;
        AmountType: Option Cost,Price;
        NoPriceFoundErr: Label 'No price found';
        SeveralPricesFoundErr: Label 'Several records in price list found';
        AdjmtTxt: Label 'Adj.';

    [Scope('OnPrem')]
    procedure CreateTempReceipts(var TempValueEntryReceipts: Record "Value Entry"; var ErrorBuffer: Record "Value Entry"; var EntriesCount: Integer; var ErrorsCount: Integer; var ResidOnstart: Decimal; StartDate: Date; EndDate: Date; LocationCode: Code[10]; PassedAmountType: Option; PassedReceiptsDetailing: Option; PassedSalesPriceType: Enum "Sales Price Type"; SalesCode: Code[20]; ShowCostReceipts: Boolean)
    var
        Vendor: Record Vendor;
        Customer: Record Customer;
        Location: Record Location;
        Item: Record Item;
        GLItemRelation: Record "G/L - Item Ledger Relation";
        GLEntry: Record "G/L Entry";
        ValueEntryReceipts: Record "Value Entry";
        ItemLedgEntry: Record "Item Ledger Entry";
        UpdateFlag: Boolean;
        LastKeyString: Text[255];
        CurrentKeyString: Text[255];
        SourceName: Text[255];
        AdjustmentText: Text[30];
        CurrentCostAmount: Decimal;
        CurrentSalesAmount: Decimal;
    begin
        UpdateFlag := false;
        LastKeyString := '';
        CurrentKeyString := '';
        CurrentSalesAmount := 0;
        CurrentCostAmount := 0;
        EntriesCount := 0;
        ErrorsCount := 0;
        ResidOnstart := 0;
        Location.Get(LocationCode);

        ResidOnstart :=
          CalcRcptResidOnStart(ErrorBuffer, ErrorsCount, StartDate, LocationCode, PassedAmountType, PassedSalesPriceType, SalesCode);

        case PassedReceiptsDetailing of
            ReceiptsDetailing::Document:
                ValueEntryReceipts.SetCurrentKey("Posting Date", "Document No.", "Document Type");
            ReceiptsDetailing::Item:
                ValueEntryReceipts.SetCurrentKey("Posting Date", "Item No.");
            ReceiptsDetailing::Operation:
                ValueEntryReceipts.SetCurrentKey("Posting Date", "Item No.");
        end;

        ValueEntryReceipts.SetRange("Posting Date", StartDate, EndDate);
        ValueEntryReceipts.SetRange("Location Code", LocationCode);

        if ValueEntryReceipts.FindSet() then
            repeat
                if ValueEntryReceipts.IsDebit() then begin
                    case PassedReceiptsDetailing of
                        ReceiptsDetailing::Document:
                            CurrentKeyString := StrSubstNo('%1|%2|%3',
                                ValueEntryReceipts."Document No.",
                                ValueEntryReceipts."Document Type",
                                ValueEntryReceipts."Posting Date");
                        ReceiptsDetailing::Item:
                            CurrentKeyString := StrSubstNo('%1|%2',
                                ValueEntryReceipts."Posting Date",
                                ValueEntryReceipts."Item No.");
                        ReceiptsDetailing::Operation:
                            CurrentKeyString := StrSubstNo('%1',
                                ValueEntryReceipts."Entry No.");
                    end;

                    if LastKeyString = CurrentKeyString then
                        UpdateFlag := true
                    else begin
                        UpdateFlag := false;
                        TempValueEntryReceipts.Init();
                        EntriesCount := EntriesCount + 1;
                        LastKeyString := CurrentKeyString;
                        CurrentSalesAmount := 0;
                        CurrentCostAmount := 0;
                    end;

                    if PassedAmountType = AmountType::Price then
                        CurrentSalesAmount +=
                          CalcAmountFromSalesPrice(ErrorBuffer, ErrorsCount, ValueEntryReceipts, PassedSalesPriceType, SalesCode, UpdateFlag);
                    if (PassedAmountType = AmountType::Cost) or ShowCostReceipts then begin
                        CurrentCostAmount := CurrentCostAmount + Round(ValueEntryReceipts."Cost Amount (Actual)");
                        TempValueEntryReceipts."Valued Quantity" := CurrentCostAmount;
                    end else
                        TempValueEntryReceipts."Valued Quantity" := CurrentSalesAmount;

                    if (PassedAmountType = AmountType::Cost) and (PassedReceiptsDetailing = ReceiptsDetailing::Operation) then begin
                        GLItemRelation.SetRange("Value Entry No.", ValueEntryReceipts."Entry No.");
                        if GLItemRelation.FindSet() then
                            repeat
                                if GLEntry.Get(GLItemRelation."G/L Entry No.") then
                                    if (GLEntry.Amount > 0) xor ((GLEntry."Debit Amount" < 0) or (GLEntry."Credit Amount" < 0)) then
                                        TempValueEntryReceipts."Job No." := GLEntry."G/L Account No."
                                    else
                                        TempValueEntryReceipts."Job Task No." := GLEntry."G/L Account No."
                            until GLItemRelation.Next() = 0;
                    end;
                    TempValueEntryReceipts."Posting Date" := ValueEntryReceipts."Posting Date";
                    TempValueEntryReceipts."Sales Amount (Actual)" := CurrentSalesAmount;
                    TempValueEntryReceipts."Cost Amount (Actual)" := CurrentCostAmount;
                    TempValueEntryReceipts."Entry No." := EntriesCount;
                    TempValueEntryReceipts."Item Ledger Entry Quantity" :=
                      TempValueEntryReceipts."Item Ledger Entry Quantity" + ValueEntryReceipts."Item Ledger Entry Quantity";
                    case PassedReceiptsDetailing of
                        ReceiptsDetailing::Document:
                            begin
                                SourceName := '';
                                AdjustmentText := '';
                                if ValueEntryReceipts."Source Type" = ValueEntryReceipts."Source Type"::" " then begin
                                    ItemLedgEntry.Get(ValueEntryReceipts."Item Ledger Entry No.");
                                    ValueEntryReceipts."Source Type" := ItemLedgEntry."Source Type";
                                    ValueEntryReceipts."Source No." := ItemLedgEntry."Source No.";
                                end;
                                case ValueEntryReceipts."Source Type" of
                                    ValueEntryReceipts."Source Type"::Vendor:
                                        begin
                                            Vendor.Get(ValueEntryReceipts."Source No.");
                                            SourceName := Vendor."Search Name";
                                        end;
                                    ValueEntryReceipts."Source Type"::Customer:
                                        begin
                                            Customer.Get(ValueEntryReceipts."Source No.");
                                            SourceName := Customer."Search Name";
                                        end;
                                end;
                                if (PassedAmountType = AmountType::Cost) and (TempValueEntryReceipts."Item Ledger Entry Quantity" = 0) then
                                    AdjustmentText := AdjmtTxt;

                                TempValueEntryReceipts.Description := StrSubstNo('%1 %2 %3 %4',
                                    Format(ValueEntryReceipts."Item Ledger Entry Type"),
                                    AdjustmentText,
                                    ValueEntryReceipts."Source No.",
                                    SourceName);
                                TempValueEntryReceipts."Document No." := ValueEntryReceipts."Document No.";
                            end;
                        ReceiptsDetailing::Item:
                            if Item.Get(ValueEntryReceipts."Item No.") then
                                TempValueEntryReceipts.Description := Item.Description;
                        ReceiptsDetailing::Operation:
                            begin
                                Item.Get(ValueEntryReceipts."Item No.");
                                TempValueEntryReceipts."Document No." := ValueEntryReceipts."Document No.";
                                TempValueEntryReceipts.Description := StrSubstNo('%1 %2',
                                    Format(ValueEntryReceipts."Item Ledger Entry Type"),
                                    Item.Description);
                            end;
                    end;
                    if UpdateFlag then
                        TempValueEntryReceipts.Modify()
                    else
                        TempValueEntryReceipts.Insert();
                end;
            until ValueEntryReceipts.Next() = 0;
        ValueEntryReceipts.Reset();
        TempValueEntryReceipts.Reset();
    end;

    [Scope('OnPrem')]
    procedure CreateTempShipment(var TempValueEntryShipment: Record "Value Entry"; var ErrorBuffer: Record "Value Entry"; var EntriesCount: Integer; var ErrorsCount: Integer; StartDate: Date; EndDate: Date; LocationCode: Code[10]; PassedAmountType: Option; PassedShipmentDetailing: Option; PassedSalesType: Enum "Sales Price Type"; SalesCode: Code[20]; ShowCostShipment: Boolean)
    var
        Item: Record Item;
        Vendor: Record Vendor;
        Customer: Record Customer;
        GLItemRelation: Record "G/L - Item Ledger Relation";
        GLEntry: Record "G/L Entry";
        ValueEntryShipment: Record "Value Entry";
        UpdateFlag: Boolean;
        LastKeyString: Text[255];
        CurrentKeyString: Text[255];
        SourceName: Text[255];
        AdjustmentText: Text[30];
        CurrentCostAmount: Decimal;
        CurrentSalesAmount: Decimal;
    begin
        UpdateFlag := false;
        LastKeyString := '';
        CurrentKeyString := '';
        CurrentSalesAmount := 0;
        CurrentCostAmount := 0;
        EntriesCount := 0;

        case PassedShipmentDetailing of
            ShipmentDetailing::Document:
                ValueEntryShipment.SetCurrentKey("Posting Date", "Document No.", "Document Type");
            ShipmentDetailing::Item:
                ValueEntryShipment.SetCurrentKey("Posting Date", "Item No.");
            ShipmentDetailing::Operation:
                ValueEntryShipment.SetCurrentKey("Posting Date", "Item No.");
            ShipmentDetailing::Sum:
                ValueEntryShipment.SetCurrentKey("Item No.");
        end;

        ValueEntryShipment.SetRange("Posting Date", StartDate, EndDate);
        ValueEntryShipment.SetRange("Location Code", LocationCode);
        if ValueEntryShipment.FindSet() then
            repeat
                if not ValueEntryShipment.IsDebit() then begin
                    case PassedShipmentDetailing of
                        ShipmentDetailing::Document:
                            CurrentKeyString := StrSubstNo('%1|%2|%3',
                                ValueEntryShipment."Document No.",
                                ValueEntryShipment."Document Type",
                                ValueEntryShipment."Posting Date");
                        ShipmentDetailing::Item:
                            CurrentKeyString := StrSubstNo('%1|%2',
                                ValueEntryShipment."Posting Date",
                                ValueEntryShipment."Item No.");
                        ShipmentDetailing::Operation:
                            CurrentKeyString := StrSubstNo('%1',
                                ValueEntryShipment."Entry No.");
                        ShipmentDetailing::Sum:
                            CurrentKeyString := StrSubstNo('1',
                                ValueEntryShipment."Entry No.");
                    end;

                    if LastKeyString = CurrentKeyString then
                        UpdateFlag := true
                    else begin
                        UpdateFlag := false;
                        TempValueEntryShipment.Init();
                        EntriesCount := EntriesCount + 1;
                        LastKeyString := CurrentKeyString;
                        CurrentSalesAmount := 0;
                        CurrentCostAmount := 0;
                    end;

                    if PassedAmountType = AmountType::Price then
                        CurrentSalesAmount +=
                          CalcAmountFromSalesPrice(ErrorBuffer, ErrorsCount, ValueEntryShipment, PassedSalesType, SalesCode, UpdateFlag);
                    if (PassedAmountType = AmountType::Cost) or ShowCostShipment then begin
                        CurrentCostAmount := CurrentCostAmount + Round(ValueEntryShipment."Cost Amount (Actual)");
                        TempValueEntryShipment."Valued Quantity" := -CurrentCostAmount;
                    end else
                        TempValueEntryShipment."Valued Quantity" := -CurrentSalesAmount;

                    if (PassedAmountType = AmountType::Cost) and (PassedShipmentDetailing = ShipmentDetailing::Operation) then begin
                        GLItemRelation.SetRange("Value Entry No.", ValueEntryShipment."Entry No.");
                        if GLItemRelation.FindSet() then
                            repeat
                                if GLEntry.Get(GLItemRelation."G/L Entry No.") then
                                    if (GLEntry.Amount > 0) xor ((GLEntry."Debit Amount" < 0) or (GLEntry."Credit Amount" < 0)) then
                                        TempValueEntryShipment."Job No." := GLEntry."G/L Account No."
                                    else
                                        TempValueEntryShipment."Job Task No." := GLEntry."G/L Account No.";
                            until GLItemRelation.Next() = 0;
                    end;

                    TempValueEntryShipment."Posting Date" := ValueEntryShipment."Posting Date";
                    TempValueEntryShipment."Sales Amount (Actual)" := CurrentSalesAmount;
                    TempValueEntryShipment."Cost Amount (Actual)" := CurrentCostAmount;
                    TempValueEntryShipment."Entry No." := EntriesCount;
                    TempValueEntryShipment."Item Ledger Entry Quantity" :=
                      TempValueEntryShipment."Item Ledger Entry Quantity" + ValueEntryShipment."Item Ledger Entry Quantity";
                    case PassedShipmentDetailing of
                        ShipmentDetailing::Document:
                            begin
                                SourceName := '';
                                AdjustmentText := '';
                                case ValueEntryShipment."Source Type" of
                                    ValueEntryShipment."Source Type"::Vendor:
                                        begin
                                            Vendor.Get(ValueEntryShipment."Source No.");
                                            SourceName := Vendor."Search Name";
                                        end;
                                    ValueEntryShipment."Source Type"::Customer:
                                        begin
                                            Customer.Get(ValueEntryShipment."Source No.");
                                            SourceName := Customer."Search Name";
                                        end;
                                end;

                                if (PassedAmountType = AmountType::Cost) and (TempValueEntryShipment."Item Ledger Entry Quantity" = 0) then
                                    AdjustmentText := AdjmtTxt;

                                TempValueEntryShipment.Description := StrSubstNo('%1 %2 %3 %4',
                                    Format(ValueEntryShipment."Item Ledger Entry Type"),
                                    AdjustmentText,
                                    ValueEntryShipment."Source No.",
                                    SourceName);
                                TempValueEntryShipment."Document No." := ValueEntryShipment."Document No.";
                            end;
                        ShipmentDetailing::Item:
                            begin
                                Item.Get(ValueEntryShipment."Item No.");
                                TempValueEntryShipment.Description := Item.Description;
                            end;
                        ShipmentDetailing::Operation:
                            begin
                                Item.Get(ValueEntryShipment."Item No.");
                                TempValueEntryShipment."Document No." := ValueEntryShipment."Document No.";
                                TempValueEntryShipment.Description := StrSubstNo('%1 %2',
                                    Format(ValueEntryShipment."Item Ledger Entry Type"),
                                    Item.Description);
                            end;
                        ShipmentDetailing::Sum:
                            TempValueEntryShipment.Description := '';
                    end;
                    if UpdateFlag then
                        TempValueEntryShipment.Modify()
                    else
                        TempValueEntryShipment.Insert();
                end;
            until ValueEntryShipment.Next() = 0;
        ValueEntryShipment.Reset();
    end;

    local procedure CalcAmountFromSalesPrice(var ErrorBuffer: Record "Value Entry"; var ErrorsCount: Integer; ValueEntry: Record "Value Entry"; SalesPriceType: Enum "Sales Price Type"; SalesCode: Code[20]; UpdateFlag: Boolean) Result: Decimal
    var
        PriceListLine: Record "Price List Line";
    begin
        FilterSalesPrice(PriceListLine, ValueEntry, SalesPriceType, SalesCode);
        if PriceListLine.FindFirst() and (PriceListLine.Count = 1) then
            Result := Round(PriceListLine."Unit Price" * ValueEntry."Item Ledger Entry Quantity");
        if not UpdateFlag then begin
            ErrorsCount := ErrorsCount + 1;
            ErrorBuffer.Init();
            ErrorBuffer."Item No." := ValueEntry."Item No.";
            ErrorBuffer."Posting Date" := ValueEntry."Posting Date";
            if PriceListLine.Count = 0 then
                ErrorBuffer.Description := NoPriceFoundErr
            else
                ErrorBuffer.Description := SeveralPricesFoundErr;
            ErrorBuffer."Entry No." := ErrorsCount;
            ErrorBuffer.Insert();
        end;
    end;


    local procedure CalcRcptResidOnStart(var ErrorBuffer: Record "Value Entry"; var ErrorsCount: Integer; StartDate: Date; LocationCode: Code[10]; PassedAmountType: Option; PassedSalesType: Enum "Sales Price Type"; SalesCode: Code[20]) ResidOnstart: Decimal
    var
        Item: Record Item;
        ValueEntryReceipts: Record "Value Entry";
        CurItemCode: Code[30];
        LastItemCode: Code[30];
    begin
        LastItemCode := '';
        ValueEntryReceipts.SetCurrentKey("Item No.", "Posting Date");
        ValueEntryReceipts.SetFilter("Posting Date", '<%1', StartDate);
        ValueEntryReceipts.SetFilter("Location Code", LocationCode);
        if ValueEntryReceipts.FindSet() then
            repeat
                if ValueEntryReceipts.IsDebit() then
                    if PassedAmountType = AmountType::Cost then
                        ResidOnstart := ResidOnstart + Round(ValueEntryReceipts."Cost Amount (Actual)")
                    else begin
                        CurItemCode := ValueEntryReceipts."Item No.";
                        if CurItemCode <> LastItemCode then begin
                            Item.Get(CurItemCode);
                            LastItemCode := CurItemCode;
                        end;
                        ResidOnstart +=
                          CalcAmountFromSalesPrice(ErrorBuffer, ErrorsCount, ValueEntryReceipts, PassedSalesType, SalesCode, false);
                    end;
            until ValueEntryReceipts.Next() = 0;
    end;

    local procedure FilterSalesPrice(var PriceListLine: Record "Price List Line"; ValueEntry: Record "Value Entry"; SalesPriceType: Enum "Sales Price Type"; SourceNo: Code[20])
    var
        Item: Record Item;
    begin

        PriceListLine.Reset();
        PriceListLine.SetRange("Asset Type", "Price Asset Type"::Item);
        PriceListLine.SetRange("Asset No.", ValueEntry."Item No.");
        PriceListLine.SetRange("Currency Code", '');
        PriceListLine.SetRange("Minimum Quantity", 0);
        Item.Get(ValueEntry."Item No.");
        PriceListLine.SetRange("Unit of Measure Code", Item."Base Unit of Measure");
        PriceListLine.SetRange("Source No.", SourceNo);
        PriceListLine.SetRange("Source Type", GetSourceType(SalesPriceType));
        PriceListLine.SetFilter("Starting Date", '<=%1', ValueEntry."Posting Date");
        PriceListLine.SetFilter("Ending Date", '>=%1|''''', ValueEntry."Posting Date");
        PriceListLine.SetRange(Status, "Price Status"::Active);
    end;

    local procedure GetSourceType(SalesPriceType: Enum "Sales Price Type"): Enum "Price Source Type";
    begin
        case SalesPriceType of
            SalesPriceType::"All Customers":
                exit("Price Source Type"::"All Customers");
            SalesPriceType::Campaign:
                exit("Price Source Type"::Campaign);
            SalesPriceType::"Customer Price Group":
                exit("Price Source Type"::"Customer Price Group");
        end;
    end;

    [Scope('OnPrem')]
    procedure InitReportTemplate()
    var
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.Get();
        ExcelReportBuilderManager.InitTemplate(InventorySetup."TORG-29 Template Code");
    end;

    [Scope('OnPrem')]
    procedure SetMainSheet()
    begin
        ExcelReportBuilderManager.SetSheet('Sheet1');
    end;

    [Scope('OnPrem')]
    procedure SetErrorsSheet()
    begin
        ExcelReportBuilderManager.SetSheet('Sheet2');
    end;

    [Scope('OnPrem')]
    procedure FillHeader(DepartmentName: Text; OperationType: Text; ReportNo: Text; ReportDate: Text; StartDate: Date; EndDate: Text; RespName: Text; RespNo: Text; ResidOnstart: Text)
    var
        CompanyInfo: Record "Company Information";
    begin
        CompanyInfo.Get();
        ExcelReportBuilderManager.AddSection('REPORTHEADER');
        ExcelReportBuilderManager.AddDataToSection(
          'CompanyName', StdRepMgt.GetCompanyName());
        ExcelReportBuilderManager.AddDataToSection(
          'DepartmentName', DepartmentName);
        ExcelReportBuilderManager.AddDataToSection(
          'OKPO', CompanyInfo."OKPO Code");

        ExcelReportBuilderManager.AddDataToSection('OperationType', OperationType);
        ExcelReportBuilderManager.AddDataToSection('DocumentNumber', ReportNo);
        ExcelReportBuilderManager.AddDataToSection('DocumentDate', ReportDate);
        ExcelReportBuilderManager.AddDataToSection('PeriodDateBegin', Format(StartDate));
        ExcelReportBuilderManager.AddDataToSection('PeriodDateEnd', EndDate);
        ExcelReportBuilderManager.AddDataToSection('MatResPerson', RespName);
        ExcelReportBuilderManager.AddDataToSection('TabNumber', RespNo);
        ExcelReportBuilderManager.AddDataToSection(
          'BalanceDateBegin', Format(Date2DMY(StartDate, 1)) + ' ' + LocMgt.Month2Text(StartDate));
        ExcelReportBuilderManager.AddDataToSection('BalanceDateBeginYear', Format(Date2DMY(StartDate, 3)));
        ExcelReportBuilderManager.AddDataToSection('GoodsBalanceBegin', ResidOnstart);
    end;

    [Scope('OnPrem')]
    procedure FillPageHeader(LineEntryType: Option)
    begin
        case LineEntryType of
            EntryType::Receipt:
                ExcelReportBuilderManager.AddSection('RECEIPTPAGEHEADER');
            EntryType::Shipment:
                ExcelReportBuilderManager.AddSection('ISSUEPAGEHEADER');
        end;
    end;

    [Scope('OnPrem')]
    procedure FillErrorReportHeader()
    begin
        ExcelReportBuilderManager.AddSection('ERRORHEADER');
    end;

    [Scope('OnPrem')]
    procedure FillLine(Name: Text; DocDate: Text; DocNo: Text; Qty: Text; JobNo: Text; JobTaskNo: Text; LineEntryType: Option)
    begin
        if not ExcelReportBuilderManager.TryAddSectionWithPlaceForFooter('BODY', GetFooterSectionName(LineEntryType)) then begin
            ExcelReportBuilderManager.AddPagebreak();
            FillPageHeader(LineEntryType);
            ExcelReportBuilderManager.AddSection('BODY');
        end;

        ExcelReportBuilderManager.AddDataToSection('LineName', Name);
        ExcelReportBuilderManager.AddDataToSection('LineDocDate', DocDate);
        ExcelReportBuilderManager.AddDataToSection('LineDocNum', DocNo);
        ExcelReportBuilderManager.AddDataToSection('LineAmount', Qty);
        ExcelReportBuilderManager.AddDataToSection('JobNo', JobNo);
        ExcelReportBuilderManager.AddDataToSection('JobTaskNo', JobTaskNo);
    end;

    [Scope('OnPrem')]
    procedure FillErrorLine(Date: Text; ItemNo: Text; Description: Text)
    begin
        ExcelReportBuilderManager.AddSection('ERRORBODY');
        ExcelReportBuilderManager.AddDataToSection('ErrorDate', Date);
        ExcelReportBuilderManager.AddDataToSection('ErrorItemNo', ItemNo);
        ExcelReportBuilderManager.AddDataToSection('ErrorDescription', Description);
    end;

    [Scope('OnPrem')]
    procedure FillRcptPageFooter(ReceiptsTotal: Text; ReceiptsWithCostsTotal: Text; ReceiptsWithResidTotal: Text)
    begin
        ExcelReportBuilderManager.AddSection(GetFooterSectionName(EntryType::Receipt));
        ExcelReportBuilderManager.AddDataToSection('ReceiptGoodsSum', ReceiptsTotal);
        ExcelReportBuilderManager.AddDataToSection('ReceiptPlusCostsGoodsSum', ReceiptsWithCostsTotal);
        ExcelReportBuilderManager.AddDataToSection('ReceiptPlusBalanceGoodsSum', ReceiptsWithResidTotal);
    end;

    [Scope('OnPrem')]
    procedure FillShptPageFooter(EndDate: Date; ShipmentTotal: Text; Total: Text; Attaches: Text; AcceptorJobTitle: Text; AcceptorName: Text; ResponsibleJobTitle: Text; ResponsibleName: Text)
    begin
        ExcelReportBuilderManager.AddSection(GetFooterSectionName(EntryType::Shipment));
        ExcelReportBuilderManager.AddDataToSection(
          'BalanceDateEnd', Format(Date2DMY(EndDate, 1)) + ' ' + LocMgt.Month2Text(EndDate));
        ExcelReportBuilderManager.AddDataToSection('BalanceDateEndYear', Format(Date2DMY(EndDate, 3)));
        ExcelReportBuilderManager.AddDataToSection('IssueGoodsSum', ShipmentTotal);
        ExcelReportBuilderManager.AddDataToSection('GoodsBalanceEnd', Total);
        ExcelReportBuilderManager.AddDataToSection('AttachesNo', Attaches);
        ExcelReportBuilderManager.AddDataToSection('AccountantTitle', AcceptorJobTitle);
        ExcelReportBuilderManager.AddDataToSection('AccountantName', AcceptorName);
        ExcelReportBuilderManager.AddDataToSection('MatResPersonTitle', ResponsibleJobTitle);
        ExcelReportBuilderManager.AddDataToSection('MatResPersonName', ResponsibleName);
    end;

    [Scope('OnPrem')]
    procedure FillIssueHeader(ShipmentTotal: Text)
    begin
        ExcelReportBuilderManager.AddSection('ISSUEHEADER');
        ExcelReportBuilderManager.AddDataToSection('ShipmentTotal', ShipmentTotal);
    end;

    [Scope('OnPrem')]
    procedure ExportData()
    begin
        ExcelReportBuilderManager.ExportData();
    end;

    [Scope('OnPrem')]
    procedure ExportDataFile(FileName: Text)
    begin
        ExcelReportBuilderManager.ExportDataToClientFile(FileName);
    end;

    [Scope('OnPrem')]
    procedure CheckSignature(var DocSign: Record "Document Signature"; ActNo: Code[20]; EmpType: Integer)
    var
        DocSignMgt: Codeunit "Doc. Signature Management";
    begin
        DocSignMgt.GetDocSign(
          DocSign, DATABASE::"Invent. Act Header",
          0, ActNo, EmpType, true);
    end;

    [Scope('OnPrem')]
    procedure NewPage()
    begin
        ExcelReportBuilderManager.AddPagebreak();
    end;

    [Scope('OnPrem')]
    procedure GetRcptType(): Integer
    begin
        exit(EntryType::Receipt);
    end;

    [Scope('OnPrem')]
    procedure GetShptType(): Integer
    begin
        exit(EntryType::Shipment);
    end;

    local procedure GetFooterSectionName(LineEntryType: Option): Text
    begin
        case LineEntryType of
            EntryType::Receipt:
                exit('RECEIPTFOOTER');
            EntryType::Shipment:
                exit('REPORTFOOTER');
        end;
    end;
}
