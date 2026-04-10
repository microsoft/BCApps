// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Resources.Ledger;

using System.Security.User;

page 274 "Resource Registers"
{
    ApplicationArea = Jobs;
    Caption = 'Resource Registers';
    Editable = false;
    PageType = List;
    SourceTable = "Resource Register";
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
                    ApplicationArea = Jobs;
                }
                field("Creation Date"; Rec."Creation Date")
                {
                    ApplicationArea = Jobs;
                }
                field("Creation Time"; Rec."Creation Time")
                {
                    ApplicationArea = Jobs;
                }
                field("User ID"; Rec."User ID")
                {
                    ApplicationArea = Jobs;

                    trigger OnDrillDown()
                    var
                        UserMgt: Codeunit "User Management";
                    begin
                        UserMgt.DisplayUserInformation(Rec."User ID");
                    end;
                }
                field("Source Code"; Rec."Source Code")
                {
                    ApplicationArea = Jobs;
                }
                field("Journal Batch Name"; Rec."Journal Batch Name")
                {
                    ApplicationArea = Jobs;
                }
                field("From Entry No."; Rec."From Entry No.")
                {
                    ApplicationArea = Jobs;
                }
                field("To Entry No."; Rec."To Entry No.")
                {
                    ApplicationArea = Jobs;
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
                action("Resource Ledger")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Resource Ledger';
                    Image = ResourceLedger;
                    RunObject = Codeunit "Res. Reg.-Show Ledger";
                    ToolTip = 'View the ledger entries for the resource.';
                }
            }
        }
        area(processing)
        {
            action("Delete Empty Resource Registers")
            {
                ApplicationArea = All;
                Caption = 'Delete Empty Resource Registers';
                Image = Delete;
                RunObject = Report "Delete Empty Res. Registers";
                ToolTip = 'Find and delete empty resource registers.';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("Resource Ledger_Promoted"; "Resource Ledger")
                {
                }
            }
        }
    }
}

