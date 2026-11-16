// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 7430 "EA Corp Card Settlements"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Corporate Card Settlements';
    CardPageId = "EA Corp Card Settlement";
    Editable = false;
    PageType = List;
    SourceTable = "EA Corp Card Settlement";
    SourceTableView = sorting("Settlement Date") order(descending);
    UsageCategory = Lists;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Settlement Entry No."; Rec."Settlement Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the internal settlement entry number.';
                }
                field("Provider Code"; Rec."Provider Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the provider being settled.';
                }
                field("Settlement No."; Rec."Settlement No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the provider settlement identifier.';
                }
                field("Settlement Date"; Rec."Settlement Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the settlement date.';
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the settlement currency.';
                }
                field("Settlement Amount"; Rec."Settlement Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount that the provider will collect.';
                }
                field("Statement Total"; Rec."Statement Total")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total amount of the included statements.';
                }
                field("Statement Count"; Rec."Statement Count")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of included statements.';
                }
                field("Corp Card Bank Account No."; Rec."Corp Card Bank Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the corporate card liability bank account.';
                }
                field("Payment Bank Account No."; Rec."Payment Bank Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the bank account from which the provider will be paid.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the lifecycle status of the settlement.';
                }
                field("Posted Document No."; Rec."Posted Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the document number used to post the settlement.';
                }
                field("Posted Date"; Rec."Posted Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date on which the settlement was posted.';
                }
                field("Reversal Transaction No."; Rec."Reversal Transaction No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the transaction number created by settlement reversal.';
                }
                field("Reversed At"; Rec."Reversed At")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies when the settlement was reversed.';
                }
            }
        }
    }
}
