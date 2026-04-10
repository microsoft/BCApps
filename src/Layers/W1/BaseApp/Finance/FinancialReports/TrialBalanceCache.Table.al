// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

/// <summary>
/// Cache table storing pre-calculated trial balance data for performance optimization.
/// Contains period-based amounts and descriptions for rapid trial balance display and reporting.
/// </summary>
/// <remarks>
/// Performance optimization table that stores calculated trial balance amounts across multiple periods
/// to reduce computation time for frequent trial balance access. Includes period captions and 
/// calculated amounts for efficient data presentation without real-time account schedule calculations.
/// </remarks>
table 1318 "Trial Balance Cache"
{
    Caption = 'Trial Balance Cache';
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Unique sequential identifier for trial balance cache entries.
        /// </summary>
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        /// <summary>
        /// Description of the account or account group for trial balance display.
        /// </summary>
        field(2; Description; Text[100])
        {
            Caption = 'Description';
            DataClassification = AccountData;
        }
        /// <summary>
        /// Calculated amount for the first period in trial balance comparison.
        /// </summary>
        field(3; "Period 1 Amount"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Period 1 Amount';
            DataClassification = AccountData;
        }
        /// <summary>
        /// Calculated amount for the second period in trial balance comparison.
        /// </summary>
        field(4; "Period 2 Amount"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Period 2 Amount';
            DataClassification = AccountData;
        }
        /// <summary>
        /// Column header caption for the first period display.
        /// </summary>
        field(5; "Period 1 Caption"; Text[50])
        {
            Caption = 'Period 1 Caption';
        }
        /// <summary>
        /// Column header caption for the second period display.
        /// </summary>
        field(6; "Period 2 Caption"; Text[50])
        {
            Caption = 'Period 2 Caption';
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}
