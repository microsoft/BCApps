// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

/// <summary>
/// Defines VAT report configuration types determining report format and processing behavior.
/// Controls validation rules, submission methods, and data collection requirements for different VAT report types.
/// </summary>
enum 740 "VAT Report Configuration"
{
    Extensible = true;
    AssignmentCompatibility = true;

    /// <summary>
    /// European Community Sales List for intra-community VAT reporting requirements.
    /// </summary>
    value(0; "EC Sales List") { Caption = 'EC Sales List'; }
    /// <summary>
    /// Standard VAT return for periodic VAT liability reporting to tax authorities.
    /// </summary>
    value(1; "VAT Return") { Caption = 'VAT Return'; }
    /// <summary>
    /// Intrastat report for statistical reporting of goods movement within EU.
    /// </summary>
    value(2; "Intrastat Report") { Caption = 'Intrastat Report'; }
}
