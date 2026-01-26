// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

page 12195 "List of Posted Vend. Bill List"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Posted Vendor Bill Card';
    CardPageID = "Posted Vendor Bill Card";
    Editable = false;
    PageType = List;
    SourceTable = "Posted Vendor Bill Header";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1130000)
            {
                ShowCaption = false;
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the posted bill number.';
                }
                field("Bank Account No."; Rec."Bank Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the bank account number of the bank that is managing the vendor bills and bank transfers.';
                }
                field("Payment Method Code"; Rec."Payment Method Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the payment method code for the vendor bills that is entered in the Vendor Card.';
                }
                field("Temporary Bill No."; Rec."Temporary Bill No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a temporary identification number for the customer bill.';
                }
                field("List Status"; Rec."List Status")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the vendor bill list remains open or has been sent to the bank.';
                }
                field("List Date"; Rec."List Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when the vendor bill was created.';
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date that the bill header was posted.';
                }
                field("Beneficiary Value Date"; Rec."Beneficiary Value Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when the transferred funds from vendor bill are available for use by the vendor.';
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the currency code used to calculate the amounts on the bill.';
                }
                field("Currency Factor"; Rec."Currency Factor")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the currency exchange factor based on the list date of the bank transfer.';
                }
                field("Reason Code"; Rec."Reason Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the reason code for the vendor bill.';
                }
                field("No. Series"; Rec."No. Series")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number series code used to assign a number to the posted bill.';
                }
                field("Total Amount"; Rec."Total Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the sum of the amounts in the Amount to Pay fields on the related posted vendor bill lines.';
                }
                field("Bank Expense"; Rec."Bank Expense")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies any expenses or fees that are charged by the bank for the bank transfer.';
                }
                field("Report Header"; Rec."Report Header")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a descriptive title for the report header.';
                }
            }
        }
    }

    actions
    {
        area(reporting)
        {
            action("Issued Vendor Bill List")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Issued Vendor Bill List';
                Image = "Report";
                RunObject = Report "Issued Vendor Bill List";
                ToolTip = 'View the releated issued vendor bill list.';
            }
        }
        area(Promoted)
        {
            group(Category_Report)
            {
                Caption = 'Reports';

                actionref("Issued Vendor Bill List_Promoted"; "Issued Vendor Bill List")
                {
                }
            }
        }
    }
}

