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
            ToolTip = 'Specifies the code of the bank clearing standard that you choose in the Bank Clearing Standard field on a company, customer, or vendor bank account card.';
        }
        /// <summary>
        /// Descriptive text explaining the bank clearing standard.
        /// Provides human-readable information about the clearing code purpose.
        /// </summary>
        field(2; Description; Text[80])
        {
            Caption = 'Description';
            ToolTip = 'Specifies the description of the bank clearing standard that you choose in the Bank Clearing Standard field on a company, customer, or vendor bank account card.';
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

