// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Receivables;

page 7000073 Suffixes
{
    Caption = 'Suffixes';
    PageType = List;
    SourceTable = Suffix;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Bank Acc. Code"; Rec."Bank Acc. Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the bank code that identifies the banking entity that assigns the bank suffixes.';
                }
                field(Suffix; Rec.Suffix)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a three-digit number that is used by financial institutions to identify the ordering customer.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the nature of the operation for which the bank has assigned a suffix.';
                }
            }
        }
    }

    actions
    {
    }
}

