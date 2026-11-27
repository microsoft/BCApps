// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting.Test;

using Microsoft.Manufacturing.Subcontracting;

table 149929 "Subc WIP Concurrent Signal"
{
    Access = Internal;
    DataClassification = CustomerContent;
    fields
    {
        field(1; "Run ID"; Guid) { }
        field(2; Worker; Integer) { }
        field(3; Action; Code[20]) { }
        field(4; "Session ID"; Integer) { }
        field(5; Ready; Boolean) { }
        field(6; Done; Boolean) { }
        field(7; Succeeded; Boolean) { }
        field(8; Failure; Text[2048]) { }
        field(9; "Order No."; Code[20]) { }
        field(10; "Run Trigger"; Boolean) { }
        field(11; Cohort; Enum "Subc. WIP Cohort") { }
        field(12; "Lineage ID"; Guid) { }
        field(13; "Ledger Entry No."; Integer) { }
        field(14; "Purchase Order No."; Code[20]) { }
        field(15; "Purchase Line No."; Integer) { }
        field(16; "Blocked Observed"; Boolean) { }
        field(17; "Transfer Order No."; Code[20]) { }
        field(18; "Expected Available"; Decimal) { }
    }
    keys
    {
        key(PK; "Run ID", Worker) { Clustered = true; }
    }
}
