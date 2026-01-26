// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Reports;
using Microsoft.Finance.GeneralLedger.Account;

page 12175 "Customer Bill Card"
{
    Caption = 'Customer Bill Card';
    PageType = Document;
    SourceTable = "Customer Bill Header";

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
                    ToolTip = 'Specifies the number of the bill header you are setting up.';

                    trigger OnAssistEdit()
                    begin
                        if Rec.AssistEdit(xRec) then
                            CurrPage.Update();
                    end;
                }
                field("Bank Account No."; Rec."Bank Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the account number of the bank that is managing the customer bills.';
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
                    ToolTip = 'Specifies the date you want the bill header to be issued.';
                }
                field("List Date"; Rec."List Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when the bill is created.';
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
                    ToolTip = 'Specifies if the customer bill is of type person or company.';
                }
            }
            part(CustomerBillLine; "Subform Customer Bill Line")
            {
                ApplicationArea = Basic, Suite;
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
            part(Control1901848907; "Customer Bill Information")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "No." = field("No.");
                Visible = true;
            }
            part("File Export Errors"; "Payment Journal Errors Part")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'File Export Errors';
                Provider = CustomerBillLine;
                SubPageLink = "Journal Template Name" = const(''),
                              "Journal Batch Name" = const('12174'),
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
                action(SuggestCustomerBill)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Suggest Customer Bill';
                    Ellipsis = true;
                    Image = SuggestCustomerBill;
                    ToolTip = 'Generate a customer bill based on the current information.';

                    trigger OnAction()
                    begin
                        Rec.TestField("Payment Method Code");
                        Rec.TestField("Bank Account No.");

                        GetBillCode();

                        Clear(SuggestCustomerBill);
                        SuggestCustomerBill.InitValues(Rec, Bill."Allow Issue");
                        SuggestCustomerBill.RunModal();
                    end;
                }
                separator(Action1130009)
                {
                }
                action("Recall Customer Bill")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Recall Customer Bill';
                    Image = ReturnCustomerBill;
                    RunObject = Codeunit "Recall Customer Bill";
                    ToolTip = 'Recall an existing customer bill.';
                }
            }
            group("P&osting")
            {
                Caption = 'P&osting';
                Image = Post;
                action(TestReport)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Test Report';
                    Ellipsis = true;
                    Image = TestReport;
                    ToolTip = 'Print a test report for the document.';

                    trigger OnAction()
                    begin
                        CustomerBillLine.SetRange("Customer Bill No.", Rec."No.");
                        CustomerBillLine.SetRange(Amount, 0);
                        if CustomerBillLine.FindFirst() then
                            Error(Text1130004,
                              CustomerBillLine."Line No.",
                              CustomerBillLine.FieldCaption(Amount));

                        Rec."Test Report" := true;
                        Rec.Modify();
                        Commit();
                        Rec.SetRecFilter();
                        REPORT.RunModal(REPORT::"List of Bank Receipts", true, false, Rec);
                        Rec.SetRange("No.");
                    end;
                }
                action("Post and Print")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Post and Print';
                    Image = PostPrint;
                    RunObject = Codeunit "Customer Bill - Post + Print";
                    ShortCutKey = 'Shift+F9';
                    ToolTip = 'Post the document and also print it.';
                }
            }
        }
        area(reporting)
        {
            action(ExportBillToFile)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Export Bill to File';
                Image = Export;
                ToolTip = 'Export the document.';

                trigger OnAction()
                begin
                    Rec.ExportToFile();
                end;
            }
            action("List of Bank Receipts")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'List of Bank Receipts';
                Image = "Report";
                RunObject = Report "List of Bank Receipts";
                ToolTip = 'View the related list of bank receipts.';
            }
            action(ExportBillToFloppyFile)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Export Bill to Floppy File';
                Image = Export;
                ToolTip = 'Export the document in the local format.';

                trigger OnAction()
                begin
                    Rec.ExportToFloppyFile();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("Post and Print_Promoted"; "Post and Print")
                {
                }
                actionref(SuggestCustomerBill_Promoted; SuggestCustomerBill)
                {
                }
                actionref(ExportBillToFile_Promoted; ExportBillToFile)
                {
                }
                actionref(ExportBillToFloppyFile_Promoted; ExportBillToFloppyFile)
                {
                }
            }
            group(Category_Report)
            {
                Caption = 'Reports';

                actionref("List of Bank Receipts_Promoted"; "List of Bank Receipts")
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        CalcBalance();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        CalcBalance();
    end;

    var
        Bill: Record Bill;
        CustomerBillLine: Record "Customer Bill Line";
        SuggestCustomerBill: Report "Suggest Customer Bills";
        Text1130004: Label 'Line %1 has %2 equal to 0.';
        Balance: Decimal;
        TotalPayments: Decimal;

    procedure GetBillCode()
    var
        PaymentMethod: Record "Payment Method";
    begin
        PaymentMethod.Get(Rec."Payment Method Code");
        Bill.Get(PaymentMethod."Bill Code");
    end;

    procedure CalcBalance()
    var
        BankAcc: Record "Bank Account";
        BankAccPostingGroup: Record "Bank Account Posting Group";
        BillPostingGroup: Record "Bill Posting Group";
        GLAcc: Record "G/L Account";
    begin
        if Rec."Bank Account No." <> '' then begin
            BankAcc.Get(Rec."Bank Account No.");
            if Rec.Type <> Rec.Type::" " then begin
                BankAcc.TestField("Bank Acc. Posting Group");
                BankAccPostingGroup.Get(BankAcc."Bank Acc. Posting Group");
                if BillPostingGroup.Get(Rec."Bank Account No.", Rec."Payment Method Code") then
                    case Rec.Type of
                        Rec.Type::"Bills For Collection":
                            begin
                                if BillPostingGroup."Bills For Collection Acc. No." <> '' then
                                    GLAcc.Get(BillPostingGroup."Bills For Collection Acc. No.");

                                GLAcc.CalcFields(Balance);
                                Balance := GLAcc.Balance;
                            end;
                        Rec.Type::"Bills For Discount":
                            begin
                                if BillPostingGroup."Bills For Discount Acc. No." <> '' then
                                    GLAcc.Get(BillPostingGroup."Bills For Discount Acc. No.");

                                GLAcc.CalcFields(Balance);
                                Balance := GLAcc.Balance;
                            end;
                        Rec.Type::"Bills Subject To Collection":
                            begin
                                if BillPostingGroup."Bills Subj. to Coll. Acc. No." <> '' then
                                    GLAcc.Get(BillPostingGroup."Bills Subj. to Coll. Acc. No.");

                                GLAcc.CalcFields(Balance);
                                Balance := GLAcc.Balance;
                            end;
                    end;
            end;
            Rec.CalcFields("Total Amount");
            TotalPayments := Rec."Total Amount";
        end else begin
            TotalPayments := 0;
            Balance := 0;
        end;
        OnAfterCalcBalance(Rec, Balance, TotalPayments);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcBalance(var CustomerBillHeader: Record "Customer Bill Header"; var Balance: Decimal; var TotalPayments: Decimal)
    begin
    end;
}

