// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Setup;

/// <summary>
/// Master table for SWIFT (Society for Worldwide Interbank Financial Telecommunication) codes.
/// Stores standardized bank identification codes used for international wire transfers.
/// </summary>
table 1210 "SWIFT Code"
{
    Caption = 'SWIFT Code';
    LookupPageID = "SWIFT Codes";
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// SWIFT Bank Identifier Code (BIC) for international banking transactions.
        /// Standardized format code that uniquely identifies financial institutions globally.
        /// </summary>
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        /// <summary>
        /// Name of the financial institution associated with this SWIFT code.
        /// Provides human-readable identification of the bank or financial organization.
        /// </summary>
        field(2; Name; Text[100])
        {
            Caption = 'Name';
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(Brick; "Code", Name)
        {
        }
    }
}

