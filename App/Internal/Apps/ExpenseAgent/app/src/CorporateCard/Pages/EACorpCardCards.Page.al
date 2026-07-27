// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 7221 EACorpCardCards
{
    Caption = 'Corp Cards';
    PageType = List;
    UsageCategory = Lists;
    SourceTable = EACorpCard;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Card Id"; Rec."Card Id")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the internal card identifier.';
                }
                field("Provider Code"; Rec."Provider Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the transaction feed provider for this card.';
                }
                field("External Card Ref"; Rec."External Card Ref")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the provider external card reference.';
                }
                field("Masked Card No."; Rec."Masked Card No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the masked card number.';
                }
                field("Expense User No."; Rec."Expense User No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the expense user linked to this card.';
                }
                field(Blocked; Rec.Blocked)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether this card is blocked from new imports.';
                }
            }
        }
    }
}