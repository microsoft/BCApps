// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.WithholdingTax;

page 6791 "WHT Group Lines Subform"
{
    ApplicationArea = Basic, Suite;
    Caption = 'WHT Group Lines';
    PageType = ListPart;
    SourceTable = "Withholding Tax Group Line";
    AutoSplitKey = true;
    DelayedInsert = true;

    layout
    {
        area(content)
        {
            repeater(Lines)
            {
                ShowCaption = false;
                field("Wthldg. Tax Prod. Post. Group"; Rec."Wthldg. Tax Prod. Post. Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the withholding tax product posting group for this component.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description for this component.';
                }
                field("Component Order"; Rec."Component Order")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the calculation order for compound withholding tax. Lower numbers are calculated first.';
                }
                field("Compound Base Includes"; Rec."Compound Base Includes")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies comma-separated product posting group codes whose tax amounts are included in the base for this component when using compound calculation.';
                }
            }
        }
    }
}
