// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.WithholdingTax;

page 12122 "Withholding Tax Payment List"
{
    ApplicationArea = Basic, Suite;
    Caption = 'WithHolding Tax Payment';
    InsertAllowed = false;
    PageType = List;
    SourceTable = "Withholding Tax Payment";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Month; Rec.Month)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the month of the withholding tax payment in numeric format.';
                }
                field(Year; Rec.Year)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the year of the withholding tax payment in numeric format.';
                }
                field("Tax Code"; Rec."Tax Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a unique four-digit code that is used to reference the fiscal withholding tax that is applied to this entry.';
                }
                field("Total Amount"; Rec."Total Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total amount of the original purchase that is subject to withholding tax.';
                }
                field("Base - Excluded Amount"; Rec."Base - Excluded Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of the original purchase that is excluded from withholding tax based on exclusions allowed by law.';
                }
                field("Non Taxable Amount By Treaty"; Rec."Non Taxable Amount By Treaty")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of the original purchase that is excluded from withholding tax based on residency.';
                }
                field("Non Taxable Amount"; Rec."Non Taxable Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of the original purchase that is not taxable due to provisions in the law.';
                }
                field("Taxable Amount"; Rec."Taxable Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of the original purchase that is subject to withholding tax, after non-taxable and excluded amounts have been subtracted.';
                }
                field("Withholding Tax Amount"; Rec."Withholding Tax Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of withholding tax that is due for this payment entry.';
                }
                field("Payable Amount"; Rec."Payable Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of withholding tax that is payable for this entry.';
                }
                field("Payment Date"; Rec."Payment Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date that the withholding tax payable amount is paid to the tax authority.';
                }
                field("Series Number"; Rec."Series Number")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number series code used to assign the entry number.';
                }
                field("Quittance No."; Rec."Quittance No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the quittance number that is assigned to withholding tax payment.';
                }
                field("C/T"; Rec."C/T")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of the withholding tax payment.';
                }
                field("L/P/B"; Rec."L/P/B")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the destination of the withholding tax payment.';
                }
            }
        }
    }

    actions
    {
    }
}

