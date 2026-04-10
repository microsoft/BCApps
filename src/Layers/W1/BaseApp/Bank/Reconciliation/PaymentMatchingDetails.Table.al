// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reconciliation;

using Microsoft.Bank.BankAccount;

/// <summary>
/// Stores detailed information about payment matching results and criteria for bank reconciliation lines.
/// This table provides audit trail and explanatory details about how automatic payment matching
/// algorithms determined match quality, confidence levels, and specific matching criteria that
/// contributed to the final matching decision. Used for transparency and review purposes.
/// </summary>
/// <remarks>
/// Contains detailed matching messages, criteria explanations, and scoring breakdowns that help
/// users understand why specific matches were made automatically. Supports review workflows
/// where users need to validate or override automatic matching decisions. Linked directly to
/// bank reconciliation statements and individual statement lines for precise audit capability.
/// </remarks>
table 1299 "Payment Matching Details"
{
    Caption = 'Payment Matching Details';
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Bank account number for which the payment matching details apply.
        /// References the specific bank account involved in the reconciliation process.
        /// </summary>
        field(1; "Bank Account No."; Code[20])
        {
            Caption = 'Bank Account No.';
            TableRelation = "Bank Account";
        }
        /// <summary>
        /// Bank reconciliation statement number containing the matched lines.
        /// Links the matching details to the specific reconciliation batch being processed.
        /// </summary>
        field(2; "Statement No."; Code[20])
        {
            Caption = 'Statement No.';
            TableRelation = "Bank Acc. Reconciliation"."Statement No." where("Bank Account No." = field("Bank Account No."));
        }
        /// <summary>
        /// Statement line number within the reconciliation for which matching details are recorded.
        /// Identifies the specific bank statement line that was processed for matching.
        /// </summary>
        field(3; "Statement Line No."; Integer)
        {
            Caption = 'Statement Line No.';
        }
        /// <summary>
        /// Type of bank reconciliation statement (Bank Reconciliation or Payment Application).
        /// Determines the matching workflow and criteria used for automatic matching.
        /// </summary>
        field(4; "Statement Type"; Enum "Bank Acc. Rec. Stmt. Type")
        {
            Caption = 'Statement Type';
        }
        /// <summary>
        /// Sequential line number for organizing multiple matching detail records per statement line.
        /// Allows multiple explanatory messages and criteria details for complex matching scenarios.
        /// </summary>
        field(5; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        /// <summary>
        /// Detailed message explaining the matching criteria, results, or issues encountered.
        /// Provides human-readable explanation of automatic matching decisions and quality factors.
        /// </summary>
        field(6; Message; Text[250])
        {
            Caption = 'Message';
            ToolTip = 'Specifies if a message with additional match details exists.';
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

    /// <summary>
    /// Merges multiple matching detail messages for a bank reconciliation line into a summary text.
    /// Counts the total number of detail messages available for the specified reconciliation line
    /// and returns a formatted summary indicating the message count for user information.
    /// </summary>
    /// <param name="BankAccReconciliationLine">Bank reconciliation line for which to merge matching detail messages.</param>
    /// <returns>Formatted text indicating the number of matching detail messages available.</returns>
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

    /// <summary>
    /// Creates a new payment matching detail record for a specific bank reconciliation line.
    /// Initializes and inserts a new detail record with the provided explanatory message,
    /// automatically assigning the next available line number and linking to the reconciliation line.
    /// </summary>
    /// <param name="BankAccReconciliationLine">Bank reconciliation line for which to create the matching detail.</param>
    /// <param name="DetailMessage">Explanatory message describing matching criteria, results, or issues.</param>
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

