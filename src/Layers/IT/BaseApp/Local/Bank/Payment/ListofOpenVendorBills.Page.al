// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

page 12194 "List of Open Vendor Bills"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Vendor Bill Card';
    CardPageID = "Vendor Bill Card";
    Editable = false;
    PageType = List;
    SourceTable = "Vendor Bill Header";
    SourceTableView = where("List Status" = const(Open));
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
                    ToolTip = 'Specifies the number of the bill header you are setting up.';
                }
                field("Bank Account No."; Rec."Bank Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the account number of the bank that is managing the vendor bills and bank transfers.';
                }
                field("Payment Method Code"; Rec."Payment Method Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the payment method code for the vendor bills that is entered in the Vendor Card.';
                }
                field("Vendor Bill List No."; Rec."Vendor Bill List No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the vendor bill list identification number.';
                }
                field("List Date"; Rec."List Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when the bill is created .';
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date you want the bill header to be posted.';
                }
                field("Beneficiary Value Date"; Rec."Beneficiary Value Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when the transferred funds from vendor bill are available for use by the vendor.';
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the currency code of the amounts on the bill lines.';
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
                    ToolTip = 'Specifies the number series code used to assign the bill''s number.';
                }
                field("Total Amount"; Rec."Total Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the sum of the amounts in the Amount field on the associated lines.';
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
            action("Vendor Bill List")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Vendor Bill List';
                Image = "Report";
                RunObject = Report "Vendor Bill Report";
                ToolTip = 'View the list of vendor bills.';
            }
        }
        area(Promoted)
        {
            group(Category_Report)
            {
                Caption = 'Reports';

                actionref("Vendor Bill List_Promoted"; "Vendor Bill List")
                {
                }
            }
        }
    }
}

