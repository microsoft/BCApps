// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Bank.Reports;

page 12180 "Issued Customer Bill Card"
{
    Caption = 'Issued Customer Bill Card';
    DeleteAllowed = true;
    Editable = false;
    PageType = Card;
    SourceTable = "Issued Customer Bill Header";

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
                    ToolTip = 'Specifies the issued bill number.';
                }
                field("Bank Account No."; Rec."Bank Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the bank account number of the bank that is managing the customer bills.';
                }
                field("Payment Method Code"; Rec."Payment Method Code")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the payment method code for the customer bills that is entered in the Customer Card.';
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the date the bill header was issued.';
                }
                field("List Date"; Rec."List Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date that the issued customer bill list is created.';
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the type of the bank receipt that is applied to the customer bill.';
                }
                field("Partner Type"; Rec."Partner Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the issued customer bill is of type person or company.';
                }
            }
            part(BankReceiptsLines; "Subform Issued Cust.Bill Lines")
            {
                ApplicationArea = Basic, Suite;
                Editable = false;
                SubPageLink = "Customer Bill No." = field("No.");
            }
            group(Posting)
            {
                Caption = 'Posting';
                field("Reason Code"; Rec."Reason Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the reason code from the transaction entry.';
                }
                field("Report Header"; Rec."Report Header")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a descriptive title for the report header.';
                }
            }
        }
        area(factboxes)
        {
            part(Control1901849007; "Issued Cust. Bill Information")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "No." = field("No.");
                Visible = true;
            }
            part("File Export Errors"; "Payment Journal Errors Part")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'File Export Errors';
                Provider = BankReceiptsLines;
                SubPageLink = "Journal Template Name" = const(''),
                              "Journal Batch Name" = const('12177'),
                              "Journal Line No." = field("Line No."),
                              "Document No." = field("Customer Bill No.");
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                separator(Action1130008)
                {
                }
            }
            action(PrintIssuedCustBill)
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Print';
                Ellipsis = true;
                Image = Print;
                ToolTip = 'Print the customer bill.';

                trigger OnAction()
                begin
                    Rec.SetRange("No.", Rec."No.");
                    REPORT.RunModal(REPORT::"Issued Cust Bills Report", true, false, Rec);
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
            action(ExportIssuedBillToFile)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Export Issued Bill to File';
                Image = Export;
                ToolTip = 'Export the document.';

                trigger OnAction()
                begin
                    Rec.ExportToFile();
                end;
            }
            action(ExportIssuedBillToFloppyFile)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Export Issued Bill to Floppy File';
                Image = Export;
                ToolTip = 'Export the document in the local format.';

                trigger OnAction()
                begin
                    Rec.ExportToFloppyFile();
                end;
            }
            action("Issued Cust Bills Report")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Issued Cust Bills Report';
                Image = "Report";
                RunObject = Report "Issued Cust Bills Report";
                ToolTip = 'View a report of issued customer bills.';
            }
            action("Closing Bank Receipts")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Closing Bank Receipts';
                Image = "Report";
                RunObject = Report "Closing Bank Receipts";
                ToolTip = 'View the related closing bank receipts.';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(PrintIssuedCustBill_Promoted; PrintIssuedCustBill)
                {
                }
                actionref("&Navigate_Promoted"; "&Navigate")
                {
                }
                actionref(ExportIssuedBillToFile_Promoted; ExportIssuedBillToFile)
                {
                }
                actionref(ExportIssuedBillToFloppyFile_Promoted; ExportIssuedBillToFloppyFile)
                {
                }
            }
            group(Category_Report)
            {
                Caption = 'Reports';

                actionref("Issued Cust Bills Report_Promoted"; "Issued Cust Bills Report")
                {
                }
                actionref("Closing Bank Receipts_Promoted"; "Closing Bank Receipts")
                {
                }
            }
        }
    }
}

