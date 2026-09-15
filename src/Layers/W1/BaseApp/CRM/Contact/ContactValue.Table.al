// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Contact;

table 5101 "Contact Value"
{
    Caption = 'Contact Value';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Contact No."; Code[20])
        {
            Caption = 'Contact No.';
            TableRelation = Contact;
        }
        field(2; Value; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Value';
        }
        field(3; "Last Date Updated"; Date)
        {
            Caption = 'Last Date Updated';
        }
        field(4; "Questions Answered (%)"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Questions Answered (%)';
        }
    }

    keys
    {
        key(Key1; "Contact No.")
        {
            Clustered = true;
        }
        key(Key2; Value)
        {
        }
    }

    fieldgroups
    {
    }
}
