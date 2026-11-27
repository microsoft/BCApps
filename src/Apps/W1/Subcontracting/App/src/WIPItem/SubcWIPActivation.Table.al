// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

table 20580 "Subc. WIP Activation"
{
    Access = Internal;
    DataClassification = SystemMetadata;
    fields
    {
        field(1; "Primary Key"; Code[10]) { }
        field(2; Version; Integer) { }
    }
    keys { key(PK; "Primary Key") { Clustered = true; } }
}
