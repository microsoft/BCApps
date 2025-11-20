// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.DirectDebit;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Foundation.Enums;
using System.Security.AccessControl;

/// <summary>
/// Represents a collection of direct debit transactions that are grouped together for processing and export.
/// This table serves as the header for organizing multiple direct debit entries into a single collection
/// for efficient processing and SEPA file generation.
/// </summary>
table 1207 "Direct Debit Collection"
{
    Caption = 'Direct Debit Collection';
    DataCaptionFields = Identifier, "Created Date-Time";
    DrillDownPageID = "Direct Debit Collections";
    LookupPageID = "Direct Debit Collections";
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Sequential number that uniquely identifies the direct debit collection within the system.
        /// </summary>
        field(1; "No."; Integer)
        {
            Caption = 'No.';
        }
        /// <summary>
        /// Business identifier for the collection, used in external file formats and customer communication.
        /// </summary>
        field(2; Identifier; Code[20])
        {
            Caption = 'Identifier';
        }
        /// <summary>
        /// Timestamp when the direct debit collection was initially created.
        /// </summary>
        field(3; "Created Date-Time"; DateTime)
        {
            Caption = 'Created Date-Time';
        }
        /// <summary>
        /// User name of the person who created this direct debit collection.
        /// </summary>
        field(4; "Created by User"; Code[50])
        {
            Caption = 'Created by User';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
        }
        /// <summary>
        /// Current processing status of the collection, tracking its lifecycle from creation to completion.
        /// </summary>
        field(5; Status; Option)
        {
            Caption = 'Status';
            OptionCaption = 'New,Canceled,File Created,Posted,Closed';
            OptionMembers = New,Canceled,"File Created",Posted,Closed;
        }
        /// <summary>
        /// Calculated count of direct debit collection entries associated with this collection.
        /// </summary>
        field(6; "No. of Transfers"; Integer)
        {
            CalcFormula = count("Direct Debit Collection Entry" where("Direct Debit Collection No." = field("No.")));
            Caption = 'No. of Transfers';
            FieldClass = FlowField;
        }
        /// <summary>
        /// Bank account that will receive the direct debit collections when processed.
        /// </summary>
        field(7; "To Bank Account No."; Code[20])
        {
            Caption = 'To Bank Account No.';
            TableRelation = "Bank Account";
        }
        /// <summary>
        /// Name of the destination bank account, retrieved from the bank account master data.
        /// </summary>
        field(8; "To Bank Account Name"; Text[100])
        {
            CalcFormula = lookup("Bank Account".Name where("No." = field("To Bank Account No.")));
            Caption = 'To Bank Account Name';
            FieldClass = FlowField;
        }
        /// <summary>
        /// Unique message identifier used in SEPA XML files for tracking and reconciliation purposes.
        /// </summary>
        field(9; "Message ID"; Code[35])
        {
            Caption = 'Message ID';
        }
        /// <summary>
        /// Specifies the partner type for the collection, determining processing rules and file formats.
        /// </summary>
        field(10; "Partner Type"; Enum "Partner Type")
        {
            Caption = 'Partner Type';
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        CloseQst: Label 'If you close the collection, you will not be able to register the payments from the collection. Do you want to close the collection anyway?';

    /// <summary>
    /// Creates a new direct debit collection record with the specified parameters.
    /// </summary>
    /// <param name="NewIdentifier">Business identifier for the collection</param>
    /// <param name="NewBankAccountNo">Bank account that will receive the collections</param>
    /// <param name="PartnerType">Partner type determining processing rules</param>
    procedure CreateRecord(NewIdentifier: Code[20]; NewBankAccountNo: Code[20]; PartnerType: Enum "Partner Type")
    begin
        Reset();
        LockTable();
        if FindLast() then;
        Init();
        "No." += 1;
        Identifier := NewIdentifier;
        "Message ID" := Identifier;
        "Created Date-Time" := CurrentDateTime();
        "Created by User" := UserId();
        "To Bank Account No." := NewBankAccountNo;
        "Partner Type" := PartnerType;
        Insert();
    end;

    /// <summary>
    /// Closes the collection and sets status of pending entries to rejected.
    /// Prompts user for confirmation as this action prevents payment registration.
    /// </summary>
    procedure CloseCollection()
    var
        DirectDebitCollectionEntry: Record "Direct Debit Collection Entry";
    begin
        if Status in [Status::Closed, Status::Canceled] then
            exit;
        if not Confirm(CloseQst) then
            exit;

        if Status = Status::New then
            Status := Status::Canceled
        else
            Status := Status::Closed;
        Modify();

        DirectDebitCollectionEntry.SetRange("Direct Debit Collection No.", "No.");
        DirectDebitCollectionEntry.SetRange(Status, DirectDebitCollectionEntry.Status::New);
        DirectDebitCollectionEntry.ModifyAll(Status, DirectDebitCollectionEntry.Status::Rejected);
    end;

    /// <summary>
    /// Initiates SEPA export process for all entries in this collection.
    /// </summary>
    procedure Export()
    var
        DirectDebitCollectionEntry: Record "Direct Debit Collection Entry";
    begin
        DirectDebitCollectionEntry.SetRange("Direct Debit Collection No.", "No.");
        if DirectDebitCollectionEntry.FindFirst() then
            DirectDebitCollectionEntry.ExportSEPA();
    end;

    /// <summary>
    /// Checks if any payment file errors exist for entries in this collection.
    /// </summary>
    /// <returns>True if payment file errors are found</returns>
    procedure HasPaymentFileErrors() Result: Boolean
    var
        GenJnlLine: Record "Gen. Journal Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeHasPaymentFileErrors(Rec, GenJnlLine, Result, IsHandled);
        if IsHandled then
            exit(Result);

        GenJnlLine."Document No." := CopyStr(Format("No."), 1, MaxStrLen(GenJnlLine."Document No."));
        exit(GenJnlLine.HasPaymentFileErrorsInBatch());
    end;

    /// <summary>
    /// Updates the collection status with proper locking.
    /// </summary>
    /// <param name="NewStatus">The new status to set</param>
    procedure SetStatus(NewStatus: Option)
    begin
        LockTable();
        Find();
        Status := NewStatus;
        Modify();
    end;

    /// <summary>
    /// Removes all payment file errors associated with entries in this collection.
    /// </summary>
    procedure DeletePaymentFileErrors()
    var
        DirectDebitCollectionEntry: Record "Direct Debit Collection Entry";
    begin
        DirectDebitCollectionEntry.SetRange("Direct Debit Collection No.", "No.");
        if DirectDebitCollectionEntry.FindSet() then
            repeat
                DirectDebitCollectionEntry.DeletePaymentFileErrors();
            until DirectDebitCollectionEntry.Next() = 0;
    end;

    /// <summary>
    /// Integration event that allows customization of payment file error checking logic.
    /// </summary>
    /// <param name="DirectDebitCollection">The direct debit collection being checked</param>
    /// <param name="DirectDebit">General journal line for error checking</param>
    /// <param name="Result">Result of the error check</param>
    /// <param name="IsHandled">Whether the event has been handled by subscribers</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeHasPaymentFileErrors(DirectDebitCollection: Record "Direct Debit Collection"; var DirectDebit: Record "Gen. Journal Line"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;
}

