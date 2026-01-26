// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

page 12131 "Contribution Payment List"
{
    ApplicationArea = Basic, Suite;
    Caption = 'INAIL Payment';
    Editable = false;
    PageType = List;
    SourceTable = "Contribution Payment";
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
                    ToolTip = 'Specifies the month of the contribution payment in numeric format.';
                }
                field(Year; Rec.Year)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the year of the contribution payment in numeric format.';
                }
                field("Payment Date"; Rec."Payment Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date that the contribution amount is paid to the tax authority.';
                }
                field("Gross Amount"; Rec."Gross Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total amount of the original purchase that is subject to contributions.';
                }
                field("Non Taxable Amount"; Rec."Non Taxable Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of the original purchase that is not taxable due to provisions in the law.';
                }
                field("Contribution Base"; Rec."Contribution Base")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of the original purchase that is subject to contribution tax after nontaxable amounts have been subtracted.';
                }
                field("Total Social Security Amount"; Rec."Total Social Security Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total amount of Social Security tax that is due for this payment.';
                }
                field("Free-Lance Amount"; Rec."Free-Lance Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of the Social Security tax that is paid by the independent contractor or vendor.';
                }
                field("Company Amount"; Rec."Company Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of Social Security tax that your company is liable for.';
                }
                field("Series Number"; Rec."Series Number")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number series code used to assign the entry number.';
                }
                field("Quiettance No."; Rec."Quiettance No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number that was assigned to the entry upon payment to release your organization from the contribution debt and obligation.';
                }
            }
        }
    }

    actions
    {
    }
}

