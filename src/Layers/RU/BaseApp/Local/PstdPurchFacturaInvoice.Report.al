#pragma warning disable AA0247
report 14939 "Pstd. Purch. Factura-Invoice"
{
    Caption = 'Pstd. Purch. Factura-Invoice';
    ProcessingOnly = true;

    dataset
    {
        dataitem(Header; "Purch. Inv. Header")
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
                                AttachedPurchInvLine.FindSet()
                            else
                                AttachedPurchInvLine.Next();

                            CopyArray(LastTotalAmount, TotalAmount, 1);
                            FacturaInvoiceHelper.TransferLineDescrValues(LineValues, AttachedPurchInvLine.Description);
                            FillBody(LineValues);
                        end;

                        trigger OnPreDataItem()
                        begin
                            AttachedPurchInvLine.SetRange("Attached to Line No.", PurchInvLine."Line No.");
                            SetRange(Number, 1, AttachedPurchInvLine.Count);
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
                        LineValues: array[13] of Text;
                    begin
                        if Number = 1 then begin
                            if not PurchInvLine.FindFirst() then
                                CurrReport.Break();
                        end else
                            if PurchInvLine.Next(1) = 0 then begin
                                FormatTotalAmounts();
                                CurrReport.Break();
                            end;

                        CopyArray(LastTotalAmount, TotalAmount, 1);

                        if PurchInvLine.Type <> PurchInvLine.Type::" " then begin
                            if PurchInvLine.Quantity = 0 then
                                CurrReport.Skip();
                            if AmountInvoiceCurrent = AmountInvoiceCurrent::LCY then begin
                                PurchInvLine.Amount := PurchInvLine."Amount (LCY)";
                                PurchInvLine."Amount Including VAT" := PurchInvLine."Amount Including VAT (LCY)";
                            end;
                            PurchInvLine."Unit Price (LCY)" :=
                              Round(PurchInvLine.Amount / PurchInvLine.Quantity,
                                Currency."Unit-Amount Rounding Precision");
                            IncrAmount(PurchInvLine);
                        end else
                            PurchInvLine."No." := '';

                        OnItemTrackingLineOnBeforeTransferReportValues(
                            PurchInvLine, TempTrackingSpecBuffer, TempTrackingSpecBuffer2,
                            MultipleCD, CDNo, CountryCode, CountryName, TrackingSpecCount);

                        if Header."Prepayment Invoice" then
                            LastTotalAmount[1] := 0;

                        if PurchInvLine.Type = PurchInvLine.Type::" " then
                            FacturaInvoiceHelper.TransferLineDescrValues(LineValues, PurchInvLine.Description)
                        else
                            TransferReportValues(LineValues, PurchInvLine, CountryName, CDNo, CountryCode);

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
                    if not CurrReport.Preview then
                        CODEUNIT.Run(CODEUNIT::"Purch. Inv.-Printed", Header);
                end;

                trigger OnPreDataItem()
                begin
                    if not PurchInvLine.FindFirst() then
                        CurrReport.Break();

                    SetRange(Number, 1, CopiesNumber);
                end;
            }

            trigger OnAfterGetRecord()
            var
                Vendor: Record Vendor;
                VendAgrmt: Record "Vendor Agreement";
            begin
                CompanyInfo.Get();

                Vendor.Get("Buy-from Vendor No.");

                AmountInvoiceCurrent := AmountInvoiceDone;
                if "Currency Code" = '' then
                    AmountInvoiceCurrent := AmountInvoiceCurrent::LCY;

                Sign := 1;
                PurchInvLine.Reset();
                PurchInvLine.SetRange("Document No.", "No.");
                PurchInvLine.SetFilter("Attached to Line No.", '<>%1', 0);
                if PurchInvLine.FindSet() then
                    repeat
                        AttachedPurchInvLine := PurchInvLine;
                        AttachedPurchInvLine.Insert();
                    until PurchInvLine.Next() = 0;

                PurchInvLine.SetRange("Attached to Line No.", 0);

                if "Currency Code" <> '' then
                    if not Currency.Get("Currency Code") then
                        Currency.Description := DollarUSATxt;

                PaymentDocument :=
                  StrSubstNo(PaymentDocTxt, "Vendor Invoice No.", "Posting Date");

                CurrencyWrittenAmount := FacturaInvoiceHelper.GetCurrencyAmtCode("Currency Code", AmountInvoiceCurrent);
                FacturaInvoiceHelper.GetCurrencyInfo(CurrencyWrittenAmount, CurrencyDigitalCode, CurrencyDescription);

                if Vendor."VAT Agent Type" = Vendor."VAT Agent Type"::"State Authority" then begin
                    VATRegNo := Vendor."VAT Registration No." + '/' + Vendor."KPP Code";
                    VATAgentText := StateMunicipalPropTxt;
                end else begin
                    VATRegNo := '-';
                    VATAgentText := ForeignEntityTxt;
                end;

                if "Agreement No." <> '' then begin
                    VendAgrmt.Get("Buy-from Vendor No.", "Agreement No.");
                    VendorFunds := VendAgrmt."VAT Payment Source Type" = VendAgrmt."VAT Payment Source Type"::"Vendor Funds";
                end else
                    VendorFunds := Vendor."VAT Payment Source Type" = Vendor."VAT Payment Source Type"::"Vendor Funds";

                IsNonResidentVATAgent :=
                  Vendor."VAT Agent" and (Vendor."VAT Agent Type" = Vendor."VAT Agent Type"::"Non-resident");
            end;
        }
    }

    requestpage
    {

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

    trigger OnInitReport()
    begin
        SalesSetup.Get();
        SalesSetup.TestField("Factura Template Code");
        FacturaInvoiceHelper.InitReportTemplate(SalesSetup."Factura Template Code");
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
        if not CurrReport.UseRequestPage then
            CopiesNumber := 1;
    end;

    var
        CompanyInfo: Record "Company Information";
        PurchInvLine: Record "Purch. Inv. Line";
        AttachedPurchInvLine: Record "Purch. Inv. Line" temporary;
        Currency: Record Currency;
        PackageNoInfo: Record "Package No. Information";
        TempTrackingSpecBuffer: Record "Tracking Specification" temporary;
        TempTrackingSpecBuffer2: Record "Tracking Specification" temporary;
        UoM: Record "Unit of Measure";
        SalesSetup: Record "Sales & Receivables Setup";
        LocMgt: Codeunit "Localisation Management";
        StdRepMgt: Codeunit "Local Report Management";
        FacturaInvoiceHelper: Codeunit "Factura-Invoice Report Helper";
        TotalAmount: array[8] of Decimal;
        LastTotalAmount: array[8] of Decimal;
        Sign: Decimal;
        CopiesNumber: Integer;
        TrackingSpecCount: Integer;
        CurrencyDescription: Text[30];
        CountryName: Text[30];
        CDNo: Text[50];
        PaymentDocument: Text[1024];
        PaymentDocTxt: Label '%1 from %2', Comment = '%1 «Ô %2';
        TotalAmountText: array[3] of Text[50];
        VATRegNo: Text[30];
        ForeignEntityTxt: Label 'For a foreign entity', Comment = 'Must be translated: çá ¿¡«ßÔÓá¡¡«Ñ ½¿µ«';
        StateMunicipalPropTxt: Label 'State and municipal property rent', Comment = 'Must be translated: ÇÓÑ¡ñá ú«ßÒñáÓßÔóÑ¡¡«ú« ¿ ¼Ò¡¿µ¿»á½ý¡«ú« ¿¼ÒÚÑßÔóá';
        VATAgentText: Text;
        FileName: Text;
        DashTxt: Label '-';
        MultipleCD: Boolean;
        VATExemptTotal: Boolean;
        VendorFunds: Boolean;
        AmountInvoiceDone: Option "Invoice Currency",LCY;
        AmountInvoiceCurrent: Option "Invoice Currency",LCY;
        CurrencyWrittenAmount: Code[20];
        CountryCode: Code[10];
        CurrencyDigitalCode: Code[3];
        DollarUSATxt: Label 'US Dollar', Comment = 'Must be translated: ñ«½½áÓ æÿÇ';
        IsNonResidentVATAgent: Boolean;

    [Scope('OnPrem')]
    procedure IncrAmount(PurchInvLine2: Record "Purch. Inv. Line")
    begin
        TotalAmount[1] := TotalAmount[1] + PurchInvLine2.Amount;
        TotalAmount[2] := TotalAmount[2] + PurchInvLine2."Amount Including VAT" - PurchInvLine2.Amount;
        TotalAmount[3] := TotalAmount[3] + PurchInvLine2."Amount Including VAT";
        TotalAmount[4] := TotalAmount[4] + PurchInvLine2.Quantity;
    end;

    [Scope('OnPrem')]
    procedure TransferReportValues(var ReportValues: array[13] of Text; PurchInvLine2: Record "Purch. Inv. Line"; CountryName2: Text[30]; CDNo2: Text[50]; CountryCode2: Code[10])
    begin
        ReportValues[1] := PurchInvLine2.Description;
        ReportValues[2] := '-';
        if Header."Prepayment Invoice" then begin
            ReportValues[3] := '-';
            ReportValues[4] := '-';
            ReportValues[5] := '-';
            ReportValues[6] := '-';
            if VendorFunds then
                ReportValues[7] := Format(PurchInvLine2."VAT %") + '/' + Format(100 + PurchInvLine2."VAT %")
            else
                ReportValues[7] := Format(PurchInvLine2."VAT %");
            ReportValues[8] :=
              StdRepMgt.FormatReportValue(PurchInvLine2."Amount Including VAT" - PurchInvLine2.Amount, 2);
            ReportValues[9] := StdRepMgt.FormatReportValue(PurchInvLine2."Amount Including VAT", 2);
            ReportValues[10] := '-';
            ReportValues[11] := '-';
            ReportValues[12] := '-';
        end else begin
            if IsNonResidentVATAgent then begin
                ReportValues[3] := '-';
                ReportValues[4] := '-';
                ReportValues[5] := '-';
            end else begin
                if UoM.Get(PurchInvLine2."Unit of Measure Code") then
                    ReportValues[2] := StdRepMgt.FormatTextValue(UoM."OKEI Code");
                ReportValues[3] := StdRepMgt.FormatTextValue(PurchInvLine2."Unit of Measure Code");
                ReportValues[4] := Format(Sign * PurchInvLine2.Quantity);
                ReportValues[5] := StdRepMgt.FormatReportValue(PurchInvLine2."Unit Price (LCY)", 2);
            end;

            ReportValues[6] := StdRepMgt.FormatReportValue(Sign * PurchInvLine2.Amount, 2);
            if VendorFunds or IsNonResidentVATAgent then
                ReportValues[7] := Format(PurchInvLine2."VAT %") + '/' + Format(100 + PurchInvLine2."VAT %")
            else
                ReportValues[7] := Format(PurchInvLine2."VAT %");
            ReportValues[8] :=
              StdRepMgt.FormatReportValue(Sign * (PurchInvLine2."Amount Including VAT" - PurchInvLine2.Amount), 2);
            ReportValues[9] := StdRepMgt.FormatReportValue(Sign * PurchInvLine2."Amount Including VAT", 2);
            ReportValues[10] := StdRepMgt.FormatTextValue(CountryCode2);
            ReportValues[11] := StdRepMgt.FormatTextValue(CountryName2);
            ReportValues[12] := StdRepMgt.FormatTextValue(CDNo2);
        end;

        if not IsNonResidentVATAgent and
           StdRepMgt.VATExemptLine(PurchInvLine2."VAT Bus. Posting Group", PurchInvLine2."VAT Prod. Posting Group")
        then
            StdRepMgt.FormatVATExemptLine(ReportValues[7], ReportValues[8])
        else
            VATExemptTotal := false;
    end;

    [Scope('OnPrem')]
    procedure FormatTotalAmounts()
    begin
        if Header."Prepayment Invoice" then
            TotalAmountText[1] := '-'
        else
            TotalAmountText[1] := StdRepMgt.FormatReportValue(TotalAmount[1], 2);

        if VATExemptTotal then
            TotalAmountText[2] := '-'
        else
            TotalAmountText[2] := StdRepMgt.FormatReportValue(TotalAmount[2], 2);

        TotalAmountText[3] := StdRepMgt.FormatReportValue(TotalAmount[3], 2);
    end;

    [Scope('OnPrem')]
    procedure InitializeRequest(NoOfCopies: Integer; PrintCurr: Option)
    begin
        CopiesNumber := NoOfCopies;
        AmountInvoiceDone := PrintCurr;
    end;

    [Scope('OnPrem')]
    procedure SetFileNameSilent(NewFileName: Text)
    begin
        FileName := NewFileName;
    end;

    local procedure FillDocHeader(var DocNo: Code[20]; var DocDate: Text; var RevNo: Code[20]; var RevDate: Text)
    var
        CorrDocMgt: Codeunit "Corrective Document Mgt.";
    begin
        if Header."Corrective Doc. Type" = Header."Corrective Doc. Type"::Revision then begin
            case Header."Original Doc. Type" of
                Header."Original Doc. Type"::Invoice:
                    DocDate := LocMgt.Date2Text(CorrDocMgt.GetPurchInvHeaderPostingDate(Header."Original Doc. No."));
                Header."Original Doc. Type"::"Credit Memo":
                    DocDate := LocMgt.Date2Text(CorrDocMgt.GetPurchCrMHeaderPostingDate(Header."Original Doc. No."));
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

    [Scope('OnPrem')]
    procedure TransferHeaderValues(var HeaderValue: array[12] of Text)
    begin
        HeaderValue[1] := StdRepMgt.GetVendorName(Header."Buy-from Vendor No.");
        HeaderValue[2] := StdRepMgt.GetVendorAddress(Header."Buy-from Vendor No.");
        HeaderValue[3] := VATRegNo;
        HeaderValue[4] := DashTxt;
        HeaderValue[5] := DashTxt;
        HeaderValue[6] := PaymentDocument;
        HeaderValue[7] := StdRepMgt.GetCompanyName();
        HeaderValue[8] := StdRepMgt.GetLegalAddress();
        HeaderValue[9] := CompanyInfo."VAT Registration No." + ' / ' + CompanyInfo."KPP Code";
        HeaderValue[10] := CurrencyDigitalCode;
        HeaderValue[11] := CurrencyDescription;
        HeaderValue[12] := VATAgentText;
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

    [IntegrationEvent(false, false)]
    local procedure OnItemTrackingLineOnBeforeTransferReportValues(PurchInvLine: Record "Purch. Inv. Line"; var TempTrackingSpecification: Record "Tracking Specification" temporary; var TempTrackingSpecification2: Record "Tracking Specification" temporary; var MultipleCD: Boolean; var CDNo: Text; var CountryCode: Code[10]; var CountryName: Text; var TrackingSpecCount: Integer);
    begin
    end;
}

