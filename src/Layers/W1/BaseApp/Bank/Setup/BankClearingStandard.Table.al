// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Setup;

/// <summary>
/// Defines standard bank clearing codes used for electronic payment processing.
/// Provides lookup values for bank routing and clearing house identification.
/// </summary>
table 1280 "Bank Clearing Standard"
{
    Caption = 'Bank Clearing Standard';
    LookupPageID = "Bank Clearing Standards";
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Unique code identifying the bank clearing standard.
        /// Used as the primary key and reference in banking setup.
        /// </summary>
        field(1; "Code"; Text[50])
        {
            Caption = 'Code';
        }
        /// <summary>
        /// Descriptive text explaining the bank clearing standard.
        /// Provides human-readable information about the clearing code purpose.
        /// </summary>
        field(2; Description; Text[80])
        {
            Caption = 'Description';
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
    }
}

