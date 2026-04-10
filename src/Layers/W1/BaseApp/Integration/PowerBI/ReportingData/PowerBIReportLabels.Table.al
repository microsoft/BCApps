// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.PowerBI;

table 6306 "Power BI Report Labels"
{
    Caption = 'Power BI Report Labels';
    DataClassification = SystemMetadata;
    ReplicateData = false;

    fields
    {
        field(1; "Label ID"; Text[100])
        {
            Caption = 'Label ID';
            DataClassification = SystemMetadata;
            Description = 'ID specifying which field on which report this represents.';
        }
        field(2; "Text Value"; Text[250])
        {
            Caption = 'Text Value';
            DataClassification = SystemMetadata;
            Description = 'Display value to show in the report''s field.';
        }
    }

    keys
    {
        key(Key1; "Label ID")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

