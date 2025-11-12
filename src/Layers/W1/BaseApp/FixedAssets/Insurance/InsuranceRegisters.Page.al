// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Insurance;

using System.Security.User;

page 5656 "Insurance Registers"
{
    ApplicationArea = FixedAssets;
    Caption = 'Insurance Registers';
    Editable = false;
    PageType = List;
    SourceTable = "Insurance Register";
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
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field("Creation Date"; Rec."Creation Date")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the date when the entries in the register were posted.';
                }
                field("Creation Time"; Rec."Creation Time")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the time when the entries in the register were posted.';
                }
                field("User ID"; Rec."User ID")
                {
                    ApplicationArea = FixedAssets;
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
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the source code that specifies where the entry was created.';
                }
                field("Journal Batch Name"; Rec."Journal Batch Name")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the name of the journal batch, a personalized journal layout, that the entries were posted from.';
                }
                field("From Entry No."; Rec."From Entry No.")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the first item entry number in the register.';
                }
                field("To Entry No."; Rec."To Entry No.")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the last insurance entry number in the register.';
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
                action("Ins&urance Coverage Ledger")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Ins&urance Coverage Ledger';
                    Image = InsuranceLedger;
                    RunObject = Codeunit "Ins. Reg.-Show Coverage Ledger";
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View insurance ledger entries that were created when you post to an insurance account from a purchase invoice, credit memo or journal line.';
                }
            }
        }
        area(processing)
        {
            action("Delete Empty")
            {
                ApplicationArea = All;
                Caption = 'Delete Empty Registers';
                Image = Delete;
                RunObject = Report "Delete Empty Insurance Reg.";
                ToolTip = 'Find and delete empty insurance registers.';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("Ins&urance Coverage Ledger_Promoted"; "Ins&urance Coverage Ledger")
                {
                }
            }
        }
    }
}

