// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 7225 EACorpCardMCCMap
{
    ApplicationArea = Basic, Suite;
    Caption = 'Corp Card MCC Map';
    PageType = List;
    UsageCategory = Lists;
    SourceTable = EACorpCardMCCMap;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field(MCC; Rec.MCC)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the merchant category code.';
                }
                field("Expense Category"; Rec."Expense Category")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the expense category mapped to this MCC.';
                }
                field("VAT Bus. Posting Group"; Rec."VAT Bus. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT business posting group suggestion for this MCC.';
                }
                field(Blocked; Rec.Blocked)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether this mapping is blocked.';
                }
            }
        }
    }
}