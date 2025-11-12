// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.PositivePay;

using System.IO;

/// <summary>
/// Stores detailed check information for positive pay export files, containing individual check data for bank validation.
/// This table represents the detail records in positive pay files that banks use to verify issued checks.
/// </summary>
/// <remarks>
/// The Positive Pay Detail table contains individual check records that are exported to banks for positive pay validation.
/// Each record represents a single check with its essential attributes including check number, amount, payee, and issue date.
/// This table is populated during the positive pay export process and is linked to data exchange entries for tracking and processing.
/// The table supports both regular and voided checks through the void indicator field.
/// </remarks>
table 1241 "Positive Pay Detail"
{
    Caption = 'Positive Pay Detail';
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Links this detail record to the associated data exchange entry for tracking and processing.
        /// </summary>
        field(1; "Data Exch. Entry No."; Integer)
        {
            Caption = 'Data Exch. Entry No.';
            TableRelation = "Data Exch."."Entry No.";
        }
        /// <summary>
        /// Unique sequential number identifying this detail record within the data exchange entry.
        /// </summary>
        field(2; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        /// <summary>
        /// Bank account number for which this positive pay detail is being generated.
        /// </summary>
        field(3; "Account Number"; Text[30])
        {
            Caption = 'Account Number';
        }
        /// <summary>
        /// Code indicating the type of record (typically 'D' for detail records in positive pay files).
        /// </summary>
        field(4; "Record Type Code"; Text[1])
        {
            Caption = 'Record Type Code';
        }
        /// <summary>
        /// Indicator specifying whether this check has been voided ('V' for voided, blank for active).
        /// </summary>
        field(5; "Void Check Indicator"; Text[1])
        {
            Caption = 'Void Check Indicator';
        }
        /// <summary>
        /// The check number as printed on the physical check document.
        /// </summary>
        field(6; "Check Number"; Code[20])
        {
            Caption = 'Check Number';
        }
        /// <summary>
        /// The monetary amount of the check in the account's base currency.
        /// </summary>
        field(7; Amount; Decimal)
        {
            Caption = 'Amount';
        }
        /// <summary>
        /// The date when the check was issued or printed.
        /// </summary>
        field(8; "Issue Date"; Date)
        {
            Caption = 'Issue Date';
        }
        /// <summary>
        /// The name of the individual or organization to whom the check is payable.
        /// </summary>
        field(9; Payee; Text[100])
        {
            Caption = 'Payee';
            DataClassification = EndUserIdentifiableInformation;
        }
        /// <summary>
        /// Currency code for the check amount, typically matching the bank account's currency.
        /// </summary>
        field(10; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
        }
    }

    keys
    {
        key(Key1; "Data Exch. Entry No.", "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Void Check Indicator")
        {
        }
    }

    fieldgroups
    {
    }
}

