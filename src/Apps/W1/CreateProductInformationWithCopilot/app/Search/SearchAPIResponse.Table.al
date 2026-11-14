#if not CLEAN30
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Item.Substitution;

table 7339 "Search API Response"
{
    ObsoleteState = Pending;
    ObsoleteReason = 'Copilot item substitution suggestions are discontinued. Use modern search on the Items list instead.';
    ObsoleteTag = '30.0';
    Access = Internal;
    TableType = Temporary;
    InherentEntitlements = X;
    InherentPermissions = X;

    fields
    {
        field(1; SysId; Guid)
        {
            DataClassification = SystemMetadata;
        }
        field(2; Score; Decimal)
        {
            DataClassification = SystemMetadata;
            AutoFormatType = 0;
        }
    }

    keys
    {
        key(Key1; SysId)
        {
            Clustered = true;
        }
    }
}
#endif
