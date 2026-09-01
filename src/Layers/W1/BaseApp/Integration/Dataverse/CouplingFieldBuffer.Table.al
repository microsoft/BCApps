#if not CLEANSCHEMA25 
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.Dataverse;

table 5333 "Coupling Field Buffer"
{
    Caption = 'Coupling Field Buffer';
    ReplicateData = false;
    ObsoleteState = Removed;
    ObsoleteTag = '25.0';
    ObsoleteReason = 'This table is no longer used. Use Coupling Field Buffer table instead.';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Field Name"; Text[50])
        {
            Caption = 'Field Name';
            DataClassification = SystemMetadata;
        }
        field(3; Value; Text[250])
        {
            Caption = 'Value';
            DataClassification = SystemMetadata;
        }
        field(4; "Integration Value"; Text[250])
        {
            Caption = 'Integration Value';
            DataClassification = SystemMetadata;
        }
        field(6; Direction; Option)
        {
            Caption = 'Direction';
            DataClassification = SystemMetadata;
            OptionCaption = 'Bidirectional,ToIntegrationTable,FromIntegrationTable';
            OptionMembers = Bidirectional,ToIntegrationTable,FromIntegrationTable;
        }
        field(8; "Validate Field"; Boolean)
        {
            Caption = 'Validate Field';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Field Name")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

 
#endif
