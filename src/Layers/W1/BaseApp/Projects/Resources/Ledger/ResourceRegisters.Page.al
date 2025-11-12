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
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field("Creation Date"; Rec."Creation Date")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the date when you posted the entries in the journal.';
                }
                field("Creation Time"; Rec."Creation Time")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the time when you posted the entries in the journal.';
                }
                field("User ID"; Rec."User ID")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the ID of the user who posted the entry, to be used, for example, in the change log.';

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
                    ToolTip = 'Specifies the source code that specifies where the entry was created.';
                }
                field("Journal Batch Name"; Rec."Journal Batch Name")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the name of the journal batch, a personalized journal layout, that the entries were posted from.';
                }
                field("From Entry No."; Rec."From Entry No.")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the first item entry number in the register.';
                }
                field("To Entry No."; Rec."To Entry No.")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the number of the last entry line that you included before you posted the entries in the journal.';
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

