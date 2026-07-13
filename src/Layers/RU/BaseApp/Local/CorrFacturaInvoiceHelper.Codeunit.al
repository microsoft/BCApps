#pragma warning disable AA0247
codeunit 14932 "Corr. Factura-Invoice Helper"
{

    trigger OnRun()
    begin
    end;

    var
        ExcelReportBuilderMgr: Codeunit "Excel Report Builder Manager";
        PrevDocumentPageNo: Integer;
        CurrentDocumentNos: array[4] of Text;
        CurrentDocumentDates: array[4] of Text;
#pragma warning disable AA0470
        CorrInvTxt: Label 'CORRECTIVE FACTURA-INVOICE %1 from %2 (1)';
#pragma warning restore AA0470
#pragma warning disable AA0470
        ModInvTxt: Label 'CORRECTION OF CORRECTIVE FACTURA-INVOICE %1 from %2 (1a)';
#pragma warning restore AA0470
#pragma warning disable AA0470
        OrigInvTxt: Label 'TO FACTURA-INVOICE %1 from %2';
#pragma warning restore AA0470
#pragma warning disable AA0470
        RevInvTxt: Label 'with correction %1 from %2 (1b)';
#pragma warning restore AA0470
#pragma warning disable AA0470
        PageNoTxt: Label 'Page %1';
#pragma warning restore AA0470
        LineNo: Integer;

    [Scope('OnPrem')]
    procedure InitReportTemplate()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        SheetName: Text;
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.TestField("Corr. Factura Template Code");
        SheetName := 'Sheet1';
        ExcelReportBuilderMgr.InitTemplate(SalesReceivablesSetup."Corr. Factura Template Code");
        ExcelReportBuilderMgr.SetSheet(SheetName);
    end;

    [Scope('OnPrem')]
    procedure ExportData()
    begin
        ExcelReportBuilderMgr.ExportData();
    end;

    [Scope('OnPrem')]
    procedure FillHeader(ReportNos: array[4] of Text; ReportDates: array[4] of Text; HeaderDetails: array[8] of Text)
    begin
        ExcelReportBuilderMgr.AddSection('REPORTHEADER');

        ExcelReportBuilderMgr.AddDataToSection('FactureNum', ReportNos[1]);
        ExcelReportBuilderMgr.AddDataToSection('FactureDate', ReportDates[1]);
        ExcelReportBuilderMgr.AddDataToSection('ModificationNum', ReportNos[2]);
        ExcelReportBuilderMgr.AddDataToSection('ModificationDate', ReportDates[2]);
        ExcelReportBuilderMgr.AddDataToSection('OrigFactureNum', ReportNos[3]);
        ExcelReportBuilderMgr.AddDataToSection('OrigFactureDate', ReportDates[3]);
        ExcelReportBuilderMgr.AddDataToSection('OrigModificationNum', ReportNos[4]);
        ExcelReportBuilderMgr.AddDataToSection('OrigModificationDate', ReportDates[4]);

        ExcelReportBuilderMgr.AddDataToSection('CompanyName', HeaderDetails[1]);
        ExcelReportBuilderMgr.AddDataToSection('CompanyAddress', HeaderDetails[2]);
        ExcelReportBuilderMgr.AddDataToSection('CompanyINN', HeaderDetails[3]);
        ExcelReportBuilderMgr.AddDataToSection('BuyerName', HeaderDetails[4]);
        ExcelReportBuilderMgr.AddDataToSection('BuyerAddress', HeaderDetails[5]);
        ExcelReportBuilderMgr.AddDataToSection('BuyerINN', HeaderDetails[6]);
        ExcelReportBuilderMgr.AddDataToSection('CurrencyName', HeaderDetails[7]);
        ExcelReportBuilderMgr.AddDataToSection('CurrencyCode', HeaderDetails[8]);

        ExcelReportBuilderMgr.AddSection('PAGEHEADER');

        CopyArray(CurrentDocumentNos, ReportNos, 1);
        CopyArray(CurrentDocumentDates, ReportDates, 1);
    end;

    [Scope('OnPrem')]
    procedure FillPageHeader()
    begin
        ExcelReportBuilderMgr.AddSection('PAGEHEADER');

        ExcelReportBuilderMgr.AddDataToSection(
          'PageNoTxt',
          GetHeaderText(CurrentDocumentNos, CurrentDocumentDates) + ' ' +
          StrSubstNo(PageNoTxt, ExcelReportBuilderMgr.GetLastPageNo() - PrevDocumentPageNo));
    end;

    [Scope('OnPrem')]
    procedure FillBody(LineBeforeValue: array[10] of Text; LineAfterValue: array[9] of Text; LineIncrValue: array[3] of Text; LineDecrValue: array[3] of Text)
    begin
        if not ExcelReportBuilderMgr.TryAddSection('BODY') then begin
            ExcelReportBuilderMgr.AddPagebreak();
            FillPageHeader();
            ExcelReportBuilderMgr.AddSection('BODY');
        end;

        LineNo += 1;
        ExcelReportBuilderMgr.AddDataToSection('LineNo', Format(LineNo));
        ExcelReportBuilderMgr.AddDataToSection('Description', LineBeforeValue[1]);
        ExcelReportBuilderMgr.AddDataToSection('UnitIdBefore', LineBeforeValue[2]);
        ExcelReportBuilderMgr.AddDataToSection('UnitCodeBefore', LineBeforeValue[3]);
        ExcelReportBuilderMgr.AddDataToSection('QtyBefore', LineBeforeValue[4]);
        ExcelReportBuilderMgr.AddDataToSection('PriceBefore', LineBeforeValue[5]);
        ExcelReportBuilderMgr.AddDataToSection('LineAmountBefore', LineBeforeValue[6]);
        ExcelReportBuilderMgr.AddDataToSection('VATValueBefore', LineBeforeValue[7]);
        ExcelReportBuilderMgr.AddDataToSection('TaxAmountBefore', LineBeforeValue[8]);
        ExcelReportBuilderMgr.AddDataToSection('AmountInclTaxBefore', LineBeforeValue[9]);
        ExcelReportBuilderMgr.AddDataToSection('TariffNoBefore', LineBeforeValue[10]);

        ExcelReportBuilderMgr.AddDataToSection('UnitIdAfter', LineAfterValue[1]);
        ExcelReportBuilderMgr.AddDataToSection('UnitCodeAfter', LineAfterValue[2]);
        ExcelReportBuilderMgr.AddDataToSection('QtyAfter', LineAfterValue[3]);
        ExcelReportBuilderMgr.AddDataToSection('PriceAfter', LineAfterValue[4]);
        ExcelReportBuilderMgr.AddDataToSection('LineAmountAfter', LineAfterValue[5]);
        ExcelReportBuilderMgr.AddDataToSection('VATValueAfter', LineAfterValue[6]);
        ExcelReportBuilderMgr.AddDataToSection('TaxAmountAfter', LineAfterValue[7]);
        ExcelReportBuilderMgr.AddDataToSection('AmountInclTaxAfter', LineAfterValue[8]);
        ExcelReportBuilderMgr.AddDataToSection('TariffNoAfter', LineAfterValue[9]);

        ExcelReportBuilderMgr.AddDataToSection('LineAmountIncrease', LineIncrValue[1]);
        ExcelReportBuilderMgr.AddDataToSection('TaxAmountIncrease', LineIncrValue[2]);
        ExcelReportBuilderMgr.AddDataToSection('AmountInclTaxIncrease', LineIncrValue[3]);

        ExcelReportBuilderMgr.AddDataToSection('LineAmountDecrease', LineDecrValue[1]);
        ExcelReportBuilderMgr.AddDataToSection('TaxAmountDecrease', LineDecrValue[2]);
        ExcelReportBuilderMgr.AddDataToSection('AmountInclTaxDecrease', LineDecrValue[3]);
    end;

    [Scope('OnPrem')]
    procedure FillReportFooter(AmtIncrArrayTxt: array[3] of Text; AmtDecrArrayTxt: array[3] of Text; ResponsiblePerson: array[2] of Text)
    begin
        if not ExcelReportBuilderMgr.TryAddSectionWithPlaceForFooter('REPORTFOOTER', 'PAGEFOOTER') then begin
            ExcelReportBuilderMgr.AddPagebreak();
            FillPageHeader();
            ExcelReportBuilderMgr.AddSection('REPORTFOOTER');
        end;

        ExcelReportBuilderMgr.AddDataToSection('LineAmountTotalIncrease', AmtIncrArrayTxt[1]);
        ExcelReportBuilderMgr.AddDataToSection('TaxAmountTotalIncrease', AmtIncrArrayTxt[2]);
        ExcelReportBuilderMgr.AddDataToSection('AmountInclTaxTotalIncrease', AmtIncrArrayTxt[3]);

        ExcelReportBuilderMgr.AddDataToSection('LineAmountTotalDecrease', AmtDecrArrayTxt[1]);
        ExcelReportBuilderMgr.AddDataToSection('TaxAmountTotalDecrease', AmtDecrArrayTxt[2]);
        ExcelReportBuilderMgr.AddDataToSection('AmountInclTaxTotalDecrease', AmtDecrArrayTxt[3]);

        ExcelReportBuilderMgr.AddDataToSection('DirectorName', ResponsiblePerson[1]);
        ExcelReportBuilderMgr.AddDataToSection('AccountantName', ResponsiblePerson[2]);

        ExcelReportBuilderMgr.AddSection('PAGEFOOTER');

        PrevDocumentPageNo := ExcelReportBuilderMgr.GetLastPageNo();
    end;

    [Scope('OnPrem')]
    procedure FinalizeReport(AmtIncrArrayTxt: array[3] of Text; AmtDecrArrayTxt: array[3] of Text; ResponsiblePerson: array[2] of Text)
    begin
        FillReportFooter(AmtIncrArrayTxt, AmtDecrArrayTxt, ResponsiblePerson);
        ExcelReportBuilderMgr.AddPagebreak();
    end;

    local procedure GetHeaderText(DocNos: array[4] of Text; DocDates: array[8] of Text) HdrText: Text[1024]
    var
        CorrectionText: array[4] of Text[200];
        i: Integer;
    begin
        InitHeaderTextLines(CorrectionText);
        for i := 1 to ArrayLen(DocNos) do begin
            HdrText +=
              AddHeaderText(CorrectionText[i], DocNos[i], DocDates[i]);
            if i <> ArrayLen(DocNos) then
                HdrText += ', ';
        end;
    end;

    local procedure AddHeaderText(CorrectionText: Text[200]; DocNo: Text; DocDate: Text): Text[250]
    begin
        if DocNo = '' then
            exit(StrSubstNo(CorrectionText, '-', '-'));
        exit(StrSubstNo(CorrectionText, DocNo, DocDate));
    end;

    local procedure InitHeaderTextLines(var HdrTextLine: array[4] of Text[200])
    begin
        HdrTextLine[1] := CorrInvTxt;
        HdrTextLine[2] := ModInvTxt;
        HdrTextLine[3] := OrigInvTxt;
        HdrTextLine[4] := RevInvTxt;
    end;

    [Scope('OnPrem')]
    procedure ExportDataFile(FileName: Text)
    begin
        ExcelReportBuilderMgr.ExportDataToClientFile(FileName);
    end;
}

