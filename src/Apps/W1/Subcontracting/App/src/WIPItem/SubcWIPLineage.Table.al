// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

table 20581 "Subc. WIP Lineage"
{
    Access = Internal;
    DataClassification = SystemMetadata;
    fields
    {
        field(1; ID; Guid) { }
        field(2; Cohort; Enum "Subc. WIP Cohort") { }
        field(3; Version; Integer) { }
    }
    keys { key(PK; ID) { Clustered = true; } }
}
