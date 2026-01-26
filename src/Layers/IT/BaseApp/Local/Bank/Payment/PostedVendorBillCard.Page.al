// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

page 12192 "Posted Vendor Bill Card"
{
    Caption = 'Posted Vendor Bill Card';
    Editable = false;
    PageType = Document;
    SourceTable = "Posted Vendor Bill Header";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the posted bill number.';
                }
                field("Bank Account No."; Rec."Bank Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the bank account number of the bank that is managing the vendor bills and bank transfers.';
                }
                field("Payment Method Code"; Rec."Payment Method Code")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the payment method code for the vendor bills that is entered in the Vendor Card.';
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the date that the vendor bill was posted.';
                }
                field("List Date"; Rec."List Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when the vendor bill was created.';
                }
                field("Beneficiary Value Date"; Rec."Beneficiary Value Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when the transferred funds from vendor bill are available for use by the vendor.';
                }
                field("Bank Expense"; Rec."Bank Expense")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies any expenses or fees that are charged by the bank for the bank transfer.';
                }
                field("Total Amount"; Rec."Total Amount")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the sum of the amounts in the Amount to Pay fields on the related posted vendor bill lines.';
                }
            }
            part(SubformPostedVendBillLines; "Subform Posted Vend Bill Lines")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "Vendor Bill No." = field("No.");
            }
            group(Posting)
            {
                Caption = 'Posting';
                field("Reason Code"; Rec."Reason Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the reason code for the vendor bill.';
                }
                field("Report Header"; Rec."Report Header")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a descriptive title for the report header.';
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the currency code used to calculate the amounts on the bill.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("&Print")
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Print';
                Ellipsis = true;
                Image = Print;
                ToolTip = 'Print the vendor bill.';

                trigger OnAction()
                begin
                    Rec.SetRecFilter();
                    REPORT.RunModal(REPORT::"Issued Vendor Bill List", true, false, Rec);
                    Rec.SetRange("No.");
                end;
            }
            action("&Navigate")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Find entries...';
                Image = Navigate;
                ToolTip = 'View the number and type of entries that have the same document number or posting date.';

                trigger OnAction()
                begin
                    Rec.Navigate();
                end;
            }
        }
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
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("&Print_Promoted"; "&Print")
                {
                }
                actionref("&Navigate_Promoted"; "&Navigate")
                {
                }
            }
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

