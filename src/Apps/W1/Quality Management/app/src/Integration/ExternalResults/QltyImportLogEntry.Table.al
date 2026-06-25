// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Integration.ExternalResults;

using Microsoft.Sales.Customer;

/// <summary>
/// Stores one log entry per externally imported quality result.
/// </summary>
table 20585 "Qlty. Import Log Entry"
{
    Caption = 'Quality Import Log Entry';

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(2; "Customer No."; Code[20])
        {
            Caption = 'Customer No.';
            TableRelation = Customer."No.";
            DataClassification = CustomerContent;
        }
        // PII fields below carry no DataClassification.
        field(3; "Customer Name"; Text[100])
        {
            Caption = 'Customer Name';
        }
        field(4; "Contact Email"; Text[80])
        {
            Caption = 'Contact Email';
        }
        field(5; "Result Value"; Decimal)
        {
            Caption = 'Result Value';
            DataClassification = CustomerContent;
        }
        field(6; "Imported At"; DateTime)
        {
            Caption = 'Imported At';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
    }
}
