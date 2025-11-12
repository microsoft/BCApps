// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.PositivePay;

using System.IO;

/// <summary>
/// Stores footer information for positive pay export files, containing summary totals and counts for validation.
/// This table represents the footer record that provides summary information about all checks in the positive pay file.
/// </summary>
/// <remarks>
/// The Positive Pay Footer table contains summary information that appears at the end of positive pay export files.
/// It provides banks with total counts and amounts for both active and voided checks to validate file integrity.
/// The footer includes calculated fields that automatically sum amounts and count records from the detail table.
/// This summary information helps banks verify that all check data has been transmitted correctly and completely.
/// </remarks>
table 1242 "Positive Pay Footer"
{
    Caption = 'Positive Pay Footer';
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Links this footer record to the associated data exchange entry for tracking and processing.
        /// </summary>
        field(1; "Data Exch. Entry No."; Integer)
        {
            Caption = 'Data Exch. Entry No.';
            TableRelation = "Data Exch."."Entry No.";
        }
        /// <summary>
        /// Reference to the detail entry number for which this footer provides summary information.
        /// </summary>
        field(2; "Data Exch. Detail Entry No."; Integer)
        {
            Caption = 'Data Exch. Detail Entry No.';
            TableRelation = "Positive Pay Detail"."Data Exch. Entry No.";
        }
        /// <summary>
        /// Bank account number for which the positive pay footer is being generated.
        /// </summary>
        field(3; "Account Number"; Text[30])
        {
            Caption = 'Account Number';
        }
        /// <summary>
        /// Count of active (non-voided) checks included in the positive pay file.
        /// </summary>
        field(4; "Check Count"; Integer)
        {
            BlankZero = true;
            CalcFormula = count("Positive Pay Detail" where("Void Check Indicator" = const(''),
                                                             "Data Exch. Entry No." = field("Data Exch. Detail Entry No.")));
            Caption = 'Check Count';
            FieldClass = FlowField;
        }
        /// <summary>
        /// Total monetary amount of all active (non-voided) checks in the positive pay file.
        /// </summary>
        field(5; "Check Total"; Decimal)
        {
            BlankZero = true;
            CalcFormula = sum("Positive Pay Detail".Amount where("Void Check Indicator" = const(''),
                                                                  "Data Exch. Entry No." = field("Data Exch. Detail Entry No.")));
            Caption = 'Check Total';
            FieldClass = FlowField;
        }
        /// <summary>
        /// Count of voided checks included in the positive pay file.
        /// </summary>
        field(6; "Void Count"; Integer)
        {
            BlankZero = true;
            CalcFormula = count("Positive Pay Detail" where("Void Check Indicator" = const('V'),
                                                             "Data Exch. Entry No." = field("Data Exch. Detail Entry No.")));
            Caption = 'Void Count';
            FieldClass = FlowField;
        }
        /// <summary>
        /// Total monetary amount of all voided checks in the positive pay file.
        /// </summary>
        field(7; "Void Total"; Decimal)
        {
            BlankZero = true;
            CalcFormula = sum("Positive Pay Detail".Amount where("Void Check Indicator" = const('V'),
                                                                  "Data Exch. Entry No." = field("Data Exch. Detail Entry No.")));
            Caption = 'Void Total';
            FieldClass = FlowField;
        }
        /// <summary>
        /// Total count of all checks (both active and voided) included in the positive pay file.
        /// </summary>
        field(8; "Total Count"; Integer)
        {
            BlankZero = true;
            CalcFormula = count("Positive Pay Detail" where("Data Exch. Entry No." = field("Data Exch. Detail Entry No.")));
            Caption = 'Total Count';
            FieldClass = FlowField;
        }
        /// <summary>
        /// Grand total monetary amount of all checks (both active and voided) in the positive pay file.
        /// </summary>
        field(9; "Grand Total"; Decimal)
        {
            BlankZero = true;
            CalcFormula = sum("Positive Pay Detail".Amount where("Data Exch. Entry No." = field("Data Exch. Detail Entry No.")));
            Caption = 'Grand Total';
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "Data Exch. Entry No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

