// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 7099 EACorpCardDetails
{
    ApplicationArea = Basic, Suite;
    Caption = 'Corp Card Level 3 Details';
    Editable = false;
    PageType = List;
    UsageCategory = Lists;
    SourceTable = EACorpCardTransDetail;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Trans Entry No."; Rec."Trans Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the linked corporate card transaction entry.';
                }
                field("Line No."; Rec."Line No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the detail line number.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the merchant-provided Level 3 line description.';
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the quantity from the Level 3 detail line.';
                }
                field("Unit Cost"; Rec."Unit Cost")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the unit cost from the Level 3 detail line.';
                }
                field("VAT Amount"; Rec."VAT Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT amount from the Level 3 detail line.';
                }
                field("Tax Amount"; Rec."Tax Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the tax amount from the Level 3 detail line.';
                }
                field("Tax Code"; Rec."Tax Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the tax code from the Level 3 detail line.';
                }
            }
        }
    }
}
