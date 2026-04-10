#pragma warning disable AA0247
report 12483 "Posted Purchase Receipt M-4"
{
    Caption = 'Posted Purchase Receipt M-4';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Purch. Inv. Header"; "Purch. Inv. Header")
        {
            dataitem("G/L Account Net Change"; "G/L Account Net Change")
            {
                trigger OnAfterGetRecord()
                begin
                    if "No." <> AccNo then
                        InventoryReportsHelper.FillM4BodyInv("No.");
                end;
            }
            dataitem("Purch. Inv. Line"; "Purch. Inv. Line")
            {
                DataItemLink = "Document No." = field("No.");
                DataItemTableView = sorting("Document No.", "Line No.");

                trigger OnAfterGetRecord()
                begin
                    if "Purch. Inv. Header"."Currency Code" <> '' then begin
                        Amount := Round(Amount / CurrencyFactor, Currency."Amount Rounding Precision");
                        "Amount Including VAT" := Round("Amount Including VAT" / CurrencyFactor, Currency."Amount Rounding Precision");
                    end;

                    if (Type <> Type::" ") and (Quantity <> 0) then
                        UnitCost := Round(Amount / Quantity, 0.00001);
                    TotalAmount += "Amount (LCY)";
                    TotalAmountInclVAT += "Amount Including VAT (LCY)";

                    if StdRepMgt.VATExemptLine("VAT Bus. Posting Group", "VAT Prod. Posting Group") then
                        StdRepMgt.FormatVATExemptLine(LineVATText[1], LineVATText[2])
                    else begin
                        VATExemptTotal := false;
                        LineVATText[2] :=
                          StdRepMgt.FormatReportValue("Amount Including VAT (LCY)" - "Amount (LCY)", 2);
                    end;

                    if Type <> Type::" " then
                        TotalQtyToReceive := TotalQtyToReceive + Quantity;

                    FillBody();
                end;

                trigger OnPostDataItem()
                begin
                    FormatTotalAmounts();

                    FillReportFooter();
                end;

                trigger OnPreDataItem()
                begin
                    VATExemptTotal := true;

                    InventoryReportsHelper.FillM4PageHeader();
                end;
            }

            trigger OnAfterGetRecord()
            begin
                TempGLAccountNetChange.DeleteAll();
                AccNo := '';
                CompanyInfo.Get();

                PurchInvLine.Reset();
                PurchInvLine.SetRange("Document No.", "Purch. Inv. Header"."No.");
                if PurchInvLine.FindSet() then
                    repeat
                        case PurchInvLine.Type of
                            PurchInvLine.Type::"G/L Account":
                                InventoryReportsHelper.InsertGLAccount(TempGLAccountNetChange, PurchInvLine."No.", AccNo);
                            PurchInvLine.Type::Item:
                                begin
                                    InvPostingSetup.Get("Location Code", PurchInvLine."Posting Group");
                                    InventoryReportsHelper.InsertGLAccount(TempGLAccountNetChange, InvPostingSetup."Inventory Account (Interim)", AccNo);
                                end;
                            PurchInvLine.Type::"Charge (Item)":
                                begin
                                    GeneralPostingSetup.Get("Gen. Bus. Posting Group", PurchInvLine."Gen. Prod. Posting Group");
                                    InventoryReportsHelper.InsertGLAccount(TempGLAccountNetChange, GeneralPostingSetup."Purch. Account", AccNo);
                                end;
                            PurchInvLine.Type::"Fixed Asset":
                                begin
                                    PurchInvLine.TestField("Depreciation Book Code");
                                    FADepreciationBook.Get(PurchInvLine."No.", PurchInvLine."Depreciation Book Code");
                                    FAPostingGroup.Get(FADepreciationBook."FA Posting Group");
                                    InventoryReportsHelper.InsertGLAccount(TempGLAccountNetChange, FAPostingGroup."Acquisition Cost Account", AccNo);
                                end;
                            PurchInvLine.Type::"Empl. Purchase":
                                begin
                                    VendPostingGroup.Get("Vendor Posting Group");
                                    InventoryReportsHelper.InsertGLAccount(TempGLAccountNetChange, VendPostingGroup."Payables Account", AccNo);
                                end;
                        end;
                    until PurchInvLine.Next() = 0;

                if "Currency Code" <> '' then
                    Currency.Get("Currency Code")
                else
                    Currency.InitRoundingPrecision();

                CurrencyFactor := "Currency Factor";
                if CurrencyFactor = 0 then
                    CurrencyFactor := 1;

                CheckSignature(ReleasedBy, ReleasedBy."Employee Type"::ReleasedBy);
                CheckSignature(ReceivedBy, ReceivedBy."Employee Type"::ReceivedBy);

                FillReportTitle();
            end;
        }
    }

    requestpage
    {

        layout
        {
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnPostReport()
    begin
        if FileName <> '' then
            InventoryReportsHelper.ExportDataFile(FileName)
        else
            InventoryReportsHelper.ExportData();
    end;

    trigger OnPreReport()
    begin
        InitReportTemplate();
    end;

    var
        CompanyInfo: Record "Company Information";
        GeneralPostingSetup: Record "General Posting Setup";
        InvPostingSetup: Record "Inventory Posting Setup";
        PurchInvLine: Record "Purch. Inv. Line";
        FADepreciationBook: Record "FA Depreciation Book";
        FAPostingGroup: Record "FA Posting Group";
        VendPostingGroup: Record "Vendor Posting Group";
        ReleasedBy: Record "Posted Document Signature";
        ReceivedBy: Record "Posted Document Signature";
        Currency: Record Currency;
        TempGLAccountNetChange: Record "G/L Account Net Change" temporary;
        StdRepMgt: Codeunit "Local Report Management";
        DocSignMgt: Codeunit "Doc. Signature Management";
        InventoryReportsHelper: Codeunit "Purchase Receipt M-4 Helper";
        AccNo: Code[20];
        CurrencyFactor: Decimal;
        TotalAmount: Decimal;
        TotalAmountInclVAT: Decimal;
        UnitCost: Decimal;
        LineVATText: array[2] of Text[50];
        TotalVATAmountText: Text[50];
        FileName: Text;
        VATExemptTotal: Boolean;
        TotalQtyToReceive: Decimal;

    [Scope('OnPrem')]
    procedure CheckSignature(var PostedDocSign: Record "Posted Document Signature"; EmpType: Integer)
    begin
        DocSignMgt.GetPostedDocSign(
          PostedDocSign, DATABASE::"Purch. Inv. Header",
          0, "Purch. Inv. Header"."No.", EmpType, false);
    end;

    [Scope('OnPrem')]
    procedure FormatTotalAmounts()
    begin
        if VATExemptTotal then
            TotalVATAmountText := '-'
        else
            TotalVATAmountText := StdRepMgt.FormatReportValue(TotalAmountInclVAT - TotalAmount, 2);
    end;

    [Scope('OnPrem')]
    procedure InitReportTemplate()
    begin
        InventoryReportsHelper.InitM4Report();
    end;

    [Scope('OnPrem')]
    procedure SetFileNameSilent(NewFileName: Text)
    begin
        FileName := NewFileName;
    end;

    local procedure FillReportTitle()
    var
        ReportHeaderArr: array[10] of Text;
    begin
        ReportHeaderArr[1] := StdRepMgt.GetCompanyName();
        ReportHeaderArr[2] := ReceivedBy."Employee Org. Unit";
        ReportHeaderArr[3] := CompanyInfo."OKPO Code";
        ReportHeaderArr[4] := "Purch. Inv. Header"."No.";
        ReportHeaderArr[5] := Format("Purch. Inv. Header"."Document Date");
        ReportHeaderArr[6] := "Purch. Inv. Header"."Location Code";
        ReportHeaderArr[7] := StdRepMgt.GetVendorName("Purch. Inv. Header"."Buy-from Vendor No.");
        ReportHeaderArr[8] := "Purch. Inv. Header"."Buy-from Vendor No.";
        ReportHeaderArr[9] := AccNo;
        ReportHeaderArr[10] := "Purch. Inv. Header"."Vendor Invoice No.";

        InventoryReportsHelper.FillM4ReportTitle(ReportHeaderArr);
    end;

    [Scope('OnPrem')]
    procedure FillBody()
    var
        PageHeaderArr: array[10] of Text;
    begin
        PageHeaderArr[1] := "Purch. Inv. Line".Description + "Purch. Inv. Line"."Description 2";
        PageHeaderArr[2] := "Purch. Inv. Line"."No.";
        PageHeaderArr[3] := "Purch. Inv. Line"."Unit of Measure Code";
        PageHeaderArr[4] := "Purch. Inv. Line"."Unit of Measure";
        PageHeaderArr[5] := Format("Purch. Inv. Line".Quantity);
        PageHeaderArr[6] := Format("Purch. Inv. Line".Quantity);
        PageHeaderArr[7] := FormatAmount(UnitCost);
        PageHeaderArr[8] := FormatAmount("Purch. Inv. Line".Amount);
        PageHeaderArr[9] := LineVATText[2];
        PageHeaderArr[10] := FormatAmount("Purch. Inv. Line"."Amount Including VAT");

        InventoryReportsHelper.FillM4Body(PageHeaderArr);
    end;

    local procedure FillReportFooter()
    var
        ReportFooterArr: array[8] of Text;
    begin
        ReportFooterArr[1] := Format(TotalQtyToReceive);
        ReportFooterArr[2] := FormatAmount(TotalAmount);
        ReportFooterArr[3] := TotalVATAmountText;
        ReportFooterArr[4] := FormatAmount(TotalAmountInclVAT);
        ReportFooterArr[5] := ReceivedBy."Employee Job Title";
        ReportFooterArr[6] := ReceivedBy."Employee Name";
        ReportFooterArr[7] := ReleasedBy."Employee Job Title";
        ReportFooterArr[8] := ReleasedBy."Employee Name";

        InventoryReportsHelper.FillM4ReportFooter(ReportFooterArr);
    end;

    local procedure FormatAmount(Amount: Decimal): Text
    begin
        exit(StdRepMgt.FormatReportValue(Amount, 2));
    end;
}

