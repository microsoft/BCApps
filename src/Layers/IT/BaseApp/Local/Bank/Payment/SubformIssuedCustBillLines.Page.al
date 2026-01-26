// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

page 12181 "Subform Issued Cust.Bill Lines"
{
    AutoSplitKey = true;
    Caption = 'Lines';
    DelayedInsert = true;
    Editable = false;
    PageType = ListPart;
    SourceTable = "Issued Customer Bill Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Customer No."; Rec."Customer No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the identification number of the customer.';
                }
                field("Customer Name"; Rec."Customer Name")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    ToolTip = 'Specifies the name of the customer from the posted invoice.';
                }
                field("Temporary Cust. Bill No."; Rec."Temporary Cust. Bill No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a temporary identification number for the customer bill.';
                    Visible = false;
                }
                field("Final Cust. Bill No."; Rec."Final Cust. Bill No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a final identification number for the customer bill.';
                }
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of document that is the source of the customer bill.';
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a unique identification number, that refers to the source document generated the customer bill entry.';
                }
                field("Document Date"; Rec."Document Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the transaction date of the source document that generated the customer bill entry.';
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the customer''s amount due for payment.';
                }
                field("Due Date"; Rec."Due Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when the bill is due for payment.';
                }
                field("Customer Bank Acc. No."; Rec."Customer Bank Acc. No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the bank account number of the bank that is managing the customer''s bills.';
                }
                field("Cumulative Bank Receipts"; Rec."Cumulative Bank Receipts")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the customer bill entry is included in a cumulative bank receipt.';
                }
                field("Recalled by"; Rec."Recalled by")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if a customer bill has been recalled.';
                }
                field("Direct Debit Mandate ID"; Rec."Direct Debit Mandate ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the mandate.';
                }
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
                action(SelectBillToRecall)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Select Bill to Recall';
                    ShortCutKey = 'F7';
                    ToolTip = 'Specify the customer bill to recall.';

                    trigger OnAction()
                    begin
                        SetApply();
                    end;
                }
                action("Recall Customer Bill")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Recall Customer Bill';
                    Image = ReturnCustomerBill;
                    ToolTip = 'Recall an existing customer bill.';

                    trigger OnAction()
                    begin
                        RecallBill();
                    end;
                }
            }
        }
    }

    var
        Text000: Label 'Customer Bill %1 already recalled.';
        IssuedCustomerBillLine: Record "Issued Customer Bill Line";
        IssuingCustomerBill: Codeunit "Recall Customer Bill";

    [Scope('OnPrem')]
    procedure RecallBill()
    begin
        IssuingCustomerBill.RecallIssuedBill(Rec);
    end;

    [Scope('OnPrem')]
    procedure SetApply()
    begin
        IssuedCustomerBillLine.Get(Rec."Customer Bill No.", Rec."Line No.");
        if Rec."Recall Date" <> 0D then
            Error(Text000, Rec."Temporary Cust. Bill No.");

        if Rec."Line No." <> 0 then begin
            if Rec."Recalled by" <> '' then
                IssuedCustomerBillLine."Recalled by" := ''
            else
                if UserId <> '' then
                    IssuedCustomerBillLine."Recalled by" := UserId
                else
                    IssuedCustomerBillLine."Recalled by" := '***';
            IssuedCustomerBillLine.Modify();
        end;
    end;
}

