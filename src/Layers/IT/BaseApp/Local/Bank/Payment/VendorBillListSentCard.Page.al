// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Bank.BankAccount;
using System.Telemetry;

page 12190 "Vendor Bill List Sent Card"
{
    Caption = 'Vendor Bill List Sent Card';
    PageType = Card;
    SourceTable = "Vendor Bill Header";
    SourceTableView = where("List Status" = const(Sent));

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; Rec."No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the number of the bill header you are setting up.';

                    trigger OnAssistEdit()
                    begin
                        Rec.AssistEdit(xRec);
                    end;
                }
                field("Vendor Bill List No."; Rec."Vendor Bill List No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the vendor bill list identification number.';
                }
                field("Bank Account No."; Rec."Bank Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the account number of the bank that is managing the vendor bills and bank transfers.';
                }
                field("Payment Method Code"; Rec."Payment Method Code")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the payment method code for the vendor bills that is entered in the Vendor Card.';
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the date you want the bill header to be posted.';
                }
                field("List Date"; Rec."List Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when the bill is created .';
                }
                field("Beneficiary Value Date"; Rec."Beneficiary Value Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
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
                    ToolTip = 'Specifies the sum of the amounts in the Amount field on the associated lines.';
                }
            }
            part(VendBillLinesSent; "Subform Sent Vendor Bill Lines")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "Vendor Bill List No." = field("No.");
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
                    Editable = false;
                    ToolTip = 'Specifies the currency code of the amounts on the bill lines.';
                }
            }
        }
        area(factboxes)
        {
            part("Payment Journal Errors"; "Payment Journal Errors Part")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'File Export Errors';
                Provider = VendBillLinesSent;
                SubPageLink = "Journal Template Name" = const(''),
                              "Journal Batch Name" = const(''),
                              "Document No." = field("Vendor Bill List No."),
                              "Journal Line No." = field("Line No.");
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Vend. Bill")
            {
                Caption = '&Vend. Bill';
                Image = VendorBill;
                action(List)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'List';
                    Image = OpportunitiesList;
                    RunObject = Page "List of Sent Vendor Bills";
                    ShortCutKey = 'Shift+Ctrl+L';
                    ToolTip = 'View the list of all documents.';
                }
                action(Card)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Card';
                    Image = EditLines;
                    RunObject = Page "Bank Account Card";
                    RunPageLink = "No." = field("Bank Account No.");
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'Open the card.';
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action(ExportBillListToFile)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Export Bill List to File';
                    Ellipsis = true;
                    Image = Export;
                    ToolTip = 'View the releated export bill list to file.';

                    trigger OnAction()
                    begin
                        FeatureTelemetry.LogUptake('1000HQ8', ITPaymentBillTok, Enum::"Feature Uptake Status"::"Used");
                        Rec.ExportToFile();
                        FeatureTelemetry.LogUsage('1000HQ9', ITPaymentBillTok, 'IT Vendor Payments and Customer Bills Exported');
                    end;
                }
            }
            group("P&osting")
            {
                Caption = 'P&osting';
                Image = Post;
                action(Post)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Post';
                    Image = Post;
                    RunObject = Codeunit "Vendor Bill List - Post";
                    ShortCutKey = 'F9';
                    ToolTip = 'Post the document.';
                }
            }
            action(CancelList)
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Cancel List';
                Image = Cancel;
                ToolTip = 'Cancel the changes to the list of sent vendor bills.';

                trigger OnAction()
                begin
                    VendBillListChangeStatus.FromSentToOpen(Rec);
                    CurrPage.Update();
                end;
            }
            action(Print)
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Print';
                Ellipsis = true;
                Image = Print;
                ToolTip = 'Print the list of vendor bills.';

                trigger OnAction()
                begin
                    Rec.SetRecFilter();
                    REPORT.RunModal(REPORT::"Vendor Bill Report", true, false, Rec);
                    Rec.SetRange("No.");
                end;
            }
        }
        area(reporting)
        {
            action("Vendor Bills List")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Vendor Bills List';
                Image = "Report";
                RunObject = Report "Vendor Bill Report";
                ToolTip = 'View the list of vendor bills.';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(Post_Promoted; Post)
                {
                }
                actionref(CancelList_Promoted; CancelList)
                {
                }
                actionref(Print_Promoted; Print)
                {
                }
            }
            group(Category_Report)
            {
                Caption = 'Reports';

                actionref(ExportBillListToFile_Promoted; ExportBillListToFile)
                {
                }
                actionref("Vendor Bills List_Promoted"; "Vendor Bills List")
                {
                }
            }
        }
    }

    var
        VendBillListChangeStatus: Codeunit "Vend. Bill List-Change Status";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        ITPaymentBillTok: Label 'IT Issue Vendor Payments and Customer Bills', Locked = true;
}

