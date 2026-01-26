// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Bank.BankAccount;

page 12185 "Vendor Bill Card"
{
    Caption = 'Vendor Bill Card';
    PageType = Document;
    SourceTable = "Vendor Bill Header";
    SourceTableView = where("List Status" = const(Open));

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
                    ToolTip = 'Specifies the number of the bill header you are setting up.';

                    trigger OnAssistEdit()
                    begin
                        Rec.AssistEdit(xRec);
                    end;
                }
                field("Bank Account No."; Rec."Bank Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the account number of the bank that is managing the vendor bills and bank transfers.';
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
            part(VendorBillLines; "Subform Vendor Bill Lines")
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
                    ToolTip = 'Specifies the currency code of the amounts on the bill lines.';
                }
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
                action(SuggestPayment)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Suggest Payment';
                    Ellipsis = true;
                    Image = SuggestVendorPayments;
                    ToolTip = 'Get a suggested payment.';

                    trigger OnAction()
                    begin
                        Rec.TestField("Payment Method Code");

                        if Rec."List Status" = Rec."List Status"::Sent then
                            Error(Text1130001,
                              Rec.FieldCaption("List Status"),
                              SelectStr(2, Text1130002));

                        Clear(SuggestPayment);
                        SuggestPayment.InitValues(Rec);
                        SuggestPayment.RunModal();
                    end;
                }
                action(InsertVendBillLineManual)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Insert Vend. Bill Line Manual';
                    Image = ExpandDepositLine;
                    ToolTip = 'Manually add an entry line to an existing vendor bill and have the amount applied to withholding tax, social security, and payment amounts.';

                    trigger OnAction()
                    var
                        ManualVendPmtLine: Page "Manual vendor Payment Line";
                    begin
                        ManualVendPmtLine.SetVendBillNoAndDueDate(Rec."No.", Rec."Posting Date");
                        ManualVendPmtLine.Run();
                    end;
                }
            }
            action("&Create List")
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Create List';
                Image = ReleaseDoc;
                RunObject = Codeunit "Vend. Bill List-Change Status";
                ToolTip = 'Send bills to your vendor based on the current information.';
            }
            action(Print)
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Print';
                Ellipsis = true;
                Image = Print;
                ToolTip = 'Print the vendor bill.';

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
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(SuggestPayment_Promoted; SuggestPayment)
                {
                }
                actionref("&Create List_Promoted"; "&Create List")
                {
                }
                actionref(Print_Promoted; Print)
                {
                }
            }
            group(Category_Report)
            {
                Caption = 'Reports';

                actionref("Vendor Bill List_Promoted"; "Vendor Bill List")
                {
                }
            }
        }
    }

    var
        SuggestPayment: Report "Suggest Vendor Bills";
        Text1130001: Label '%1 must be %2.';
        Text1130002: Label 'Open,Sent';
}

