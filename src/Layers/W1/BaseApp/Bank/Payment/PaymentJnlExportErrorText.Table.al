// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Finance.GeneralLedger.Journal;

/// <summary>
/// Stores error messages and details that occur during payment journal export operations.
/// This table provides detailed error tracking for payment file generation and validation processes.
/// </summary>
table 1228 "Payment Jnl. Export Error Text"
{
    Caption = 'Payment Jnl. Export Error Text';
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Specifies the name of the journal template associated with the payment export error.
        /// This field links the error to a specific journal template configuration.
        /// </summary>
        field(1; "Journal Template Name"; Code[10])
        {
            Caption = 'Journal Template Name';
            TableRelation = "Gen. Journal Template";
        }
        /// <summary>
        /// Specifies the name of the journal batch associated with the payment export error.
        /// This field links the error to a specific batch within the journal template.
        /// </summary>
        field(2; "Journal Batch Name"; Code[10])
        {
            Caption = 'Journal Batch Name';
            TableRelation = "Gen. Journal Batch".Name where("Journal Template Name" = field("Journal Template Name"));
        }
        /// <summary>
        /// Specifies the line number of the journal line that caused the export error.
        /// This field identifies the specific journal line where the error occurred.
        /// </summary>
        field(3; "Journal Line No."; Integer)
        {
            Caption = 'Journal Line No.';
        }
        /// <summary>
        /// Specifies the sequential line number for multiple errors related to the same journal line.
        /// This field allows multiple error messages to be stored for a single journal line.
        /// </summary>
        field(4; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        /// <summary>
        /// Contains the error message text describing the payment export error.
        /// This field provides detailed information about what went wrong during the export process.
        /// </summary>
        field(5; "Error Text"; Text[250])
        {
            Caption = 'Error Text';
        }
        /// <summary>
        /// Specifies the document number associated with the journal line that caused the error.
        /// This field helps identify the specific document involved in the export error.
        /// </summary>
        field(6; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        /// <summary>
        /// Contains additional information about the payment export error.
        /// This field provides supplementary details that may help in resolving the error.
        /// </summary>
        field(7; "Additional Information"; Text[250])
        {
            Caption = 'Additional Information';
        }
        /// <summary>
        /// Contains a URL to external support resources related to the payment export error.
        /// This field provides a link to help documentation or support sites for error resolution.
        /// </summary>
        field(8; "Support URL"; Text[250])
        {
            Caption = 'Support URL';
        }
    }

    keys
    {
        key(Key1; "Journal Template Name", "Journal Batch Name", "Document No.", "Journal Line No.", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    /// <summary>
    /// Creates a new payment export error record for a general journal line.
    /// This procedure adds error information to help track and resolve payment export issues.
    /// </summary>
    /// <param name="GenJnlLine">The general journal line associated with the error.</param>
    /// <param name="NewText">The error message text.</param>
    /// <param name="NewAddnlInfo">Additional information about the error.</param>
    /// <param name="NewExtSupportInfo">External support URL for error resolution.</param>
    procedure CreateNew(GenJnlLine: Record "Gen. Journal Line"; NewText: Text; NewAddnlInfo: Text; NewExtSupportInfo: Text)
    begin
        SetLineFilters(GenJnlLine);
        if FindLast() then;
        "Journal Template Name" := GenJnlLine."Journal Template Name";
        "Journal Batch Name" := GenJnlLine."Journal Batch Name";
        "Document No." := GenJnlLine."Document No.";
        "Journal Line No." := GenJnlLine."Line No.";
        "Line No." += 1;
        "Error Text" := CopyStr(NewText, 1, MaxStrLen("Error Text"));
        "Additional Information" := CopyStr(NewAddnlInfo, 1, MaxStrLen("Additional Information"));
        "Support URL" := CopyStr(NewExtSupportInfo, 1, MaxStrLen("Support URL"));
        Insert();
    end;

    /// <summary>
    /// Checks whether a specific general journal line has payment export errors.
    /// </summary>
    /// <param name="GenJnlLine">The general journal line to check for errors.</param>
    /// <returns>True if the journal line has errors, false otherwise.</returns>
    procedure JnlLineHasErrors(GenJnlLine: Record "Gen. Journal Line"): Boolean
    begin
        SetLineFilters(GenJnlLine);
        exit(not IsEmpty);
    end;

    /// <summary>
    /// Checks whether a journal batch has payment export errors.
    /// </summary>
    /// <param name="GenJnlLine">The general journal line to identify the batch to check.</param>
    /// <returns>True if the journal batch has errors, false otherwise.</returns>
    procedure JnlBatchHasErrors(GenJnlLine: Record "Gen. Journal Line"): Boolean
    begin
        SetBatchFilters(GenJnlLine);
        exit(not IsEmpty);
    end;

    /// <summary>
    /// Deletes all payment export errors associated with a specific general journal line.
    /// </summary>
    /// <param name="GenJnlLine">The general journal line whose errors should be deleted.</param>
    procedure DeleteJnlLineErrors(GenJnlLine: Record "Gen. Journal Line")
    begin
        if JnlLineHasErrors(GenJnlLine) then
            DeleteAll();
    end;

    /// <summary>
    /// Deletes all payment export errors associated with a journal batch.
    /// </summary>
    /// <param name="GenJnlLine">The general journal line to identify the batch whose errors should be deleted.</param>
    procedure DeleteJnlBatchErrors(GenJnlLine: Record "Gen. Journal Line")
    begin
        if JnlBatchHasErrors(GenJnlLine) then
            DeleteAll();
    end;

    /// <summary>
    /// Deletes payment export errors for a journal line when the record is being deleted.
    /// This procedure is used during cleanup operations to maintain data integrity.
    /// </summary>
    /// <param name="GenJnlLine">The general journal line being deleted.</param>
    procedure DeleteJnlLineErrorsWhenRecDeleted(GenJnlLine: Record "Gen. Journal Line")
    begin
        if JnlLineHasErrorsWhenRecDeleted(GenJnlLine) then
            DeleteAll();
    end;

    /// <summary>
    /// Checks whether a general journal line has payment export errors when the record is being deleted.
    /// This procedure is used to verify error existence during cleanup operations.
    /// </summary>
    /// <param name="GenJnlLine">The general journal line being deleted.</param>
    /// <returns>True if the journal line has errors, false otherwise.</returns>
    procedure JnlLineHasErrorsWhenRecDeleted(GenJnlLine: Record "Gen. Journal Line"): Boolean
    begin
        SetLineFiltersWhenRecDeleted(GenJnlLine);
        exit(not IsEmpty);
    end;

    local procedure SetLineFiltersWhenRecDeleted(GenJnlLine: Record "Gen. Journal Line")
    begin
        SetRange("Journal Template Name", GenJnlLine."Journal Template Name");
        SetRange("Journal Batch Name", GenJnlLine."Journal Batch Name");
        SetRange("Journal Line No.", GenJnlLine."Line No.");
    end;

    local procedure SetBatchFilters(GenJnlLine: Record "Gen. Journal Line")
    begin
        SetRange("Journal Template Name", GenJnlLine."Journal Template Name");
        SetRange("Journal Batch Name", GenJnlLine."Journal Batch Name");
        if ((GenJnlLine."Journal Template Name" = '') and (GenJnlLine."Journal Batch Name" = '')) or (GenJnlLine."Document No." <> '') then
            SetRange("Document No.", GenJnlLine."Document No.");
    end;

    local procedure SetLineFilters(GenJnlLine: Record "Gen. Journal Line")
    begin
        SetRange("Journal Template Name", GenJnlLine."Journal Template Name");
        SetRange("Journal Batch Name", GenJnlLine."Journal Batch Name");
        SetRange("Document No.", GenJnlLine."Document No.");
        SetRange("Journal Line No.", GenJnlLine."Line No.");
    end;
}

