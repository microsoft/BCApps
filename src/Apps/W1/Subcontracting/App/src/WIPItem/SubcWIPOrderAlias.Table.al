// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Manufacturing.Document;

table 20582 "Subc. WIP Order Alias"
{
    Access = Internal;
    DataClassification = CustomerContent;
    fields
    {
        field(1; Status; Enum "Production Order Status") { }
        field(2; "Order No."; Code[20]) { }
        field(3; "Lineage ID"; Guid) { TableRelation = "Subc. WIP Lineage"; }
    }
    keys
    {
        key(PK; Status, "Order No.") { Clustered = true; }
        key(Lineage; "Lineage ID") { }
    }
}
