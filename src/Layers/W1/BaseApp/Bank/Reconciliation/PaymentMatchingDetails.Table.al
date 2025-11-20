// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reconciliation;

using Microsoft.Bank.BankAccount;

table 1299 "Payment Matching Details"
{
    Caption = 'Payment Matching Details';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Bank Account No."; Code[20])
        {
            Caption = 'Bank Account No.';
            TableRelation = "Bank Account";
        }
        field(2; "Statement No."; Code[20])
        {
            Caption = 'Statement No.';
            TableRelation = "Bank Acc. Reconciliation"."Statement No." where("Bank Account No." = field("Bank Account No."));
        }
        field(3; "Statement Line No."; Integer)
        {
            Caption = 'Statement Line No.';
        }
        field(4; "Statement Type"; Enum "Bank Acc. Rec. Stmt. Type")
        {
            Caption = 'Statement Type';
        }
        field(5; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(6; Message; Text[250])
        {
            Caption = 'Message';
        }
    }

    keys
    {
        key(Key1; "Statement Type", "Bank Account No.", "Statement No.", "Statement Line No.", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        MultipleMessagesTxt: Label '%1 message(s)', Comment = 'Used to show users how many messages is present. Text will be followed by actual messages text. %1 is number of messages.';

    procedure MergeMessages(BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"): Text
    var
        PaymentMatchingDetails: Record "Payment Matching Details";
        Message2: Text;
        NoOfMessages: Integer;
    begin
        Message2 := '';

        PaymentMatchingDetails.SetRange("Statement Type", BankAccReconciliationLine."Statement Type");
        PaymentMatchingDetails.SetRange("Bank Account No.", BankAccReconciliationLine."Bank Account No.");
        PaymentMatchingDetails.SetRange("Statement No.", BankAccReconciliationLine."Statement No.");
        PaymentMatchingDetails.SetRange("Statement Line No.", BankAccReconciliationLine."Statement Line No.");

        NoOfMessages := PaymentMatchingDetails.Count();
        if NoOfMessages >= 1 then
            Message2 := StrSubstNo(MultipleMessagesTxt, NoOfMessages);

        exit(Message2);
    end;

    procedure CreatePaymentMatchingDetail(BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; DetailMessage: Text[250])
    begin
        Clear(Rec);

        Init();
        "Statement Type" := BankAccReconciliationLine."Statement Type";
        "Bank Account No." := BankAccReconciliationLine."Bank Account No.";
        "Statement No." := BankAccReconciliationLine."Statement No.";
        "Statement Line No." := BankAccReconciliationLine."Statement Line No.";
        "Line No." := GetNextAvailableLineNo();
        Message := DetailMessage;
        Insert(true);
    end;

    local procedure GetNextAvailableLineNo() NextLineNo: Integer
    var
        PaymentMatchingDetails: Record "Payment Matching Details";
    begin
        NextLineNo := 10000;

        PaymentMatchingDetails.SetRange("Statement Type", "Statement Type");
        PaymentMatchingDetails.SetRange("Bank Account No.", "Bank Account No.");
        PaymentMatchingDetails.SetRange("Statement No.", "Statement No.");
        PaymentMatchingDetails.SetRange("Statement Line No.", "Statement Line No.");

        if PaymentMatchingDetails.FindLast() then
            NextLineNo += PaymentMatchingDetails."Line No.";

        exit(NextLineNo);
    end;
}

