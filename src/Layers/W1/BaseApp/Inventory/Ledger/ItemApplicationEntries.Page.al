// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Ledger;

page 506 "Item Application Entries"
{
    Caption = 'Item Application Entries';
    Editable = false;
    PageType = List;
    SourceTable = "Item Application Entry";
    ApplicationArea = Basic, Suite;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Posting Date"; Rec."Posting Date")
                {
                    ToolTip = 'Specifies the posting date that corresponds to the posting date of the item ledger entry, for which this item application entry was created.';
                }
                field("Item Ledger Entry No."; Rec."Item Ledger Entry No.")
                {
                    ToolTip = 'Specifies one or more item application entries for each inventory transaction that is posted.';
                }
                field("Inbound Item Entry No."; Rec."Inbound Item Entry No.")
                {
                    ToolTip = 'Specifies the number of the item ledger entry corresponding to the inventory increase or positive quantity in inventory.';
                }
                field("Outbound Item Entry No."; Rec."Outbound Item Entry No.")
                {
                    ToolTip = 'Specifies the number of the item ledger entry corresponding to the inventory decrease for this entry.';
                }
                field(Quantity; Rec.Quantity)
                {
                    ToolTip = 'Specifies the quantity of the item that is being applied from the inventory decrease in the Outbound Item Entry No. field, to the inventory increase in the Inbound Item Entry No. field.';
                }
                field("Item No."; Rec."Item No.")
                {
                    ToolTip = 'Specifies the item number';
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ToolTip = 'Specifies the variant code of the item.';
                }
                field("Location Code"; Rec."Location Code")
                {
                    ToolTip = 'Specifies the location code';
                }
                field("Latest Valuation Date"; Rec."Latest Valuation Date")
                {
                    ToolTip = 'Specifies the latest valuation date of the item ledger entry.';
                }
                field("Transferred-from Entry No."; Rec."Transferred-from Entry No.")
                {
                    ToolTip = 'Specifies the item ledger entry number of the original inventory increase of the item if the item application entry originates from a transfer.';
                }
                field("Outbound Entry is Updated"; Rec."Outbound Entry is Updated")
                {
                    ToolTip = 'Specifies that the cost of the related outbound item entry is already updated. If the field is selected, then the cost adjustment routine will not try to update any previous related outbound entries.';
                }
                field("Cost Application"; Rec."Cost Application")
                {
                    ToolTip = 'Specifies that the application entry should have the cost forwarded or simply included in an average cost calculation.';
                }
                field("Entry No."; Rec."Entry No.")
                {
                    ToolTip = 'Specifies the number of the entry, as assigned from the specified number series when the entry was created.';
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
        area(Processing)
        {
            group(Edit)
            {
                Caption = 'Edit';

                action("Outbound Not Updated")
                {
                    Image = ResetStatus;
                    Caption = 'Reset Outbound Entry is Updated';
                    ToolTip = 'Reset the Outbound Entry is Updated field to allow the cost adjustment routine to update the related outbound item entry.';

                    trigger OnAction()
                    var
                        ItemLedgerEntry: Record "Item Ledger Entry";
                    begin
                        ItemLedgerEntry.Get(Rec."Inbound Item Entry No.");
                        Rec.SetOutboundsNotUpdated(ItemLedgerEntry);

                        CurrPage.Update(false);
                    end;
                }
                action("Set/Reset Cost Application")
                {
                    Image = ApplyEntries;
                    Caption = 'Set/Reset Cost Application';
                    ToolTip = 'Set or reset the Cost Application field to indicate whether the cost of the related outbound item entry should be forwarded or simply included in an average cost calculation.';

                    trigger OnAction()
                    begin
                        Rec.SetCostApplication(not Rec."Cost Application");

                        CurrPage.Update(false);
                    end;
                }
            }
            group(Traverse)
            {
                Caption = 'Traverse';

                action(FilterByInbound)
                {
                    Caption = 'Filter by Inbound';
                    ToolTip = 'Filter the list to show only item application entries with the current inbound item entry number.';
                    Image = MoveDown;

                    trigger OnAction()
                    begin
                        Rec.Reset();
                        if Rec."Inbound Item Entry No." <> 0 then
                            Rec.SetRange("Inbound Item Entry No.", Rec."Inbound Item Entry No.");
                        CurrPage.Update(false);
                    end;
                }
                action(FilterByOutbound)
                {
                    Caption = 'Filter by Outbound';
                    ToolTip = 'Filter the list to show only item application entries with the current outbound item entry number.';
                    Image = MoveUp;

                    trigger OnAction()
                    begin
                        Rec.Reset();
                        if Rec."Outbound Item Entry No." <> 0 then
                            Rec.SetRange("Outbound Item Entry No.", Rec."Outbound Item Entry No.");
                        CurrPage.Update(false);
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Category4)
            {
                Caption = 'Edit';

                actionref("Outbound Not Updated_Promoted"; "Outbound Not Updated") { }
                actionref("Set/Reset Cost Application_Promoted"; "Set/Reset Cost Application") { }
            }
            group(Category_Category5)
            {
                Caption = 'Traverse';

                actionref(FilterByInbound_Promoted; FilterByInbound) { }
                actionref(FilterByOutbound_Promoted; FilterByOutbound) { }
            }
        }
    }
}

