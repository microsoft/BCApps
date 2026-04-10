// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Analysis;

using Microsoft.Finance.GeneralLedger.Setup;

/// <summary>
/// Temporary buffer table for staging analysis view entry updates during analysis view refresh operations.
/// Accumulates transaction data before final aggregation into analysis view entries and budget entries.
/// </summary>
table 2151 "Upd Analysis View Entry Buffer"
{
    TableType = Temporary;

    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Auto-incrementing primary key for unique record identification in the temporary buffer.
        /// Ensures each staged entry has a unique identifier during processing.
        /// </summary>
        field(1; "Primary Key"; Integer)
        {
            DataClassification = SystemMetadata;
            AutoIncrement = true;
        }
        /// <summary>
        /// Account number from the source transaction being processed for analysis view update.
        /// G/L Account or Cash Flow Account number depending on the account source type.
        /// </summary>
        field(2; AccNo; Code[20])
        {
            DataClassification = CustomerContent;
        }
        /// <summary>
        /// Business unit code for consolidation scenarios in analysis view updates.
        /// Empty for single-company analysis, populated from source entries for consolidation.
        /// </summary>
        field(3; BusUnitCode; Code[20])
        {
            DataClassification = CustomerContent;
        }
        /// <summary>
        /// Cash flow forecast number for cash flow analysis view updates.
        /// Links to Cash Flow Forecast for cash flow account source entries.
        /// </summary>
        field(4; CashFlowForecastNo; Code[20])
        {
            DataClassification = CustomerContent;
        }
        /// <summary>
        /// First dimension value code from source transactions for analysis view aggregation.
        /// Staging area for dimension 1 values before final analysis entry creation.
        /// </summary>
        field(5; DimValue1; Code[20])
        {
            DataClassification = CustomerContent;
        }
        /// <summary>
        /// Second dimension value code from source transactions for analysis view aggregation.
        /// Staging area for dimension 2 values before final analysis entry creation.
        /// </summary>
        field(6; DimValue2; Code[20])
        {
            DataClassification = CustomerContent;
        }
        /// <summary>
        /// Third dimension value code from source transactions for analysis view aggregation.
        /// Staging area for dimension 3 values before final analysis entry creation.
        /// </summary>
        field(7; DimValue3; Code[20])
        {
            DataClassification = CustomerContent;
        }
        /// <summary>
        /// Fourth dimension value code from source transactions for analysis view aggregation.
        /// Staging area for dimension 4 values before final analysis entry creation.
        /// </summary>
        field(8; DimValue4; Code[20])
        {
            DataClassification = CustomerContent;
        }
        /// <summary>
        /// Posting date from source transactions for period-based analysis view updates.
        /// Used for date filtering and period aggregation during analysis view refresh.
        /// </summary>
        field(9; PostingDate; Date)
        {
            DataClassification = CustomerContent;
        }
        /// <summary>
        /// Net amount from source transactions in local currency for analysis view aggregation.
        /// Calculated as debit amount minus credit amount for final analysis entries.
        /// </summary>
        field(10; Amount; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            DataClassification = CustomerContent;
        }
        /// <summary>
        /// Debit amount from source transactions in local currency for analysis view updates.
        /// Staged for aggregation into final analysis view entries with dimension breakdown.
        /// </summary>
        field(11; DebitAmount; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            DataClassification = CustomerContent;
        }
        /// <summary>
        /// Credit amount from source transactions in local currency for analysis view updates.
        /// Staged for aggregation into final analysis view entries with dimension breakdown.
        /// </summary>
        field(12; CreditAmount; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            DataClassification = CustomerContent;
        }
        /// <summary>
        /// Net amount from source transactions in additional currency for multi-currency analysis.
        /// Additional reporting currency amount for global financial reporting requirements.
        /// </summary>
        field(13; AmountACY; Decimal)
        {
            AutoFormatExpression = GetAdditionalReportingCurrencyCode();
            AutoFormatType = 1;
            DataClassification = CustomerContent;
        }
        /// <summary>
        /// Debit amount from source transactions in additional currency for multi-currency analysis.
        /// Additional reporting currency debit amount for global reporting compliance.
        /// </summary>
        field(14; DebitAmountACY; Decimal)
        {
            AutoFormatExpression = GetAdditionalReportingCurrencyCode();
            AutoFormatType = 1;
            DataClassification = CustomerContent;
        }
        /// <summary>
        /// Credit amount from source transactions in additional currency for multi-currency analysis.
        /// Additional reporting currency credit amount for global reporting compliance.
        /// </summary>
        field(15; CreditAmountACY; Decimal)
        {
            AutoFormatExpression = GetAdditionalReportingCurrencyCode();
            AutoFormatType = 1;
            DataClassification = CustomerContent;
        }
        /// <summary>
        /// Entry number from source transactions for traceability and audit purposes.
        /// Links back to the original G/L or Cash Flow entry that generated this buffer record.
        /// </summary>
        field(16; EntryNo; Integer)
        {
            DataClassification = CustomerContent;
        }
        /// <summary>
        /// Account source type indicating whether this entry originates from G/L or Cash Flow accounts.
        /// Determines the source table and processing logic for analysis view updates.
        /// </summary>
        field(17; "Account Source"; Enum "Analysis Account Source")
        {
            Caption = 'Account Source';
        }
    }
    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }

    local procedure GetAdditionalReportingCurrencyCode(): Code[10]
    var
        GLSetup: Record "General Ledger Setup";
    begin
        if GLSetup.Get() then
            exit(GLSetup."Additional Reporting Currency");
    end;
}
