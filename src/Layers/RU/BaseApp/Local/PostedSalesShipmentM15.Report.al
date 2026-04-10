#pragma warning disable AA0247
report 12473 "Posted Sales Shipment M-15"
{
    Caption = 'Posted Sales Shipment M-15';
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
                    begin
                        if Number = 1 then begin
                            if not SalesLine1.Find('-') then
                                CurrReport.Break();
                        end else
                            if SalesLine1.Next(1) = 0 then
                                CurrReport.Break();

                        CopyArray(LastTotalAmount, TotalAmount, 1);

                        if SalesLine1.Quantity = 0 then
                            CurrReport.Skip();
                        SalesLine1.Amount := SalesLine1."Amount (LCY)";
                        SalesLine1."Amount Including VAT" := SalesLine1."Amount Including VAT (LCY)";
                        SalesLine1."Unit Price" :=
                          Round(SalesLine1.Amount / SalesLine1.Quantity, Currency."Unit-Amount Rounding Precision");
                        IncrAmount(SalesLine1);

                        if StdRepMgt.VATExemptLine(SalesLine1."VAT Bus. Posting Group", SalesLine1."VAT Prod. Posting Group") then
                            StdRepMgt.FormatVATExemptLine(LineVATText[1], LineVATText[2])
                        else
                            LineVATText[2] :=
                              StdRepMgt.FormatReportValue(SalesLine1."Amount Including VAT" - SalesLine1.Amount, 2);

                        InvPostingSetup.Reset();
                        InvPostingSetup.SetRange("Location Code", SalesLine1."Location Code");
                        InvPostingSetup.SetRange("Invt. Posting Group Code", SalesLine1."Posting Group");
                        if InvPostingSetup.FindFirst() then
                            BalAccNo := InvPostingSetup."Inventory Account"
                        else
                            BalAccNo := '';

                        FillBody();
                    end;

                    trigger OnPostDataItem()
                    begin
                        FillReportFooter();
                    end;

                    trigger OnPreDataItem()
                    begin
                        Currency.InitRoundingPrecision();
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    Clear(TotalAmount);

                    FillReportHeader();
                    FillPageHeader();
                end;

                trigger OnPostDataItem()
                begin
                    if not CurrReport.Preview then
                        CODEUNIT.Run(CODEUNIT::"Sales Inv.-Printed", Header);
                end;

                trigger OnPreDataItem()
                begin
                    if not SalesLine1.Find('-') then
                        CurrReport.Break();

                    if not CurrReport.UseRequestPage then
                        CopiesNumber := 1;
                    SetRange(Number, 1, CopiesNumber);
                end;
            }

            trigger OnAfterGetRecord()
            begin
                CompanyInfo.Get();

                SalesLine1.Reset();
                SalesLine1.SetRange("Document No.", "No.");
                SalesLine1.SetFilter(Type, '<>%1', SalesLine1.Type::" ");

                LineCount := SalesLine1.Count();

                CheckSignature(PassedBy, PassedBy."Employee Type"::PassedBy);
                CheckSignature(ApprovedBy, PassedBy."Employee Type"::Responsible);
                CheckSignature(ReleasedBy, ReleasedBy."Employee Type"::ReleasedBy);
                CheckSignature(ReceivedBy, ReceivedBy."Employee Type"::ReceivedBy);

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
                    field(OperationType; OperationType)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Operation Type';
                        ToolTip = 'Specifies the type of the related operation, for the purpose of VAT reporting.';
                    }
                    field(Reason; Reason)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Reason';
                        MultiLine = true;
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
        if FileName <> '' then
            SalesShipmentM15Helper.ExportDataFile(FileName)
        else
            SalesShipmentM15Helper.ExportData();
    end;

    trigger OnPreReport()
    begin
        SalesShipmentM15Helper.InitM15Report();
    end;

    var
        CompanyInfo: Record "Company Information";
        InvPostingSetup: Record "Inventory Posting Setup";
        SalesLine1: Record "Sales Invoice Line";
        PassedBy: Record "Posted Document Signature";
        ApprovedBy: Record "Posted Document Signature";
        ReleasedBy: Record "Posted Document Signature";
        ReceivedBy: Record "Posted Document Signature";
        Currency: Record Currency;
        LocMgt: Codeunit "Localisation Management";
        StdRepMgt: Codeunit "Local Report Management";
        DocSignMgt: Codeunit "Doc. Signature Management";
        SegManagement: Codeunit SegManagement;
        SalesShipmentM15Helper: Codeunit "Sales Shipment M-15 Helper";
        BalAccNo: Code[20];
        OperationType: Text[30];
        Reason: Text[250];
        FileName: Text;
        LineCount: Integer;
        LogInteraction: Boolean;
        CopiesNumber: Integer;
        TotalAmount: array[8] of Decimal;
        LastTotalAmount: array[8] of Decimal;
        LineVATText: array[2] of Text[50];

    [Scope('OnPrem')]
    procedure CheckSignature(var PostedDocSign: Record "Posted Document Signature"; EmpType: Integer)
    begin
        DocSignMgt.GetPostedDocSign(
          PostedDocSign, DATABASE::"Sales Invoice Header",
          0, Header."No.", EmpType, false);
    end;

    [Scope('OnPrem')]
    procedure IncrAmount(SalesLine2: Record "Sales Invoice Line")
    begin
        TotalAmount[1] := TotalAmount[1] + SalesLine2.Amount;
        TotalAmount[2] := TotalAmount[2] + SalesLine2."Amount Including VAT" - SalesLine2.Amount;
        TotalAmount[3] := TotalAmount[3] + SalesLine2."Amount Including VAT";
        TotalAmount[4] := TotalAmount[4] + SalesLine2.Quantity;
    end;

    [Scope('OnPrem')]
    procedure SetFileNameSilent(NewFileName: Text)
    begin
        FileName := NewFileName;
    end;

    local procedure FillReportHeader()
    var
        ReportHeaderArr: array[15] of Text;
    begin
        ReportHeaderArr[1] := Header."No.";
        ReportHeaderArr[2] := StdRepMgt.GetCompanyName();
        ReportHeaderArr[3] := CompanyInfo."OKPO Code";
        ReportHeaderArr[4] := Format(Header."Shipment Date");
        ReportHeaderArr[5] := OperationType;
        ReportHeaderArr[6] := Header."Location Code";
        ReportHeaderArr[8] := Header."Sell-to Customer No.";
        ReportHeaderArr[13] := Reason;
        ReportHeaderArr[14] := Header."Ship-to Name";
        ReportHeaderArr[15] := PassedBy."Employee Name";

        SalesShipmentM15Helper.FillM15ReportHeader(ReportHeaderArr);
    end;

    local procedure FillPageHeader()
    begin
        SalesShipmentM15Helper.FillM15PageHeader();
    end;

    local procedure FillBody()
    var
        ReportBodyArr: array[15] of Text;
    begin
        ReportBodyArr[1] := BalAccNo;
        ReportBodyArr[3] := SalesLine1.Description;
        ReportBodyArr[4] := SalesLine1."No.";
        ReportBodyArr[5] := SalesLine1."Unit of Measure Code";
        ReportBodyArr[6] := SalesLine1."Unit of Measure";
        ReportBodyArr[7] := Format(SalesLine1.Quantity);
        ReportBodyArr[9] := FormatAmount(SalesLine1."Unit Price");
        ReportBodyArr[10] := FormatAmount(SalesLine1.Amount);
        ReportBodyArr[11] := LineVATText[2];
        ReportBodyArr[12] := FormatAmount(SalesLine1."Amount Including VAT");

        SalesShipmentM15Helper.FillM15Body(ReportBodyArr);
    end;

    local procedure FillReportFooter()
    var
        ReportFooterArr: array[12] of Text;
        TotalIntAmount: Decimal;
    begin
        ReportFooterArr[1] := LocMgt.Integer2Text(LineCount, 2, '', '', '');
        TotalIntAmount := Round(TotalAmount[3], 1, '<');
        ReportFooterArr[2] := LocMgt.Integer2Text(TotalIntAmount, 0, '', '', '');
        ReportFooterArr[3] := LocMgt.Integer2Text((TotalAmount[3] - TotalIntAmount) * 100, 0, '', '', '');
        TotalIntAmount := Round(TotalAmount[2], 1, '<');
        ReportFooterArr[4] := LocMgt.Integer2Text(TotalIntAmount, 0, '', '', '');
        ReportFooterArr[5] := LocMgt.Integer2Text((TotalAmount[2] - TotalIntAmount) * 100, 0, '', '', '');

        ReportFooterArr[6] := ApprovedBy."Employee Job Title";
        ReportFooterArr[7] := ApprovedBy."Employee Name";
        ReportFooterArr[8] := StdRepMgt.GetAccountantName(true, 112, 0, Header."No.");
        ReportFooterArr[9] := ReleasedBy."Employee Job Title";
        ReportFooterArr[10] := ReleasedBy."Employee Name";
        ReportFooterArr[11] := ReceivedBy."Employee Job Title";
        ReportFooterArr[12] := ReceivedBy."Employee Name";

        SalesShipmentM15Helper.FillM15ReportFooter(ReportFooterArr);
    end;

    local procedure FormatAmount(Amount: Decimal): Text
    begin
        exit(StdRepMgt.FormatReportValue(Amount, 2));
    end;
}

