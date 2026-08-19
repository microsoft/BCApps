#pragma warning disable AA0247
report 12420 "Posted Inv. Item Waybill 1-T"
{
    Caption = 'Posted Inv. Item Waybill 1-T';
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
                        LineValues: array[9] of Text;
                    begin
                        if Number = 1 then begin
                            if not SalesLine1.Find('-') then
                                CurrReport.Break();
                        end else
                            if SalesLine1.Next(1) = 0 then
                                CurrReport.Break();

                        if SalesLine1.Type <> SalesLine1.Type::" " then begin
                            if SalesLine1.Quantity = 0 then
                                CurrReport.Skip();
                            SalesLine1."Amount Including VAT" := SalesLine1."Amount Including VAT (LCY)";
                            SalesLine1."Unit Price" :=
                              Round(SalesLine1."Amount Including VAT" / SalesLine1.Quantity,
                                Currency."Unit-Amount Rounding Precision");
                            TotalAmount := TotalAmount + SalesLine1."Amount Including VAT";
                        end;

                        if SalesLine1.Type = SalesLine1.Type::Item then begin
                            Item.Get(SalesLine1."No.");
                            ProductionCode := Item."No.";
                            TotalQty += SalesLine1.Quantity;
                            AmountLineNo := AmountLineNo + 1;
                        end else
                            if SalesLine1.Type = SalesLine1.Type::" " then
                                ProductionCode := ''
                            else begin
                                AmountLineNo := AmountLineNo + 1;
                                ProductionCode := SalesLine1."No.";
                                QtyNotItem += SalesLine1.Quantity;
                            end;

                        if SalesLine1.Type <> SalesLine1.Type::" " then
                            TransferLineValues(LineValues, SalesLine1)
                        else
                            WaybillReportHelper.TransferLineDescrValues(LineValues, SalesLine1.Description);

                        FillBody(LineValues);
                    end;

                    trigger OnPostDataItem()
                    var
                    begin
                        if QtyNotItem < 1 then
                            AddendumSheets := ''
                        else
                            AddendumSheets := LocMgt.Integer2Text(QtyNotItem, 1, '', '', '');

                        FillFooter();
                    end;

                    trigger OnPreDataItem()
                    begin
                        Currency.InitRoundingPrecision();

                        FillProlog();
                    end;
                }
                dataitem("Back Side"; "Integer")
                {
                    DataItemTableView = sorting(Number);
                    MaxIteration = 1;

                    trigger OnAfterGetRecord()
                    begin
                        FillBackSide();
                    end;

                    trigger OnPreDataItem()
                    begin
                        if not BackSideNecessary then
                            CurrReport.Break();
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    TotalAmount := 0;
                    AmountLineNo := 0;
                    QtyNotItem := 0;
                end;

                trigger OnPostDataItem()
                begin
                    if not CurrReport.Preview then
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

                DocumentDate := "Posting Date";
                DocNo := "No.";

                if not ShipmentMethod.Get("Shipment Method Code") then
                    ShipmentMethod.Init();

                if not PaymentTerms.Get("Payment Terms Code") then
                    PaymentTerms.Init();

                Cust.Get("Bill-to Customer No.");

                ShowDiscount := false;

                SalesLine1.Reset();
                SalesLine1.SetRange("Document No.", "No.");

                if LogInteraction then
                    if not CurrReport.Preview then
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
                CheckPrintOneDocument(Header);
                WaybillReportHelper.SetMainSheet();
            end;
        }
    }

    requestpage
    {
        PopulateAllFields = true;
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
                    field(BackSideNecessary; BackSideNecessary)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Back Side Necessary';
                        ToolTip = 'Specifies if the waybill is double-sided.';
                    }
                    field(LogInteraction; LogInteraction)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Log Interaction';
                        ToolTip = 'Specifies that interactions with the related contact are logged.';
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
        if FileName = '' then
            WaybillReportHelper.ExportData()
        else
            WaybillReportHelper.ExportDataFile(FileName);
    end;

    trigger OnPreReport()
    begin
        if not CurrReport.UseRequestPage then
            CopiesNumber := 1;

        WaybillReportHelper.InitWaybillReportTmpl();
    end;

    var
        ShipmentMethod: Record "Shipment Method";
        PaymentTerms: Record "Payment Terms";
        CompanyInfo: Record "Company Information";
        Cust: Record Customer;
        SalesLine1: Record "Sales Invoice Line";
        Item: Record Item;
        Currency: Record Currency;
        SegManagement: Codeunit SegManagement;
        LocMgt: Codeunit "Localisation Management";
        StdRepMgt: Codeunit "Local Report Management";
        WaybillReportHelper: Codeunit "Waybill 1-T Report Helper";
        ShowDiscount: Boolean;
        TotalAmount: Decimal;
        TotalQty: Decimal;
        CopiesNumber: Integer;
        AmountLineNo: Integer;
        DocumentDate: Date;
        DocNo: Code[20];
        ProductionCode: Text[20];
        QtyNotItem: Decimal;
        AddendumSheets: Text[80];
        BackSideNecessary: Boolean;
        LogInteraction: Boolean;
        IncorrectNumberErr: Label 'Please select only one document.';
        FileName: Text;

    local procedure CheckPrintOneDocument(var SalesHeader: Record "Sales Invoice Header")
    var
        SalesHeader2: Record "Sales Invoice Header";
    begin
        // Do not allow to print a bunch of documents.
        SalesHeader2.CopyFilters(SalesHeader);
        if SalesHeader2.Count <> 1 then
            Error(IncorrectNumberErr);
    end;

    local procedure TransferHeaderValues(var HeaderValue: array[8] of Text)
    begin
        HeaderValue[1] := DocNo;
        HeaderValue[2] := LocMgt.Date2Text(DocumentDate);
        HeaderValue[3] := CompanyInfo."OKPO Code";
        HeaderValue[4] := '';
        HeaderValue[5] := '';
        HeaderValue[6] := StdRepMgt.GetCompanyName() + '. ' + StdRepMgt.GetLegalAddress();
        HeaderValue[7] :=
          StdRepMgt.GetShipToAddrName(
            Header."Sell-to Customer No.", Header."Ship-to Code", Header."Ship-to Name", Header."Ship-to Name 2") + '  ' +
          Header."Ship-to City" + ' ' + Header."Ship-to Address" + ' ' + Header."Ship-to Address 2";
        HeaderValue[8] :=
          StdRepMgt.GetCustName(Header."Bill-to Customer No.") + '  ' + Header."Bill-to City" + ' ' +
          Header."Bill-to Address" + ' ' + Header."Bill-to Address 2";
    end;

    local procedure TransferLineValues(var LineValues: array[9] of Text; SalesLine: Record "Sales Invoice Line")
    begin
        LineValues[1] := ProductionCode;
        LineValues[2] := StdRepMgt.FormatReportValue(SalesLine.Quantity, 2);
        LineValues[3] := StdRepMgt.FormatReportValue(SalesLine."Unit Price", 2);
        LineValues[4] := SalesLine.Description;
        LineValues[5] := StdRepMgt.FormatTextValue(SalesLine."Unit of Measure");
        LineValues[6] := '';
        LineValues[7] := '';
        LineValues[8] := '';
        LineValues[9] := StdRepMgt.FormatReportValue(SalesLine."Amount Including VAT", 2);
    end;

    local procedure TransferFooterValues(var FooterValue: array[12] of Text)
    begin
        FooterValue[1] := LocMgt.Integer2Text(AmountLineNo, 1, '', '', '');
        FooterValue[2] := LocMgt.Integer2Text(AmountLineNo, 2, '', '', '');
        FooterValue[3] := StdRepMgt.FormatReportValue(TotalAmount, 2);
        FooterValue[4] := '';
        FooterValue[5] := AddendumSheets;
        FooterValue[6] := '';
        FooterValue[7] := LocMgt.Amount2Text('', TotalAmount);
        FooterValue[8] := '';
        FooterValue[9] := LocMgt.Date2Text(Header."Posting Date");
        FooterValue[10] := '';
        FooterValue[11] := '';
        FooterValue[12] := '';
    end;

    local procedure FillProlog()
    var
        HeaderValue: array[8] of Text;
    begin
        TransferHeaderValues(HeaderValue);
        WaybillReportHelper.FillProlog(HeaderValue);
    end;

    [Scope('OnPrem')]
    procedure FillBody(LineValues: array[9] of Text)
    begin
        WaybillReportHelper.FillBody(LineValues);
    end;

    local procedure FillFooter()
    var
        FooterValues: array[12] of Text;
    begin
        TransferFooterValues(FooterValues);
        WaybillReportHelper.FinalizeReport(FooterValues);
    end;

    local procedure FillBackSide()
    begin
        WaybillReportHelper.FillBackSide(DocNo);
    end;

    [Scope('OnPrem')]
    procedure SetFileNameSilent(NewFileName: Text)
    begin
        FileName := NewFileName;
    end;
}

