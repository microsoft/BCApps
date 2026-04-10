// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.D365Sales;

table 5391 "CRM Annotation Buffer"
{
    Caption = 'CRM Annotation Buffer';
    DataClassification = CustomerContent;

    fields
    {
        field(1; ID; Integer)
        {
            AutoIncrement = true;
            Caption = 'ID';
            DataClassification = SystemMetadata;
        }
        field(2; "Related Table ID"; Integer)
        {
            Caption = 'Related Table ID';
            DataClassification = SystemMetadata;
        }
        field(3; "Related Record ID"; RecordID)
        {
            Caption = 'Related Record ID';
            DataClassification = CustomerContent;
        }
        field(4; "Record ID"; RecordID)
        {
            Caption = 'Record ID';
            DataClassification = CustomerContent;
        }
        field(5; "Change Type"; Option)
        {
            Caption = 'Change Type';
            DataClassification = SystemMetadata;
            OptionCaption = ',Created,Deleted';
            OptionMembers = ,Created,Deleted;
        }
        field(6; "Change DateTime"; DateTime)
        {
            Caption = 'Change DateTime';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; ID)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

