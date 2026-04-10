#pragma warning disable AA0247
report 12484 "Posted Cr. M. Factura-Invoice"
{
    Caption = 'Posted Cr. M. Factura-Invoice';
    ProcessingOnly = true;

    dataset
    {
        dataitem(Header; "Sales Cr.Memo Header")
        {
            DataItemTableView = sorting("No.");
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
                        var
                            LineValues: array[13] of Text;
                        begin
                            if Number = 1 then
                                AttachedSalesLine.FindSet()
                            else
                                AttachedSalesLine.Next();

                            CopyArray(LastTotalAmount, TotalAmount, 1);
                            FacturaInvoiceHelper.TransferLineDescrValues(LineValues, AttachedSalesLine.Description);
                            FillBody(LineValues);
                        end;

                        trigger OnPreDataItem()
                        begin
                            AttachedSalesLine.SetRange("Attached to Line No.", SalesCrMemoLine."Line No.");
                            SetRange(Number, 1, AttachedSalesLine.Count);
                        end;
                    }
                    dataitem(ItemTrackingLine; "Integer")
                    {
                        DataItemTableView = sorting(Number) where(Number = filter(1 ..));

                        trigger OnAfterGetRecord()
                        var
                            LineValues: array[13] of Text;
                        begin
                            if Header."Prepayment Credit Memo" then
                                CurrReport.Break();

                            if Number = 1 then
                                TempTrackingSpecBuffer2.FindSet()
                            else
                                TempTrackingSpecBuffer2.Next();

                            if PackageNoInfo.Get(
                                 TempTrackingSpecBuffer2."Item No.", TempTrackingSpecBuffer2."Variant Code", TempTrackingSpecBuffer2."Package No.")
                            then begin
                                CountryName := PackageNoInfo.GetCountryName();
                                CountryCode := PackageNoInfo.GetCountryLocalCode();
                            end;

                            CopyArray(LastTotalAmount, TotalAmount, 1);
                            FacturaInvoiceHelper.TransferItemTrLineValues(LineValues, TempTrackingSpecBuffer2, CountryCode, CountryName, Sign);
                            FillBody(LineValues);
                        end;

                        trigger OnPreDataItem()
                        begin
                            if not MultipleCD then
                                CurrReport.Break();

                            SetRange(Number, 1, TrackingSpecCount);
                        end;
                    }

                    trigger OnAfterGetRecord()
                    var
                        LineValues: array[13] of Text;
                    begin
                        if Number = 1 then begin
                            if not SalesCrMemoLine.Find('-') then
                                CurrReport.Break();
                        end else
                            if SalesCrMemoLine.Next(1) = 0 then begin
                                FacturaInvoiceHelper.FormatTotalAmounts(
                                  TotalAmountText, TotalAmount, Sign, Header."Prepayment Credit Memo", VATExemptTotal);
                                CurrReport.Break();
                            end;

                        CopyArray(LastTotalAmount, TotalAmount, 1);

                        if SalesCrMemoLine.Type <> SalesCrMemoLine.Type::" " then begin
                            if SalesCrMemoLine.Quantity = 0 then
                                CurrReport.Skip();
                            if AmountInvoiceCurrent = AmountInvoiceCurrent::LCY then begin
                                SalesCrMemoLine.Amount := SalesCrMemoLine."Amount (LCY)";
                                SalesCrMemoLine."Amount Including VAT" := SalesCrMemoLine."Amount Including VAT (LCY)";
                            end;
                            SalesCrMemoLine."Unit Price" :=
                              Round(SalesCrMemoLine.Amount / SalesCrMemoLine.Quantity, Currency."Unit-Amount Rounding Precision");
                            IncrAmount(SalesCrMemoLine);
                        end else
                            SalesCrMemoLine."No." := '';

                        OnItemTrackingLineOnBeforeTransferReportValues(
                            SalesCrMemoLine, TempTrackingSpecBuffer, TempTrackingSpecBuffer2,
                            MultipleCD, CDNo, CountryCode, CountryName, TrackingSpecCount);

                        if Header."Prepayment Credit Memo" then
                            LastTotalAmount[1] := 0;

                        if SalesCrMemoLine.Type = SalesCrMemoLine.Type::" " then
                            FacturaInvoiceHelper.TransferLineDescrValues(LineValues, SalesCrMemoLine.Description)
                        else
                            TransferReportValues(LineValues, SalesCrMemoLine, CountryName, CDNo, CountryCode);

                        FillBody(LineValues);
                    end;

                    trigger OnPostDataItem()
                    var
                        ResponsiblePerson: array[2] of Text;
                    begin
                        FillRespPerson(ResponsiblePerson);
                        FacturaInvoiceHelper.FinalizeReport(TotalAmountText, ResponsiblePerson, false);
                    end;

                    trigger OnPreDataItem()
                    begin
                        if (AmountInvoiceCurrent = AmountInvoiceCurrent::"Invoice Currency") and (Header."Currency Code" <> '') then
                            Currency.Get(Header."Currency Code")
                        else
                            Currency.InitRoundingPrecision();

                        VATExemptTotal := true;

                        FillHeader();
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    Clear(TotalAmount);
                end;

                trigger OnPostDataItem()
                begin
                    if not PreviewReport then
                        CODEUNIT.Run(CODEUNIT::"Sales Cr. Memo-Printed", Header);
                end;

                trigger OnPreDataItem()
                begin
                    if not SalesCrMemoLine.Find('-') then
                        CurrReport.Break();

                    SetRange(Number, 1, CopiesNumber);
                end;
            }

            trigger OnAfterGetRecord()
            begin
                Customer.Get("Bill-to Customer No.");

                AmountInvoiceCurrent := AmountInvoiceDone;
                if "Currency Code" = '' then
                    AmountInvoiceCurrent := AmountInvoiceCurrent::LCY;

                Sign := -1;
                SalesCrMemoLine.Reset();
                SalesCrMemoLine.SetRange("Document No.", "No.");
                SalesCrMemoLine.SetFilter("Attached to Line No.", '<>%1', 0);
                if SalesCrMemoLine.FindSet() then
                    repeat
                        AttachedSalesLine := SalesCrMemoLine;
                        AttachedSalesLine.Insert();
                    until SalesCrMemoLine.Next() = 0;

                SalesCrMemoLine.SetRange("Attached to Line No.", 0);

                if "Currency Code" <> '' then
                    if not Currency.Get("Currency Code") then
                        Currency.Description := DollarUSATxt;

                CurrencyWrittenAmount := FacturaInvoiceHelper.GetCurrencyAmtCode("Currency Code", AmountInvoiceCurrent);
                FacturaInvoiceHelper.GetCurrencyInfo(CurrencyWrittenAmount, CurrencyDigitalCode, CurrencyDescription);

                if "Prepayment Credit Memo" or PrintShortAddr("No.") then
                    FacturaInvoiceHelper.InitAddressInfo(ConsignorName, ConsignorAddress, Receiver)
                else begin
                    Receiver[1] := StdRepMgt.GetCustInfo(Header, 0, 1);
                    Receiver[2] := StdRepMgt.GetCustInfo(Header, 1, 1);
                    FacturaInvoiceHelper.GetConsignorInfo("Consignor No.", ConsignorName, ConsignorAddress);
                end;

                if "KPP Code" <> '' then
                    KPPCode := "KPP Code"
                else
                    KPPCode := Customer."KPP Code";

                if "Prepayment Credit Memo" then
                    PrepmtDocsLine := StrSubstNo(PrepaymentTxt, "External Document Text", "Posting Date")
                else
                    CollectPrepayments(PrepmtDocsLine);

                ItemTrackingDocMgt.RetrieveDocumentItemTracking(
                    TempTrackingSpecBuffer, "No.", DATABASE::"Sales Cr.Memo Header", 0);

                if LogInteraction then
                    if not PreviewReport then
                        if "Bill-to Contact No." <> '' then
                            SegManagement.LogDocument(
                              6, "No.", 0, 0, DATABASE::Contact, "Bill-to Contact No.", "Salesperson Code",
                              "Campaign No.", "Posting Description", '')
                        else
                            SegManagement.LogDocument(
                              6, "No.", 0, 0, DATABASE::Customer, "Bill-to Customer No.", "Salesperson Code",
                              "Campaign No.", "Posting Description", '');
            end;

            trigger OnPreDataItem()
            begin
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
            FacturaInvoiceHelper.ExportDataFile(FileName)
        else
            FacturaInvoiceHelper.ExportData();
    end;

    trigger OnPreReport()
    begin
        if not CurrReport.UseRequestPage then
            CopiesNumber := 1;

        SalesSetup.Get();
        SalesSetup.TestField("Factura Template Code");
        FacturaInvoiceHelper.InitReportTemplate(SalesSetup."Factura Template Code");
    end;

    var
        DollarUSATxt: Label 'US Dollar';
        CompanyInfo: Record "Company Information";
        Customer: Record Customer;
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        AttachedSalesLine: Record "Sales Cr.Memo Line" temporary;
        Currency: Record Currency;
        SalesSetup: Record "Sales & Receivables Setup";
        PackageNoInfo: Record "Package No. Information";
        TempTrackingSpecBuffer: Record "Tracking Specification" temporary;
        TempTrackingSpecBuffer2: Record "Tracking Specification" temporary;
        UoM: Record "Unit of Measure";
        LocMgt: Codeunit "Localisation Management";
        StdRepMgt: Codeunit "Local Report Management";
        SegManagement: Codeunit SegManagement;
        FacturaInvoiceHelper: Codeunit "Factura-Invoice Report Helper";
        ItemTrackingDocMgt: Codeunit "Item Tracking Doc. Management";
        CurrencyDescription: Text;
        TotalAmount: array[8] of Decimal;
        LastTotalAmount: array[8] of Decimal;
        CopiesNumber: Integer;
        AmountInvoiceDone: Option "Invoice Currency",LCY;
        AmountInvoiceCurrent: Option "Invoice Currency",LCY;
        MultipleCD: Boolean;
        CurrencyWrittenAmount: Code[20];
        ConsignorName: Text;
        ConsignorAddress: Text;
        Sign: Decimal;
        CountryCode: Code[10];
        CountryName: Text;
        LogInteraction: Boolean;
        CDNo: Text;
        KPPCode: Code[10];
        PrepmtDocsLine: Text;
        PrepaymentTxt: Label '%1 from %2', Comment = '%1 «Ô %2';
        Receiver: array[2] of Text;
        VATExemptTotal: Boolean;
        TotalAmountText: array[3] of Text;
        TrackingSpecCount: Integer;
        CurrencyDigitalCode: Code[3];
        PreviewReport: Boolean;
        FileName: Text;

    [Scope('OnPrem')]
    procedure IncrAmount(SalesLine2: Record "Sales Cr.Memo Line")
    begin
        TotalAmount[1] := TotalAmount[1] + SalesLine2.Amount;
        TotalAmount[2] := TotalAmount[2] + SalesLine2."Amount Including VAT" - SalesLine2.Amount;
        TotalAmount[3] := TotalAmount[3] + SalesLine2."Amount Including VAT";
    end;

    [Scope('OnPrem')]
    procedure CollectPrepayments(var PrepmtList: Text)
    var
        TempCustLedgEntry: Record "Cust. Ledger Entry" temporary;
        Delimiter: Text;
    begin
        PrepmtList := '';
        Delimiter := ' ';
        Customer.CollectPrepayments(Header."Sell-to Customer No.", Header."No.", TempCustLedgEntry);
        if TempCustLedgEntry.FindSet() then
            repeat
                PrepmtList :=
                  PrepmtList + Delimiter +
                  StrSubstNo(PrepaymentTxt, TempCustLedgEntry."External Document No.", TempCustLedgEntry."Posting Date");
                Delimiter := ', ';
            until TempCustLedgEntry.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure TransferReportValues(var ReportValues: array[13] of Text; SalesLine2: Record "Sales Cr.Memo Line"; CountryName2: Text; CDNo2: Text; CountryCode2: Code[10])
    begin
        ReportValues[1] := SalesLine2.Description;
        ReportValues[2] := '-';
        if Header."Prepayment Credit Memo" then begin
            ReportValues[3] := '-';
            ReportValues[4] := '-';
            ReportValues[5] := '-';
            ReportValues[6] := '-';
            ReportValues[7] := Format(SalesLine2."VAT %") + '/' + Format(100 + SalesLine2."VAT %");
            ReportValues[8] :=
              StdRepMgt.FormatReportValue(Sign * (SalesLine2."Amount Including VAT" - SalesLine2.Amount), 2);
            ReportValues[9] := StdRepMgt.FormatReportValue(Sign * SalesLine2."Amount Including VAT", 2);
            ReportValues[10] := '-';
            ReportValues[11] := '-';
            ReportValues[12] := '-';
        end else begin
            if UoM.Get(SalesLine2."Unit of Measure Code") then
                ReportValues[2] := StdRepMgt.FormatTextValue(UoM."OKEI Code");
            ReportValues[3] := StdRepMgt.FormatTextValue(SalesLine2."Unit of Measure Code");
            ReportValues[4] := Format(Sign * SalesLine2.Quantity);
            ReportValues[5] := StdRepMgt.FormatReportValue(SalesLine2."Unit Price", 2);
            ReportValues[6] := StdRepMgt.FormatReportValue(Sign * SalesLine2.Amount, 2);
            ReportValues[7] := Format(SalesCrMemoLine."VAT %");
            ReportValues[8] :=
              StdRepMgt.FormatReportValue(Sign * (SalesLine2."Amount Including VAT" - SalesLine2.Amount), 2);
            ReportValues[9] := StdRepMgt.FormatReportValue(Sign * SalesLine2."Amount Including VAT", 2);
            ReportValues[10] := StdRepMgt.FormatTextValue(CountryCode2);
            ReportValues[11] := StdRepMgt.FormatTextValue(CountryName2);
            ReportValues[12] := StdRepMgt.FormatTextValue(CDNo2);
        end;

        if StdRepMgt.VATExemptLine(SalesLine2."VAT Bus. Posting Group", SalesLine2."VAT Prod. Posting Group") then
            StdRepMgt.FormatVATExemptLine(ReportValues[7], ReportValues[8])
        else
            VATExemptTotal := false;

        ReportValues[13] := StdRepMgt.GetEAEUItemTariffNo_SalesCrMemoLine(SalesLine2);
    end;

    [Scope('OnPrem')]
    procedure TransferHeaderValues(var HeaderValue: array[12] of Text)
    begin
        HeaderValue[1] := StdRepMgt.GetCompanyName();
        HeaderValue[2] := StdRepMgt.GetLegalAddress();
        HeaderValue[3] := CompanyInfo."VAT Registration No." + ' / ' + CompanyInfo."KPP Code";
        HeaderValue[4] := ConsignorName + '  ' + ConsignorAddress;
        HeaderValue[5] := Receiver[1] + ' ' + Receiver[2];
        HeaderValue[6] := Header."External Document Text";
        HeaderValue[7] := StdRepMgt.GetCustInfo(Header, 0, 2);
        HeaderValue[8] := StdRepMgt.GetCustInfo(Header, 1, 2);
        HeaderValue[9] := Customer."VAT Registration No." + '/' + KPPCode;
        HeaderValue[10] := CurrencyDigitalCode;
        HeaderValue[11] := CurrencyDescription;
    end;

    [Scope('OnPrem')]
    procedure PrintShortAddr(DocNo: Code[20]): Boolean
    var
        SalesInvLine: Record "Sales Cr.Memo Line";
    begin
        SalesInvLine.SetRange("Document No.", DocNo);
        SalesInvLine.SetFilter(Type, '%1|%2', SalesInvLine.Type::Item, SalesInvLine.Type::"Fixed Asset");
        SalesInvLine.SetFilter("No.", '<>''''');
        SalesInvLine.SetFilter(Quantity, '<>0');
        exit(SalesInvLine.IsEmpty);
    end;

    local procedure FillDocHeader(var DocNo: Code[20]; var DocDate: Text; var RevNo: Code[20]; var RevDate: Text)
    var
        CorrDocMgt: Codeunit "Corrective Document Mgt.";
    begin
        if Header."Corrective Doc. Type" = Header."Corrective Doc. Type"::Revision then begin
            case Header."Original Doc. Type" of
                Header."Original Doc. Type"::Invoice:
                    DocDate := LocMgt.Date2Text(CorrDocMgt.GetSalesInvHeaderPostingDate(Header."Original Doc. No."));
                Header."Original Doc. Type"::"Credit Memo":
                    DocDate := LocMgt.Date2Text(CorrDocMgt.GetSalesCrMHeaderPostingDate(Header."Original Doc. No."));
            end;
            DocNo := Header."Original Doc. No.";
            RevNo := Header."Revision No.";
            RevDate := LocMgt.Date2Text(Header."Document Date");
        end else begin
            DocNo := Header."No.";
            DocDate := LocMgt.Date2Text(Header."Document Date");
            RevNo := '-';
            RevDate := '-';
        end;
    end;

    local procedure FillHeader()
    var
        DocNo: Code[20];
        RevNo: Code[20];
        DocDate: Text;
        RevDate: Text;
        HeaderValues: array[12] of Text;
    begin
        FillDocHeader(DocNo, DocDate, RevNo, RevDate);
        TransferHeaderValues(HeaderValues);

        FacturaInvoiceHelper.FillHeader(DocNo, DocDate, RevNo, RevDate, HeaderValues);
    end;

    local procedure FillBody(LineValue: array[13] of Text)
    begin
        FacturaInvoiceHelper.FillBody(LineValue, false);
    end;

    local procedure FillRespPerson(var ResponsiblePerson: array[2] of Text)
    begin
        ResponsiblePerson[1] := StdRepMgt.GetDirectorName(true, 112, 0, Header."No.");
        ResponsiblePerson[2] := StdRepMgt.GetAccountantName(true, 112, 0, Header."No.");
    end;

    [Scope('OnPrem')]
    procedure SetFileNameSilent(NewFileName: Text)
    begin
        FileName := NewFileName;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnItemTrackingLineOnBeforeTransferReportValues(SalesCrMemoLine: Record "Sales Cr.Memo Line"; var TempTrackingSpecification: Record "Tracking Specification" temporary; var TempTrackingSpecification2: Record "Tracking Specification" temporary; var MultipleCD: Boolean; var CDNo: Text; var CountryCode: Code[10]; var CountryName: Text; var TrackingSpecCount: Integer);
    begin
    end;
}

