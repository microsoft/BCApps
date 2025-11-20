// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.PositivePay;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.Currency;
using System.Security.AccessControl;

/// <summary>
/// Stores individual check details for positive pay entries, providing detailed information about each check in an upload.
/// This table maintains the detailed check information that was uploaded to the bank for positive pay validation.
/// </summary>
/// <remarks>
/// The Positive Pay Entry Detail table stores the individual check records that were submitted to the bank as part of
/// a positive pay upload. Each record represents a single check with its complete details including check number, amount,
/// payee, and document type. This table provides an audit trail of what check information was sent to the bank and when.
/// The records are linked to their parent Positive Pay Entry through the bank account and upload date-time fields.
/// </remarks>
table 1232 "Positive Pay Entry Detail"
{
    Caption = 'Positive Pay Entry Detail';
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Bank account number for which this positive pay entry detail was uploaded.
        /// </summary>
        field(1; "Bank Account No."; Code[20])
        {
            Caption = 'Bank Account No.';
            TableRelation = "Bank Account"."No.";
        }
        /// <summary>
        /// Date and time when this positive pay entry was uploaded to the bank.
        /// </summary>
        field(2; "Upload Date-Time"; DateTime)
        {
            Caption = 'Upload Date-Time';
            TableRelation = "Positive Pay Entry"."Upload Date-Time" where("Bank Account No." = field("Bank Account No."));
        }
        /// <summary>
        /// Sequential number identifying this detail record within the positive pay upload.
        /// </summary>
        field(3; "No."; Integer)
        {
            Caption = 'No.';
        }
        /// <summary>
        /// Check number as it appears on the physical check document.
        /// </summary>
        field(5; "Check No."; Code[20])
        {
            Caption = 'Check No.';
        }
        /// <summary>
        /// Currency code for the check amount, typically matching the bank account's currency.
        /// </summary>
        field(6; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency.Code;
        }
        /// <summary>
        /// Type of document indicating whether this is a regular check or a voided check.
        /// </summary>
        field(7; "Document Type"; Option)
        {
            Caption = 'Document Type';
            OptionCaption = 'CHECK,VOID';
            OptionMembers = CHECK,VOID;
        }
        /// <summary>
        /// Date when the check was issued or printed.
        /// </summary>
        field(8; "Document Date"; Date)
        {
            Caption = 'Document Date';
        }
        /// <summary>
        /// Monetary amount of the check in the specified currency.
        /// </summary>
        field(9; Amount; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Amount';
        }
        /// <summary>
        /// Name of the individual or organization to whom the check is payable.
        /// </summary>
        field(10; Payee; Text[100])
        {
            Caption = 'Payee';
            DataClassification = EndUserIdentifiableInformation;
        }
        /// <summary>
        /// User ID of the person who created or last updated this positive pay entry detail.
        /// </summary>
        field(11; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
        }
        /// <summary>
        /// Date when this positive pay entry detail was last updated.
        /// </summary>
        field(12; "Update Date"; Date)
        {
            Caption = 'Update Date';
        }
    }

    keys
    {
        key(Key1; "Bank Account No.", "Upload Date-Time", "No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    /// <summary>
    /// Copies data from a Positive Pay Detail record into this entry detail record for tracking purposes.
    /// </summary>
    /// <param name="PosPayDetail">The source positive pay detail record to copy data from.</param>
    /// <param name="BankAcct">The bank account code to associate with this entry detail.</param>
    /// <remarks>
    /// This procedure is used to create audit trail records that track what check information was uploaded to the bank.
    /// It maps document types from the export format to the entry detail format and sets tracking fields.
    /// </remarks>
    procedure CopyFromPosPayEntryDetail(PosPayDetail: Record "Positive Pay Detail"; BankAcct: Code[20])
    begin
        "Bank Account No." := BankAcct;
        "No." := PosPayDetail."Entry No.";
        "Check No." := PosPayDetail."Check Number";
        "Currency Code" := PosPayDetail."Currency Code";
        if PosPayDetail."Record Type Code" = 'V' then
            "Document Type" := "Document Type"::VOID
        else
            "Document Type" := "Document Type"::CHECK;

        "Document Date" := PosPayDetail."Issue Date";
        Amount := PosPayDetail.Amount;
        Payee := PosPayDetail.Payee;
        "User ID" := CopyStr(UserId(), 1, MaxStrLen("User ID"));
        "Update Date" := Today;
    end;
}

