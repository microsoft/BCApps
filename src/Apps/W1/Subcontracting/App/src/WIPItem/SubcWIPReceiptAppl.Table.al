// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

table 20584 "Subc. WIP Receipt Appl."
{
    Access = Internal;
    DataClassification = CustomerContent;
    fields
    {
        field(1; "Capacity Entry No."; Integer) { }
        field(2; "Receipt No."; Code[20]) { }
        field(3; "Receipt Line No."; Integer) { }
        field(4; "Purchase Order No."; Code[20]) { }
        field(5; "Purchase Order Line No."; Integer) { }
        field(6; "Quantity (Base)"; Decimal) { DecimalPlaces = 0 : 5; }
        field(7; "Application ID"; Guid) { }
        field(8; Finalized; Boolean) { }
        field(9; Reversed; Boolean) { }
    }
    keys
    {
        key(PK; "Capacity Entry No.") { Clustered = true; }
        key(Receipt; "Receipt No.", "Receipt Line No.", Finalized) { }
    }
}
