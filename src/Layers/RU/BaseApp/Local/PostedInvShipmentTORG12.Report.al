#pragma warning disable AA0247
report 12413 "Posted Inv. Shipment TORG-12"
{
    Caption = 'Posted Inv. Shipment TORG-12';
    ProcessingOnly = true;

    dataset
    {
        dataitem(Header; "Sales Invoice Header")
        {
            DataItemTableView = sorting("No.");
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
                            if SalesLine1.Next(1) = 0 then begin
                                SerialNumbersText := LocMgt.Integer2Text(SerialNumbers, 1, '', '', '');
                                SerialNumbersText := LowerCase(CopyStr(SerialNumbersText, 1, 1)) + CopyStr(SerialNumbersText, 2);
                                CurrReport.Break();
                            end;

                        if SalesLine1.Type <> SalesLine1.Type::" " then begin
                            if SalesLine1.Quantity = 0 then
                                CurrReport.Skip();
                            SerialNumbers += 1;
                            if AmountInvoiceCurrent = AmountInvoiceCurrent::LCY then begin
                                SalesLine1.Amount := SalesLine1."Amount (LCY)";
                                SalesLine1."Amount Including VAT" := SalesLine1."Amount Including VAT (LCY)";
                            end;
                            SalesLine1."Unit Price" := Round(SalesLine1.Amount / SalesLine1.Quantity, Currency."Unit-Amount Rounding Precision");
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
                                CurrentNo := SalesLine1."No."
                            else
                                CurrentNo := '-';
                        end else
                            SalesLine1."No." := '';

                        if not AtLeastOneLineExists then begin
                            AtLeastOneLineExists := true;
                            TransferHeaderValues();
                            TORG12Helper.FillPageHeader(CurrencyText);
                        end;

                        TransferBodyValues(AmountValues);
                    end;

                    trigger OnPostDataItem()
                    begin
                        if AtLeastOneLineExists then
                            TransferFooterValues();
                    end;

                    trigger OnPreDataItem()
                    begin
                        SalesLine1.SetRange(Quantity);
                        if (AmountInvoiceCurrent = AmountInvoiceCurrent::"Invoice Currency") and (Header."Currency Code" <> '') then
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
                        CODEUNIT.Run(CODEUNIT::"Sales Inv.-Printed", Header);
                end;

                trigger OnPreDataItem()
                begin
                    SalesLine1.SetFilter(Quantity, '<>0');
                    if not SalesLine1.Find('-') then
                        CurrReport.Break();
                    SetRange(Number, 1, CopiesNumber);
                end;
            }

            trigger OnAfterGetRecord()
            begin
                CompanyInfo.Get();

                DocumentNo := "No.";
                DocumentDate := "Document Date";
                SerialNumbers := 0;

                Cust.Get("Bill-to Customer No.");

                AmountInvoiceCurrent := AmountInvoiceDone;
                if "Currency Code" = '' then
                    AmountInvoiceCurrent := AmountInvoiceCurrent::LCY;

                SalesLine1.Reset();
                SalesLine1.SetRange("Document No.", "No.");

                ReasonType := '';
                ReasonNo := '';
                ReasonData := 0D;
                if "Order No." <> '' then begin
                    ReasonType := OrderTxt;
                    ReasonNo := "Order No.";
                    ReasonData := "Order Date";
                end else
                    if "Pre-Assigned No." <> '' then begin
                        ReasonType := BillTxt;
                        ReasonNo := "Pre-Assigned No.";
                        ReasonData := "Posting Date";
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
                        CurrencyText := ForeignTxt;
                    ReportCurrCode := "Currency Code";
                    if not Currency.Get("Currency Code") then
                        Currency.Description := DollarUSATxt;
                    AddCondition :=
                      CopyStr(
                        StrSubstNo(
                          AddConditionCurrency,
                          LowerCase(Currency.Description)),
                        1, MaxStrLen(AddCondition));
                end;

                if BillCust.Get("Bill-to Customer No.") then;

                if LogInteraction then
                    if not PreviewReport then
                        if "Bill-to Contact No." <> '' then
                            SegManagement.LogDocument(
                              4, "No.", 0, 0, DATABASE::Contact, "Bill-to Contact No.", "Salesperson Code",
                              "Campaign No.", "Posting Description", '')
                        else
                            SegManagement.LogDocument(
                              4, "No.", 0, 0, DATABASE::Customer, "Bill-to Customer No.", "Salesperson Code",
                              "Campaign No.", "Posting Description", '');
            end;

            trigger OnPreDataItem()
            begin
                SalesSetup.Get();
                AddConditionCurrency := ConvertStr(SalesSetup."Invoice Comment", '\', ' ');
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
        DollarUSATxt: Label 'USD';
        CompanyInfo: Record "Company Information";
        Cust: Record Customer;
        SalesLine1: Record "Sales Invoice Line";
        SalesSetup: Record "Sales & Receivables Setup";
        CustomerAgreement: Record "Customer Agreement";
        Currency: Record Currency;
        BillCust: Record Customer;
        LocMgt: Codeunit "Localisation Management";
        StdRepMgt: Codeunit "Local Report Management";
        SegManagement: Codeunit SegManagement;
        TORG12Helper: Codeunit "TORG-12 Report Helper";
        CopiesNumber: Integer;
        DocumentDate: Date;
        SerialNumbers: Integer;
        DocumentNo: Code[20];
        SerialNumbersText: Text[250];
        CurrentNo: Code[20];
        ReasonType: Text[30];
        ReasonNo: Text[30];
        ReasonData: Date;
        AddCondition: Text[250];
        AddConditionCurrency: Text[250];
        AmountInvoiceDone: Option "Invoice Currency",LCY;
        AmountInvoiceCurrent: Option "Invoice Currency",LCY;
        ReportCurrCode: Code[10];
        OrderTxt: Label 'Order';
        BillTxt: Label 'Bill';
        LogInteraction: Boolean;
        PrintWeightInfo: Boolean;
        AgreementTxt: Label 'Agreement';
        LineVATText: array[2] of Text[50];
        VATExemptTotal: Boolean;
        CurrencyTxt: Label 'rub. kop.';
        ForeignTxt: Label 'u.e.';
        CurrencyText: Text[30];
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
            exit(Format(SalesLine1."Gross Weight" * SalesLine1.Quantity));

        exit('');
    end;

    local procedure TransferHeaderValues()
    var
        HeaderDetails: array[15] of Text;
    begin
        HeaderDetails[1] := DocumentNo;
        HeaderDetails[2] := Format(DocumentDate);
        HeaderDetails[3] := StdRepMgt.GetConsignerInfo(Header."Consignor No.", Header."Responsibility Center");
        HeaderDetails[4] := StdRepMgt.GetConsigneeInfo(Header, Header."Sell-to Customer No.");
        HeaderDetails[5] := StdRepMgt.GetCompanyName() + ' ' + StdRepMgt.GetLegalAddress() +
          StdRepMgt.GetCompanyPhoneFax() + StdRepMgt.GetCompanyBankAttrib();
        HeaderDetails[6] := StdRepMgt.GetPayerInfo(Header, Header."Bill-to Customer No.", Header."Agreement No.");
        HeaderDetails[7] := ReasonType;
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
        BodyDetails[2] := SalesLine1.Description;

        if SalesLine1.Type <> SalesLine1.Type::" " then begin
            BodyDetails[1] := Format(SerialNumbers);
            BodyDetails[3] := CurrentNo;
            BodyDetails[4] := SalesLine1."Unit of Measure";
            BodyDetails[5] := StdRepMgt.GetOKEICode(SalesLine1."Unit of Measure Code");
            BodyDetails[6] := LineGrossWeight();
            BodyDetails[7] := Format(SalesLine1.Quantity);
            BodyDetails[8] := StdRepMgt.FormatReportValue(SalesLine1."Unit Price", 2);
            BodyDetails[9] := StdRepMgt.FormatReportValue(SalesLine1.Amount, 2);
            BodyDetails[10] := LineVATText[1];
            BodyDetails[11] := LineVATText[2];
            BodyDetails[12] := StdRepMgt.FormatReportValue(SalesLine1."Amount Including VAT", 2);
        end;

        TORG12Helper.FillLine(BodyDetails, AmountValues);
    end;

    local procedure TransferAmounts(SalesLine: Record "Sales Invoice Line"; var AmountValues: array[6] of Decimal)
    begin
        AmountValues[1] := SalesLine.Amount;
        AmountValues[2] := SalesLine."Amount Including VAT" - SalesLine.Amount;
        AmountValues[3] := SalesLine."Amount Including VAT";
        AmountValues[4] := SalesLine.Quantity;
        AmountValues[5] := SalesLine.Quantity * SalesLine."Gross Weight";
        AmountValues[6] := SalesLine.Quantity * SalesLine."Net Weight";
    end;

    [Scope('OnPrem')]
    procedure TransferFooterValues()
    var
        FooterDetails: array[6] of Text;
    begin
        FooterDetails[1] := SerialNumbersText;
        FooterDetails[2] := ReportCurrCode;

        FooterDetails[3] := StdRepMgt.GetReleasedByName(true, DATABASE::"Sales Invoice Header", 0, Header."No.");
        FooterDetails[4] := StdRepMgt.GetAccountantName(true, DATABASE::"Sales Invoice Header", 0, Header."No.");
        FooterDetails[5] := StdRepMgt.GetPassedByName(true, DATABASE::"Sales Invoice Header", 0, Header."No.");
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

