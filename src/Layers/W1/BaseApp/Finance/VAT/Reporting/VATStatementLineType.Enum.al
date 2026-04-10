// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

/// <summary>
/// Defines the calculation methods and behavior for VAT statement lines.
/// Controls how statement lines calculate their values and what data sources they use.
/// </summary>
enum 256 "VAT Statement Line Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    /// <summary>
    /// Totals amounts from specified General Ledger accounts using account number filtering.
    /// </summary>
    value(0; "Account Totaling")
    {
        Caption = 'Account Totaling';
    }
    /// <summary>
    /// Totals amounts from VAT entries based on VAT posting setup and posting type filters.
    /// </summary>
    value(1; "VAT Entry Totaling")
    {
        Caption = 'VAT Entry Totaling';
    }
    /// <summary>
    /// Totals amounts from other VAT statement lines using row number references.
    /// </summary>
    value(2; "Row Totaling")
    {
        Caption = 'Row Totaling';
    }
    /// <summary>
    /// Descriptive line with no calculation - used for headers and explanatory text.
    /// </summary>
    value(3; Description)
    {
        Caption = 'Description';
    }
}
