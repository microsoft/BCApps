#pragma warning disable AA0247
report 14966 "Sales Corr. Factura-Invoice"
{
    Caption = 'Sales Corr. Factura-Invoice';
    ProcessingOnly = true;

    dataset
    {
        dataitem(Header; "Sales Header")
        {
            DataItemTableView = sorting("Document Type", "No.");
            RequestFilterFields = "No.";
            dataitem(CopyCycle; "Integer")
            {
                DataItemTableView = sorting(Number);
                dataitem(LineCycle; "Integer")
                {
                    DataItemTableView = sorting(Number) where(Number = filter(1 ..));
                    dataitem(AttachedLineCycle; "Integer")
                    {
                        DataItemTableView = sorting(Number);

                        trigger OnAfterGetRecord()
                        begin
                            if Number = 1 then
                                AttachedSalesLine.FindSet()
                            else
                                AttachedSalesLine.Next();
                        end;

                        trigger OnPreDataItem()
                        begin
                            AttachedSalesLine.SetRange("Attached to Line No.", SalesLine1."Line No.");
                            SetRange(Number, 1, AttachedSalesLine.Count);
                        end;
                    }

                    trigger OnAfterGetRecord()
                    var
                        TotalsToDecrease: array[3] of Decimal;
                        TotalsToIncrease: array[3] of Decimal;
                        LineBeforeValue: array[10] of Text;
                        LineAfterValue: array[9] of Text;
                        LineIncrValue: array[3] of Text;
                        LineDecrValue: array[3] of Text;
                    begin
                        GetTotalsDifference(TotalsToDecrease, TotalAmountBefore, TotalAmountAfter);
                        GetTotalsDifference(TotalsToIncrease, TotalAmountAfter, TotalAmountBefore);

                        if Number = 1 then begin
                            if not SalesLine1.Find('-') then
                                CurrReport.Break();
                        end else
                            if SalesLine1.Next(1) = 0 then begin
                                FormatTotalAmounts(TotalAmountTextToDecrease, TotalsToDecrease);
                                FormatTotalAmounts(TotalAmountTextToAdd, TotalsToIncrease);
                                CurrReport.Break();
                            end;

                        FormatTotalAmounts(LastTotalAmountToDecrease, TotalsToDecrease);
                        FormatTotalAmounts(LastTotalAmountToAdd, TotalsToIncrease);

                        if SalesLine1.Type <> SalesLine1.Type::" " then begin
                            if SalesLine1."Qty. to Invoice" = 0 then
                                CurrReport.Skip();
                            if AmountInvoiceCurrent = AmountInvoiceCurrent::LCY then begin
                                SalesLine1."Amount Including VAT (Before)" := SalesLine1."Amt. Incl. VAT (LCY) (Before)";
                                SalesLine1."Amount Including VAT (After)" := SalesLine1."Amt. Incl. VAT (LCY) (After)";
                                SalesLine1."Amount (Before)" := SalesLine1."Amount (LCY) (Before)";
                                SalesLine1."Amount (After)" := SalesLine1."Amount (LCY) (After)";
                            end;
                            SalesLine1."Unit Price" := Round(SalesLine1.Amount / SalesLine1."Qty. to Invoice", Currency."Unit-Amount Rounding Precision");
                            IncrAmount(
                              TotalAmountBefore, SalesLine1."Amount (Before)", SalesLine1."Amount Including VAT (Before)");
                            IncrAmount(
                              TotalAmountAfter, SalesLine1."Amount (After)", SalesLine1."Amount Including VAT (After)");

                            TransferReportValues(SalesLine1);
                            TransferLineValues(
                              LineBeforeValue, LineAfterValue, LineIncrValue, LineDecrValue, SalesLine1.Description);
                            FillBody(LineBeforeValue, LineAfterValue, LineIncrValue, LineDecrValue);
                        end else
                            SalesLine1."No." := '';
                    end;

                    trigger OnPostDataItem()
                    var
                        ResponsiblePerson: array[2] of Text;
                    begin
                        FillRespPerson(ResponsiblePerson);
                        ChangeEmptyValuesToDash(TotalAmountTextToAdd);
                        ChangeEmptyValuesToDash(TotalAmountTextToDecrease);
                        CorrFacturaHelper.FinalizeReport(TotalAmountTextToAdd, TotalAmountTextToDecrease, ResponsiblePerson);
                    end;

                    trigger OnPreDataItem()
                    begin
                        if (AmountInvoiceCurrent = AmountInvoiceCurrent::"Invoice Currency") and (Header."Currency Code" <> '') then
                            Currency.Get(Header."Currency Code")
                        else
                            Currency.InitRoundingPrecision();

                        VATExemptTotal := true;

                        FillHeader(Header);
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    Clear(TotalAmountBefore);
                    Clear(TotalAmountAfter);
                end;

                trigger OnPostDataItem()
                begin
                    if not PreviewReport then
                        CODEUNIT.Run(CODEUNIT::"Sales-Printed", Header);
                end;

                trigger OnPreDataItem()
                var
                    NoSeries: Codeunit "No. Series";
                begin
                    if not SalesLine1.Find('-') then
                        CurrReport.Break();

                    if Header."Posting No." = '' then begin
                        if PreviewReport then
                            Header."Posting No." := NoSeries.PeekNextNo(Header."Posting No. Series", Header."Posting Date")
                        else
                            Header."Posting No." := NoSeries.GetNextNo(Header."Posting No. Series", Header."Posting Date");
                        if not PreviewReport then
                            Header.Modify();
                    end;
                    ReportNos[1] := Header."Posting No.";

                    SetRange(Number, 1, CopiesNumber);
                end;
            }

            trigger OnAfterGetRecord()
            begin
                TestField(Status);
                Customer.Get("Bill-to Customer No.");

                AmountInvoiceCurrent := AmountInvoiceDone;
                if "Currency Code" = '' then
                    AmountInvoiceCurrent := AmountInvoiceCurrent::LCY;

                SalesLine1.Reset();
                SalesLine1.SetRange("Document Type", "Document Type");
                SalesLine1.SetRange("Document No.", "No.");
                SalesLine1.SetFilter("Attached to Line No.", '<>%1', 0);
                if SalesLine1.FindSet() then
                    repeat
                        AttachedSalesLine := SalesLine1;
                        AttachedSalesLine.Insert();
                    until SalesLine1.Next() = 0;

                SalesLine1.SetRange("Attached to Line No.");

                GetDocHeader(Header, ReportNos, ReportDates);

                if AmountInvoiceCurrent = AmountInvoiceCurrent::LCY then
                    CurrencyWrittenAmount := ''
                else
                    CurrencyWrittenAmount := "Currency Code";
                GetCurrencyInfo(CurrencyWrittenAmount);

                if "KPP Code" <> '' then
                    KPPCode := "KPP Code"
                else
                    KPPCode := Customer."KPP Code";

                if not PreviewReport then begin
                    if ArchiveDocument then
                        ArchiveManagement.StoreSalesDocument(Header, LogInteraction);
                    if LogInteraction then begin
                        CalcFields("No. of Archived Versions");
                        if "Bill-to Contact No." <> '' then
                            SegManagement.LogDocument(
                              3, "No.", "Doc. No. Occurrence",
                              "No. of Archived Versions", DATABASE::Contact, "Bill-to Contact No."
                              , "Salesperson Code", "Campaign No.", "Posting Description", "Opportunity No.")
                        else
                            SegManagement.LogDocument(
                              3, "No.", "Doc. No. Occurrence",
                              "No. of Archived Versions", DATABASE::Customer, "Bill-to Customer No.",
                              "Salesperson Code", "Campaign No.", "Posting Description", "Opportunity No.");
                    end;
                end;
            end;

            trigger OnPreDataItem()
            begin
                SalesSetup.Get();
                CompanyInfo.Get();
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(CopiesNumber; CopiesNumber)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'No. of Copies';
                        ToolTip = 'Specifies how many copies of the document to print.';

                        trigger OnValidate()
                        begin
                            if CopiesNumber < 1 then
                                CopiesNumber := 1;
                        end;
                    }
                    field(AmountInvoiceDone; AmountInvoiceDone)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Print Currency';
                        OptionCaption = 'Invoice Currency,LCY';
                        ToolTip = 'Specifies if the currency code is shown in the report.';
                    }
                    field(LogInteraction; LogInteraction)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Log Interaction';
                        ToolTip = 'Specifies that interactions with the related contact are logged.';
                    }
                    field(Preview; PreviewReport)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Preview';
                        ToolTip = 'Specifies that the report can be previewed.';
                    }
                    field(ArchiveDocument; ArchiveDocument)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Archive Document';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            if CopiesNumber < 1 then
                CopiesNumber := 1;
        end;
    }

    labels
    {
    }

    trigger OnPostReport()
    begin
        if FileName <> '' then
            CorrFacturaHelper.ExportDataFile(FileName)
        else
            CorrFacturaHelper.ExportData();
    end;

    trigger OnPreReport()
    begin
        if not CurrReport.UseRequestPage then
            CopiesNumber := 1;

        CorrFacturaHelper.InitReportTemplate();
    end;

    var
        CompanyInfo: Record "Company Information";
        Customer: Record Customer;
        SalesLine1: Record "Sales Line";
        AttachedSalesLine: Record "Sales Line" temporary;
        SalesSetup: Record "Sales & Receivables Setup";
        Currency: Record Currency;
        StdRepMgt: Codeunit "Local Report Management";
        ArchiveManagement: Codeunit ArchiveManagement;
        SegManagement: Codeunit SegManagement;
        CorrFacturaHelper: Codeunit "Corr. Factura-Invoice Helper";
        TotalAmountBefore: array[3] of Decimal;
        TotalAmountAfter: array[3] of Decimal;
        LastTotalAmountToAdd: array[3] of Text[50];
        LastTotalAmountToDecrease: array[3] of Text[50];
        FileName: Text;
        CopiesNumber: Integer;
        AmountInvoiceDone: Option "Invoice Currency",LCY;
        AmountInvoiceCurrent: Option "Invoice Currency",LCY;
        CurrencyWrittenAmount: Code[10];
        LogInteraction: Boolean;
        ArchiveDocument: Boolean;
        KPPCode: Code[10];
        ReportValues: array[20] of Text[50];
        VATExemptTotal: Boolean;
        TotalAmountTextToDecrease: array[3] of Text[50];
        TotalAmountTextToAdd: array[3] of Text[50];
        CurrencyDescription: Text[30];
        CurrencyDigitalCode: Code[3];
        ReportNos: array[4] of Text;
        ReportDates: array[4] of Text;
        PreviewReport: Boolean;

    [Scope('OnPrem')]
    procedure IncrAmount(var TotalAmount: array[3] of Decimal; Amount: Decimal; AmountIncludingVAT: Decimal)
    begin
        TotalAmount[1] := TotalAmount[1] + Amount;
        TotalAmount[2] := TotalAmount[2] + AmountIncludingVAT - Amount;
        TotalAmount[3] := TotalAmount[3] + AmountIncludingVAT;
    end;

    [Scope('OnPrem')]
    procedure TransferReportValues(SalesLine: Record "Sales Line")
    var
        UnitOfMeasure: Record "Unit of Measure";
        Item: Record Item;
    begin
        CleanReportValues(ReportValues);

        ReportValues[2] := GetOriginalUnitOfMeasureCode(SalesLine);
        ReportValues[1] := '-';
        if UnitOfMeasure.Get(ReportValues[2]) then
            ReportValues[1] := CopyStr(StdRepMgt.FormatTextValue(UnitOfMeasure."OKEI Code"), 1);

        ReportValues[3] := Format(SalesLine."Quantity (Before)");
        ReportValues[4] := Format(SalesLine."Quantity (After)");

        ReportValues[5] := CopyStr(StdRepMgt.FormatReportValue(SalesLine."Unit Price (Before)", 2), 1);
        ReportValues[6] := CopyStr(StdRepMgt.FormatReportValue(SalesLine."Unit Price (After)", 2), 1);

        FillAmountQuartet(ReportValues, 7, SalesLine."Amount (Before)", SalesLine."Amount (After)");
        FillAmountQuartet(
          ReportValues, 12,
          SalesLine."Amount Including VAT (Before)" - SalesLine."Amount (Before)",
          SalesLine."Amount Including VAT (After)" - SalesLine."Amount (After)");
        FillAmountQuartet(ReportValues, 16, SalesLine."Amount Including VAT (Before)", SalesLine."Amount Including VAT (After)");

        ReportValues[11] := Format(SalesLine."VAT %");

        if not StdRepMgt.VATExemptLine(SalesLine."VAT Bus. Posting Group", SalesLine."VAT Prod. Posting Group") then
            VATExemptTotal := false;

        if SalesLine.Type = SalesLine.Type::Item then
            if Item.Get(SalesLine."No.") then
                ReportValues[20] := Item."Tariff No.";
    end;

    [Scope('OnPrem')]
    procedure FormatTotalAmounts(var TotalAmountTextArray: array[3] of Text[50]; TotalAmountArray: array[3] of Decimal)
    begin
        TotalAmountTextArray[1] := GetTextDecimalValue(TotalAmountArray[1]);

        if VATExemptTotal then
            TotalAmountTextArray[2] := '-'
        else
            TotalAmountTextArray[2] := GetTextDecimalValue(TotalAmountArray[2]);

        TotalAmountTextArray[3] := GetTextDecimalValue(TotalAmountArray[3]);
    end;

    local procedure GetDocHeader(SalesHeader: Record "Sales Header"; var HeaderNos: array[4] of Text; var HeaderDates: array[4] of Text)
    var
        TempSalesHeader: Record "Sales Header" temporary;
        CorrDocumentMgt: Codeunit "Corrective Document Mgt.";
    begin
        TempSalesHeader := SalesHeader;
        CorrDocumentMgt.GetDocHeaderText(TempSalesHeader, HeaderNos, HeaderDates);
    end;

    [Scope('OnPrem')]
    procedure GetCurrencyInfo(CurrencyCode: Code[10])
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
    procedure GetTotalsDifference(var TotalsDifference: array[3] of Decimal; Totals1: array[3] of Decimal; Totals2: array[3] of Decimal)
    var
        I: Integer;
    begin
        for I := 1 to 3 do
            TotalsDifference[I] := Totals1[I] - Totals2[I];
    end;

    [Scope('OnPrem')]
    procedure CleanReportValues(var ReportValues: array[20] of Text[50])
    var
        I: Integer;
    begin
        for I := 1 to ArrayLen(ReportValues) do
            ReportValues[I] := '';
    end;

    [Scope('OnPrem')]
    procedure FillAmountQuartet(var ReportValues: array[20] of Text[50]; StartingIndex: Integer; AmountBefore: Decimal; AmountAfter: Decimal)
    begin
        ReportValues[StartingIndex] := StdRepMgt.FormatReportValue(AmountBefore, 2);
        ReportValues[StartingIndex + 1] := StdRepMgt.FormatReportValue(AmountAfter, 2);

        if AmountAfter <> AmountBefore then
            if AmountAfter > AmountBefore then
                ReportValues[StartingIndex + 3] := StdRepMgt.FormatReportValue(AmountAfter - AmountBefore, 2)
            else
                ReportValues[StartingIndex + 2] := StdRepMgt.FormatReportValue(AmountBefore - AmountAfter, 2);
    end;

    [Scope('OnPrem')]
    procedure GetTextDecimalValue(Input: Decimal): Text[50]
    begin
        if Input > 0 then
            exit(StdRepMgt.FormatReportValue(Input, 2));
        exit('');
    end;

    [Scope('OnPrem')]
    procedure GetOriginalUnitOfMeasureCode(SalesLine: Record "Sales Line"): Code[10]
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
    begin
        case SalesLine."Original Doc. Type" of
            SalesLine."Original Doc. Type"::Invoice:
                if SalesInvoiceLine.Get(SalesLine."Original Doc. No.", SalesLine."Original Doc. Line No.") then
                    exit(SalesInvoiceLine."Unit of Measure Code");
            SalesLine."Original Doc. Type"::"Credit Memo":
                if SalesCrMemoLine.Get(SalesLine."Original Doc. No.", SalesLine."Original Doc. Line No.") then
                    exit(SalesCrMemoLine."Unit of Measure Code");
        end;

        exit('');
    end;

    local procedure FillHeader(SalesHeader: Record "Sales Header")
    var
        HeaderValue: array[8] of Text;
    begin
        TransferHeaderValues(HeaderValue, SalesHeader);
        CorrFacturaHelper.FillHeader(ReportNos, ReportDates, HeaderValue);
    end;

    local procedure FillBody(LineBeforeValue: array[10] of Text; LineAfterValue: array[9] of Text; LineIncrValue: array[4] of Text; LineDecrValue: array[4] of Text)
    begin
        CorrFacturaHelper.FillBody(LineBeforeValue, LineAfterValue, LineIncrValue, LineDecrValue);
    end;

    local procedure FillRespPerson(var ResponsiblePerson: array[2] of Text)
    begin
        ResponsiblePerson[1] := StdRepMgt.GetDirectorName(false, 36, Header."Document Type".AsInteger(), Header."No.");
        ResponsiblePerson[2] := StdRepMgt.GetAccountantName(false, 36, Header."Document Type".AsInteger(), Header."No.");
    end;

    local procedure TransferHeaderValues(var HeaderValue: array[8] of Text; var SalesHeader: Record "Sales Header")
    begin
        HeaderValue[1] := StdRepMgt.GetCompanyName();
        HeaderValue[2] := StdRepMgt.GetLegalAddress();
        HeaderValue[3] := CompanyInfo."VAT Registration No." + ' / ' + CompanyInfo."KPP Code";
        HeaderValue[4] := StdRepMgt.GetCustName(SalesHeader."Bill-to Customer No.");
        HeaderValue[5] := StdRepMgt.GetCustInfo(SalesHeader, 1, 2);
        HeaderValue[6] := Customer."VAT Registration No." + ' / ' + KPPCode;
        HeaderValue[7] := CurrencyDescription;
        HeaderValue[8] := CurrencyDigitalCode;
    end;

    local procedure TransferLineValues(var LineBeforeValue: array[10] of Text; var LineAfterValue: array[9] of Text; var LineIncrValue: array[3] of Text; var LineDecrValue: array[3] of Text; SalesLineDescr: Text)
    begin
        TransferLineBeforeValues(LineBeforeValue, SalesLineDescr);
        TransferLineAfterValues(LineAfterValue);
        TransferLineIncrValues(LineIncrValue);
        TransferLineDecrValues(LineDecrValue);
    end;

    local procedure TransferLineBeforeValues(var LineValue: array[10] of Text; LineDescription: Text)
    begin
        LineValue[1] := LineDescription;
        LineValue[2] := ReportValues[1];
        LineValue[3] := ReportValues[2];
        LineValue[4] := ReportValues[3];
        LineValue[5] := ReportValues[5];
        LineValue[6] := ReportValues[7];
        LineValue[7] := ReportValues[11];
        LineValue[8] := ReportValues[12];
        LineValue[9] := ReportValues[16];
        LineValue[10] := ReportValues[20];
    end;

    local procedure TransferLineAfterValues(var LineValue: array[9] of Text)
    begin
        LineValue[1] := ReportValues[1];
        LineValue[2] := ReportValues[2];
        LineValue[3] := ReportValues[4];
        LineValue[4] := ReportValues[6];
        LineValue[5] := ReportValues[8];
        LineValue[6] := ReportValues[11];
        LineValue[7] := ReportValues[13];
        LineValue[8] := ReportValues[17];
        LineValue[9] := ReportValues[20];
    end;

    local procedure TransferLineIncrValues(var LineValue: array[3] of Text)
    begin
        LineValue[1] := ReportValues[10];
        LineValue[2] := ReportValues[15];
        LineValue[3] := ReportValues[19];
        ChangeEmptyValuesToDash(LineValue);
    end;

    local procedure TransferLineDecrValues(var LineValue: array[3] of Text)
    begin
        LineValue[1] := ReportValues[9];
        LineValue[2] := ReportValues[14];
        LineValue[3] := ReportValues[18];
        ChangeEmptyValuesToDash(LineValue);
    end;

    [Scope('OnPrem')]
    procedure SetFileNameSilent(NewFileName: Text)
    begin
        FileName := NewFileName;
    end;

    local procedure ChangeEmptyValuesToDash(var LineValues: array[3] of Text)
    var
        i: Integer;
    begin
        for i := 1 to 3 do
            if LineValues[i] = '' then
                LineValues[i] := '-';
    end;
}

