// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

using Microsoft.Finance.GeneralLedger.Account;

/// <summary>
/// Buffer table for trial balance data export to external APIs and integrations.
/// Stores formatted trial balance amounts and account information for entity exposure.
/// </summary>
table 5488 "Trial Balance Entity Buffer"
{
    Caption = 'Trial Balance Entity Buffer';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// G/L account number for trial balance data identification.
        /// </summary>
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
            ToolTip = 'Specifies the No..';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// G/L account name for display in trial balance reports and exports.
        /// </summary>
        field(2; Name; Text[100])
        {
            Caption = 'Name';
            ToolTip = 'Specifies the Name.';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Formatted debit amount for net change in the specified period.
        /// </summary>
        field(3; "Net Change Debit"; Text[30])
        {
            Caption = 'Net Change Debit';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Formatted credit amount for net change in the specified period.
        /// </summary>
        field(4; "Net Change Credit"; Text[30])
        {
            Caption = 'Net Change Credit';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Formatted debit balance as of the specified date filter.
        /// </summary>
        field(5; "Balance at Date Debit"; Text[30])
        {
            Caption = 'Balance at Date Debit';
            ToolTip = 'Specifies the Balance at Date Debit Amount.';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Formatted credit balance as of the specified date filter.
        /// </summary>
        field(6; "Balance at Date Credit"; Text[30])
        {
            Caption = 'Balance at Date Credit';
            ToolTip = 'Specifies the Balance at Date Credit Amount.';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Date filter applied for balance calculations and period determination.
        /// </summary>
        field(7; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            ToolTip = 'Specifies the Date Filter.';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Formatted total debit amount including opening balance and net change.
        /// </summary>
        field(8; "Total Debit"; Text[30])
        {
            Caption = 'Total Debit';
            ToolTip = 'Specifies the Total Debit Amount.';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Formatted total credit amount including opening balance and net change.
        /// </summary>
        field(9; "Total Credit"; Text[30])
        {
            Caption = 'Total Credit';
            ToolTip = 'Specifies the Total Credit Amount.';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// G/L account type determining posting behavior and balance calculation.
        /// </summary>
        field(10; "Account Type"; Enum "G/L Account Type")
        {
            Caption = 'Account Type';
            ToolTip = 'Specifies the Account Type.';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// System identifier linking buffer record to source G/L account.
        /// </summary>
        field(11; "Account Id"; Guid)
        {
            Caption = 'Account Id';
            ToolTip = 'Specifies the Account Id.';
            DataClassification = SystemMetadata;
            TableRelation = "G/L Account".SystemId;
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
}

