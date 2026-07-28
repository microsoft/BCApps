// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 7227 "EACorpCardMerchantRules"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Merchant Normalization Rules';
    PageType = List;
    UsageCategory = Lists;
    SourceTable = EACorpCardMerchantRule;
    SourceTableView = sorting(Priority);

    layout
    {
        area(Content)
        {
            repeater(Rules)
            {
                field("Rule Id"; Rec."Rule Id")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the rule ID.';
                    Editable = false;
                }
                field(Priority; Rec.Priority)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the priority order for rule evaluation (lower = higher priority).';
                }
                field(Active; Rec.Active)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether this rule is active.';
                }
                field(Pattern; Rec.Pattern)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the regex pattern to match merchant names.';
                }
                field("Normalized Name"; Rec."Normalized Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the normalized merchant name to use when this pattern matches.';
                }
                field("Expense Category"; Rec."Expense Category")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the expense category code for matching transactions.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(MovePriority)
            {
                Caption = 'Change Priority';
                ApplicationArea = Basic, Suite;
                Image = MoveUp;
                ToolTip = 'Change the priority order for rule evaluation.';

                trigger OnAction()
                begin
                    if Rec.Priority < 1000 then
                        Rec.Priority += 10
                    else
                        Rec.Priority := 10;
                    Rec.Modify();
                end;
            }
        }
    }
}
