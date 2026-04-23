// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

page 99001560 "WIP Ledger Entries"
{
    ApplicationArea = Manufacturing;
    Caption = 'WIP Ledger Entries';
    Editable = false;
    PageType = List;
    SourceTable = "Subcontractor WIP Ledger Entry";
    UsageCategory = History;
    SaveValues = false;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Posting Date"; Rec."Posting Date")
                {
                }
                field("Entry Type"; Rec."Entry Type")
                {
                }
                field("Document Type"; Rec."Document Type")
                {
                }
                field("Document No."; Rec."Document No.")
                {
                }
                field("Document Line No."; Rec."Document Line No.")
                {
                }
                field("Item No."; Rec."Item No.")
                {
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    Visible = false;
                }
                field(Description; Rec.Description)
                {
                }
                field("Description 2"; Rec."Description 2")
                {
                    Visible = false;
                }
                field("Location Code"; Rec."Location Code")
                {
                }
                field("Quantity (Base)"; Rec."Quantity (Base)")
                {
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                }
                field("Prod. Order Status"; Rec."Prod. Order Status")
                {
                }
                field("Prod. Order No."; Rec."Prod. Order No.")
                {
                }
                field("Prod. Order Line No."; Rec."Prod. Order Line No.")
                {
                }
                field("Routing No."; Rec."Routing No.")
                {
                }
                field("Routing Reference No."; Rec."Routing Reference No.")
                {
                }
                field("Operation No."; Rec."Operation No.")
                {
                }
                field("Work Center No."; Rec."Work Center No.")
                {
                }
                field("Entry No."; Rec."Entry No.")
                {
                }
                field("In Transit"; Rec."In Transit")
                {
                    Visible = false;
                }
            }
        }
        area(factboxes)
        {
            systempart(Links; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Notes; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action("WIP Adjustment")
            {
                ApplicationArea = Manufacturing;
                Caption = 'WIP Adjustment';
                Image = AdjustEntries;
                ToolTip = 'Manually adjust the WIP quantity for the selected WIP ledger entry.';
                Enabled = WIPAdjustmentEnabled;
                Visible = WIPAdjustmentEnabled;

                trigger OnAction()
                var
                    WIPLedgerEntry: Record "Subcontractor WIP Ledger Entry";
                    WIPAdjustmentPage: Page "WIP Adjustment";
                begin
                    WIPLedgerEntry := Rec;
                    WIPLedgerEntry.SetRecFilter();
                    WIPAdjustmentPage.SetWIPLedgerEntry(WIPLedgerEntry);
                    WIPAdjustmentPage.SetDocumentNo(Rec."Document No.");
                    WIPAdjustmentPage.RunModal();
                end;
            }
        }
        area(Promoted)
        {
            actionref(WipAdjustment_Promoted; "WIP Adjustment") { }
        }
    }

    var
        WIPAdjustmentEnabled: Boolean;

    trigger OnOpenPage()
    begin
        WIPAdjustmentEnabled := not Rec.IsTemporary();
    end;
}