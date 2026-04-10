// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Consolidation;

using Microsoft.Finance.GeneralLedger.Account;
using System.Environment;

/// <summary>
/// Stores consolidation account master data for mapping subsidiary G/L accounts to consolidated accounts.
/// Used during consolidation processing to standardize account structures across business units.
/// </summary>
/// <remarks>
/// Consolidation accounts define the chart of accounts structure for consolidated financial reporting.
/// Maps subsidiary company accounts to standardized consolidation account numbers and categories.
/// </remarks>
table 1829 "Consolidation Account"
{
    Caption = 'Consolidation Account';
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Unique consolidation account number used for mapping subsidiary accounts during consolidation.
        /// </summary>
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
            NotBlank = true;
        }
        /// <summary>
        /// Descriptive name of the consolidation account for identification and reporting purposes.
        /// </summary>
        field(2; Name; Text[100])
        {
            Caption = 'Name';
        }
        /// <summary>
        /// Classification of account as Income Statement or Balance Sheet account for consolidation reporting.
        /// </summary>
        field(3; "Income/Balance"; Enum "G/L Account Report Type")
        {
            Caption = 'Income/Balance';
        }
        /// <summary>
        /// Indicates if consolidation account is blocked from use in consolidation processing.
        /// </summary>
        field(4; Blocked; Boolean)
        {
            Caption = 'Blocked';
        }
        /// <summary>
        /// Specifies whether direct posting to this consolidation account is allowed during consolidation.
        /// </summary>
        field(5; "Direct Posting"; Boolean)
        {
            Caption = 'Direct Posting';
            InitValue = true;
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

    /// <summary>
    /// Creates sample consolidation accounts with default configuration for initial setup.
    /// Inserts standard checking account entry as consolidation account template.
    /// </summary>
    procedure PopulateAccounts()
    begin
        InsertData('10100', 'Checking account', 1, true);
    end;

    local procedure InsertData(AccountNo: Code[20]; AccountName: Text[100]; IncomeBalance: Integer; DirectPosting: Boolean)
    var
        ConsolidationAccount: Record "Consolidation Account";
    begin
        ConsolidationAccount.Init();
        ConsolidationAccount.Validate("No.", AccountNo);
        ConsolidationAccount.Validate(Name, AccountName);
        ConsolidationAccount.Validate("Direct Posting", DirectPosting);
        ConsolidationAccount.Validate("Income/Balance", "G/L Account Report Type".FromInteger(IncomeBalance));
        ConsolidationAccount.Insert();
    end;

    /// <summary>
    /// Populates consolidation accounts by copying G/L account structure from an existing consolidated company.
    /// Creates consolidation account mapping based on existing G/L chart of accounts.
    /// </summary>
    /// <param name="ConsolidatedCompany">Name of the consolidated company to copy account structure from</param>
    procedure PopulateConsolidationAccountsForExistingCompany(ConsolidatedCompany: Text[50])
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount.ChangeCompany(ConsolidatedCompany);
        GLAccount.Reset();
        GLAccount.SetFilter("Account Type", Format(GLAccount."Account Type"::Posting));
        if GLAccount.Find('-') then
            repeat
                InsertData(GLAccount."No.", GLAccount.Name, GLAccount."Income/Balance".AsInteger(), GLAccount."Direct Posting");
            until GLAccount.Next() = 0;
    end;

    /// <summary>
    /// Validates if the provided country code matches the application system country configuration.
    /// Checks country code against the application version string for country-specific features.
    /// </summary>
    /// <param name="CountryCode">Two-character country code to validate</param>
    /// <returns>True if country code matches system configuration, false otherwise</returns>
    procedure ValidateCountry(CountryCode: Code[2]): Boolean
    var
        ApplicationSystemConstants: Codeunit "Application System Constants";
    begin
        if StrPos(ApplicationSystemConstants.ApplicationVersion(), CountryCode) = 1 then
            exit(true);

        exit(false);
    end;
}

