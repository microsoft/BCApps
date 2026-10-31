// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Costing;

using Microsoft.Inventory.Ledger;

page 5813 "Post Value Entries to G/L"
{
    PageType = List;
    ApplicationArea = Basic, Suite;
    SourceTable = "Post Value Entry to G/L";
    Caption = 'Value Entries to Post to G/L';
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    Permissions = tabledata "Value Entry" = r;

    layout
    {
        area(Content)
        {
            repeater(Entries)
            {
                field("Value Entry No."; Rec."Value Entry No.")
                {
                }
                field("Item No."; Rec."Item No.")
                {
                }
                field("Posting Date"; Rec."Posting Date")
                {
                }
                field("Cost Amount (Actual)"; ValueEntry."Cost Amount (Actual)")
                {
                    Caption = 'Cost Amount (Actual)';
                    ToolTip = 'Specifies the actual cost of the value entry.';
                }
                field("Cost Posted to G/L"; ValueEntry."Cost Posted to G/L")
                {
                    Caption = 'Cost Posted to G/L';
                    ToolTip = 'Specifies the actual cost of the value entry that has been posted to the general ledger.';
                }
                field("Cost Amount (Expected)"; ValueEntry."Cost Amount (Expected)")
                {
                    Caption = 'Cost Amount (Expected)';
                    ToolTip = 'Specifies the expected cost of the value entry.';
                }
                field("Expected Cost Posted to G/L"; ValueEntry."Expected Cost Posted to G/L")
                {
                    Caption = 'Expected Cost Posted to G/L';
                    ToolTip = 'Specifies the expected cost of the value entry that has been posted to the interim account in the general ledger.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action("Clean Up")
            {
                Caption = 'Clean up fully posted entries';
                ToolTip = 'Delete the entries in the list whose cost is already fully posted to the general ledger or whose value entry no longer exists. The current filters are used.';
                Image = ClearLog;

                trigger OnAction()
                var
                    PostValueEntryToGL: Record "Post Value Entry to G/L";
                begin
                    PostValueEntryToGL.CopyFilters(Rec);
                    Report.RunModal(Report::"Clean Up Post Value Entries", true, false, PostValueEntryToGL);
                    CurrPage.Update(false);
                end;
            }
            action("Post Inventory Cost to G/L")
            {
                Caption = 'Post inventory cost to G/L';
                ToolTip = 'Post the cost of the value entries in the list to the general ledger.';
                Image = PostInventoryToGL;

                trigger OnAction()
                var
                    PostValueEntryToGL: Record "Post Value Entry to G/L";
                begin
                    PostValueEntryToGL.CopyFilters(Rec);
                    Report.RunModal(Report::"Post Inventory Cost to G/L", true, false, PostValueEntryToGL);
                    CurrPage.Update(false);
                end;
            }
        }
        area(Navigation)
        {
            action("Value Entry")
            {
                Caption = 'Value entry';
                ToolTip = 'View the value entry for the selected line.';
                Image = ValueLedger;
                RunObject = page "Value Entries";
                RunPageLink = "Entry No." = field("Value Entry No.");
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("Clean Up_Promoted"; "Clean Up") { }
                actionref("Post Inventory Cost to G/L_Promoted"; "Post Inventory Cost to G/L") { }
            }
            group(Category_Entry)
            {
                Caption = 'Entry';

                actionref("Value Entry_Promoted"; "Value Entry") { }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        ValueEntry.SetLoadFields("Cost Amount (Actual)", "Cost Posted to G/L", "Cost Amount (Expected)", "Expected Cost Posted to G/L");
        if not ValueEntry.Get(Rec."Value Entry No.") then
            Clear(ValueEntry);
    end;

    var
        ValueEntry: Record "Value Entry";
}
