#pragma warning disable AA0247
codeunit 14931 "Factura-Invoice Report Helper"
{

    trigger OnRun()
    begin
    end;

    var
        ExcelReportBuilderMgr: Codeunit "Excel Report Builder Manager";
        StdRepMgt: Codeunit "Local Report Management";
        SameTxt: Label 'Same';
        PrevDocumentPageNo: Integer;
        CurrentDocumentNo: Text;
        CurrentDocumentDate: Text;
#pragma warning disable AA0470
        InvoiceTxt: Label 'Invoice %1 from %2 Page %3';
#pragma warning restore AA0470
        LineNo: Integer;

    [Scope('OnPrem')]
    procedure InitReportTemplate(TemplateCode: Code[10])
    var
        SheetName: Text;
    begin
        SheetName := 'Sheet1';
        ExcelReportBuilderMgr.InitTemplate(TemplateCode);
        ExcelReportBuilderMgr.SetSheet(SheetName);
        PrevDocumentPageNo := 0;
    end;

    [Scope('OnPrem')]
    procedure ExportData()
    begin
        ExcelReportBuilderMgr.ExportData();
    end;

    [Scope('OnPrem')]
    procedure FillHeader(DocNo: Code[20]; DocDate: Text; RevNo: Code[20]; RevDate: Text; HeaderDetails: array[12] of Text)
    begin
        ExcelReportBuilderMgr.AddSection('REPORTHEADER');

        ExcelReportBuilderMgr.AddDataToSection('FactureNum', DocNo);
        ExcelReportBuilderMgr.AddDataToSection('FactureDate', DocDate);
        ExcelReportBuilderMgr.AddDataToSection('RevisionNum', RevNo);
        ExcelReportBuilderMgr.AddDataToSection('RevisionDate', RevDate);

        ExcelReportBuilderMgr.AddDataToSection('SellerName', HeaderDetails[1]);
        ExcelReportBuilderMgr.AddDataToSection('SellerAddress', HeaderDetails[2]);
        ExcelReportBuilderMgr.AddDataToSection('SellerINN', HeaderDetails[3]);
        ExcelReportBuilderMgr.AddDataToSection('ConsignorAndAddress', HeaderDetails[4]);
        ExcelReportBuilderMgr.AddDataToSection('ConsigneeAndAddress', HeaderDetails[5]);
        ExcelReportBuilderMgr.AddDataToSection('DocumentNumDate', HeaderDetails[6]);
        ExcelReportBuilderMgr.AddDataToSection('BuyerName', HeaderDetails[7]);
        ExcelReportBuilderMgr.AddDataToSection('BuyerAddress', HeaderDetails[8]);
        ExcelReportBuilderMgr.AddDataToSection('BuyerINN', HeaderDetails[9]);
        ExcelReportBuilderMgr.AddDataToSection('CurrencyCode', HeaderDetails[10]);
        ExcelReportBuilderMgr.AddDataToSection('CurrencyName', HeaderDetails[11]);
        ExcelReportBuilderMgr.AddDataToSection('VATAgentText', HeaderDetails[12]);

        ExcelReportBuilderMgr.AddSection('PAGEHEADER');

        CurrentDocumentNo := DocNo;
        CurrentDocumentDate := DocDate;
    end;

    [Scope('OnPrem')]
    procedure FillPageHeader()
    begin
        ExcelReportBuilderMgr.AddSection('PAGEHEADER');

        ExcelReportBuilderMgr.AddDataToSection(
          'PageNoTxt',
          StrSubstNo(
            InvoiceTxt, CurrentDocumentNo, CurrentDocumentDate,
            ExcelReportBuilderMgr.GetLastPageNo() - PrevDocumentPageNo));
    end;

    [Scope('OnPrem')]
    procedure FillBody(LineValue: array[13] of Text; IsProforma: Boolean)
    begin
        if not ExcelReportBuilderMgr.TryAddSection('BODY') then begin
            ExcelReportBuilderMgr.AddPagebreak();
            FillPageHeader();
            ExcelReportBuilderMgr.AddSection('BODY');
        end;

        LineNo += 1;
        if not IsProforma then
            ExcelReportBuilderMgr.AddDataToSection('LineNo', Format(LineNo));
        ExcelReportBuilderMgr.AddDataToSection('ItemName', LineValue[1]);
        ExcelReportBuilderMgr.AddDataToSection('Unit', LineValue[2]);
        ExcelReportBuilderMgr.AddDataToSection('UnitName', LineValue[3]);
        ExcelReportBuilderMgr.AddDataToSection('Quantity', LineValue[4]);
        ExcelReportBuilderMgr.AddDataToSection('Price', LineValue[5]);
        ExcelReportBuilderMgr.AddDataToSection('Amount', LineValue[6]);
        ExcelReportBuilderMgr.AddDataToSection('TaxRate', LineValue[7]);
        ExcelReportBuilderMgr.AddDataToSection('TaxAmount', LineValue[8]);
        ExcelReportBuilderMgr.AddDataToSection('AmountInclTax', LineValue[9]);
        ExcelReportBuilderMgr.AddDataToSection('CountryCode', LineValue[10]);
        ExcelReportBuilderMgr.AddDataToSection('Country', LineValue[11]);
        ExcelReportBuilderMgr.AddDataToSection('GTD', LineValue[12]);

        if (not IsProforma) and (LineValue[13] <> '') then
            ExcelReportBuilderMgr.AddDataToSection('TariffNo', LineValue[13]);
    end;

    [Scope('OnPrem')]
    procedure FillReportFooter(AmountArrayTxt: array[3] of Text; ResponsiblePerson: array[2] of Text; IsProforma: Boolean)
    var
        CompanyInformation: Record "Company Information";
    begin
        if not ExcelReportBuilderMgr.TryAddSectionWithPlaceForFooter('REPORTFOOTER', 'FOOTER') then begin
            ExcelReportBuilderMgr.AddPagebreak();
            FillPageHeader();
            ExcelReportBuilderMgr.AddSection('REPORTFOOTER');
        end;

        ExcelReportBuilderMgr.AddDataToSection('AmountTotal', AmountArrayTxt[1]);
        ExcelReportBuilderMgr.AddDataToSection('TaxAmountTotal', AmountArrayTxt[2]);
        ExcelReportBuilderMgr.AddDataToSection('AmountInclTaxTotal', AmountArrayTxt[3]);

        if IsProforma then begin
            CompanyInformation.Get();
            ExcelReportBuilderMgr.AddDataToSection('BankName', CompanyInformation."Bank Name");
            ExcelReportBuilderMgr.AddDataToSection('BankCity', CompanyInformation."Bank City");
            ExcelReportBuilderMgr.AddDataToSection('CompanyINN', CompanyInformation."VAT Registration No.");
            ExcelReportBuilderMgr.AddDataToSection('CompanyKPP', CompanyInformation."KPP Code");
            ExcelReportBuilderMgr.AddDataToSection('CompanyName', StdRepMgt.GetCompanyName());
            ExcelReportBuilderMgr.AddDataToSection('BankBranchNo', CompanyInformation."Bank Branch No.");
            ExcelReportBuilderMgr.AddDataToSection('BankBIC', CompanyInformation."Bank BIC");
            ExcelReportBuilderMgr.AddDataToSection('BankCorrespAccNo', CompanyInformation."Bank Corresp. Account No.");
            ExcelReportBuilderMgr.AddDataToSection('BankAccountNo', CompanyInformation."Bank Account No.");
        end;

        ExcelReportBuilderMgr.AddDataToSection('DirectorName', ResponsiblePerson[1]);
        ExcelReportBuilderMgr.AddDataToSection('AccountantName', ResponsiblePerson[2]);

        ExcelReportBuilderMgr.AddSection('FOOTER');

        PrevDocumentPageNo := ExcelReportBuilderMgr.GetLastPageNo();
    end;

    [Scope('OnPrem')]
    procedure FinalizeReport(AmountArrayTxt: array[3] of Text; ResponsiblePerson: array[2] of Text; IsProforma: Boolean)
    begin
        FillReportFooter(AmountArrayTxt, ResponsiblePerson, IsProforma);
        ExcelReportBuilderMgr.AddPagebreak();
    end;

    [Scope('OnPrem')]
    procedure GetCurrencyInfo(CurrencyCode: Code[10]; var CurrencyDigitalCode: Code[3]; var CurrencyDescription: Text)
    var
        GLSetup: Record "General Ledger Setup";
        Currency: Record Currency;
    begin
        CurrencyDigitalCode := '';
        CurrencyDescription := '';
        if CurrencyCode = '' then begin
            GLSetup.Get();
            CurrencyCode := GLSetup."LCY Code";
        end;

        if Currency.Get(CurrencyCode) then begin
            CurrencyDigitalCode := Currency."RU Bank Digital Code";
            CurrencyDescription := LowerCase(CopyStr(Currency.Description, 1, 1)) + CopyStr(Currency.Description, 2);
        end;
    end;

    [Scope('OnPrem')]
    procedure GetConsignorInfo(VendorNo: Code[20]; var ConsignorName: Text; var ConsignorAddress: Text)
    var
        Vendor: Record Vendor;
    begin
        if VendorNo = '' then begin
            ConsignorName := SameTxt;
            ConsignorAddress := '';
        end else begin
            Vendor.Get(VendorNo);
            ConsignorName := StdRepMgt.GetVendorName(VendorNo);
            ConsignorAddress := Vendor."Post Code" + ', ' + Vendor.City + ', ' + Vendor.Address + ' ' + Vendor."Address 2";
        end;
    end;

    [Scope('OnPrem')]
    procedure GetCurrencyAmtCode(CurrencyCode: Code[20]; AmountInvoiceCurrent: Option "Invoice Currency",LCY) CurrencyWrittenAmount: Code[20]
    begin
        CurrencyWrittenAmount := '';
        if AmountInvoiceCurrent = AmountInvoiceCurrent::"Invoice Currency" then
            CurrencyWrittenAmount := CurrencyCode;
    end;

    [Scope('OnPrem')]
    procedure InitAddressInfo(var ConsignorName: Text; var ConsignorAddress: Text; var Receiver: array[2] of Text)
    begin
        ConsignorName := '-';
        ConsignorAddress := '';
        Receiver[1] := '-';
        Receiver[2] := '';
    end;

    [Scope('OnPrem')]
    procedure FormatTotalAmounts(var TotalAmountTxt: array[3] of Text; TotalAmount: array[3] of Decimal; Sign: Integer; Prepayment: Boolean; VATExemptTotal: Boolean)
    begin
        if Prepayment then
            TotalAmountTxt[1] := '-'
        else
            TotalAmountTxt[1] := StdRepMgt.FormatReportValue(Sign * TotalAmount[1], 2);

        if VATExemptTotal then
            TotalAmountTxt[2] := '-'
        else
            TotalAmountTxt[2] := StdRepMgt.FormatReportValue(Sign * TotalAmount[2], 2);

        TotalAmountTxt[3] := StdRepMgt.FormatReportValue(Sign * TotalAmount[3], 2);
    end;

    [Scope('OnPrem')]
    procedure TransferItemTrLineValues(var LineValues: array[12] of Text; var TrackingSpecBuf: Record "Tracking Specification" temporary; CountryCode: Code[10]; CountryName: Text; Sign: Integer)
    var
        I: Integer;
    begin
        for I := 1 to 3 do
            LineValues[I] := '';

        LineValues[4] := Format(Sign * TrackingSpecBuf."Quantity (Base)");

        for I := 5 to 9 do
            LineValues[I] := '-';

        LineValues[10] := StdRepMgt.FormatTextValue(CountryCode);
        LineValues[11] := StdRepMgt.FormatTextValue(CopyStr(CountryName, 1, 1024));
        LineValues[12] := StdRepMgt.FormatTextValue(TrackingSpecBuf."Package No.")
    end;

    [Scope('OnPrem')]
    procedure TransferLineDescrValues(var LineValues: array[12] of Text; LineDescription: Text)
    var
        I: Integer;
    begin
        LineValues[1] := LineDescription;

        for I := 2 to 12 do
            LineValues[I] := '';
    end;

    [Scope('OnPrem')]
    procedure ExportDataFile(FileName: Text)
    begin
        ExcelReportBuilderMgr.ExportDataToClientFile(FileName);
    end;
}

