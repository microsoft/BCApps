// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Vendor;

using Microsoft.Purchases.Payables;

pageextension 7000184 "CRT Vendor Statistics" extends "Vendor Statistics"
{
    layout
    {
        addlast(content)
        {
            group("Payable Docs.")
            {
                Caption = 'Payable Docs.';
                fixed(Control1903836701)
                {
                    ShowCaption = false;
                    group("No. of Documents")
                    {
                        Caption = 'No. of Documents';
                        field("NoOpen[1]"; NoOpen[1])
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Open Documents';
                            Editable = false;
                            ToolTip = 'Specifies non-processed payments.';
                        }
                        field("NoOpen[2]"; NoOpen[2])
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Open Docs. in Payment Order';
                            Editable = false;
                            ToolTip = 'Specifies non-processed payments.';
                        }
                        field("NoOpen[3]"; NoOpen[3])
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Open Docs. in Posted Payment Order';
                            Editable = false;
                            ToolTip = 'Specifies non-processed payments.';
                        }
                        field("NoHonored[3]"; NoHonored[3])
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Honored Docs. in Posted Payment Order';
                            Editable = false;
                            ToolTip = 'Specifies settled payments.';
                        }
                    }
                    group("Amount  (LCY)")
                    {
                        Caption = 'Amount  (LCY)';
                        field("OpenAmtLCY[1]"; OpenAmtLCY[1])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            AutoFormatExpression = '';
                            Caption = 'Open';
                            Editable = false;
                            ToolTip = 'Specifies that the related payment is not processed yet. ';

                            trigger OnDrillDown()
                            begin
                                DrillDownOpen(4); // Cartera
                            end;
                        }
                        field("OpenAmtLCY[2]"; OpenAmtLCY[2])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            AutoFormatExpression = '';
                            Caption = 'Open';
                            Editable = false;
                            ToolTip = 'Specifies that the related payment is not processed yet. ';

                            trigger OnDrillDown()
                            begin
                                DrillDownOpen(3); // Payment Order
                            end;
                        }
                        field("OpenAmtLCY[3]"; OpenAmtLCY[3])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            AutoFormatExpression = '';
                            Caption = 'Open';
                            Editable = false;
                            ToolTip = 'Specifies that the related payment is not processed yet. ';

                            trigger OnDrillDown()
                            begin
                                DrillDownOpen(1); // Posted Payment Order
                            end;
                        }
                        field("HonoredAmtLCY[3]"; HonoredAmtLCY[3])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            AutoFormatExpression = '';
                            Caption = 'Honored';
                            Editable = false;
                            ToolTip = 'Specifies that the related payment is settled. ';

                            trigger OnDrillDown()
                            begin
                                DrillDownHonored(1); // Posted Payment Order
                            end;
                        }
                    }
                    group("Remaining Amt.  (LCY)")
                    {
                        Caption = 'Remaining Amt.  (LCY)';
                        field("OpenRemainingAmtLCY[1]"; OpenRemainingAmtLCY[1])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            AutoFormatExpression = '';
                            Caption = 'Open';
                            Editable = false;
                            ToolTip = 'Specifies that the related payment is not processed yet. ';

                            trigger OnDrillDown()
                            begin
                                DrillDownOpen(4); // Cartera
                            end;
                        }
                        field("OpenRemainingAmtLCY[2]"; OpenRemainingAmtLCY[2])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            AutoFormatExpression = '';
                            Caption = 'Open';
                            Editable = false;
                            ToolTip = 'Specifies that the related payment is not processed yet. ';

                            trigger OnDrillDown()
                            begin
                                DrillDownOpen(3); // Payment Order
                            end;
                        }
                        field("OpenRemainingAmtLCY[3]"; OpenRemainingAmtLCY[3])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            AutoFormatExpression = '';
                            Caption = 'Open';
                            Editable = false;
                            ToolTip = 'Specifies that the related payment is not processed yet. ';

                            trigger OnDrillDown()
                            begin
                                DrillDownOpen(1); // Posted Payment Order
                            end;
                        }
                        field("HonoredRemainingAmtLCY[3]"; HonoredRemainingAmtLCY[3])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            AutoFormatExpression = '';
                            Caption = 'Honored';
                            Editable = false;
                            ToolTip = 'Specifies that the related payment is settled. ';

                            trigger OnDrillDown()
                            begin
                                DrillDownHonored(1); // Posted Payment Order
                            end;
                        }
                    }
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        UpdateBillStatistics();
    end;

#pragma warning disable AS0107
    var
        NoOpen: array[3] of Integer;
        NoHonored: array[3] of Integer;
        OpenAmtLCY: array[3] of Decimal;
        OpenRemainingAmtLCY: array[3] of Decimal;
        HonoredAmtLCY: array[3] of Decimal;
        HonoredRemainingAmtLCY: array[3] of Decimal;
        DocumentSituationFilter: array[3] of Option " ","Posted BG/PO","Closed BG/PO","BG/PO",Cartera,"Closed Documents";
        j: Integer;
#pragma warning restore AS0107

    [Scope('OnPrem')]
    procedure UpdateBillStatistics()
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        DocumentSituationFilter[1] := DocumentSituationFilter::Cartera;
        DocumentSituationFilter[2] := DocumentSituationFilter::"BG/PO";
        DocumentSituationFilter[3] := DocumentSituationFilter::"Posted BG/PO";

        VendLedgEntry.SetCurrentKey("Vendor No.", "Document Type", "Document Situation", "Document Status");
        VendLedgEntry.SetRange("Vendor No.", Rec."No.");
        for j := 1 to 3 do begin
            VendLedgEntry.SetRange("Document Situation", DocumentSituationFilter[j]);
            VendLedgEntry.SetRange("Document Status", VendLedgEntry."Document Status"::Open);
            VendLedgEntry.CalcSums("Amount (LCY) stats.", "Remaining Amount (LCY) stats.");
            OpenAmtLCY[j] := VendLedgEntry."Amount (LCY) stats.";
            OpenRemainingAmtLCY[j] := VendLedgEntry."Remaining Amount (LCY) stats.";
            NoOpen[j] := VendLedgEntry.Count;
            VendLedgEntry.SetRange("Document Status");

            VendLedgEntry.SetRange("Document Status", VendLedgEntry."Document Status"::Honored);
            VendLedgEntry.CalcSums("Amount (LCY) stats.", "Remaining Amount (LCY) stats.");
            HonoredAmtLCY[j] := VendLedgEntry."Amount (LCY) stats.";
            HonoredRemainingAmtLCY[j] := VendLedgEntry."Remaining Amount (LCY) stats.";
            NoHonored[j] := VendLedgEntry.Count;
            VendLedgEntry.SetRange("Document Status");

            VendLedgEntry.SetRange("Document Situation");
        end;
    end;

    [Scope('OnPrem')]
    procedure DrillDownOpen(Situation: Option " ","Posted BG/PO","Closed BG/PO","BG/PO",Cartera,"Closed Documents")
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
        VendLedgEntriesForm: Page "Vendor Ledger Entries";
    begin
        VendLedgEntry.SetCurrentKey("Vendor No.", "Document Type", "Document Situation", "Document Status");
        VendLedgEntry.SetRange("Vendor No.", Rec."No.");
        case Situation of
            Situation::Cartera:
                VendLedgEntry.SetRange("Document Situation", VendLedgEntry."Document Situation"::Cartera);
            Situation::"BG/PO":
                VendLedgEntry.SetRange("Document Situation", VendLedgEntry."Document Situation"::"BG/PO");
            Situation::"Posted BG/PO":
                VendLedgEntry.SetRange("Document Situation", VendLedgEntry."Document Situation"::"Posted BG/PO");
        end;
        VendLedgEntry.SetRange("Document Status", VendLedgEntry."Document Status"::Open);
        VendLedgEntriesForm.SetTableView(VendLedgEntry);
        VendLedgEntriesForm.SetRecord(VendLedgEntry);
        VendLedgEntriesForm.RunModal();
        VendLedgEntry.SetRange("Document Status");
        VendLedgEntry.SetRange("Document Situation");
    end;

    [Scope('OnPrem')]
    procedure DrillDownHonored(Situation: Option " ","Posted BG/PO","Closed BG/PO","BG/PO",Cartera,"Closed Documents")
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
        VendLedgEntriesForm: Page "Vendor Ledger Entries";
    begin
        VendLedgEntry.SetCurrentKey("Vendor No.", "Document Type", "Document Situation", "Document Status");
        VendLedgEntry.SetRange("Vendor No.", Rec."No.");
        case Situation of
            Situation::Cartera:
                VendLedgEntry.SetRange("Document Situation", VendLedgEntry."Document Situation"::Cartera);
            Situation::"BG/PO":
                VendLedgEntry.SetRange("Document Situation", VendLedgEntry."Document Situation"::"BG/PO");
            Situation::"Posted BG/PO":
                VendLedgEntry.SetRange("Document Situation", VendLedgEntry."Document Situation"::"Posted BG/PO");
        end;

        VendLedgEntry.SetRange("Document Status", VendLedgEntry."Document Status"::Honored);
        VendLedgEntriesForm.SetTableView(VendLedgEntry);
        VendLedgEntriesForm.SetRecord(VendLedgEntry);
        VendLedgEntriesForm.RunModal();
        VendLedgEntry.SetRange("Document Status");
        VendLedgEntry.SetRange("Document Situation");
    end;
}
