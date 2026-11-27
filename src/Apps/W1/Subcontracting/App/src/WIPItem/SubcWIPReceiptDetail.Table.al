// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

table 20585 "Subc. WIP Receipt Detail"
{
    Access = Internal;
    DataClassification = CustomerContent;
    fields
    {
        field(1; "Capacity Entry No."; Integer) { }
        field(2; "Detail No."; Integer) { }
        field(3; "Source Position No."; Integer) { }
        field(4; "Donor Lot ID"; Guid) { }
        field(5; "Quantity (Base)"; Decimal) { DecimalPlaces = 0 : 5; }
        field(6; "Unprocessed Entry No."; Integer) { }
        field(7; "Processed Entry No."; Integer) { }
    }
    keys { key(PK; "Capacity Entry No.", "Detail No.") { Clustered = true; } }
}
