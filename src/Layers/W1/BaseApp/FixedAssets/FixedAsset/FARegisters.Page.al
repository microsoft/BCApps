// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Ledger;

using Microsoft.FixedAssets.Maintenance;
using System.Security.User;

page 5627 "FA Registers"
{
    AdditionalSearchTerms = 'fixed asset registers';
    ApplicationArea = FixedAssets;
    Caption = 'FA Registers';
    Editable = false;
    PageType = List;
    SourceTable = "FA Register";
    UsageCategory = History;
    AboutTitle = 'About FA Registers';
    AboutText = 'With the **FA Registers**, you can review all the transactions posted for fixed assets with the information of Journal Type, G/L Register No., Creation Date & Time, User ID, Source Code, Journal Batch Name, From and To Entry No.';

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
                field("Journal Type"; Rec."Journal Type")
                {
                    ApplicationArea = FixedAssets;
                }
                field("G/L Register No."; Rec."G/L Register No.")
                {
                    ApplicationArea = FixedAssets;
                }
                field(SystemCreatedAt; Rec.SystemCreatedAt)
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the date and time when the entries in the register were posted.';
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
                field("From Maintenance Entry No."; Rec."From Maintenance Entry No.")
                {
                    ApplicationArea = FixedAssets;
                }
                field("To Maintenance Entry No."; Rec."To Maintenance Entry No.")
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
                action("F&A Ledger")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'F&A Ledger';
                    Image = FixedAssetLedger;
                    RunObject = Codeunit "FA Reg.-FALedger";
                    AboutTitle = 'Review FA Ledger';
                    AboutText = 'Review the FA Ledger entries for the selected register no.';
                    ToolTip = 'View the fixed asset ledger entries that are created when you post to fixed asset accounts. Fixed asset ledger entries are created by the posting of a purchase order, invoice, credit memo or journal line.';
                }
                action("Maintenance Ledger")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Maintenance Ledger';
                    Image = MaintenanceLedgerEntries;
                    RunObject = Codeunit "FA Reg.-MaintLedger";
                    AboutTitle = 'Review Maintenance Ledger';
                    AboutText = 'Review the Maintenance Ledger entries for the selected register no.';
                    ToolTip = 'View the maintenance ledger entries for the selected fixed asset.';
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
                RunObject = Report "Delete Empty FA Registers";
                ToolTip = 'Find and delete empty FA registers.';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("F&A Ledger_Promoted"; "F&A Ledger")
                {
                }
                actionref("Maintenance Ledger_Promoted"; "Maintenance Ledger")
                {
                }
            }
        }
    }
}
