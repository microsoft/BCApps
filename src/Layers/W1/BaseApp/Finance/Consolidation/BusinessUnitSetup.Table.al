// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Consolidation;

using System.Environment;
using System.Globalization;

/// <summary>
/// Temporary table for managing company selection during business unit setup and consolidation configuration.
/// Contains company filtering and inclusion settings for consolidation processes.
/// </summary>
/// <remarks>
/// Support table used during business unit configuration to select which companies to include in consolidation.
/// Validates user access permissions to ensure only accessible companies are included.
/// </remarks>
table 1827 "Business Unit Setup"
{
    Caption = 'Business Unit Setup';
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Name of the company available for business unit consolidation setup.
        /// </summary>
        field(1; "Company Name"; Text[30])
        {
            Caption = 'Company Name';
            ToolTip = 'Specifies the name of the company.';
        }
        /// <summary>
        /// Indicates whether the company should be included in business unit consolidation processing.
        /// </summary>
        field(2; Include; Boolean)
        {
            Caption = 'Include';
            ToolTip = 'Specifies if the business unit is include on the subform.';
        }
        /// <summary>
        /// Indicates whether the business unit setup for this company has been completed.
        /// </summary>
        field(3; Completed; Boolean)
        {
            Caption = 'Completed';
        }
    }

    keys
    {
        key(Key1; "Company Name")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        Company: Record Company;

    /// <summary>
    /// Populates the table with available companies for business unit consolidation setup, excluding the consolidated company.
    /// </summary>
    /// <param name="ConsolidatedCompany">Name of the consolidated company to exclude from the list</param>
    procedure FillTable(ConsolidatedCompany: Text[30])
    var
        Language: Record Language;
    begin
        Company.SetFilter(Name, '<>%1', ConsolidatedCompany);
        if not Company.FindSet() then
            exit;

        Language.Init();

        if Company.FindSet() then
            repeat
                // Use a table that all users can access, and check whether users have permissions to open the company.
                if Language.ChangeCompany(Company.Name) then begin
                    "Company Name" := Company.Name;
                    Include := true;
                    Insert();
                end;
            until Company.Next() = 0;
    end;
}

