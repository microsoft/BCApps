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
                }
                field("Creation Date"; Rec."Creation Date")
                {
                    ApplicationArea = FixedAssets;
                }
                field("Creation Time"; Rec."Creation Time")
                {
                    ApplicationArea = FixedAssets;
                }
                field("User ID"; Rec."User ID")
                {
                    ApplicationArea = FixedAssets;

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
                }
                field("Journal Batch Name"; Rec."Journal Batch Name")
                {
                    ApplicationArea = FixedAssets;
                }
                field("From Entry No."; Rec."From Entry No.")
                {
                    ApplicationArea = FixedAssets;
                }
                field("To Entry No."; Rec."To Entry No.")
                {
                    ApplicationArea = FixedAssets;
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

