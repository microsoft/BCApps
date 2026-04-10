// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Ledger;

using System.Security.User;

page 7325 "Warehouse Registers"
{
    ApplicationArea = Warehouse;
    Caption = 'Warehouse Registers';
    Editable = false;
    PageType = List;
    SourceTable = "Warehouse Register";
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
                    ApplicationArea = Warehouse;
                }
                field("From Entry No."; Rec."From Entry No.")
                {
                    ApplicationArea = Warehouse;
                    Visible = false;
                }
                field("To Entry No."; Rec."To Entry No.")
                {
                    ApplicationArea = Warehouse;
                    Visible = false;
                }
                field("Creation Date"; Rec."Creation Date")
                {
                    ApplicationArea = Warehouse;
                }
                field("Creation Time"; Rec."Creation Time")
                {
                    ApplicationArea = Warehouse;
                }
                field("Source Code"; Rec."Source Code")
                {
                    ApplicationArea = Warehouse;
                }
                field("User ID"; Rec."User ID")
                {
                    ApplicationArea = Warehouse;

                    trigger OnDrillDown()
                    var
                        UserMgt: Codeunit "User Management";
                    begin
                        UserMgt.DisplayUserInformation(Rec."User ID");
                    end;
                }
                field("Journal Batch Name"; Rec."Journal Batch Name")
                {
                    ApplicationArea = Warehouse;
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
                action("&Warehouse Entries")
                {
                    ApplicationArea = Warehouse;
                    Caption = '&Warehouse Entries';
                    Image = BinLedger;
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View the history of quantities that are registered for the item in warehouse activities. ';

                    trigger OnAction()
                    var
                        WhseEntry: Record "Warehouse Entry";
                    begin
                        WhseEntry.SetRange("Entry No.", Rec."From Entry No.", Rec."To Entry No.");
                        WhseEntry.SetFilter("Warehouse Register No.", '%1|%2', 0, Rec."No.");
                        PAGE.Run(PAGE::"Warehouse Entries", WhseEntry);
                    end;
                }
            }
        }
        area(processing)
        {
            action("Delete Empty Registers")
            {
                ApplicationArea = All;
                Caption = 'Delete Empty Registers';
                Image = Delete;
                RunObject = Report "Delete Empty Whse. Registers";
                ToolTip = 'Find and delete empty warehouse registers.';
            }
        }
    }

    trigger OnOpenPage()
    begin
        if Rec.FindFirst() then;
    end;
}
