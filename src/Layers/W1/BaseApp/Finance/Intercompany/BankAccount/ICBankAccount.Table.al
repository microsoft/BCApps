// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany.BankAccount;

using Microsoft.Finance.Currency;
using Microsoft.Foundation.Company;

/// <summary>
/// Stores bank account information for intercompany transactions between partner companies.
/// Enables partner company bank account tracking and validation for cross-company payments.
/// </summary>
table 422 "IC Bank Account"
{
    Caption = 'IC Bank Account';
    LookupPageID = "IC Bank Account List";
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Unique identifier for the intercompany bank account record.
        /// </summary>
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
        }
        /// <summary>
        /// Identifies the intercompany partner that owns this bank account.
        /// </summary>
        field(2; "IC Partner Code"; Code[20])
        {
            Caption = 'Partner Code';
        }
        /// <summary>
        /// Descriptive name of the intercompany bank account for identification purposes.
        /// </summary>
        field(3; Name; Text[100])
        {
            Caption = 'Name';
        }
        /// <summary>
        /// Bank account number used for intercompany transactions and payment processing.
        /// </summary>
        field(4; "Bank Account No."; Text[30])
        {
            Caption = 'Bank Account No.';
        }
        /// <summary>
        /// Indicates whether the intercompany bank account is blocked from use in transactions.
        /// </summary>
        field(5; Blocked; Boolean)
        {
            Caption = 'Blocked';
        }
        /// <summary>
        /// Currency code for transactions involving this intercompany bank account.
        /// </summary>
        field(6; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;
        }
        /// <summary>
        /// International Bank Account Number for the intercompany bank account with automatic validation.
        /// </summary>
        field(7; IBAN; Code[50])
        {
            Caption = 'IBAN';

            trigger OnValidate()
            var
                CompanyInfo: Record "Company Information";
            begin
                CompanyInfo.CheckIBAN(IBAN);
            end;
        }
    }

    keys
    {
        key(Key1; "No.", "IC Partner Code")
        {
            Clustered = true;
        }
    }
}

