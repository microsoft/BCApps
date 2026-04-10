// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.BatchProcessing;

table 52 "Batch Processing Parameter"
{
    Caption = 'Batch Processing Parameter';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Batch ID"; Guid)
        {
            Caption = 'Batch ID';
        }
        field(2; "Parameter Id"; Integer)
        {
            Caption = 'Parameter Id';
        }
        field(3; "Parameter Value"; Text[250])
        {
            Caption = 'Parameter Value';
        }
    }

    keys
    {
        key(Key1; "Batch ID", "Parameter Id")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

