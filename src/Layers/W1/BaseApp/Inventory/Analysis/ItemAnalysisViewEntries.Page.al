// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Analysis;

using Microsoft.Inventory.Ledger;

page 7153 "Item Analysis View Entries"
{
    Caption = 'Analysis View Entries';
    DataCaptionFields = "Analysis View Code";
    Editable = false;
    PageType = List;
    SourceTable = "Item Analysis View Entry";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Item Ledger Entry Type"; Rec."Item Ledger Entry Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies which type of transaction that the entry is created from.';
                }
                field("Entry Type"; Rec."Entry Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value entry type for an analysis view entry.';
                }
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the item number to which the item ledger entry in an analysis view entry was posted.';
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the code of the location to which the item ledger entry in an analysis view entry was posted.';
                }
                field("Dimension 1 Value Code"; Rec."Dimension 1 Value Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the dimension value you selected for the analysis view dimension that you defined as Dimension 1 on the analysis view card.';
                }
                field("Dimension 2 Value Code"; Rec."Dimension 2 Value Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the dimension value you selected for the analysis view dimension that you defined as Dimension 2 on the analysis view card.';
                }
                field("Dimension 3 Value Code"; Rec."Dimension 3 Value Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the dimension value you selected for the analysis view dimension that you defined as Dimension 3 on the analysis view card.';
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when the item ledger entry in an analysis view entry was posted.';
                }
                field("Sales Amount (Actual)"; Rec."Sales Amount (Actual)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the sum of the actual sales amounts posted for the item ledger entries included in the analysis view entry.';

                    trigger OnDrillDown()
                    begin
                        DrillDown();
                    end;
                }
                field("Sales Amount (Expected)"; Rec."Sales Amount (Expected)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the sum of the expected sales amounts posted for the item ledger entries, included in the analysis view entry.';

                    trigger OnDrillDown()
                    begin
                        DrillDown();
                    end;
                }
                field("Cost Amount (Actual)"; Rec."Cost Amount (Actual)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the sum of the actual cost amounts posted for the item ledger entries included in the analysis view entry.';

                    trigger OnDrillDown()
                    begin
                        DrillDown();
                    end;
                }
                field("Cost Amount (Expected)"; Rec."Cost Amount (Expected)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the sum of the expected cost amounts posted for the item ledger entries included in the analysis view entry.';

                    trigger OnDrillDown()
                    begin
                        DrillDown();
                    end;
                }
                field("Cost Amount (Non-Invtbl.)"; Rec."Cost Amount (Non-Invtbl.)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the sum of the non-inventoriable cost amounts posted for the item ledger entries included in the analysis view entry.';

                    trigger OnDrillDown()
                    begin
                        DrillDown();
                    end;
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the sum of the quantity for the item ledger entries included in the analysis view entry.';

                    trigger OnDrillDown()
                    begin
                        DrillDown();
                    end;
                }
                field("Invoiced Quantity"; Rec."Invoiced Quantity")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the sum of the quantity invoiced for the item ledger entries included in the analysis view entry.';

                    trigger OnDrillDown()
                    begin
                        DrillDown();
                    end;
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetCurrRecord()
    begin
        if Rec."Analysis View Code" <> xRec."Analysis View Code" then;
    end;

    var
        TempValueEntry: Record "Value Entry" temporary;

    local procedure DrillDown()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDrillDown(Rec, IsHandled);
        if IsHandled then
            exit;

        SetAnalysisViewEntry(Rec);
        TempValueEntry.FilterGroup(DATABASE::"Item Analysis View Entry"); // Trick: FILTERGROUP is used to transfer an integer value
        PAGE.RunModal(PAGE::"Value Entries", TempValueEntry);
    end;

    procedure SetAnalysisViewEntry(ItemAnalysisViewEntry: Record "Item Analysis View Entry")
    var
        ItemAViewEntryToValueEntries: Codeunit ItemAViewEntryToValueEntries;
    begin
        TempValueEntry.Reset();
        TempValueEntry.DeleteAll();
        ItemAViewEntryToValueEntries.GetValueEntries(ItemAnalysisViewEntry, TempValueEntry);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDrillDown(var ItemAnalysisViewEntry: Record "Item Analysis View Entry"; var IsHandled: Boolean)
    begin
    end;
}

