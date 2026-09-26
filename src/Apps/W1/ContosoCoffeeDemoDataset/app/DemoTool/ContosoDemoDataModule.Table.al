// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DemoTool;

table 5161 "Contoso Demo Data Module"
{
    DataCaptionFields = Name;
    DataClassification = CustomerContent;
    Access = Internal;
    Extensible = false;
    DataPerCompany = true;
    ReplicateData = false;
    InherentEntitlements = RimdX;
    InherentPermissions = RimdX;

    fields
    {
        field(1; Module; Enum "Contoso Demo Data Module")
        {
            DataClassification = SystemMetadata;
            Caption = 'Module';
        }
        field(2; Name; Text[100])
        {
            DataClassification = SystemMetadata;
            Caption = 'Name';
        }
        field(3; "Data Level"; Enum "Contoso Demo Data Level")
        {
            DataClassification = SystemMetadata;
            Caption = 'Data Level';
        }
        field(4; Install; Boolean)
        {
            DataClassification = SystemMetadata;
            Caption = 'Install';
        }
        field(5; "Is Setup Company"; Boolean)
        {
            DataClassification = SystemMetadata;
            Caption = 'Setup Company';
        }
    }

    keys
    {
        key(Key1; Module)
        {
            Clustered = true;
        }
    }
}
