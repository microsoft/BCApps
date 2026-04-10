// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Dimension;

using Microsoft.Finance.Analysis;

/// <summary>
/// Temporary buffer table for dimension-based analysis and reporting with hierarchical display capabilities.
/// Stores dimension codes with associated totaling ranges, periods, and calculated amounts for analysis views and reports.
/// </summary>
/// <remarks>
/// Used in financial analysis, budget analysis, and dimension-based reporting scenarios.
/// Supports hierarchical display with indentation, totaling formulas, and period-based calculations.
/// Integrates with Analysis Views and dimension filtering functionality.
/// </remarks>
table 367 "Dimension Code Buffer"
{
    Caption = 'Dimension Code Buffer';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Primary code identifier for the dimension entry in analysis and reporting contexts.
        /// </summary>
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            ToolTip = 'Specifies the code of the record.';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Descriptive name for the dimension code used in analysis and reporting display.
        /// </summary>
        field(2; Name; Text[100])
        {
            Caption = 'Name';
            ToolTip = 'Specifies the name of the record.';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Totaling formula for aggregating subordinate dimension codes in hierarchical analysis.
        /// </summary>
        field(3; Totaling; Text[250])
        {
            Caption = 'Totaling';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Start date for period-based analysis and reporting calculations.
        /// </summary>
        field(4; "Period Start"; Date)
        {
            Caption = 'Period Start';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// End date for period-based analysis and reporting calculations.
        /// </summary>
        field(5; "Period End"; Date)
        {
            Caption = 'Period End';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Controls visibility of the dimension code in analysis views and reports.
        /// </summary>
        field(6; Visible; Boolean)
        {
            Caption = 'Visible';
            DataClassification = SystemMetadata;
            InitValue = true;
        }
        /// <summary>
        /// Indentation level for hierarchical display in analysis views and reports.
        /// </summary>
        field(7; Indentation; Integer)
        {
            Caption = 'Indentation';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Controls bold formatting for emphasis in hierarchical analysis displays.
        /// </summary>
        field(8; "Show in Bold"; Boolean)
        {
            Caption = 'Show in Bold';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Calculated amount value for the dimension code in analysis and reporting scenarios.
        /// </summary>
        field(9; Amount; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            CalcFormula = sum("Analysis View Entry".Amount where("Analysis View Code" = const(''),
                                                                  "Dimension 1 Value Code" = field("Dimension 1 Value Filter"),
                                                                  "Dimension 2 Value Code" = field("Dimension 2 Value Filter"),
                                                                  "Dimension 3 Value Code" = field("Dimension 3 Value Filter"),
                                                                  "Dimension 4 Value Code" = field("Dimension 4 Value Filter")));
            Caption = 'Amount';
            ToolTip = 'Specifies the total value for the amount type that you select in the Show field.';
            FieldClass = FlowField;
        }
        /// <summary>
        /// Filter for dimension 1 values used in analysis view calculations and reporting.
        /// </summary>
        field(10; "Dimension 1 Value Filter"; Code[20])
        {
            Caption = 'Dimension 1 Value Filter';
            FieldClass = FlowFilter;
        }
        /// <summary>
        /// Filter for dimension 2 values used in analysis view calculations and reporting.
        /// </summary>
        field(11; "Dimension 2 Value Filter"; Code[20])
        {
            Caption = 'Dimension 2 Value Filter';
            FieldClass = FlowFilter;
        }
        /// <summary>
        /// Filter for dimension 3 values used in analysis view calculations and reporting.
        /// </summary>
        field(12; "Dimension 3 Value Filter"; Code[20])
        {
            Caption = 'Dimension 3 Value Filter';
            FieldClass = FlowFilter;
        }
        /// <summary>
        /// Filter for dimension 4 values used in analysis view calculations and reporting.
        /// </summary>
        field(13; "Dimension 4 Value Filter"; Code[20])
        {
            Caption = 'Dimension 4 Value Filter';
            FieldClass = FlowFilter;
        }
        /// <summary>
        /// Calculated quantity value for the dimension code in analysis and reporting scenarios.
        /// </summary>
        field(7101; Quantity; Decimal)
        {
            AutoFormatType = 0;
            CalcFormula = sum("Analysis View Entry".Amount where("Analysis View Code" = const(''),
                                                                  "Dimension 1 Value Code" = field("Dimension 1 Value Filter"),
                                                                  "Dimension 2 Value Code" = field("Dimension 2 Value Filter"),
                                                                  "Dimension 3 Value Code" = field("Dimension 3 Value Filter"),
                                                                  "Dimension 4 Value Code" = field("Dimension 4 Value Filter")));
            Caption = 'Quantity';
            ToolTip = 'Specifies the total value for the amount type that you select in the Show field.';
            DecimalPlaces = 0 : 5;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
        key(Key2; "Period Start")
        {
        }
    }

    fieldgroups
    {
    }
}
