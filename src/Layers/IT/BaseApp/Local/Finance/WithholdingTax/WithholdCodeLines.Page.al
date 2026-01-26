// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.WithholdingTax;

page 12105 "Withhold Code Lines"
{
    Caption = 'Withhold Code Lines';
    DataCaptionFields = "Withhold Code";
    DelayedInsert = true;
    PageType = List;
    SourceTable = "Withhold Code Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the start date of the withholding tax.';
                }
                field("Withholding Tax %"; Rec."Withholding Tax %")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the withholding percentage that is used to calculate the withholding tax amount.';
                }
                field("Taxable Base %"; Rec."Taxable Base %")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the percentage of the original purchase that is subject to withholding tax by law.';
                }
            }
        }
    }

    actions
    {
    }
}

