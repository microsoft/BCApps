// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

page 12109 "Contribution Bracket Lines"
{
    Caption = 'Contribution Bracket Lines';
    DataCaptionFields = "Code";
    DelayedInsert = true;
    PageType = List;
    SourceTable = "Contribution Bracket Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the cutoff amount that defines the maximum limit for the bracket.';
                }
                field("Taxable Base %"; Rec."Taxable Base %")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the percentage of the taxable base that is subject to Social Security taxes.';
                }
            }
        }
    }

    actions
    {
    }
}

