// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

page 3010542 "DTA Setup List"
{
    ApplicationArea = Advanced;
    Caption = 'DTA Setup List';
    CardPageID = "DTA Setup";
    Editable = false;
    PageType = List;
    SourceTable = "DTA Setup";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Bank Code"; Rec."Bank Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a short name for the partner bank.';
                }
                field("DTA/EZAG"; Rec."DTA/EZAG")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if this setup is for DTA or EZAG.';
                }
                field("DTA Main Bank"; Rec."DTA Main Bank")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the main bank.';
                }
                field("DTA Currency Code"; Rec."DTA Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the foreign currency used for the account.';
                }
                field("DTA Debit Acc. No."; Rec."DTA Debit Acc. No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the bank account that the payment orders are debited from.';
                }
                field("DTA Bank Name"; Rec."DTA Bank Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies part of the bank address.';
                }
                field("DTA Customer ID"; Rec."DTA Customer ID")
                {
                    ToolTip = 'Specifies the identification that is assigned by the bank and is normally identical to the DTA Sender ID.';
                    Visible = false;
                }
            }
        }
    }

    actions
    {
    }
}

