// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.PositivePay;

using System.IO;

/// <summary>
/// Stores header information for positive pay export files, containing company and account identification data.
/// This table represents the header record that identifies the source company and bank account for positive pay files.
/// </summary>
/// <remarks>
/// The Positive Pay Header table contains the identifying information that appears at the beginning of positive pay export files.
/// Each header record is associated with a data exchange entry and contains company name, account number, and file generation date.
/// This information helps banks identify the source of the positive pay data and process it correctly.
/// The header record is created during the positive pay export process and provides context for the detail records that follow.
/// </remarks>
table 1240 "Positive Pay Header"
{
    Caption = 'Positive Pay Header';
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Links this header record to the associated data exchange entry for tracking and processing.
        /// </summary>
        field(1; "Data Exch. Entry No."; Integer)
        {
            Caption = 'Data Exch. Entry No.';
            TableRelation = "Data Exch."."Entry No.";
        }
        /// <summary>
        /// Name of the company generating the positive pay file, used for bank identification.
        /// </summary>
        field(2; "Company Name"; Text[30])
        {
            Caption = 'Company Name';
            DataClassification = OrganizationIdentifiableInformation;
        }
        /// <summary>
        /// Bank account number for which the positive pay file is being generated.
        /// </summary>
        field(3; "Account Number"; Text[30])
        {
            Caption = 'Account Number';
        }
        /// <summary>
        /// Date when the positive pay file was created and exported.
        /// </summary>
        field(4; "Date of File"; Date)
        {
            Caption = 'Date of File';
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

