// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.ReceivablesPayables;

using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;

page 35306 "Cartera Fact. Statistics FB"
{
    Caption = 'Cartera Fact. Statistics FB';
    Editable = false;
    PageType = CardPart;
    SourceTable = Customer;

    layout
    {
        area(content)
        {
            group("No. of Invoices")
            {
                Caption = 'No. of Invoices';
                field("NoOpen[5]"; NoOpen[5])
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Open';
                    Editable = false;
                    ToolTip = 'Specifies that the related payment is not processed yet. ';
                }
                field("NoHonored[5]"; NoHonored[5])
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Honored';
                    Editable = false;
                    ToolTip = 'Specifies that the related payment is settled. ';
                }
                field("NoRejected[5]"; NoRejected[5])
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Rejected';
                    Editable = false;
                    ToolTip = 'Specifies that the related payment is rejected.';
                }
            }
            group("Remaining Amt.  (LCY)")
            {
                Caption = 'Remaining Amt.  (LCY)';
                field("OpenRemainingAmtLCY[5]"; OpenRemainingAmtLCY[5])
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Open';
                    Editable = false;
                    ToolTip = 'Specifies that the related payment is not processed yet. ';

                    trigger OnDrillDown()
                    begin
                        DrillDownOpen(0, 0);
                    end;
                }
                field("HonoredRemainingAmtLCY[5]"; HonoredRemainingAmtLCY[5])
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Honored';
                    Editable = false;
                    ToolTip = 'Specifies that the related payment is settled. ';

                    trigger OnDrillDown()
                    begin
                        DrillDownHonored(0, 0);
                    end;
                }
                field("RejectedRemainingAmtLCY[5]"; RejectedRemainingAmtLCY[5])
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Rejected';
                    Editable = false;
                    ToolTip = 'Specifies that the related payment is rejected.';

                    trigger OnDrillDown()
                    begin
                        DrillDownRejected(0, 0);
                    end;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        UpdateDocStatistics();
    end;

    var
        DocumentSituationFilter: array[3] of Option " ","Posted BG/PO","Closed BG/PO","BG/PO",Cartera,"Closed Documents";
        NoOpen: array[5] of Integer;
        NoHonored: array[5] of Integer;
        NoRejected: array[5] of Integer;
        NoRedrawn: array[5] of Integer;
        OpenAmtLCY: array[5] of Decimal;
        HonoredAmtLCY: array[5] of Decimal;
        RejectedAmtLCY: array[5] of Decimal;
        RedrawnAmtLCY: array[5] of Decimal;
        OpenRemainingAmtLCY: array[5] of Decimal;
        RejectedRemainingAmtLCY: array[5] of Decimal;
        HonoredRemainingAmtLCY: array[5] of Decimal;
        RedrawnRemainingAmtLCY: array[5] of Decimal;
        j: Integer;

    local procedure UpdateDocStatistics()
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        DocumentSituationFilter[1] := DocumentSituationFilter::Cartera;
        DocumentSituationFilter[2] := DocumentSituationFilter::"BG/PO";
        DocumentSituationFilter[3] := DocumentSituationFilter::"Posted BG/PO";

        CustLedgEntry.SetCurrentKey("Customer No.", "Document Type", "Document Situation", "Document Status");
        CustLedgEntry.SetRange("Customer No.", Rec."No.");
        for j := 1 to 5 do begin
            case j of
                4:
                    // Closed Bill Group and Closed Documents
                    begin
                        CustLedgEntry.SetRange("Document Type", CustLedgEntry."Document Type"::Bill);
                        CustLedgEntry.SetFilter("Document Situation", '%1|%2',
                          CustLedgEntry."Document Situation"::"Closed BG/PO",
                          CustLedgEntry."Document Situation"::"Closed Documents");
                    end;
                5:
                    // Invoices
                    begin
                        CustLedgEntry.SetRange("Document Type", CustLedgEntry."Document Type"::Invoice);
                        CustLedgEntry.SetFilter("Document Situation", '<>0');
                    end;
                else begin
                    CustLedgEntry.SetRange("Document Type", CustLedgEntry."Document Type"::Bill);
                    CustLedgEntry.SetRange("Document Situation", DocumentSituationFilter[j]);
                end;
            end;
            CustLedgEntry.SetRange("Document Status", CustLedgEntry."Document Status"::Open);
            CustLedgEntry.CalcSums("Amount (LCY) stats.", "Remaining Amount (LCY) stats.");
            OpenAmtLCY[j] := CustLedgEntry."Amount (LCY) stats.";
            OpenRemainingAmtLCY[j] := CustLedgEntry."Remaining Amount (LCY) stats.";
            NoOpen[j] := CustLedgEntry.Count;
            CustLedgEntry.SetRange("Document Status");

            CustLedgEntry.SetRange("Document Status", CustLedgEntry."Document Status"::Honored);
            CustLedgEntry.CalcSums("Amount (LCY) stats.", "Remaining Amount (LCY) stats.");
            HonoredAmtLCY[j] := CustLedgEntry."Amount (LCY) stats.";
            HonoredRemainingAmtLCY[j] := CustLedgEntry."Remaining Amount (LCY) stats.";
            NoHonored[j] := CustLedgEntry.Count;
            CustLedgEntry.SetRange("Document Status");

            CustLedgEntry.SetRange("Document Status", CustLedgEntry."Document Status"::Rejected);
            CustLedgEntry.CalcSums("Amount (LCY) stats.", "Remaining Amount (LCY) stats.");
            RejectedAmtLCY[j] := CustLedgEntry."Amount (LCY) stats.";
            RejectedRemainingAmtLCY[j] := CustLedgEntry."Remaining Amount (LCY) stats.";
            NoRejected[j] := CustLedgEntry.Count;
            CustLedgEntry.SetRange("Document Status");

            CustLedgEntry.SetRange("Document Status", CustLedgEntry."Document Status"::Redrawn);
            CustLedgEntry.CalcSums("Amount (LCY) stats.", "Remaining Amount (LCY) stats.");
            RedrawnAmtLCY[j] := CustLedgEntry."Amount (LCY) stats.";
            RedrawnRemainingAmtLCY[j] := CustLedgEntry."Remaining Amount (LCY) stats.";
            NoRedrawn[j] := CustLedgEntry.Count;
            CustLedgEntry.SetRange("Document Status");

            CustLedgEntry.SetRange("Document Situation");
        end;
    end;

    local procedure DrillDownOpen(Situation: Option " ","Posted BG/PO","Closed BG/PO","BG/PO",Cartera,"Closed Documents"; DocType: Option Invoice,Bill)
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        CustLedgEntriesForm: Page "Customer Ledger Entries";
    begin
        CustLedgEntry.SetCurrentKey("Customer No.", "Document Type", "Document Situation", "Document Status");
        CustLedgEntry.SetRange("Customer No.", Rec."No.");
        case Situation of
            Situation::Cartera:
                CustLedgEntry.SetRange("Document Situation", CustLedgEntry."Document Situation"::Cartera);
            Situation::"BG/PO":
                CustLedgEntry.SetRange("Document Situation", CustLedgEntry."Document Situation"::"BG/PO");
            Situation::"Posted BG/PO":
                CustLedgEntry.SetRange("Document Situation", CustLedgEntry."Document Situation"::"Posted BG/PO");
            Situation::"Closed BG/PO":
                CustLedgEntry.SetFilter("Document Situation", '%1|%2',
                  CustLedgEntry."Document Situation"::"Closed BG/PO",
                  CustLedgEntry."Document Situation"::"Closed Documents");
            else
                CustLedgEntry.SetFilter("Document Situation", '<>0');
        end;
        case DocType of
            DocType::Invoice:
                CustLedgEntry.SetRange("Document Type", CustLedgEntry."Document Type"::Invoice);
            DocType::Bill:
                CustLedgEntry.SetRange("Document Type", CustLedgEntry."Document Type"::Bill);
        end;

        CustLedgEntry.SetRange("Document Status", CustLedgEntry."Document Status"::Open);
        CustLedgEntriesForm.SetTableView(CustLedgEntry);
        CustLedgEntriesForm.SetRecord(CustLedgEntry);
        CustLedgEntriesForm.RunModal();
        CustLedgEntry.SetRange("Document Status");
        CustLedgEntry.SetRange("Document Situation");
    end;

    local procedure DrillDownHonored(Situation: Option " ","Posted BG/PO","Closed BG/PO","BG/PO",Cartera,"Closed Documents"; DocType: Option Invoice,Bill)
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        CustLedgEntriesForm: Page "Customer Ledger Entries";
    begin
        CustLedgEntry.SetCurrentKey("Customer No.", "Document Type", "Document Situation", "Document Status");
        CustLedgEntry.SetRange("Customer No.", Rec."No.");
        case Situation of
            Situation::Cartera:
                CustLedgEntry.SetRange("Document Situation", CustLedgEntry."Document Situation"::Cartera);
            Situation::"BG/PO":
                CustLedgEntry.SetRange("Document Situation", CustLedgEntry."Document Situation"::"BG/PO");
            Situation::"Posted BG/PO":
                CustLedgEntry.SetRange("Document Situation", CustLedgEntry."Document Situation"::"Posted BG/PO");
            Situation::"Closed BG/PO":
                CustLedgEntry.SetFilter("Document Situation", '%1|%2',
                  CustLedgEntry."Document Situation"::"Closed BG/PO",
                  CustLedgEntry."Document Situation"::"Closed Documents");
            else
                CustLedgEntry.SetFilter("Document Situation", '<>0');
        end;
        case DocType of
            DocType::Invoice:
                CustLedgEntry.SetRange("Document Type", CustLedgEntry."Document Type"::Invoice);
            DocType::Bill:
                CustLedgEntry.SetRange("Document Type", CustLedgEntry."Document Type"::Bill);
        end;

        CustLedgEntry.SetRange("Document Status", CustLedgEntry."Document Status"::Honored);
        CustLedgEntriesForm.SetTableView(CustLedgEntry);
        CustLedgEntriesForm.SetRecord(CustLedgEntry);
        CustLedgEntriesForm.RunModal();
        CustLedgEntry.SetRange("Document Status");
        CustLedgEntry.SetRange("Document Situation");
    end;

    local procedure DrillDownRejected(Situation: Option " ","Posted BG/PO","Closed BG/PO","BG/PO",Cartera,"Closed Documents"; DocType: Option Invoice,Bill)
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        CustLedgEntriesForm: Page "Customer Ledger Entries";
    begin
        CustLedgEntry.SetCurrentKey("Customer No.", "Document Type", "Document Situation", "Document Status");
        CustLedgEntry.SetRange("Customer No.", Rec."No.");
        case Situation of
            Situation::Cartera:
                CustLedgEntry.SetRange("Document Situation", CustLedgEntry."Document Situation"::Cartera);
            Situation::"BG/PO":
                CustLedgEntry.SetRange("Document Situation", CustLedgEntry."Document Situation"::"BG/PO");
            Situation::"Posted BG/PO":
                CustLedgEntry.SetRange("Document Situation", CustLedgEntry."Document Situation"::"Posted BG/PO");
            Situation::"Closed BG/PO":
                CustLedgEntry.SetFilter("Document Situation", '%1|%2',
                  CustLedgEntry."Document Situation"::"Closed BG/PO",
                  CustLedgEntry."Document Situation"::"Closed Documents");
            else
                CustLedgEntry.SetFilter("Document Situation", '<>0');
        end;
        case DocType of
            DocType::Invoice:
                CustLedgEntry.SetRange("Document Type", CustLedgEntry."Document Type"::Invoice);
            DocType::Bill:
                CustLedgEntry.SetRange("Document Type", CustLedgEntry."Document Type"::Bill);
        end;

        CustLedgEntry.SetRange("Document Status", CustLedgEntry."Document Status"::Rejected);
        CustLedgEntriesForm.SetTableView(CustLedgEntry);
        CustLedgEntriesForm.SetRecord(CustLedgEntry);
        CustLedgEntriesForm.RunModal();
        CustLedgEntry.SetRange("Document Status");
        CustLedgEntry.SetRange("Document Situation");
    end;
}

