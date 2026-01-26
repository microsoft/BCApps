// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Receivables;

using Microsoft.Sales.Customer;

page 35304 "Cartera Receiv. Statistics FB"
{
    Caption = 'Cartera Receiv. Statistics FB';
    Editable = false;
    PageType = CardPart;
    SourceTable = Customer;

    layout
    {
        area(content)
        {
            group("No. of Bills")
            {
                Caption = 'No. of Bills';
                field("NoOpen[1]"; NoOpen[1])
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Open Bills';
                    Editable = false;
                    ToolTip = 'Specifies non-processed payments.';
                }
                field("NoOpen[2]"; NoOpen[2])
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Open Bills in Bill Gr.';
                    Editable = false;
                    ToolTip = 'Specifies non-processed payments.';
                }
                field("NoOpen[3]"; NoOpen[3])
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Open Bills in Post. Bill Gr.';
                    Editable = false;
                    ToolTip = 'Specifies non-processed payments.';
                }
                field("NoHonored[3]"; NoHonored[3])
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Hon. Bills in Post. Bill Gr.';
                    Editable = false;
                    ToolTip = 'Specifies settled payments.';
                }
                field("NoRejected[3]"; NoRejected[3])
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Rej. Bills in Post. Bill Gr.';
                    Editable = false;
                    ToolTip = 'Specifies rejected payments.';
                }
                field("NoRedrawn[3]"; NoRedrawn[3])
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Redr. Bills in Post. Bill Gr.';
                    Editable = false;
                    ToolTip = 'Specifies recirculated payments.';
                }
                field("NoHonored[4]"; NoHonored[4])
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Hon. Closed Bills';
                    Editable = false;
                    ToolTip = 'Specifies settled payments.';
                }
                field("NoRejected[4]"; NoRejected[4])
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Rej. Closed Bills';
                    Editable = false;
                    ToolTip = 'Specifies rejected payments.';
                }
            }
            group("Remaining Amt.  (LCY)")
            {
                Caption = 'Remaining Amt.  (LCY)';
                field("OpenRemainingAmtLCY[1]"; OpenRemainingAmtLCY[1])
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Open Bills';
                    Editable = false;
                    ToolTip = 'Specifies non-processed payments.';

                    trigger OnDrillDown()
                    begin
                        DrillDownOpen(4, 1); // Cartera
                    end;
                }
                field("OpenRemainingAmtLCY[2]"; OpenRemainingAmtLCY[2])
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Open Bills in Bill Gr.';
                    Editable = false;
                    ToolTip = 'Specifies non-processed payments.';

                    trigger OnDrillDown()
                    begin
                        DrillDownOpen(3, 1); // Bill Group;
                    end;
                }
                field("OpenRemainingAmtLCY[3]"; OpenRemainingAmtLCY[3])
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Open Bills in Post. Bill Gr.';
                    Editable = false;
                    ToolTip = 'Specifies non-processed payments.';

                    trigger OnDrillDown()
                    begin
                        DrillDownOpen(1, 1); // Posted Bill Group
                    end;
                }
                field("HonoredRemainingAmtLCY[3]"; HonoredRemainingAmtLCY[3])
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Hon. Bills in Post. Bill Gr.';
                    Editable = false;
                    ToolTip = 'Specifies settled payments.';

                    trigger OnDrillDown()
                    begin
                        DrillDownHonored(1, 1); // Posted Bill Group
                    end;
                }
                field("RejectedRemainingAmtLCY[3]"; RejectedRemainingAmtLCY[3])
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Rej. Bills in Post. Bill Gr.';
                    Editable = false;
                    ToolTip = 'Specifies rejected payments.';

                    trigger OnDrillDown()
                    begin
                        DrillDownRejected(1, 1); // Posted Bill Group
                    end;
                }
                field("RedrawnRemainingAmtLCY[3]"; RedrawnRemainingAmtLCY[3])
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Redr. Bills in Post. Bill Gr.';
                    Editable = false;
                    ToolTip = 'Specifies recirculated payments.';

                    trigger OnDrillDown()
                    begin
                        DrillDownRedrawn(1, 1); // Posted Bill Group
                    end;
                }
                field("HonoredRemainingAmtLCY[4]"; HonoredRemainingAmtLCY[4])
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Hon. Closed Bills';
                    Editable = false;
                    ToolTip = 'Specifies settled payments.';

                    trigger OnDrillDown()
                    begin
                        DrillDownHonored(5, 1); // Closed Bills
                    end;
                }
                field("RejectedRemainingAmtLCY[4]"; RejectedRemainingAmtLCY[4])
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Rej. Closed Bills';
                    Editable = false;
                    ToolTip = 'Specifies rejected payments.';

                    trigger OnDrillDown()
                    begin
                        DrillDownRejected(5, 1); // Closed Bills
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

    [Scope('OnPrem')]
    procedure UpdateDocStatistics()
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

    [Scope('OnPrem')]
    procedure DrillDownOpen(Situation: Option " ","Posted BG/PO","Closed BG/PO","BG/PO",Cartera,"Closed Documents"; DocType: Option Invoice,Bill)
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

    [Scope('OnPrem')]
    procedure DrillDownHonored(Situation: Option " ","Posted BG/PO","Closed BG/PO","BG/PO",Cartera,"Closed Documents"; DocType: Option Invoice,Bill)
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

    [Scope('OnPrem')]
    procedure DrillDownRejected(Situation: Option " ","Posted BG/PO","Closed BG/PO","BG/PO",Cartera,"Closed Documents"; DocType: Option Invoice,Bill)
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

    [Scope('OnPrem')]
    procedure DrillDownRedrawn(Situation: Option " ","Posted BG/PO","Closed BG/PO","BG/PO",Cartera,"Closed Documents"; DocType: Option Invoice,Bill)
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
            Situation::"Closed BG/PO", Situation::"Closed Documents":
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
        CustLedgEntry.SetRange("Document Status", CustLedgEntry."Document Status"::Redrawn);
        CustLedgEntriesForm.SetTableView(CustLedgEntry);
        CustLedgEntriesForm.SetRecord(CustLedgEntry);
        CustLedgEntriesForm.RunModal();
        CustLedgEntry.SetRange("Document Status");
        CustLedgEntry.SetRange("Document Situation");
    end;
}

