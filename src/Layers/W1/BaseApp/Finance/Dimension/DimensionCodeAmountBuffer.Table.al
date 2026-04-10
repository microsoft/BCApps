// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Dimension;

/// <summary>
/// Temporary buffer table for storing dimension codes with associated amounts in matrix reporting scenarios.
/// Used for aggregating and displaying dimensional financial data in cross-tabular report formats.
/// </summary>
/// <remarks>
/// Typically used in analysis and reporting where dimension values form matrix axes with calculated amounts.
/// Supports temporary data storage for dimension-based financial analysis and drill-down capabilities.
/// </remarks>
table 375 "Dimension Code Amount Buffer"
{
    Caption = 'Dimension Code Amount Buffer';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Line identifier representing row dimension in matrix reports and analysis views.
        /// </summary>
        field(1; "Line Code"; Code[20])
        {
            Caption = 'Line Code';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Column identifier representing column dimension in matrix reports and analysis views.
        /// </summary>
        field(2; "Column Code"; Code[20])
        {
            Caption = 'Column Code';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Calculated amount value for the intersection of line and column dimension codes.
        /// </summary>
        field(3; Amount; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Amount';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Line Code", "Column Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}
