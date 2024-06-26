// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.AI;

/// <summary>
/// Table to keep track of each Copilot Capability settings.
/// </summary>
table 7775 "Copilot Settings"
{
    Access = Internal;
    DataPerCompany = false;
    InherentEntitlements = rimdX;
    InherentPermissions = rimdX;
    ReplicateData = false;

    fields
    {
        field(1; Capability; Enum "Copilot Capability")
        {
            DataClassification = SystemMetadata;
        }
        field(2; "App Id"; Guid)
        {
            DataClassification = SystemMetadata;
        }
        field(3; Availability; Enum "Copilot Availability")
        {
            DataClassification = SystemMetadata;
        }
        field(4; Publisher; Text[2048])
        {
            DataClassification = SystemMetadata;
        }
        field(5; Status; Enum "Copilot Status")
        {
            DataClassification = SystemMetadata;
            InitValue = Active;
        }
        field(6; "Learn More Url"; Text[2048])
        {
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; Capability, "App Id")
        {
            Clustered = true;
        }
    }
}