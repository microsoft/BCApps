// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Bank.DirectDebit;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Sales.Customer;
using Microsoft.Sales.FinanceCharge;
using Microsoft.Sales.History;
using Microsoft.Sales.Receivables;
using Microsoft.Sales.Reminder;

table 12175 "Customer Bill Line"
{
    Caption = 'Customer Bill Line';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Customer Bill No."; Code[20])
        {
            Caption = 'Customer Bill No.';
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(10; "Customer No."; Code[20])
        {
            Caption = 'Customer No.';
            TableRelation = Customer;
        }
        field(11; "Customer Name"; Text[100])
        {
            CalcFormula = lookup(Customer.Name where("No." = field("Customer No.")));
            Caption = 'Customer Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(12; "Customer Bank Acc. No."; Code[20])
        {
            Caption = 'Customer Bank Acc. No.';
            TableRelation = "Customer Bank Account".Code where("Customer No." = field("Customer No."));

            trigger OnValidate()
            var
                SEPADirectDebitMandate: Record "SEPA Direct Debit Mandate";
            begin
                if SEPADirectDebitMandate.Get("Direct Debit Mandate ID") then
                    TestField("Customer Bank Acc. No.", SEPADirectDebitMandate."Customer Bank Account Code");
            end;
        }
        field(15; "Temporary Cust. Bill No."; Code[20])
        {
            Caption = 'Temporary Cust. Bill No.';
        }
        field(20; "Document Type"; Enum "Gen. Journal Document Type")
        {
            Caption = 'Document Type';
        }
        field(21; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            TableRelation = if ("Document Type" = const(Invoice)) "Sales Invoice Header"
            else
            if ("Document Type" = const("Credit Memo")) "Sales Cr.Memo Header"
            else
            if ("Document Type" = const("Finance Charge Memo")) "Finance Charge Memo Header"
            else
            if ("Document Type" = const(Reminder)) "Reminder Header";
        }
        field(22; "Document Occurrence"; Integer)
        {
            Caption = 'Document Occurrence';
        }
        field(23; "Document Date"; Date)
        {
            Caption = 'Document Date';
        }
        field(28; Amount; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Amount';
        }
        field(30; "Due Date"; Date)
        {
            Caption = 'Due Date';
        }
        field(35; "Cumulative Bank Receipts"; Boolean)
        {
            Caption = 'Cumulative Bank Receipts';

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateCumulativeBankReceipts(Rec, xRec, IsHandled);
                if IsHandled then
                    exit;

                TestField("Direct Debit Mandate ID", '');
            end;
        }
        field(40; "Recalled by"; Code[50])
        {
            Caption = 'Recalled by';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(45; "Customer Entry No."; Integer)
        {
            Caption = 'Customer Entry No.';
            TableRelation = "Cust. Ledger Entry";
        }
        field(12000; "Direct Debit Mandate ID"; Code[35])
        {
            Caption = 'Direct Debit Mandate ID';
            TableRelation = "SEPA Direct Debit Mandate" where("Customer No." = field("Customer No."));

            trigger OnValidate()
            var
                SEPADirectDebitMandate: Record "SEPA Direct Debit Mandate";
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateDirectDebitMandateID(Rec, xRec, IsHandled);
                if IsHandled then
                    exit;

                if SEPADirectDebitMandate.Get("Direct Debit Mandate ID") then begin
                    "Customer Bank Acc. No." := SEPADirectDebitMandate."Customer Bank Account Code";
                    TestField("Cumulative Bank Receipts", false);
                end else
                    "Customer Bank Acc. No." := '';
            end;
        }
    }

    keys
    {
        key(Key1; "Customer Bill No.", "Line No.")
        {
            Clustered = true;
            SumIndexFields = Amount;
        }
        key(Key2; "Customer Entry No.")
        {
        }
        key(Key3; "Customer No.", "Due Date", "Customer Bank Acc. No.", "Cumulative Bank Receipts")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        DeletePaymentFileErrors();
    end;

    [Scope('OnPrem')]
    procedure DeletePaymentFileErrors()
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        GenJnlLine."Journal Template Name" := '';
        GenJnlLine."Journal Batch Name" := Format(DATABASE::"Customer Bill Header");
        GenJnlLine."Document No." := "Customer Bill No.";
        GenJnlLine."Line No." := "Line No.";
        GenJnlLine.DeletePaymentFileErrors();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateCumulativeBankReceipts(var CustomerBillLine: Record "Customer Bill Line"; xCustomerBillLine: Record "Customer Bill Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateDirectDebitMandateID(var CustomerBillLine: Record "Customer Bill Line"; xCustomerBillLine: Record "Customer Bill Line"; var IsHandled: Boolean)
    begin
    end;
}

