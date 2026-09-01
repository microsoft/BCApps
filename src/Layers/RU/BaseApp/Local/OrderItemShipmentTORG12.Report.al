#pragma warning disable AA0247
report 12407 "Order Item Shipment TORG-12"
{
    Caption = 'Order Item Shipment TORG-12';
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

                    trigger OnAfterGetRecord()
                    var
                        AmountValues: array[6] of Decimal;
                    begin
                        if Number = 1 then begin
                            if not SalesLine1.Find('-') then
                                CurrReport.Break();
                        end else
                            if SalesLine1.Next(1) = 0 then
                                CurrReport.Break();

                        if SalesLine1.Type <> SalesLine1.Type::" " then begin
                            if SalesLine1."Qty. to Invoice" = 0 then
                                CurrReport.Skip();
                            SerialNumbers += 1;
                            if AmountInvoiceCurrent = AmountInvoiceCurrent::LCY then begin
                                SalesLine1.Amount := SalesLine1."Amount (LCY)";
                                SalesLine1."Amount Including VAT" := SalesLine1."Amount Including VAT (LCY)";
                            end;
                            SalesLine1.Amount :=
                              Round(SalesLine1.Amount * SalesLine1."Qty. to Invoice" / SalesLine1.Quantity, Currency."Amount Rounding Precision");
                            SalesLine1."Amount Including VAT" :=
                              Round(SalesLine1."Amount Including VAT" * SalesLine1."Qty. to Invoice" / SalesLine1.Quantity,
                                Currency."Amount Rounding Precision");
                            SalesLine1."Unit Price" := Round(SalesLine1.Amount / SalesLine1."Qty. to Invoice", Currency."Unit-Amount Rounding Precision");

                            TransferAmounts(SalesLine1, AmountValues);

                            if StdRepMgt.VATExemptLine(SalesLine1."VAT Bus. Posting Group", SalesLine1."VAT Prod. Posting Group") then
                                StdRepMgt.FormatVATExemptLine(LineVATText[1], LineVATText[2])
                            else begin
                                VATExemptTotal := false;
                                LineVATText[1] := Format(SalesLine1."VAT %");
                                LineVATText[2] :=
                                  StdRepMgt.FormatReportValue(SalesLine1."Amount Including VAT" - SalesLine1.Amount, 2);
                            end;

                            if (SalesLine1.Type = SalesLine1.Type::Item) or (SalesLine1.Type = SalesLine1.Type::"Fixed Asset") then
                                ObjectCode := SalesLine1."No."
                            else
                                ObjectCode := '-';
                        end else
                            SalesLine1."No." := '';

                        CurrentNo := SalesLine1."No.";

                        if not AtLeastOneLineExists then begin
                            AtLeastOneLineExists := true;
                            TransferHeaderValues();
                            TORG12Helper.FillPageHeader(CurrencyText);
                        end;

                        TransferBodyValues(AmountValues);
                    end;

                    trigger OnPostDataItem()
                    begin
                        SerialNumbersText := LocMgt.Integer2Text(SerialNumbers, 1, '', '', '');
                        SerialNumbersText := LowerCase(CopyStr(SerialNumbersText, 1, 1)) + CopyStr(SerialNumbersText, 2);

                        if AtLeastOneLineExists then
                            TransferFooterValues();
                    end;

                    trigger OnPreDataItem()
                    begin
                        if (AmountInvoiceCurrent = AmountInvoiceCurrent::"Invoce Currency") and (Header."Currency Code" <> '') then
                            Currency.Get(Header."Currency Code")
                        else
                            Currency.InitRoundingPrecision();

                        SerialNumbers := 0;

                        VATExemptTotal := true;
                        AtLeastOneLineExists := false;
                    end;
                }

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

                    if Header."Shipping No." = '' then
                        if (Header."Shipping No. Series" = '') or (Header."Shipping No. Series" = Header."Posting No. Series") then
                            if Header."Posting No." = '' then begin
                                if PreviewReport then
                                    Header."Posting No." := NoSeriesBatch.GetNextNo(Header."Posting No. Series", Header."Posting Date")
                                else
                                    Header."Posting No." := NoSeries.GetNextNo(Header."Posting No. Series", Header."Posting Date");
                                Header."Shipping No." := Header."Posting No.";
                                if not PreviewReport then
                                    Header.Modify();
                            end else begin
                                Header."Shipping No." := Header."Posting No.";
                                if not PreviewReport then
                                    Header.Modify();
                            end
                        else begin
                            Clear(NoSeriesBatch);
                            if PreviewReport then
                                Header."Shipping No." := NoSeriesBatch.GetNextNo(Header."Shipping No. Series", Header."Posting Date")
                            else
                                Header."Shipping No." := NoSeries.GetNextNo(Header."Shipping No. Series", Header."Posting Date");
                            if not PreviewReport then
                                Header.Modify();
                        end;
                    DocumentNo := Header."Shipping No.";
                    DocumentDate := Header."Posting Date";

                    SetRange(Number, 1, CopiesNumber);
                end;
            }

            trigger OnAfterGetRecord()
            begin
                TestField(Status);
                CompanyInfo.Get();

                Cust.Get("Bill-to Customer No.");

                AmountInvoiceCurrent := AmountInvoiceDone;
                if "Currency Code" = '' then
                    AmountInvoiceCurrent := AmountInvoiceCurrent::LCY;

                SalesLine1.Reset();
                SalesLine1.SetRange("Document Type", "Document Type");
                SalesLine1.SetRange("Document No.", "No.");

                case "Document Type" of
                    "Document Type"::Order:
                        begin
                            ReasonType := OrderTxt;
                            ReasonNo := "No.";
                            ReasonData := "Order Date";
                        end;
                    "Document Type"::Invoice:
                        begin
                            ReasonType := InvoiceTxt;
                            ReasonNo := "No.";
                            ReasonData := "Posting Date";
                        end;
                    else begin
                        ReasonType := '';
                        ReasonNo := '';
                        ReasonData := 0D;
                    end;
                end;

                if "Agreement No." <> '' then begin
                    CustomerAgreement.Get("Bill-to Customer No.", "Agreement No.");
                    ReasonType := AgreementTxt;
                    ReasonNo := CustomerAgreement."External Agreement No.";
                    ReasonData := CustomerAgreement."Agreement Date";
                end;

                if AmountInvoiceCurrent = AmountInvoiceCurrent::LCY then begin
                    ReportCurrCode := '';
                    AddCondition := '';
                    CurrencyText := CurrencyTxt;
                end else begin
                    if "Currency Code" = '' then
                        CurrencyText := CurrencyTxt
                    else
                        CurrencyText := ForeignCurrencyTxt;
                    ReportCurrCode := "Currency Code";
                    if Currency.Get("Currency Code") then
                        AddCondition :=
                          CopyStr(
                            StrSubstNo(
                              Currency."Invoice Comment",
                              LowerCase(Currency.Description)),
                            1, MaxStrLen(AddCondition));
                end;

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
                        Caption = 'Currency';
                        OptionCaption = 'Invoice Currency,LCY';
                        ToolTip = 'Specifies the currency that amounts are shown in.';
                    }
                    field(ArchiveDocument; ArchiveDocument)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Save in Archive';
                        ToolTip = 'Specifies if you want to archive the related information. Archiving occurs when the report is printed.';
                    }
                    field(LogInteraction; LogInteraction)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Log Interaction';
                        ToolTip = 'Specifies that interactions with the related contact are logged.';
                    }
                    field(PrintWeightInfo; PrintWeightInfo)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Print Weight Information';
                        ToolTip = 'Specifies if you want to print shipping weight information.';
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
        if ReportFileName = '' then
            TORG12Helper.ExportData()
        else
            TORG12Helper.ExportDataToClientFile(ReportFileName);
    end;

    trigger OnPreReport()
    begin
        if not CurrReport.UseRequestPage then
            CopiesNumber := 1;

        TORG12Helper.InitReportTemplate();
    end;

    var
        CompanyInfo: Record "Company Information";
        Cust: Record Customer;
        SalesLine1: Record "Sales Line";
        SalesSetup: Record "Sales & Receivables Setup";
        CustomerAgreement: Record "Customer Agreement";
        Currency: Record Currency;
        LocMgt: Codeunit "Localisation Management";
        StdRepMgt: Codeunit "Local Report Management";
        NoSeriesBatch: Codeunit "No. Series - Batch";
        ArchiveManagement: Codeunit ArchiveManagement;
        SegManagement: Codeunit SegManagement;
        TORG12Helper: Codeunit "TORG-12 Report Helper";
        CopiesNumber: Integer;
        DocumentDate: Date;
        SerialNumbers: Integer;
        DocumentNo: Code[20];
        CurrentNo: Code[20];
        ReasonType: Text[30];
        ReasonNo: Text[30];
        ReasonData: Date;
        AddCondition: Text[250];
        AmountInvoiceDone: Option "Invoce Currency",LCY;
        AmountInvoiceCurrent: Option "Invoce Currency",LCY;
        ReportCurrCode: Code[10];
        OrderTxt: Label 'Order';
        InvoiceTxt: Label 'Bill';
        ArchiveDocument: Boolean;
        LogInteraction: Boolean;
        PrintWeightInfo: Boolean;
        AgreementTxt: Label 'Agreement';
        LineVATText: array[2] of Text[50];
        VATExemptTotal: Boolean;
        CurrencyTxt: Label 'rub. kop.';
        ForeignCurrencyTxt: Label 'u.e.';
        CurrencyText: Text[30];
        ObjectCode: Code[20];
        SerialNumbersText: Text;
        AtLeastOneLineExists: Boolean;
        PreviewReport: Boolean;
        ReportFileName: Text;

    local procedure ShipmentDocNo(): Code[20]
    begin
        if Header."Consignor No." <> '' then
            exit(DocumentNo);

        exit('');
    end;

    local procedure ShipmentDate(): Date
    begin
        if Header."Consignor No." <> '' then
            exit(DocumentDate);

        exit(0D);
    end;

    local procedure LineGrossWeight(): Text[30]
    begin
        if PrintWeightInfo then
            exit(Format(SalesLine1."Gross Weight" * SalesLine1."Qty. to Invoice"));

        exit('');
    end;

    local procedure TransferHeaderValues()
    var
        HeaderDetails: array[15] of Text;
    begin
        HeaderDetails[1] := DocumentNo;
        HeaderDetails[2] := Format(DocumentDate);
        HeaderDetails[3] :=
          StdRepMgt.GetConsignerInfo(Header."Consignor No.", Header."Responsibility Center");
        HeaderDetails[4] :=
          StdRepMgt.GetConsigneeInfo(Header, Header."Sell-to Customer No.");
        HeaderDetails[5] := StdRepMgt.GetCompanyName() + ' ' + StdRepMgt.GetLegalAddress() +
          StdRepMgt.GetCompanyPhoneFax() + StdRepMgt.GetCompanyBankAttrib();
        HeaderDetails[6] :=
          StdRepMgt.GetPayerInfo(Header, Header."Bill-to Customer No.", Header."Agreement No.");
        HeaderDetails[7] := LowerCase(ReasonType);
        HeaderDetails[8] := StdRepMgt.GetSalesConsignerOKPOCode(Header."Consignor No.");
        HeaderDetails[9] := StdRepMgt.GetCustOKPOCode(Header."Sell-to Customer No.");
        HeaderDetails[10] := CompanyInfo."OKPO Code";
        HeaderDetails[11] := StdRepMgt.GetCustOKPOCode(Header."Bill-to Customer No.");
        HeaderDetails[12] := ReasonNo;
        HeaderDetails[13] := ShipmentDocNo();
        HeaderDetails[14] := Format(ShipmentDate());

        HeaderDetails[15] := Format(ReasonData);

        TORG12Helper.FillHeader(HeaderDetails);
    end;

    local procedure TransferBodyValues(AmountValues: array[6] of Decimal)
    var
        BodyDetails: array[14] of Text;
    begin
        if CurrentNo <> '' then
            BodyDetails[2] := CurrentNo + ' ';
        BodyDetails[2] += SalesLine1.Description;

        if SalesLine1.Type <> SalesLine1.Type::" " then begin
            BodyDetails[1] := Format(SerialNumbers);
            BodyDetails[3] := ObjectCode;
            BodyDetails[4] := SalesLine1."Unit of Measure";
            BodyDetails[5] := StdRepMgt.GetOKEICode(SalesLine1."Unit of Measure Code");
            BodyDetails[6] := LineGrossWeight();
            BodyDetails[7] := Format(SalesLine1."Qty. to Invoice");
            BodyDetails[8] := StdRepMgt.FormatReportValue(SalesLine1."Unit Price", 2);
            BodyDetails[9] := StdRepMgt.FormatReportValue(SalesLine1.Amount, 2);
            BodyDetails[10] := LineVATText[1];
            BodyDetails[11] := LineVATText[2];
            BodyDetails[12] := StdRepMgt.FormatReportValue(SalesLine1."Amount Including VAT", 2);
        end;

        TORG12Helper.FillLine(BodyDetails, AmountValues);
    end;

    local procedure TransferAmounts(SalesLine: Record "Sales Line"; var AmountValues: array[6] of Decimal)
    begin
        AmountValues[1] := SalesLine.Amount;
        AmountValues[2] := SalesLine."Amount Including VAT" - SalesLine.Amount;
        AmountValues[3] := SalesLine."Amount Including VAT";
        AmountValues[4] := SalesLine."Qty. to Invoice";
        AmountValues[5] := SalesLine."Qty. to Invoice" * SalesLine."Gross Weight";
        AmountValues[6] := SalesLine."Qty. to Invoice" * SalesLine."Net Weight";
    end;

    local procedure TransferFooterValues()
    var
        FooterDetails: array[6] of Text;
    begin
        FooterDetails[1] := LowerCase(SerialNumbersText);
        FooterDetails[2] := ReportCurrCode;

        FooterDetails[3] :=
          StdRepMgt.GetReleasedByName(false, DATABASE::"Sales Header", Header."Document Type".AsInteger(), Header."No.");
        FooterDetails[4] :=
          StdRepMgt.GetAccountantName(false, DATABASE::"Sales Header", Header."Document Type".AsInteger(), Header."No.");
        FooterDetails[5] :=
          StdRepMgt.GetPassedByName(false, DATABASE::"Sales Header", Header."Document Type".AsInteger(), Header."No.");
        FooterDetails[6] := LocMgt.Date2Text(DocumentDate);

        TORG12Helper.FinishDocument(FooterDetails, VATExemptTotal, PrintWeightInfo);
    end;

    [Scope('OnPrem')]
    procedure InitializeRequest(FileName: Text; NewPreview: Boolean)
    begin
        ReportFileName := FileName;
        PreviewReport := NewPreview;
    end;
}

