// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany.Setup;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Intercompany.Partner;

/// <summary>
/// Stores intercompany configuration settings for company-to-company transaction processing.
/// Manages inbox setup, partner identification, and default journal templates for intercompany operations.
/// </summary>
table 443 "IC Setup"
{
    Caption = 'IC Setup';
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Primary key field for singleton table record containing intercompany configuration.
        /// </summary>
        field(1; "Primary Key"; Code[10])
        {
            AllowInCustomizations = Never;
            Caption = 'Primary Key';
        }
        /// <summary>
        /// Unique identifier for this company when referenced by intercompany partners.
        /// </summary>
        field(2; "IC Partner Code"; Code[20])
        {
            Caption = 'IC Partner Code';
        }
        /// <summary>
        /// Specifies inbox storage method for receiving intercompany transactions.
        /// </summary>
        field(3; "IC Inbox Type"; Option)
        {
            Caption = 'IC Inbox Type';
            InitValue = Database;
            OptionCaption = 'File Location,Database';
            OptionMembers = "File Location",Database;

            trigger OnValidate()
            begin
                if "IC Inbox Type" = "IC Inbox Type"::Database then
                    "IC Inbox Details" := '';
            end;
        }
        /// <summary>
        /// Storage location details for intercompany inbox transactions.
        /// </summary>
        field(4; "IC Inbox Details"; Text[250])
        {
            Caption = 'IC Inbox Details';
        }
        /// <summary>
        /// Enables automatic transmission of transactions from outbox to partners.
        /// </summary>
        field(5; "Auto. Send Transactions"; Boolean)
        {
            Caption = 'Auto. Send Transactions';
        }
        /// <summary>
        /// Default journal template for creating intercompany general journal entries.
        /// </summary>
        field(6; "Default IC Gen. Jnl. Template"; Code[10])
        {
            Caption = 'Default IC General Journal Template';
            TableRelation = "Gen. Journal Template";
        }
        /// <summary>
        /// Default journal batch for creating intercompany general journal entries.
        /// </summary>
        field(7; "Default IC Gen. Jnl. Batch"; Code[10])
        {
            Caption = 'Default IC General Journal Batch';
            TableRelation = "Gen. Journal Batch".Name where("Journal Template Name" = field("Default IC Gen. Jnl. Template"));
        }
        /// <summary>
        /// Partner code used for account synchronization operations between companies.
        /// </summary>
        field(8; "Partner Code for Acc. Syn."; Code[20])
        {
            Caption = 'Account Syncronization Partner Code';
            TableRelation = "IC Partner".Code where("Inbox Type" = filter("IC Partner Inbox Type"::Database));
        }
        /// <summary>
        /// Enables notifications when new intercompany transactions are created.
        /// </summary>
        field(9; "Transaction Notifications"; Boolean)
        {
            Caption = 'Transaction Nofitications';
            InitValue = true;
        }
    }

    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }
}
