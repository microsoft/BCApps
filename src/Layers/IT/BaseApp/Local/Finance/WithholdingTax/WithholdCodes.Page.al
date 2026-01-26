// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.WithholdingTax;

page 12104 "Withhold Codes"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Withholding Tax Codes';
    DelayedInsert = true;
    PageType = List;
    SourceTable = "Withhold Code";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Rec.Code)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a code for a withhold code.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a description of what the code stands for.';
                }
                field("Tax Code"; Rec."Tax Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a unique four-digit code that is used to reference the fiscal withholding tax applied to this entry.';
                }
                field("770 Code"; Rec."770 Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the different types of withholding tax that can apply to vendor purchases.';
                }
                field("770 Form"; Rec."770 Form")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of withholding tax that will be reported on form 770.';
                }
                field("Recipient May Report Income"; Rec."Recipient May Report Income")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the vendor can report income based on the purchases assigned to this withhold code.';
                }
                field("Source-Withholding Tax"; Rec."Source-Withholding Tax")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the source of the withhold code is an official withholding tax governed by the Italian tax authority.';
                }
                field("Withholding Taxes Payable Acc."; Rec."Withholding Taxes Payable Acc.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the general ledger account that is used to post the withholding tax for the purchase.';
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("With&hold Rates")
            {
                Caption = 'With&hold Rates';
                Image = Percentage;
                action("Withhold Code Lines")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Withhold Code Lines';
                    Image = CodesList;
                    RunObject = Page "Withhold Code Lines";
                    RunPageLink = "Withhold Code" = field(Code);
                    ToolTip = 'View the lines.';
                }
            }
        }
    }
}

