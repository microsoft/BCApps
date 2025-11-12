// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.BankAccount;

/// <summary>
/// Links local bank accounts to external online banking services for automated statement import.
/// Stores connection parameters and authentication information for third-party banking integrations.
/// </summary>
/// <remarks>
/// Used for connecting to bank feeds and online banking services. 
/// Contains sensitive connection data with appropriate data classification.
/// </remarks>
table 777 "Online Bank Acc. Link"
{
    Caption = 'Online Bank Acc. Link';
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Local bank account number that is linked to the online service.
        /// </summary>
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
            TableRelation = "Bank Account"."No.";
        }
        /// <summary>
        /// External bank account identifier used by the online banking service.
        /// </summary>
        field(2; "Online Bank Account ID"; Text[250])
        {
            Caption = 'Online Bank Account ID';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Bank identifier used by the online banking service provider.
        /// </summary>
        field(3; "Online Bank ID"; Text[250])
        {
            Caption = 'Online Bank ID';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Indicates whether automatic authentication is supported for this connection.
        /// </summary>
        field(4; "Automatic Logon Possible"; Boolean)
        {
            Caption = 'Automatic Logon Possible';
        }
        /// <summary>
        /// Display name of the online bank account.
        /// </summary>
        field(5; Name; Text[50])
        {
            Caption = 'Name';
        }
        /// <summary>
        /// Currency code for the online bank account.
        /// </summary>
        field(6; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
        }
        /// <summary>
        /// Contact information for the online bank account.
        /// </summary>
        field(7; Contact; Text[50])
        {
            Caption = 'Contact';
            DataClassification = EndUserIdentifiableInformation;
        }
        /// <summary>
        /// Bank account number as provided by the online banking service.
        /// </summary>
        field(8; "Bank Account No."; Text[30])
        {
            Caption = 'Bank Account No.';
        }
        /// <summary>
        /// Temporary field for holding bank account number during linking process.
        /// </summary>
        field(100; "Temp Linked Bank Account No."; Code[20])
        {
            Caption = 'Temp Linked Bank Account No.';
        }
        /// <summary>
        /// Identifier of the online banking service provider.
        /// </summary>
        field(101; ProviderId; Text[50])
        {
            Caption = 'ProviderId';
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

