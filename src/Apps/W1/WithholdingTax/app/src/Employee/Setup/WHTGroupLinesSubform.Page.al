// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.WithholdingTax.Employee;

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
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Component Order"; Rec."Component Order")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Compound Base Includes"; Rec."Compound Base Includes")
                {
                    ApplicationArea = Basic, Suite;
                }
            }
        }
    }
}
