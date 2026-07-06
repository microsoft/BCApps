#pragma warning disable AA0247
report 12475 "Purchase Receipt M-4"
{
    Caption = 'Purchase Receipt M-4';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Purchase Header"; "Purchase Header")
        {
            dataitem("G/L Account Net Change"; "G/L Account Net Change")
            {
                trigger OnAfterGetRecord()
                begin
                    if "No." <> AccNo then
                        InventoryReportsHelper.FillM4BodyInv("No.");
                end;
            }
            dataitem("Purchase Line"; "Purchase Line")
            {
                DataItemLink = "Document Type" = field("Document Type"), "Document No." = field("No.");
                DataItemTableView = sorting("Document Type", "Document No.", "Line No.");

                trigger OnAfterGetRecord()
                begin
                    UnitCost := 0;
                    if (Type <> Type::" ") and (Quantity <> 0) then
                        UnitCost := Round(Amount / Quantity, 0.00001);

                    if PurchLineWithLCYAmt.Get("Document Type", "Document No.", "Line No.") then begin
                        if PurchLineWithLCYAmt.Quantity <> 0 then
                            UnitCost := PurchLineWithLCYAmt.Amount / PurchLineWithLCYAmt.Quantity;

                        Amount := PurchLineWithLCYAmt.Amount;
                        "Amount Including VAT" := PurchLineWithLCYAmt."Amount Including VAT";
                    end;

                    if StdRepMgt.VATExemptLine("VAT Bus. Posting Group", "VAT Prod. Posting Group") then
                        StdRepMgt.FormatVATExemptLine(LineVATText[1], LineVATText[2])
                    else begin
                        VATExemptTotal := false;
                        LineVATText[2] :=
                          StdRepMgt.FormatReportValue("Amount Including VAT" - Amount, 2);
                    end;

                    if Type <> Type::" " then
                        TotalQtyToReceive := TotalQtyToReceive + "Qty. to Receive";

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
                GLAccountNetChange.DeleteAll();
                AccNo := '';
                CompanyInfo.Get();

                PurchLine.Reset();
                PurchLine.SetRange("Document No.", "Purchase Header"."No.");
                if PurchLine.FindSet() then
                    repeat
                        case PurchLine.Type of
                            PurchLine.Type::"G/L Account":
                                InventoryReportsHelper.InsertGLAccount(GLAccountNetChange, PurchLine."No.", AccNo);
                            PurchLine.Type::Item:
                                begin
                                    InvPostingSetup.Get("Location Code", PurchLine."Posting Group");
                                    InventoryReportsHelper.InsertGLAccount(GLAccountNetChange, InvPostingSetup."Inventory Account (Interim)", AccNo);
                                end;
                            PurchLine.Type::"Charge (Item)":
                                begin
                                    GeneralPostingSetup.Get("Gen. Bus. Posting Group", PurchLine."Gen. Prod. Posting Group");
                                    InventoryReportsHelper.InsertGLAccount(GLAccountNetChange, GeneralPostingSetup."Purch. Account", AccNo);
                                end;
                            PurchLine.Type::"Fixed Asset":
                                begin
                                    PurchLine.TestField("Depreciation Book Code");
                                    FADepreciationBook.Get(PurchLine."No.", PurchLine."Depreciation Book Code");
                                    FAPostingGroup.Get(FADepreciationBook."FA Posting Group");
                                    InventoryReportsHelper.InsertGLAccount(GLAccountNetChange, FAPostingGroup."Acquisition Cost Account", AccNo);
                                end;
                            PurchLine.Type::"Empl. Purchase":
                                begin
                                    VendPostingGroup.Get("Vendor Posting Group");
                                    InventoryReportsHelper.InsertGLAccount(GLAccountNetChange, VendPostingGroup."Payables Account", AccNo);
                                end;
                        end;
                    until PurchLine.Next() = 0;

                CheckSignature(ReleasedBy, ReleasedBy."Employee Type"::ReleasedBy);
                CheckSignature(ReceivedBy, ReceivedBy."Employee Type"::ReceivedBy);

                CalcAmounts("Purchase Header");

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
        InventoryReportsHelper.InitM4Report();
    end;

    var
        CompanyInfo: Record "Company Information";
        GeneralPostingSetup: Record "General Posting Setup";
        InvPostingSetup: Record "Inventory Posting Setup";
        PurchLine: Record "Purchase Line";
        GLAccountNetChange: Record "G/L Account Net Change";
        FADepreciationBook: Record "FA Depreciation Book";
        FAPostingGroup: Record "FA Posting Group";
        VendPostingGroup: Record "Vendor Posting Group";
        ReleasedBy: Record "Document Signature";
        ReceivedBy: Record "Document Signature";
        PurchLineWithLCYAmt: Record "Purchase Line" temporary;
        StdRepMgt: Codeunit "Local Report Management";
        DocSignMgt: Codeunit "Doc. Signature Management";
        InventoryReportsHelper: Codeunit "Purchase Receipt M-4 Helper";
        AccNo: Code[20];
        TotalAmount: Decimal;
        TotalAmountInclVAT: Decimal;
        UnitCost: Decimal;
        LineVATText: array[2] of Text[50];
        TotalVATAmountText: Text[50];
        FileName: Text;
        VATExemptTotal: Boolean;
        TotalQtyToReceive: Decimal;

    [Scope('OnPrem')]
    procedure CheckSignature(var DocSign: Record "Document Signature"; EmpType: Integer)
    begin
        DocSignMgt.GetDocSign(
          DocSign, DATABASE::"Purchase Header",
          "Purchase Header"."Document Type".AsInteger(), "Purchase Header"."No.", EmpType, true);
    end;

    [Scope('OnPrem')]
    procedure CalcAmounts(PurchHeader: Record "Purchase Header")
    var
        PurchLine: Record "Purchase Line";
        PurchasePosting: Codeunit "Purch.-Post";
        TotalAmountFCY: Decimal;
        TotalAmountInclVATFCY: Decimal;
    begin
        PurchLine.SetRange("Document Type", PurchHeader."Document Type");
        PurchLine.SetRange("Document No.", PurchHeader."No.");
        PurchLine.SetFilter(Type, '>0');
        PurchLine.SetFilter(Quantity, '<>0');

        PurchasePosting.SumPurchLines2Ex("Purchase Header", PurchLineWithLCYAmt, PurchLine, 0,
          TotalAmountFCY, TotalAmount, TotalAmountInclVATFCY, TotalAmountInclVAT);
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
        ReportHeaderArr[4] := "Purchase Header"."No.";
        ReportHeaderArr[5] := Format("Purchase Header"."Document Date");
        ReportHeaderArr[6] := "Purchase Header"."Location Code";
        ReportHeaderArr[7] := StdRepMgt.GetVendorName("Purchase Header"."Buy-from Vendor No.");
        ReportHeaderArr[8] := "Purchase Header"."Buy-from Vendor No.";
        ReportHeaderArr[9] := AccNo;
        ReportHeaderArr[10] := "Purchase Header"."Vendor Shipment No.";

        InventoryReportsHelper.FillM4ReportTitle(ReportHeaderArr);
    end;

    [Scope('OnPrem')]
    procedure FillBody()
    var
        PageHeaderArr: array[10] of Text;
    begin
        PageHeaderArr[1] := "Purchase Line".Description + "Purchase Line"."Description 2";
        PageHeaderArr[2] := "Purchase Line"."No.";
        PageHeaderArr[3] := "Purchase Line"."Unit of Measure Code";
        PageHeaderArr[4] := "Purchase Line"."Unit of Measure";
        PageHeaderArr[5] := Format("Purchase Line".Quantity);
        PageHeaderArr[6] := Format("Purchase Line"."Qty. to Receive");
        PageHeaderArr[7] := FormatAmount(UnitCost);
        PageHeaderArr[8] := FormatAmount("Purchase Line".Amount);
        PageHeaderArr[9] := LineVATText[2];
        PageHeaderArr[10] := FormatAmount("Purchase Line"."Amount Including VAT");

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

