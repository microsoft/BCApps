// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

page 12197 "Contribution Codes-INAIL"
{
    ApplicationArea = Basic, Suite;
    Caption = 'INAIL Codes';
    DelayedInsert = true;
    PageType = Card;
    SourceTable = "Contribution Code";
    SourceTableView = where("Contribution Type" = filter(INAIL));
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Rec.Code)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a contribution code that you want the program to attach to the entry.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a description of what the code stands for.';
                }
                field("Social Security Payable Acc."; Rec."Social Security Payable Acc.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the general ledger account that is used to post the Social Security tax that is payable for the purchase.';
                }
                field("Social Security Charges Acc."; Rec."Social Security Charges Acc.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the general ledger account that is used to post Social Security contributions.';
                }
                field("Contribution Type"; Rec."Contribution Type")
                {
                    ApplicationArea = Basic, Suite;
                    Enabled = false;
                    ToolTip = 'Specifies the type of contribution tax.';
                    Visible = false;
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Soc. Sec. Rates")
            {
                Caption = '&Soc. Sec. Rates';
                Image = SocialSecurityPercentage;
                action("Soc. Sec. Code Lines")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Soc. Sec. Code Lines';
                    Image = SocialSecurityLines;
                    RunObject = Page "Contribution Code Lines";
                    RunPageLink = Code = field(Code),
                                  "Contribution Type" = field("Contribution Type");
                    ToolTip = 'View the social security code lines.';
                }
            }
        }
    }
}

