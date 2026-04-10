// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reconciliation;

/// <summary>
/// Configuration settings for automated bank payment application and matching algorithms.
/// This table controls which types of ledger entries participate in automatic matching,
/// how related party names are matched, and various behavior settings for the payment
/// application process. Provides centralized configuration for fine-tuning automatic
/// matching performance and accuracy according to business requirements.
/// </summary>
/// <remarks>
/// Key settings include enabling/disabling specific ledger entry types for matching,
/// configuring related party name matching algorithms, controlling document number matching,
/// and managing user interface behavior during manual application processes.
/// Settings affect both automatic matching during import and manual application workflows.
/// </remarks>
table 1253 "Bank Pmt. Appl. Settings"
{
    Caption = 'Bank Payment Application Settings';
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Primary key field for the payment application settings record.
        /// Uses empty string as default key for singleton configuration pattern.
        /// </summary>
        field(1; PrimaryKey; Code[20])
        {
            DataClassification = SystemMetadata;
        }

        /// <summary>
        /// Enables automatic matching against vendor ledger entries during payment application.
        /// When enabled, bank statement lines are compared with open vendor invoices and credit memos.
        /// </summary>
        field(3; "Vendor Ledger Entries Matching"; Boolean)
        {
            ToolTip = 'Specifies if automatic matching should be enabled for Vendor Ledger Entries.';
        }

        /// <summary>
        /// Enables automatic matching against customer ledger entries during payment application.
        /// When enabled, bank statement lines are compared with open customer invoices and credit memos.
        /// </summary>
        field(4; "Cust. Ledger Entries Matching"; Boolean)
        {
            ToolTip = 'Specifies if automatic matching should be enabled for Customer Ledger Entries.';
        }

        /// <summary>
        /// Enables automatic matching against bank account ledger entries during reconciliation.
        /// Used for identifying transfers between bank accounts and other bank-related transactions.
        /// </summary>
        field(5; "Bank Ledger Entries Matching"; Boolean)
        {
            ToolTip = 'Specifies if automatic matching should be enabled for Bank Ledger Entries.';
        }

        /// <summary>
        /// Specifies the algorithm used for matching related party names in bank statements.
        /// Controls how customer and vendor names from bank data are compared with master data.
        /// </summary>
        field(6; "RelatedParty Name Matching"; Enum "Pmt. Appl. Related Party Name Matching")
        {
            ToolTip = 'Specifies which algorithm to use to determaine related party. Set this value to disabled if your bank statements do not include the name of the related party name.';
        }

        /// <summary>
        /// Enables document number matching for bank ledger entries using closing document numbers.
        /// Improves matching accuracy for bank transfers and internal transactions.
        /// </summary>
        field(7; "Bank Ledg Closing Doc No Match"; boolean)
        {
            ToolTip = 'Specifies if the algorithm should search Vendor and Customer Ledger Entries when matching Bank Ledger Entries. This functionality should be used only if your process requires it, otherwise it has a high performance impact.';
        }

        /// <summary>
        /// Disables automatic suggestion generation during manual payment application.
        /// When enabled, users must manually select entries without system suggestions.
        /// </summary>
        field(8; "Apply Man. Disable Suggestions"; boolean)
        {
            ToolTip = 'Specifies if the suggestions should be disabled for Apply Manually page. Use this setting if the opening of Apply Manually page takes too long.';
        }

        /// <summary>
        /// Enables immediate application of payments without requiring user confirmation.
        /// Streamlines workflow for high-confidence automatic matches.
        /// </summary>
        field(9; "Enable Apply Immediatelly"; boolean)
        {
            ToolTip = 'Specifies if certain rules should be applied immediatelly. If this value is set to true, if the rule is matched, then the system will not look for alternatives for the specific line. If this value is set to false, the system will search for alternatives, resulting in a higher confidence match.';
        }
        /// <summary>
        /// Enables automatic matching against employee ledger entries during payment application.
        /// When enabled, bank statement lines are compared with employee advances and reimbursements.
        /// </summary>
        field(10; "Empl. Ledger Entries Matching"; Boolean)
        {
            ToolTip = 'Specifies if automatic matching should be enabled for Employee Ledger Entries.';
        }
        /// <summary>
        /// Hides vendor ledger entries from manual application interface.
        /// Used to simplify user interface when vendor payments are not processed through this method.
        /// </summary>
        field(11; "Vend Ledg Hidden In Apply Man"; Boolean)
        {
        }
        /// <summary>
        /// Hides customer ledger entries from manual application interface.
        /// Used to simplify user interface when customer payments are not processed through this method.
        /// </summary>
        field(12; "Cust Ledg Hidden In Apply Man"; Boolean)
        {
        }
        /// <summary>
        /// Hides bank ledger entries from manual application interface.
        /// Used to simplify user interface when bank transfers are not processed through this method.
        /// </summary>
        field(13; "Bank Ledg Hidden In Apply Man"; Boolean)
        {
        }
        /// <summary>
        /// Hides employee ledger entries from manual application interface.
        /// Used to simplify user interface when employee payments are not processed through this method.
        /// </summary>
        field(14; "Empl Ledg Hidden In Apply Man"; Boolean)
        {
        }

    }

    keys
    {
        key(Key1; PrimaryKey)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    /// <summary>
    /// Retrieves existing settings record or creates a new one with default values.
    /// Ensures settings are always available for payment application processes by using
    /// singleton pattern with default configuration for new installations.
    /// </summary>
    procedure GetOrInsert()
    begin
        if Get('') then
            exit;

        "Vendor Ledger Entries Matching" := true;
        "Cust. Ledger Entries Matching" := true;
        "Bank Ledger Entries Matching" := true;
        "Empl. Ledger Entries Matching" := true;
        "Bank Ledg Closing Doc No Match" := false;
        Insert(true);
    end;
}

