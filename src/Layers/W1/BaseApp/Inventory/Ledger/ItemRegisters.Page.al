// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Ledger;

using System.Security.User;

page 117 "Item Registers"
{
    AdditionalSearchTerms = 'inventory transactions';
    ApplicationArea = Basic, Suite;
    Caption = 'Item Registers';
    Editable = false;
    PageType = List;
    SourceTable = "Item Register";
    SourceTableView = sorting("No.") order(descending);
    UsageCategory = History;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("No."; Rec."No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Creation Date"; Rec."Creation Date")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Creation Time"; Rec."Creation Time")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("User ID"; Rec."User ID")
                {
                    ApplicationArea = Basic, Suite;

                    trigger OnDrillDown()
                    var
                        UserMgt: Codeunit "User Management";
                    begin
                        UserMgt.DisplayUserInformation(Rec."User ID");
                    end;
                }
                field("Source Code"; Rec."Source Code")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Journal Batch Name"; Rec."Journal Batch Name")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("From Entry No."; Rec."From Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("To Entry No."; Rec."To Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("From Phys. Inventory Entry No."; Rec."From Phys. Inventory Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("To Phys. Inventory Entry No."; Rec."To Phys. Inventory Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("From Value Entry No."; Rec."From Value Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("To Value Entry No."; Rec."To Value Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("From Capacity Entry No."; Rec."From Capacity Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("To Capacity Entry No."; Rec."To Capacity Entry No.")
                {
                    ApplicationArea = Basic, Suite;
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
        area(navigation)
        {
            group("&Register")
            {
                Caption = '&Register';
                Image = Register;
                action("Item Ledger")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Item Ledger';
                    Image = ItemLedger;
                    RunObject = Codeunit "Item Reg.-Show Ledger";
                    ToolTip = 'View the item ledger entries that resulted in the current register entry.';
                }
                action("Phys. Invent&ory Ledger")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Phys. Invent&ory Ledger';
                    Image = PhysicalInventoryLedger;
                    RunObject = Codeunit "Item Reg.-Show Inventory Ledg.";
                    ToolTip = 'View the physical inventory ledger entries that resulted in the current register entry.';
                }
                action("Value Entries")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Value Entries';
                    Image = ValueLedger;
                    RunObject = Codeunit "Item Reg.- Show Value Entries";
                    ToolTip = 'View the value entries of the item on the document or journal line.';
                }
                action("&Capacity Ledger")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Capacity Ledger';
                    Image = CapacityLedger;
                    RunObject = Codeunit Microsoft.Manufacturing.Capacity."Item Reg.-Show Cap. Ledger";
                    ToolTip = 'View the capacity ledger entries that resulted in the current register entry.';
                }
            }
        }
        area(creation)
        {
            action("Delete Empty Registers")
            {
                ApplicationArea = All;
                Caption = 'Delete Empty Registers';
                Image = Delete;
                RunObject = Report "Delete Empty Item Registers";
                ToolTip = 'Find and delete empty item registers.';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("Item Ledger_Promoted"; "Item Ledger")
                {
                }
                actionref("Phys. Invent&ory Ledger_Promoted"; "Phys. Invent&ory Ledger")
                {
                }
                actionref("Value Entries_Promoted"; "Value Entries")
                {
                }
                actionref("&Capacity Ledger_Promoted"; "&Capacity Ledger")
                {
                }
            }
        }
    }
}

