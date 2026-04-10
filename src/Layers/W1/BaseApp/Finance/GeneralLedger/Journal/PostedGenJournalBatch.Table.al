// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Journal;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Setup;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.NoSeries;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;

/// <summary>
/// Table storing historical records of posted general journal batches for audit trail and posting history tracking.
/// Maintains posted batch configurations including balancing account settings, number series, and posting parameters.
/// </summary>
/// <remarks>
/// Archive table for posted journal batch configurations providing comprehensive posting history and audit trail.
/// Contains batch-level posting parameters including balancing account setup, number series assignments, and reason codes.
/// Key features: Posted batch history tracking, audit trail compliance, batch configuration preservation.
/// Integration: Links to Posted Gen. Journal Line table, maintains posting batch relationships and configurations.
/// </remarks>
table 182 "Posted Gen. Journal Batch"
{
    Caption = 'Posted Gen. Journal Batch';
    LookupPageId = "Posted General Journal Batch";
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Journal template name that was used for the posted general journal batch.
        /// </summary>
        field(1; "Journal Template Name"; Code[10])
        {
            Caption = 'Journal Template Name';
            ToolTip = 'Specifies the name of the journal template.';
            NotBlank = true;
            TableRelation = "Gen. Journal Template";
        }
        /// <summary>
        /// Name of the posted general journal batch for identification purposes.
        /// </summary>
        field(2; Name; Code[10])
        {
            Caption = 'Name';
            ToolTip = 'Specifies the name of the journal batch.';
            NotBlank = true;
        }
        /// <summary>
        /// Description of the posted general journal batch explaining its purpose or content.
        /// </summary>
        field(3; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies a brief description of the journal batch.';
        }
        /// <summary>
        /// Reason code that was applied to the posted general journal batch for audit purposes.
        /// </summary>
        field(4; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            TableRelation = "Reason Code";
        }
        /// <summary>
        /// Balancing account type that was used for the posted general journal batch.
        /// </summary>
        field(5; "Bal. Account Type"; Enum "Gen. Journal Account Type")
        {
            Caption = 'Bal. Account Type';
            ToolTip = 'Specifies the type of account that a balancing entry is posted to.';
        }
        /// <summary>
        /// Balancing account number that was used for the posted general journal batch.
        /// </summary>
        field(6; "Bal. Account No."; Code[20])
        {
            Caption = 'Bal. Account No.';
            ToolTip = 'Specifies the number of the general ledger, customer, vendor, or bank account that the balancing entry is posted to.';
            TableRelation = if ("Bal. Account Type" = const("G/L Account")) "G/L Account"
            else
            if ("Bal. Account Type" = const(Customer)) Customer
            else
            if ("Bal. Account Type" = const(Vendor)) Vendor
            else
            if ("Bal. Account Type" = const("Bank Account")) "Bank Account"
            else
            if ("Bal. Account Type" = const("Fixed Asset")) "Fixed Asset";
        }
        /// <summary>
        /// Number series that was used for generating document numbers in the posted general journal batch.
        /// </summary>
        field(7; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            TableRelation = "No. Series";
        }
        /// <summary>
        /// Posting number series that was used for generating posted document numbers in the posted general journal batch.
        /// </summary>
        field(8; "Posting No. Series"; Code[20])
        {
            Caption = 'Posting No. Series';
            TableRelation = "No. Series";
        }
        /// <summary>
        /// Indicates whether VAT setup was automatically copied to journal lines in the posted general journal batch.
        /// </summary>
        field(9; "Copy VAT Setup to Jnl. Lines"; Boolean)
        {
            Caption = 'Copy VAT Setup to Jnl. Lines';
            InitValue = true;
        }
        /// <summary>
        /// Indicates whether VAT differences were allowed when posting the general journal batch.
        /// </summary>
        field(10; "Allow VAT Difference"; Boolean)
        {
            Caption = 'Allow VAT Difference';
        }
        /// <summary>
        /// Indicates whether payment export was allowed for the posted general journal batch.
        /// </summary>
        field(11; "Allow Payment Export"; Boolean)
        {
            Caption = 'Allow Payment Export';
        }
        /// <summary>
        /// Bank statement import format that was configured for the posted general journal batch.
        /// </summary>
        field(12; "Bank Statement Import Format"; Code[20])
        {
            Caption = 'Bank Statement Import Format';
            TableRelation = "Bank Export/Import Setup".Code where(Direction = const(Import));
        }
        /// <summary>
        /// Indicates whether balancing amounts were automatically suggested in the posted general journal batch.
        /// </summary>
        field(23; "Suggest Balancing Amount"; Boolean)
        {
            Caption = 'Suggest Balancing Amount';
        }
        /// <summary>
        /// Indicates whether journal lines were copied to posted journal lines during posting.
        /// </summary>
        field(31; "Copy to Posted Jnl. Lines"; Boolean)
        {
            Caption = 'Copy to Posted Jnl. Lines';
        }
    }

    keys
    {
        key(Key1; "Journal Template Name", Name)
        {
            Clustered = true;
        }
    }

    /// <summary>
    /// Creates a posted general journal batch record from an existing general journal batch.
    /// </summary>
    /// <param name="GenJournalBatch">The general journal batch record to copy from.</param>
    procedure InsertFromGenJournalBatch(GenJournalBatch: Record "Gen. Journal Batch")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertFromGenJournalBatch(GenJournalBatch, IsHandled);
        if IsHandled then
            exit;

        Init();
        TransferFields(GenJournalBatch);
        Insert();

        OnAfterInsertFromGenJournalBatch(GenJournalBatch);
    end;

    /// <summary>
    /// Integration event triggered before inserting a posted general journal batch record from a general journal batch.
    /// </summary>
    /// <param name="GenJournalBatch">The source general journal batch record.</param>
    /// <param name="IsHandled">Set to true to skip the default insertion logic.</param>
    [IntegrationEvent(true, false)]
    local procedure OnBeforeInsertFromGenJournalBatch(GenJournalBatch: Record "Gen. Journal Batch"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event triggered after successfully inserting a posted general journal batch record from a general journal batch.
    /// </summary>
    /// <param name="GenJournalBatch">The source general journal batch record that was used for insertion.</param>
    [IntegrationEvent(true, false)]
    local procedure OnAfterInsertFromGenJournalBatch(GenJournalBatch: Record "Gen. Journal Batch")
    begin
    end;
}

