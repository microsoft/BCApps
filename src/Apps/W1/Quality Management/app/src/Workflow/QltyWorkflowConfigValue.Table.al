// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Workflow;

table 20435 "Qlty. Workflow Config. Value"
{
    DataClassification = CustomerContent;
    Caption = 'Quality Workflow Configuration Value';

    fields
    {
        field(1; "Template Key"; Text[20])
        {
            Caption = 'Template Key';
            NotBlank = true;
        }
        field(2; "Table ID"; Integer)
        {
            Caption = 'Table ID';
        }
        field(3; "Record ID"; RecordID)
        {
            Caption = 'Record ID';
        }
        field(10; Value; Text[100])
        {
            Caption = 'Value';
        }
    }

    keys
    {
        key(Key1; "Template Key", "Table ID", "Record ID")
        {
            Clustered = true;
        }
    }
}
