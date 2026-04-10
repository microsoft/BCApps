#pragma warning disable AA0247
codeunit 14939 "Torg-16 Document Helper"
{

    trigger OnRun()
    begin
    end;

    var
        ExcelReportBuilderMgr: Codeunit "Excel Report Builder Manager";
        StdRepMgt: Codeunit "Local Report Management";
        LocMgt: Codeunit "Localisation Management";
        TotalAmount: Decimal;

    [Scope('OnPrem')]
    procedure InitReportTemplate()
    var
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.Get();
        InventorySetup.TestField("TORG-16 Template Code");
        ExcelReportBuilderMgr.InitTemplate(InventorySetup."TORG-16 Template Code");
        ExcelReportBuilderMgr.SetSheet('Sheet1');
    end;

    [Scope('OnPrem')]
    procedure FillHeader(DocNo: Code[20]; DocDate: Date; LocationCode: Code[10]; OrderNo: Text; OrderDate: Date; OperationType: Text)
    var
        CompanyInfo: Record "Company Information";
        Location: Record Location;
        LocationName: Text;
    begin
        ExcelReportBuilderMgr.AddSection('REPORTHEADER');

        CompanyInfo.Get();
        ExcelReportBuilderMgr.AddDataToSection('CompanyName', StdRepMgt.GetCompanyName());

        if Location.Get(LocationCode) then
            LocationName := Location.Name + Location."Name 2"
        else
            LocationName := '';
        ExcelReportBuilderMgr.AddDataToSection('Department', LocationName);
        ExcelReportBuilderMgr.AddDataToSection('OKPO', CompanyInfo."OKPO Code");
        ExcelReportBuilderMgr.AddDataToSection('OrderNum', OrderNo);
        ExcelReportBuilderMgr.AddDataToSection('OrderDate', Format(OrderDate, 0, 1));
        ExcelReportBuilderMgr.AddDataToSection('OperationType', OperationType);
        ExcelReportBuilderMgr.AddDataToSection('DocumentNum', DocNo);
        ExcelReportBuilderMgr.AddDataToSection('DocumentDate', Format(DocDate, 0, 1));

        Clear(TotalAmount);
    end;

    [Scope('OnPrem')]
    procedure FillHeaderSignatures(Member: array[5, 2] of Text)
    begin
        ExcelReportBuilderMgr.AddDataToSection('BossTitle', Member[5, 1]);
        ExcelReportBuilderMgr.AddDataToSection('BossName', Member[5, 2]);
    end;

    [Scope('OnPrem')]
    procedure FillPageHeader()
    begin
        ExcelReportBuilderMgr.AddSection('PAGEHEADER');
    end;

    [Scope('OnPrem')]
    procedure FillPageHeader2()
    begin
        ExcelReportBuilderMgr.AddSection('PAGEHEADER2');
    end;

    [Scope('OnPrem')]
    procedure FillPageFooter()
    begin
        ExcelReportBuilderMgr.AddSection('PAGEFOOTER');
    end;

    [Scope('OnPrem')]
    procedure FillFooter(WriteOffSource: Text; Member: array[5, 2] of Text)
    begin
        if not ExcelReportBuilderMgr.TryAddSection('REPORTFOOTER2') then begin
            ExcelReportBuilderMgr.AddPagebreak();
            ExcelReportBuilderMgr.AddSection('REPORTFOOTER2');
        end;
        ExcelReportBuilderMgr.AddDataToSection('TotalAmount', StdRepMgt.FormatReportValue(TotalAmount, 3));
        ExcelReportBuilderMgr.AddDataToSection('AmountRTxt1', LocMgt.Integer2Text(TotalAmount div 1, 1, '', '', ''));
        ExcelReportBuilderMgr.AddDataToSection('AmountCTxt', Format((TotalAmount - TotalAmount div 1) * 100));
        ExcelReportBuilderMgr.AddDataToSection('ChairmanTitle', Member[1, 1]);
        ExcelReportBuilderMgr.AddDataToSection('ChairmanName', Member[1, 2]);
        ExcelReportBuilderMgr.AddDataToSection('MemberTitle1', Member[2, 1]);
        ExcelReportBuilderMgr.AddDataToSection('MemberName1', Member[2, 2]);
        ExcelReportBuilderMgr.AddDataToSection('MemberTitle2', Member[3, 1]);
        ExcelReportBuilderMgr.AddDataToSection('MemberName2', Member[3, 2]);
        ExcelReportBuilderMgr.AddDataToSection('InChargeTitle', Member[4, 1]);
        ExcelReportBuilderMgr.AddDataToSection('InChargeName', Member[4, 2]);
        ExcelReportBuilderMgr.AddDataToSection('AccountName', WriteOffSource);

        ExcelReportBuilderMgr.AddPagebreak();
    end;

    [Scope('OnPrem')]
    procedure FillWriteOffReasonBody(AppliesToEntry: Integer; ReasonCodeValue: Code[10]; ItemDocDate: Date)
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        ReasonCode: Record "Reason Code";
        ReceiptDate: Date;
        ReceiptDocNo: Code[20];
        Reason: Code[10];
        ReasonDesc: Text[100];
    begin
        if not ExcelReportBuilderMgr.TryAddSection('BODY') then begin
            ExcelReportBuilderMgr.AddPagebreak();
            ExcelReportBuilderMgr.AddSection('BODY');
        end;

        if ItemLedgEntry.Get(AppliesToEntry) then begin
            ReceiptDate := ItemLedgEntry."Posting Date";
            ReceiptDocNo := ItemLedgEntry."Document No.";
        end else begin
            ReceiptDate := 0D;
            ReceiptDocNo := '';
        end;

        if ReasonCode.Get(ReasonCodeValue) then begin
            Reason := ReasonCode.Code;
            ReasonDesc := ReasonCode.Description;
        end else begin
            Reason := '';
            ReasonDesc := '';
        end;

        ExcelReportBuilderMgr.AddDataToSection('DeliveryDate', Format(ReceiptDate, 0, 1));
        ExcelReportBuilderMgr.AddDataToSection('WriteOffDate', Format(ItemDocDate, 0, 1));
        ExcelReportBuilderMgr.AddDataToSection('InvoiceId', ReceiptDocNo);
        ExcelReportBuilderMgr.AddDataToSection('InvoiceDate', Format(ReceiptDate, 0, 1));
        ExcelReportBuilderMgr.AddDataToSection('ScrapName', ReasonDesc);
        ExcelReportBuilderMgr.AddDataToSection('ScrapId', Reason);
    end;

    [Scope('OnPrem')]
    procedure FillItemLedgerLine(ItemNo: Code[20]; UnitOfMeasureCode: Code[10]; InvtDocLine: Record "Invt. Document Line")
    var
        ItemDescription: Text;
        UnitOfMeasureCodeDesc: Text;
        OKEICode: Code[3];
    begin
        if not ExcelReportBuilderMgr.TryAddSection('BODY2') then begin
            ExcelReportBuilderMgr.AddPagebreak();
            ExcelReportBuilderMgr.AddSection('BODY2');
        end;

        ItemDescription := GetItemDescription(ItemNo);
        GetUOMOKEICode(UnitOfMeasureCode, UnitOfMeasureCodeDesc, OKEICode);

        InvtDocLine.Amount := Round(InvtDocLine.Quantity * InvtDocLine."Unit Cost");
        TotalAmount += InvtDocLine.Amount;
        ExcelReportBuilderMgr.AddDataToSection('ItemName', ItemDescription);
        ExcelReportBuilderMgr.AddDataToSection('ItemId', InvtDocLine."Item No.");
        ExcelReportBuilderMgr.AddDataToSection('BOMUnitId', UnitOfMeasureCodeDesc);
        ExcelReportBuilderMgr.AddDataToSection('CodeOkei', OKEICode);
        ExcelReportBuilderMgr.AddDataToSection('QtyMultiples', Format(InvtDocLine.Quantity));
        ExcelReportBuilderMgr.AddDataToSection('Weight', Format(InvtDocLine."Net Weight"));
        ExcelReportBuilderMgr.AddDataToSection('GrossWeight', StdRepMgt.FormatReportValue(InvtDocLine."Net Weight" * InvtDocLine.Quantity, 3));
        ExcelReportBuilderMgr.AddDataToSection('PriceUnit', Format(InvtDocLine."Unit Amount"));
        ExcelReportBuilderMgr.AddDataToSection('LineAmount', StdRepMgt.FormatReportValue(InvtDocLine.Amount, 2));
        ExcelReportBuilderMgr.AddDataToSection('Remark', Format(InvtDocLine.Description));
    end;

    [Scope('OnPrem')]
    procedure FillInvtShptLine(ItemNo: Code[20]; UnitOfMeasureCode: Code[10]; InvtShptLine: Record "Invt. Shipment Line")
    var
        Amount: Decimal;
        ItemDescription: Text;
        UnitOfMeasureCodeDesc: Text;
        OKEICode: Code[3];
    begin
        if not ExcelReportBuilderMgr.TryAddSection('BODY2') then begin
            ExcelReportBuilderMgr.AddPagebreak();
            ExcelReportBuilderMgr.AddSection('BODY2');
        end;

        ItemDescription := GetItemDescription(ItemNo);
        GetUOMOKEICode(UnitOfMeasureCode, UnitOfMeasureCodeDesc, OKEICode);
        Amount := InvtShptLine.Amount;
        TotalAmount += InvtShptLine.Amount;
        ExcelReportBuilderMgr.AddDataToSection('ItemName', ItemDescription);
        ExcelReportBuilderMgr.AddDataToSection('ItemId', InvtShptLine."Item No.");
        ExcelReportBuilderMgr.AddDataToSection('BOMUnitId', UnitOfMeasureCodeDesc);
        ExcelReportBuilderMgr.AddDataToSection('CodeOkei', OKEICode);
        ExcelReportBuilderMgr.AddDataToSection('QtyMultiples', Format(InvtShptLine.Quantity));
        ExcelReportBuilderMgr.AddDataToSection('Weight', Format(InvtShptLine."Net Weight"));
        ExcelReportBuilderMgr.AddDataToSection('GrossWeight', StdRepMgt.FormatReportValue(InvtShptLine."Net Weight" * InvtShptLine.Quantity, 3));
        ExcelReportBuilderMgr.AddDataToSection('PriceUnit', Format(InvtShptLine."Unit Amount"));
        ExcelReportBuilderMgr.AddDataToSection('LineAmount', StdRepMgt.FormatReportValue(InvtShptLine.Amount, 3));
        ExcelReportBuilderMgr.AddDataToSection('Remark', Format(InvtShptLine.Description));
    end;

    [Scope('OnPrem')]
    procedure InitSecondSheet()
    var
        SheetName: Text;
    begin
        SheetName := 'Sheet2';
        ExcelReportBuilderMgr.SetSheet(SheetName);
    end;

    [Scope('OnPrem')]
    procedure ExportDataFile(FileName: Text)
    begin
        ExcelReportBuilderMgr.ExportDataToClientFile(FileName);
    end;

    [Scope('OnPrem')]
    procedure GetItemDescription(ItemNo: Code[20]): Text
    var
        Item: Record Item;
    begin
        if Item.Get(ItemNo) then
            exit(Item.Description);
        exit('');
    end;

    [Scope('OnPrem')]
    procedure GetUOMOKEICode(UnitOfMeasureCode: Code[10]; var UnitOfMeasureCodeDesc: Text; var OKEICode: Code[3])
    var
        UnitOfMeasure: Record "Unit of Measure";
    begin
        if UnitOfMeasure.Get(UnitOfMeasureCode) then begin
            UnitOfMeasureCodeDesc := UnitOfMeasure.Description;
            OKEICode := UnitOfMeasure."OKEI Code";
        end else begin
            UnitOfMeasureCodeDesc := '';
            OKEICode := '';
        end;
    end;

    [Scope('OnPrem')]
    procedure ExportData()
    begin
        ExcelReportBuilderMgr.ExportData();
    end;
}

