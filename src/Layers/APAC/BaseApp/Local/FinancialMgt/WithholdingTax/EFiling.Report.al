// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.WithholdingTax;

using Microsoft.Purchases.Vendor;

report 16630 "E-Filing"
{
    Caption = 'E-Filing';
    ProcessingOnly = true;
    ShowPrintStatus = false;
    UseRequestPage = false;

    dataset
    {
        dataitem("WHT Entry"; "WHT Entry")
        {
            DataItemTableView = sorting("Bill-to/Pay-to No.", "WHT Revenue Type", "WHT Prod. Posting Group") order(ascending) where("Transaction Type" = const(Purchase), "Applies-to Entry No." = filter(<> 0));
            PrintOnlyIfDetail = false;

            trigger OnAfterGetRecord()
            begin
                Vend.Get("Bill-to/Pay-to No.");
                VendName := Vend.Name;

                if (VendNo <> "Bill-to/Pay-to No.") or (revtype <> "WHT Revenue Type") or ("WHT %" = 0) then begin
                    WHTAmount := 0;
                    "WHT%" := 0;
                    TotAmt := 0;

                    WHTEntry1.CopyFilters("WHT Entry");
                    WHTEntry1.SetRange("WHT Prod. Posting Group", "WHT Prod. Posting Group");
                    WHTEntry1.SetRange("Bill-to/Pay-to No.", "Bill-to/Pay-to No.");
                    WHTEntry1.SetRange("WHT Revenue Type", "WHT Revenue Type");
                    if WHTEntry1.Find('-') then
                        rcount := WHTEntry1.Count();
                    if rcount = 0 then
                        rcount := 1;
                    repeat
                        WHTAmount := "Amount (LCY)" + WHTAmount;
                        "WHT%" := "WHT%" + "WHT %";
                        TotAmt := TotAmt + "Base (LCY)";
                    until WHTEntry1.Next() = 0;

                    if TempWHTEntry.FindLast() then
                        TempWHTEntry."Entry No." := TempWHTEntry."Entry No." + 1
                    else
                        TempWHTEntry."Entry No." := 1;
                    TempWHTEntry.Init();
                    TempWHTEntry."Bill-to/Pay-to No." := "Bill-to/Pay-to No.";
                    TempWHTEntry.TransferFields("WHT Entry");
                    TempWHTEntry."WHT Bus. Posting Group" := "WHT Bus. Posting Group";
                    TempWHTEntry."WHT Prod. Posting Group" := "WHT Prod. Posting Group";
                    if rcount <> 0 then
                        TempWHTEntry."WHT %" := "WHT%" / rcount;
                    TempWHTEntry."Amount (LCY)" := WHTAmount;
                    TempWHTEntry."WHT Revenue Type" := "WHT Revenue Type";
                    TempWHTEntry."Base (LCY)" := TotAmt;
                    TempWHTEntry.Insert();
                    VendNo := "Bill-to/Pay-to No.";
                    WHTBusGrp := "WHT Bus. Posting Group";
                    WHTProdGrp := "WHT Prod. Posting Group";
                    revtype := "WHT Revenue Type";
                end;
            end;

            trigger OnPreDataItem()
            begin
                LastFieldNo := FieldNo("WHT Revenue Type");
                if TempWHTEntry.FindFirst() then
                    TempWHTEntry.Delete();
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

    var
        LastFieldNo: Integer;
        WHTEntry1: Record "WHT Entry";
        rcount: Integer;
        VendName: Text[30];
        Vend: Record Vendor;
        TempWHTEntry: Record "Temp WHT Entry - EFiling";
        revtype: Code[10];
        VendNo: Code[20];
        WHTAmount: Decimal;
        "WHT%": Decimal;
        TotAmt: Decimal;
        WHTBusGrp: Code[20];
        WHTProdGrp: Code[20];
}

