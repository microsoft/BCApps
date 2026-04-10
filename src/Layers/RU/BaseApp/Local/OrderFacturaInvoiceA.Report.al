#pragma warning disable AA0247
report 12411 "Order Factura-Invoice (A)"
{
    Caption = 'Order Factura-Invoice (A)';
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
                            AttachedSalesLine.SetRange("Attached to Line No.", SalesLine1."Line No.");
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
                        LineValues: array[14] of Text;
                    begin
                        if Number = 1 then begin
                            if not SalesLine1.Find('-') then
                                CurrReport.Break();
                        end else
                            if SalesLine1.Next(1) = 0 then begin
                                FacturaInvoiceHelper.FormatTotalAmounts(
                                  TotalAmountText, TotalAmount, Sign, false, VATExemptTotal);
                                CurrReport.Break();
                            end;

                        CopyArray(LastTotalAmount, TotalAmount, 1);

                        if SalesLine1.Type <> SalesLine1.Type::" " then begin
                            if SalesLine1."Qty. to Invoice" = 0 then
                                CurrReport.Skip();
                            if AmountInvoiceCurrent = AmountInvoiceCurrent::LCY then begin
                                SalesLine1.Amount := SalesLine1."Amount (LCY)";
                                SalesLine1."Amount Including VAT" := SalesLine1."Amount Including VAT (LCY)";
                            end;
                            SalesLine1.Amount :=
                              Round(SalesLine1.Amount * SalesLine1."Qty. to Invoice" / SalesLine1.Quantity,
                                Currency."Amount Rounding Precision");
                            SalesLine1."Amount Including VAT" :=
                              Round(SalesLine1."Amount Including VAT" * SalesLine1."Qty. to Invoice" / SalesLine1.Quantity,
                                Currency."Amount Rounding Precision");
                            SalesLine1."Unit Price" :=
                              Round(SalesLine1.Amount / SalesLine1."Qty. to Invoice",
                                Currency."Unit-Amount Rounding Precision");
                            IncrAmount(SalesLine1);
                            OnItemTrackingLineOnBeforeTransferReportValues(
                                SalesLine1, TempTrackingSpecBuffer, TempTrackingSpecBuffer2,
                                MultipleCD, CDNo, CountryCode, CountryName, TrackingSpecCount);
                            TransferReportValues(LineValues, SalesLine1, CountryName, CDNo, CountryCode);
                        end else begin
                            SalesLine1."No." := '';
                            FacturaInvoiceHelper.TransferLineDescrValues(LineValues, SalesLine1.Description);
                        end;

                        FillBody(LineValues);
                    end;

                    trigger OnPostDataItem()
                    var
                        ResponsiblePerson: array[2] of Text;
                    begin
                        FillRespPerson(ResponsiblePerson);
                        FacturaInvoiceHelper.FinalizeReport(TotalAmountText, ResponsiblePerson, Proforma);
                    end;

                    trigger OnPreDataItem()
                    begin
                        if (AmountInvoiceCurrent = AmountInvoiceCurrent::"Invoice Currency") and (Header."Currency Code" <> '') then
                            Currency.Get(Header."Currency Code")
                        else
                            Currency.InitRoundingPrecision();

                        VATExemptTotal := true;

                        FillHeader(Proforma);
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    Clear(TotalAmount);
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

                    if Header."Posting No." = '' then
                        if PreviewReport then
                            Header."Posting No." := NoSeries.PeekNextNo(Header."Posting No. Series", Header."Posting Date")
                        else begin
                            Header."Posting No." := NoSeries.GetNextNo(Header."Posting No. Series", Header."Posting Date");
                            Header.Modify();
                        end;

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

                if "Document Type" = "Document Type"::"Credit Memo" then
                    Sign := -1
                else
                    Sign := 1;

                SalesLine1.Reset();
                SalesLine1.SetRange("Document Type", "Document Type");
                SalesLine1.SetRange("Document No.", "No.");
                SalesLine1.SetFilter("Attached to Line No.", '<>%1', 0);
                if SalesLine1.FindSet() then
                    repeat
                        AttachedSalesLine := SalesLine1;
                        AttachedSalesLine.Insert();
                    until SalesLine1.Next() = 0;

                SalesLine1.SetRange("Attached to Line No.", 0);

                if "Currency Code" <> '' then
                    if not Currency.Get("Currency Code") then
                        Currency.Description := DollarUSATxt;

                CurrencyWrittenAmount := FacturaInvoiceHelper.GetCurrencyAmtCode("Currency Code", AmountInvoiceCurrent);
                FacturaInvoiceHelper.GetCurrencyInfo(CurrencyWrittenAmount, CurrencyDigitalCode, CurrencyDescription);

                if PrintShortAddr("Document Type".AsInteger(), "No.") then
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

                ItemTrackingDocMgt.RetrieveDocumentItemTracking(
                    TempTrackingSpecBuffer, "No.", DATABASE::"Sales Header", "Document Type".AsInteger());

                if not PreviewReport then
                    if LogInteraction then begin
                        CalcFields("No. of Archived Versions");
                        if "Bill-to Contact No." <> '' then
                            SegManagement.LogDocument(
                              3, "No.", "Doc. No. Occurrence",
                              "No. of Archived Versions", DATABASE::Contact, "Bill-to Contact No.",
                              "Salesperson Code", "Campaign No.", "Posting Description", "Opportunity No.")
                        else
                            SegManagement.LogDocument(
                              3, "No.", "Doc. No. Occurrence",
                              "No. of Archived Versions", DATABASE::Customer, "Bill-to Customer No.",
                              "Salesperson Code", "Campaign No.", "Posting Description", "Opportunity No.");
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
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            CopiesNumber := 1;
        end;
    }

    labels
    {
    }

    trigger OnInitReport()
    begin
        Proforma := false;
        CopiesNumber := 0;
    end;

    trigger OnPostReport()
    begin
        if FileName <> '' then
            FacturaInvoiceHelper.ExportDataFile(FileName)
        else
            FacturaInvoiceHelper.ExportData();
    end;

    trigger OnPreReport()
    begin
        if (not CurrReport.UseRequestPage) and (CopiesNumber = 0) then
            CopiesNumber := 1;

        FacturaInvoiceHelper.InitReportTemplate(GetTemplateCode(Proforma));
    end;

    var
        DollarUSATxt: Label 'US Dollar';
        CompanyInfo: Record "Company Information";
        Customer: Record Customer;
        SalesLine1: Record "Sales Line";
        AttachedSalesLine: Record "Sales Line" temporary;
        Currency: Record Currency;
        SalesSetup: Record "Sales & Receivables Setup";
        PackageNoInfo: Record "Package No. Information";
        TempTrackingSpecBuffer: Record "Tracking Specification" temporary;
        TempTrackingSpecBuffer2: Record "Tracking Specification" temporary;
        LocMgt: Codeunit "Localisation Management";
        StdRepMgt: Codeunit "Local Report Management";
        SegManagement: Codeunit SegManagement;
        ItemTrackingDocMgt: Codeunit "Item Tracking Doc. Management";
        FacturaInvoiceHelper: Codeunit "Factura-Invoice Report Helper";
        CurrencyDescription: Text;
        TotalAmount: array[3] of Decimal;
        LastTotalAmount: array[3] of Decimal;
        CopiesNumber: Integer;
        AmountInvoiceDone: Option "Invoice Currency",LCY;
        AmountInvoiceCurrent: Option "Invoice Currency",LCY;
        MultipleCD: Boolean;
        CurrencyWrittenAmount: Code[10];
        ConsignorName: Text;
        ConsignorAddress: Text;
        Sign: Decimal;
        CountryCode: Code[10];
        CountryName: Text;
        LogInteraction: Boolean;
        CDNo: Text;
        KPPCode: Code[10];
        Receiver: array[2] of Text;
        VATExemptTotal: Boolean;
        TotalAmountText: array[3] of Text;
        TrackingSpecCount: Integer;
        CurrencyDigitalCode: Code[3];
        PreviewReport: Boolean;
        Proforma: Boolean;
        FileName: Text;

    [Scope('OnPrem')]
    procedure InitializeRequest(NoOfCopies: Integer; PrintCurr: Option; IsLog: Boolean; IsPreview: Boolean; IsProforma: Boolean)
    begin
        CopiesNumber := NoOfCopies;
        AmountInvoiceDone := PrintCurr;
        LogInteraction := IsLog;
        PreviewReport := IsPreview;
        Proforma := IsProforma;
    end;

    [Scope('OnPrem')]
    procedure IncrAmount(SalesLine2: Record "Sales Line")
    begin
        TotalAmount[1] := TotalAmount[1] + SalesLine2.Amount;
        TotalAmount[2] := TotalAmount[2] + SalesLine2."Amount Including VAT" - SalesLine2.Amount;
        TotalAmount[3] := TotalAmount[3] + SalesLine2."Amount Including VAT";
    end;

    [Scope('OnPrem')]
    procedure TransferReportValues(var ReportValues: array[13] of Text; SalesLine2: Record "Sales Line"; CountryName2: Text; CDNo2: Text; CountryCode2: Code[10])
    var
        UoM: Record "Unit of Measure";
    begin
        ReportValues[1] := SalesLine2.Description;
        ReportValues[2] := '-';
        if UoM.Get(SalesLine2."Unit of Measure Code") then
            ReportValues[2] := StdRepMgt.FormatTextValue(UoM."OKEI Code");
        ReportValues[3] := StdRepMgt.FormatTextValue(SalesLine2."Unit of Measure Code");
        ReportValues[4] := Format(Sign * SalesLine2."Qty. to Invoice");
        ReportValues[5] := StdRepMgt.FormatReportValue(SalesLine2."Unit Price", 2);
        ReportValues[6] := StdRepMgt.FormatReportValue(Sign * SalesLine2.Amount, 2);
        ReportValues[7] := Format(SalesLine1."VAT %");
        ReportValues[8] :=
          StdRepMgt.FormatReportValue(Sign * (SalesLine2."Amount Including VAT" - SalesLine2.Amount), 2);
        ReportValues[9] := StdRepMgt.FormatReportValue(Sign * SalesLine2."Amount Including VAT", 2);
        ReportValues[10] := StdRepMgt.FormatTextValue(CountryCode2);
        ReportValues[11] := StdRepMgt.FormatTextValue(CopyStr(CountryName2, 1));
        ReportValues[12] := StdRepMgt.FormatTextValue(CopyStr(CDNo2, 1));

        if StdRepMgt.VATExemptLine(SalesLine2."VAT Bus. Posting Group", SalesLine2."VAT Prod. Posting Group") then
            StdRepMgt.FormatVATExemptLine(ReportValues[7], ReportValues[7])
        else
            VATExemptTotal := false;

        ReportValues[13] := StdRepMgt.GetEAEUItemTariffNo_SalesLine(SalesLine2);
    end;

    [Scope('OnPrem')]
    procedure TransferHeaderValues(var HeaderValue: array[12] of Text)
    begin
        HeaderValue[1] := StdRepMgt.GetCompanyName();
        HeaderValue[2] := StdRepMgt.GetLegalAddress();
        HeaderValue[3] := CompanyInfo."VAT Registration No." + ' / ' + CompanyInfo."KPP Code";
        HeaderValue[4] := ConsignorName + '  ' + ConsignorAddress;
        HeaderValue[5] := Receiver[1] + '  ' + Receiver[2];
        HeaderValue[6] := StdRepMgt.FormatTextValue(Header."External Document Text");
        HeaderValue[7] := StdRepMgt.GetCustName(Header."Bill-to Customer No.");
        HeaderValue[8] := StdRepMgt.GetCustInfo(Header, 1, 2);
        HeaderValue[9] := Customer."VAT Registration No." + ' / ' + KPPCode;
        HeaderValue[10] := CurrencyDigitalCode;
        HeaderValue[11] := CurrencyDescription;
        HeaderValue[12] := '';
    end;

    [Scope('OnPrem')]
    procedure PrintShortAddr(DocType: Option; DocNo: Code[20]): Boolean
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", DocType);
        SalesLine.SetRange("Document No.", DocNo);
        SalesLine.SetFilter(Type, '%1|%2', SalesLine.Type::Item, SalesLine.Type::"Fixed Asset");
        SalesLine.SetFilter("No.", '<>''''');
        SalesLine.SetFilter("Qty. to Invoice", '<>0');
        exit(SalesLine.IsEmpty);
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
            DocNo := Header."Posting No.";
            DocDate := LocMgt.Date2Text(Header."Document Date");
            RevNo := '-';
            RevDate := '-';
        end;
    end;

    local procedure FillProformaHeader(var DocNo: Code[20]; var DocDate: Text; var RevNo: Code[20]; var RevDate: Text)
    begin
        DocNo := Header."No.";
        DocDate := LocMgt.Date2Text(Header."Document Date");
        RevNo := '';
        RevDate := '';
    end;

    local procedure FillHeader(IsProforma: Boolean)
    var
        DocNo: Code[20];
        RevNo: Code[20];
        DocDate: Text;
        RevDate: Text;
        HeaderValues: array[12] of Text;
    begin
        if IsProforma then
            FillProformaHeader(DocNo, DocDate, RevNo, RevDate)
        else
            FillDocHeader(DocNo, DocDate, RevNo, RevDate);
        TransferHeaderValues(HeaderValues);

        FacturaInvoiceHelper.FillHeader(DocNo, DocDate, RevNo, RevDate, HeaderValues);
    end;

    local procedure FillBody(LineValue: array[13] of Text)
    begin
        FacturaInvoiceHelper.FillBody(LineValue, Proforma);
    end;

    local procedure FillRespPerson(var ResponsiblePerson: array[2] of Text)
    begin
        ResponsiblePerson[1] := StdRepMgt.GetDirectorName(false, 36, Header."Document Type".AsInteger(), Header."No.");
        ResponsiblePerson[2] := StdRepMgt.GetAccountantName(false, 36, Header."Document Type".AsInteger(), Header."No.");
    end;

    local procedure GetTemplateCode(IsProforma: Boolean): Code[10]
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        if IsProforma then begin
            SalesReceivablesSetup.TestField("Proforma Template Code");
            exit(SalesReceivablesSetup."Proforma Template Code");
        end;

        SalesReceivablesSetup.TestField("Factura Template Code");
        exit(SalesReceivablesSetup."Factura Template Code");
    end;

    [Scope('OnPrem')]
    procedure SetFileNameSilent(NewFileName: Text)
    begin
        FileName := NewFileName;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnItemTrackingLineOnBeforeTransferReportValues(SalesLine: Record "Sales Line"; var TempTrackingSpecification: Record "Tracking Specification" temporary; var TempTrackingSpecification2: Record "Tracking Specification" temporary; var MultipleCD: Boolean; var CDNo: Text; var CountryCode: Code[10]; var CountryName: Text; var TrackingSpecCount: Integer);
    begin
    end;
}

