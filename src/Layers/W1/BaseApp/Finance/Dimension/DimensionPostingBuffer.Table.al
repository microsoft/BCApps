// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Dimension;

using Microsoft.Finance.GeneralLedger.Setup;

/// <summary>
/// Temporary buffer table for aggregating amounts by dimension set during posting operations.
/// Accumulates posting amounts grouped by dimension sets and group identifiers for efficient posting processing.
/// </summary>
/// <remarks>
/// Used during posting routines to summarize amounts by dimension combinations before creating final ledger entries.
/// Supports both local currency and additional reporting currency amounts for multi-currency scenarios.
/// Essential for posting performance optimization in high-volume transaction processing.
/// </remarks>
table 385 "Dimension Posting Buffer"
{
    Caption = 'Dimension Posting Buffer';
    ReplicateData = false;
    TableType = Temporary;
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Identifier of the dimension set combination for posting aggregation.
        /// </summary>
        field(1; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            DataClassification = SystemMetadata;
            TableRelation = "Dimension Set Entry";
        }
        /// <summary>
        /// Group identifier for categorizing and aggregating posting entries by business logic.
        /// </summary>
        field(2; "Group ID"; Text[250])
        {
            Caption = 'Group ID';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Accumulated amount in local currency for the dimension set and group combination.
        /// </summary>
        field(3; Amount; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Amount';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Accumulated amount in additional reporting currency for the dimension set and group combination.
        /// </summary>
        field(4; "Amount (ACY)"; Decimal)
        {
            AutoFormatExpression = GetAdditionalReportingCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Amount (ACY)';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Dimension Set ID", "Group ID")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    protected var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GeneralLedgerSetupRead: Boolean;

    local procedure GetAdditionalReportingCurrencyCode(): Code[10]
    begin
        if not GeneralLedgerSetupRead then begin
            GeneralLedgerSetup.Get();
            GeneralLedgerSetupRead := true;
        end;
        exit(GeneralLedgerSetup."Additional Reporting Currency")
    end;
}
