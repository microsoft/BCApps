#pragma warning disable AA0247
codeunit 14935 "TORG-13 Report Helper"
{

    trigger OnRun()
    begin
    end;

    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        ExcelReportBuilderManager: Codeunit "Excel Report Builder Manager";
        StdRepMgt: Codeunit "Local Report Management";
        LocMgt: Codeunit "Localisation Management";
        PrevDocPageNo: Integer;
        CurrentDocumentNo: Text;
#pragma warning disable AA0470
        PageNoTxt: Label 'Waybill %1 Page %2';
#pragma warning restore AA0470
        LastTotalAmount: array[4] of Decimal;
        TotalAmount: array[4] of Decimal;

    [Scope('OnPrem')]
    procedure InitReportTemplate()
    var
        InventorySetup: Record "Inventory Setup";
    begin
        GeneralLedgerSetup.Get();
        InventorySetup.Get();
        InventorySetup.TestField("TORG-13 Template Code");
        ExcelReportBuilderManager.InitTemplate(InventorySetup."TORG-13 Template Code");
        ExcelReportBuilderManager.SetSheet('Sheet1');
    end;

    [Scope('OnPrem')]
    procedure IncreaseTotals(AmountValues: array[4] of Decimal)
    var
        I: Integer;
    begin
        for I := 1 to 4 do
            TotalAmount[I] += AmountValues[I];
    end;

    [Scope('OnPrem')]
    procedure SaveLastTotals()
    var
        I: Integer;
    begin
        for I := 1 to 4 do
            LastTotalAmount[I] := TotalAmount[I];
    end;

    [Scope('OnPrem')]
    procedure FillHeader(DocumentNo: Text; DocumentDate: Text; ReleasedOrgUnit: Text; ReceivedOrgUnit: Text)
    var
        CompanyInfo: Record "Company Information";
    begin
        ExcelReportBuilderManager.AddSection('REPORTHEADER');
        ExcelReportBuilderManager.AddDataToSection(
          'CompanyName', StdRepMgt.GetCompanyName());
        ExcelReportBuilderManager.AddDataToSection(
          'OKPO', CompanyInfo."OKPO Code");
        ExcelReportBuilderManager.AddDataToSection(
          'OperationCode', CompanyInfo."OKPO Code");

        ExcelReportBuilderManager.AddDataToSection('DocumentNum', DocumentNo);
        ExcelReportBuilderManager.AddDataToSection('DocumentDate', DocumentDate);
        ExcelReportBuilderManager.AddDataToSection('FromInventLocation', ReleasedOrgUnit);
        ExcelReportBuilderManager.AddDataToSection('ToInventLocation', ReceivedOrgUnit);

        CurrentDocumentNo := DocumentNo;
        Clear(TotalAmount);
        Clear(LastTotalAmount);
    end;

    [Scope('OnPrem')]
    procedure FillPageHeader()
    begin
        ExcelReportBuilderManager.AddSection('PAGEHEADER');

        if ExcelReportBuilderManager.GetLastPageNo() - PrevDocPageNo <> 1 then
            ExcelReportBuilderManager.AddDataToSection(
              'PageNoText',
              StrSubstNo(
                PageNoTxt,
                CurrentDocumentNo,
                ExcelReportBuilderManager.GetLastPageNo() - PrevDocPageNo));
    end;

    [Scope('OnPrem')]
    procedure FillLine(BodyDetails: array[6] of Text; AmountValues: array[4] of Decimal)
    begin
        if not ExcelReportBuilderManager.TryAddSectionWithPlaceForFooter('BODY', 'PAGEFOOTER') then begin
            FillPageFooter();
            ExcelReportBuilderManager.AddPagebreak();
            FillPageHeader();
            ExcelReportBuilderManager.AddSection('BODY');
        end;

        IncreaseTotals(AmountValues);

        ExcelReportBuilderManager.AddDataToSection('ItemName', BodyDetails[1]);
        ExcelReportBuilderManager.AddDataToSection('ItemId', BodyDetails[2]);
        ExcelReportBuilderManager.AddDataToSection('BOMUnitId', BodyDetails[3]);
        ExcelReportBuilderManager.AddDataToSection('CodeOkei', BodyDetails[4]);
        ExcelReportBuilderManager.AddDataToSection('QtyMultiples', BodyDetails[5]);
        ExcelReportBuilderManager.AddDataToSection('Qty', Format(AmountValues[2]));
        ExcelReportBuilderManager.AddDataToSection('GrossWeight', Format(AmountValues[3]));
        ExcelReportBuilderManager.AddDataToSection('NetWeight', Format(AmountValues[4]));
        ExcelReportBuilderManager.AddDataToSection('Price', BodyDetails[6]);
        ExcelReportBuilderManager.AddDataToSection('CostAmount', Format(RoundDecValue(AmountValues[1])));
    end;

    [Scope('OnPrem')]
    procedure FillPageFooter()
    begin
        ExcelReportBuilderManager.AddSection('PAGEFOOTER');

        ExcelReportBuilderManager.AddDataToSection(
          'QtyPage', Format(TotalAmount[2] - LastTotalAmount[2]));
        ExcelReportBuilderManager.AddDataToSection(
          'GrossWeightPage', Format(TotalAmount[3] - LastTotalAmount[3]));
        ExcelReportBuilderManager.AddDataToSection(
          'NetWeightPage', Format(TotalAmount[4] - LastTotalAmount[4]));
        ExcelReportBuilderManager.AddDataToSection(
          'CostAmountPage', Format(RoundDecValue(TotalAmount[1] - LastTotalAmount[1])));

        SaveLastTotals();
    end;

    [Scope('OnPrem')]
    procedure FillFooter(FooterDetails: array[4] of Text)
    begin
        if not ExcelReportBuilderManager.TryAddSection('REPORTFOOTER') then begin
            FillPageFooter();
            ExcelReportBuilderManager.AddPagebreak();
            FillPageHeader();
            ExcelReportBuilderManager.AddSection('REPORTFOOTER');
        end;

        ExcelReportBuilderManager.AddDataToSection('QtyTotal', Format(TotalAmount[2]));
        ExcelReportBuilderManager.AddDataToSection('GrossWeightTotal', Format(TotalAmount[3]));
        ExcelReportBuilderManager.AddDataToSection('NetWeightTotal', Format(TotalAmount[4]));
        ExcelReportBuilderManager.AddDataToSection('CostAmountTotal', Format(RoundDecValue(TotalAmount[1])));

        ExcelReportBuilderManager.AddDataToSection('SupplierTitle', FooterDetails[1]);
        ExcelReportBuilderManager.AddDataToSection('SupplierName', FooterDetails[2]);

        ExcelReportBuilderManager.AddDataToSection(
          'AmountRTxt', LocMgt.Integer2Text(TotalAmount[1] div 1, 1, '', '', ''));
        ExcelReportBuilderManager.AddDataToSection(
          'AmountCTxt', Format((RoundDecValue(TotalAmount[1]) mod 1) * 100));

        ExcelReportBuilderManager.AddDataToSection('TakerTitle', FooterDetails[3]);
        ExcelReportBuilderManager.AddDataToSection('TakerName', FooterDetails[4]);

        PrevDocPageNo := ExcelReportBuilderManager.GetLastPageNo();
        ExcelReportBuilderManager.AddPagebreak();
    end;

    [Scope('OnPrem')]
    procedure ExportData()
    begin
        ExcelReportBuilderManager.ExportData();
    end;

    [Scope('OnPrem')]
    procedure ExportDataToClientFile(FileName: Text)
    begin
        ExcelReportBuilderManager.ExportDataToClientFile(FileName);
    end;

    local procedure RoundDecValue(DecValue: Decimal): Decimal
    begin
        exit(Round(DecValue, GeneralLedgerSetup."Amount Rounding Precision"));
    end;
}

