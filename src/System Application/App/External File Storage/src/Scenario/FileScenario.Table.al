// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.ExternalFileStorage;

/// <summary>
/// Holds the mapping between file account and scenarios.
/// One scenarios is mapped to one file account.
/// One file account can be used for multiple scenarios.
/// </summary>
table 9454 "File Scenario"
{
    DataClassification = SystemMetadata;
    Access = Internal;
    ReplicateData = false;
    InherentPermissions = X;
    InherentEntitlements = X;

    fields
    {
        field(1; Scenario; Enum "File Scenario") { }
        field(2; Connector; Enum "Ext. File Storage Connector") { }
        field(3; "Account Id"; Guid) { }
    }

    keys
    {
        key(PK; Scenario)
        {
            Clustered = true;
        }
    }
}