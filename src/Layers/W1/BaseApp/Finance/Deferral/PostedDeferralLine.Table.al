// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Deferral;

using Microsoft.Finance.GeneralLedger.Account;

/// <summary>
/// Posted deferral line records that track individual posted deferral recognition entries.
/// Contains the detailed breakdown of posted deferral amounts by period.
/// </summary>
table 1705 "Posted Deferral Line"
{
    Caption = 'Posted Deferral Line';
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Type of source document (Purchase, Sales, or G/L) that initiated this posted deferral line.
        /// Links to parent Posted Deferral Header record.
        /// </summary>
        field(1; "Deferral Doc. Type"; Enum "Deferral Document Type")
        {
            Caption = 'Deferral Doc. Type';
            TableRelation = "Posted Deferral Header"."Deferral Doc. Type";
        }
        /// <summary>
        /// General Journal document number associated with the posting.
        /// Links to parent Posted Deferral Header record.
        /// </summary>
        field(2; "Gen. Jnl. Document No."; Code[20])
        {
            Caption = 'Gen. Jnl. Document No.';
            TableRelation = "Posted Deferral Header"."Gen. Jnl. Document No.";
        }
        /// <summary>
        /// G/L Account number that was used for the initial deferral posting.
        /// Links to parent Posted Deferral Header record.
        /// </summary>
        field(3; "Account No."; Code[20])
        {
            Caption = 'Account No.';
            TableRelation = "Posted Deferral Header"."Account No.";
        }
        /// <summary>
        /// Document type ID from the posted source document.
        /// Links to parent Posted Deferral Header record.
        /// </summary>
        field(4; "Document Type"; Integer)
        {
            Caption = 'Document Type';
            TableRelation = "Posted Deferral Header"."Document Type";
        }
        /// <summary>
        /// Document number from the posted source document.
        /// Links to parent Posted Deferral Header record.
        /// </summary>
        field(5; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            TableRelation = "Posted Deferral Header"."Document No.";
        }
        /// <summary>
        /// Line number within the posted source document.
        /// Links to parent Posted Deferral Header record.
        /// </summary>
        field(6; "Line No."; Integer)
        {
            Caption = 'Line No.';
            TableRelation = "Posted Deferral Header"."Line No.";
        }
        /// <summary>
        /// Date when this specific deferral amount was posted and recognized.
        /// </summary>
        field(7; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        /// <summary>
        /// Description of the posted deferral line for identification.
        /// </summary>
        field(8; Description; Text[100])
        {
            Caption = 'Description';
        }
        /// <summary>
        /// Amount that was posted and recognized for this period in document currency.
        /// </summary>
        field(9; Amount; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Amount';
        }
        /// <summary>
        /// Amount that was posted and recognized in local currency (LCY).
        /// </summary>
        field(10; "Amount (LCY)"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Amount (LCY)';
        }
        /// <summary>
        /// Currency code of the posted source document.
        /// </summary>
        field(11; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
        }
        /// <summary>
        /// G/L Account used for the temporary deferral balance in the posted transaction.
        /// </summary>
        field(12; "Deferral Account"; Code[20])
        {
            Caption = 'Deferral Account';
            NotBlank = true;
            TableRelation = "G/L Account" where("Account Type" = const(Posting),
                                                 Blocked = const(false));
        }
    }

    keys
    {
        key(Key1; "Deferral Doc. Type", "Gen. Jnl. Document No.", "Account No.", "Document Type", "Document No.", "Line No.", "Posting Date")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    /// <summary>
    /// Initializes a posted deferral line from a deferral line record during posting.
    /// Transfers data and sets up posting-specific fields.
    /// </summary>
    /// <param name="DeferralLine">Source deferral line</param>
    /// <param name="GenJnlDocNo">General journal document number</param>
    /// <param name="AccountNo">Account number from the posting</param>
    /// <param name="NewDocumentType">Document type for the posted record</param>
    /// <param name="NewDocumentNo">Document number for the posted record</param>
    /// <param name="NewLineNo">Line number for the posted record</param>
    /// <param name="DeferralAccount">Deferral account used in posting</param>
    procedure InitFromDeferralLine(DeferralLine: Record "Deferral Line"; GenJnlDocNo: Code[20]; AccountNo: Code[20]; NewDocumentType: Integer; NewDocumentNo: Code[20]; NewLineNo: Integer; DeferralAccount: Code[20])
    begin
        Init();
        TransferFields(DeferralLine);
        "Gen. Jnl. Document No." := GenJnlDocNo;
        "Account No." := AccountNo;
        "Document Type" := NewDocumentType;
        "Document No." := NewDocumentNo;
        "Line No." := NewLineNo;
        "Deferral Account" := DeferralAccount;
        OnBeforeInitFromDeferralLine(Rec, DeferralLine);
        Insert(true);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitFromDeferralLine(var PostedDeferralLine: Record "Posted Deferral Line"; DeferralLine: Record "Deferral Line")
    begin
    end;
}
