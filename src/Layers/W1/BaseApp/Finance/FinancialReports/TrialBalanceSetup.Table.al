// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

/// <summary>
/// Configuration table for trial balance display settings linking account schedules with column layouts.
/// Defines the row and column definitions used for trial balance reporting and presentation.
/// </summary>
/// <remarks>
/// Single-record setup table that specifies which account schedule (row definition) and column layout 
/// (column definition) to use for trial balance reports. Provides centralized configuration for 
/// trial balance formatting and ensures consistent trial balance presentation across the application.
/// </remarks>
table 1312 "Trial Balance Setup"
{
    Caption = 'Trial Balance Setup';
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Primary key field for trial balance setup record.
        /// </summary>
        field(1; "Primary Key"; Code[10])
        {
            AllowInCustomizations = Never;
            Caption = 'Primary Key';
        }
        /// <summary>
        /// Account schedule name defining the row structure for trial balance display.
        /// </summary>
        field(2; "Account Schedule Name"; Code[10])
        {
            Caption = 'Row Definition';
            ToolTip = 'Specifies the rows definition to use to calculate the results that display in the Trial Balance chart.';
            NotBlank = true;
            TableRelation = "Acc. Schedule Name".Name;
        }
        /// <summary>
        /// Column layout name defining the column structure for trial balance display.
        /// </summary>
        field(3; "Column Layout Name"; Code[10])
        {
            Caption = 'Column Definition';
            ToolTip = 'Specifies the columns definition to use to determine how columns display in the Trial Balance chart.';
            NotBlank = true;
            TableRelation = "Column Layout Name".Name;
        }
    }

    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

}

