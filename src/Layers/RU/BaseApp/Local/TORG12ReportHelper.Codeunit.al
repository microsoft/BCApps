#pragma warning disable AA0247
codeunit 14934 "TORG-12 Report Helper"
{

    trigger OnRun()
    begin
    end;

    var
        ExcelReportBuilderManager: Codeunit "Excel Report Builder Manager";
        StdRepMgt: Codeunit "Local Report Management";
        LocMgt: Codeunit "Localisation Management";
        LastTotalAmount: array[6] of Decimal;
        TotalAmount: array[6] of Decimal;
        PrevDocPageNo: Integer;
#pragma warning disable AA0470
        PageNoTxt: Label 'Waybill %1 Page %2';
#pragma warning restore AA0470
        DocumentNo: Text;
        PageHeaderCurrencyText: Text;

    [Scope('OnPrem')]
    procedure InitReportTemplate()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.TestField("TORG-12 Template Code");
        ExcelReportBuilderManager.InitTemplate(SalesReceivablesSetup."TORG-12 Template Code");
        ExcelReportBuilderManager.SetSheet('Sheet1');
    end;

    [Scope('OnPrem')]
    procedure IncreaseTotals(AmountValues: array[6] of Decimal)
    var
        I: Integer;
    begin
        for I := 1 to 6 do
            TotalAmount[I] += AmountValues[I];
    end;

    [Scope('OnPrem')]
    procedure SaveLastTotals()
    var
        I: Integer;
    begin
        for I := 1 to 6 do
            LastTotalAmount[I] := TotalAmount[I];
    end;

    [Scope('OnPrem')]
    procedure FillHeader(HeaderDetails: array[15] of Text)
    begin
        Clear(TotalAmount);
        Clear(LastTotalAmount);
        DocumentNo := HeaderDetails[1];

        ExcelReportBuilderManager.AddSection('REPORTHEADER');

        ExcelReportBuilderManager.AddDataToSection('InvoiceId', HeaderDetails[1]);
        ExcelReportBuilderManager.AddDataToSection('InvoiceDate', HeaderDetails[2]);
        ExcelReportBuilderManager.AddDataToSection('ConsignorBankAddress', HeaderDetails[3]);
        ExcelReportBuilderManager.AddDataToSection('ConsigneeBankAddress', HeaderDetails[4]);
        ExcelReportBuilderManager.AddDataToSection('VendBankAddress', HeaderDetails[5]);
        ExcelReportBuilderManager.AddDataToSection('CustBankAddress', HeaderDetails[6]);
        ExcelReportBuilderManager.AddDataToSection('OrderDescription', HeaderDetails[7]);
        ExcelReportBuilderManager.AddDataToSection('ConsignorOKPO', HeaderDetails[8]);
        ExcelReportBuilderManager.AddDataToSection('ConsigneeOKPO', HeaderDetails[9]);
        ExcelReportBuilderManager.AddDataToSection('VendOKPO', HeaderDetails[10]);
        ExcelReportBuilderManager.AddDataToSection('CustOKPO', HeaderDetails[11]);
        ExcelReportBuilderManager.AddDataToSection('OrderNumber', HeaderDetails[12]);
        ExcelReportBuilderManager.AddDataToSection('BillOfLading', HeaderDetails[13]);
        ExcelReportBuilderManager.AddDataToSection('BillOfLadingDate', HeaderDetails[14]);
        ExcelReportBuilderManager.AddDataToSection('OrderDate', HeaderDetails[15]);
    end;

    [Scope('OnPrem')]
    procedure FillPageHeader(CurrencyText: Text)
    begin
        ExcelReportBuilderManager.AddSection('PAGEHEADER');

        PageHeaderCurrencyText := CurrencyText;
        ExcelReportBuilderManager.AddDataToSection('CurExtPrice', PageHeaderCurrencyText);
        ExcelReportBuilderManager.AddDataToSection('CurExtAmount', PageHeaderCurrencyText);
        ExcelReportBuilderManager.AddDataToSection('CurExtVAT', PageHeaderCurrencyText);
        ExcelReportBuilderManager.AddDataToSection('CurExtAmountWithVAT', PageHeaderCurrencyText);

        if ExcelReportBuilderManager.GetLastPageNo() - PrevDocPageNo <> 1 then
            ExcelReportBuilderManager.AddDataToSection(
              'PageNoText',
              StrSubstNo(
                PageNoTxt,
                DocumentNo,
                ExcelReportBuilderManager.GetLastPageNo() - PrevDocPageNo));
    end;

    [Scope('OnPrem')]
    procedure FillLine(BodyDetails: array[14] of Text; AmountValues: array[6] of Decimal)
    begin
        if not ExcelReportBuilderManager.TryAddSectionWithPlaceForFooter('BODY', 'PAGEFOOTER') then begin
            FillPageFooter();
            ExcelReportBuilderManager.AddPagebreak();
            FillPageHeader(PageHeaderCurrencyText);
            ExcelReportBuilderManager.AddSection('BODY');
        end;

        IncreaseTotals(AmountValues);

        ExcelReportBuilderManager.AddDataToSection('lineNo', BodyDetails[1]);
        ExcelReportBuilderManager.AddDataToSection('Name', BodyDetails[2]);
        ExcelReportBuilderManager.AddDataToSection('ItemId', BodyDetails[3]);
        ExcelReportBuilderManager.AddDataToSection('UnitId', BodyDetails[4]);
        ExcelReportBuilderManager.AddDataToSection('OKEI', BodyDetails[5]);
        ExcelReportBuilderManager.AddDataToSection('Packing', '-');
        ExcelReportBuilderManager.AddDataToSection('TaxPackagingQty', '-');
        ExcelReportBuilderManager.AddDataToSection('QtyNumber', '-');
        ExcelReportBuilderManager.AddDataToSection('GrossWeight', BodyDetails[6]);
        ExcelReportBuilderManager.AddDataToSection('Qty', BodyDetails[7]);
        ExcelReportBuilderManager.AddDataToSection('Price', BodyDetails[8]);
        ExcelReportBuilderManager.AddDataToSection('Amount', BodyDetails[9]);
        ExcelReportBuilderManager.AddDataToSection('VATValue', BodyDetails[10]);
        ExcelReportBuilderManager.AddDataToSection('VATAmount', BodyDetails[11]);
        ExcelReportBuilderManager.AddDataToSection('AmountWithVAT', BodyDetails[12]);
    end;

    [Scope('OnPrem')]
    procedure FillPageFooter()
    begin
        ExcelReportBuilderManager.AddSection('PAGEFOOTER');

        ExcelReportBuilderManager.AddDataToSection('QtyPage', Format(TotalAmount[4] - LastTotalAmount[4]));
        ExcelReportBuilderManager.AddDataToSection(
          'AmountPage', StdRepMgt.FormatReportValue(TotalAmount[1] - LastTotalAmount[1], 2));
        ExcelReportBuilderManager.AddDataToSection(
          'VATAmountPage', StdRepMgt.FormatReportValue(TotalAmount[2] - LastTotalAmount[2], 2));
        ExcelReportBuilderManager.AddDataToSection(
          'AmountWithVATPage', StdRepMgt.FormatReportValue(TotalAmount[3] - LastTotalAmount[3], 2));

        SaveLastTotals();
    end;

    [Scope('OnPrem')]
    procedure FillFooter(FooterDetails: array[6] of Text; VATExemptTotal: Boolean; PrintWeightInfo: Boolean)
    begin
        if not ExcelReportBuilderManager.TryAddSection('REPORTFOOTER') then begin
            FillPageFooter();
            ExcelReportBuilderManager.AddPagebreak();
            FillPageHeader(PageHeaderCurrencyText);
            ExcelReportBuilderManager.AddSection('REPORTFOOTER');
        end;

        ExcelReportBuilderManager.AddDataToSection('QtyTotal', Format(TotalAmount[4]));
        ExcelReportBuilderManager.AddDataToSection(
          'AmountTotal', StdRepMgt.FormatReportValue(TotalAmount[1], 2));
        if VATExemptTotal then
            ExcelReportBuilderManager.AddDataToSection('VATAmountTotal', '-')
        else
            ExcelReportBuilderManager.AddDataToSection('VATAmountTotal', StdRepMgt.FormatReportValue(TotalAmount[2], 2));

        ExcelReportBuilderManager.AddDataToSection('AmountWithVATTotal', StdRepMgt.FormatReportValue(TotalAmount[3], 2));

        ExcelReportBuilderManager.AddDataToSection(
          'PageTotal', LocMgt.Integer2Text(ExcelReportBuilderManager.GetLastPageNo() - PrevDocPageNo, 1, '', '', ''));
        ExcelReportBuilderManager.AddDataToSection('ItemQty', FooterDetails[1]);

        ExcelReportBuilderManager.AddDataToSection('NetWeightStr', TotalNetWeight(PrintWeightInfo));
        ExcelReportBuilderManager.AddDataToSection('GrossWeightStr', TotalGrossWeight(PrintWeightInfo));

        ExcelReportBuilderManager.AddDataToSection(
          'TotalAmountWithVATStr', LocMgt.Amount2Text(FooterDetails[2], TotalAmount[3]));

        ExcelReportBuilderManager.AddDataToSection('DeliveryAllowedName', FooterDetails[3]);
        ExcelReportBuilderManager.AddDataToSection('AccountantName', FooterDetails[4]);
        ExcelReportBuilderManager.AddDataToSection('SupplierName', FooterDetails[5]);
        ExcelReportBuilderManager.AddDataToSection('DocumentDate', FooterDetails[6]);
    end;

    [Scope('OnPrem')]
    procedure FinishDocument(FooterDetails: array[6] of Text; VATExemptTotal: Boolean; PrintWeightInfo: Boolean)
    begin
        FillFooter(FooterDetails, VATExemptTotal, PrintWeightInfo);
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

    [Scope('OnPrem')]
    procedure TotalGrossWeight(PrintWeightInfo: Boolean): Text[1024]
    begin
        if PrintWeightInfo then
            exit(LocMgt.Integer2Text(Round(TotalAmount[5], 1), 1, '', '', ''));

        exit('');
    end;

    [Scope('OnPrem')]
    procedure TotalNetWeight(PrintWeightInfo: Boolean): Text[1024]
    begin
        if PrintWeightInfo then
            exit(LocMgt.Integer2Text(Round(TotalAmount[6], 1), 1, '', '', ''));

        exit('');
    end;
}

