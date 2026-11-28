// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Registration;

table 7403 "Registration No. Duplicate"
{
    Caption = 'Registration No. Duplicate';
    TableType = Temporary;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Record ID"; RecordId)
        {
            Caption = 'Record ID';
        }
        field(2; "Record Type"; Text[250])
        {
            Caption = 'Record Type';
        }
        field(3; "No."; Code[20])
        {
            Caption = 'No.';
        }
        field(4; Name; Text[100])
        {
            Caption = 'Name';
        }
    }

    keys
    {
        key(PK; "Record ID")
        {
            Clustered = true;
        }
    }
}
