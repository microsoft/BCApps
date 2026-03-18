// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Activity;

enum 5767 "Warehouse Activity Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; " ") { Caption = ' '; }
    value(1; "Put-away") { Caption = 'Put-away'; }
    value(2; "Pick") { Caption = 'Pick'; }
    value(3; "Movement") { Caption = 'Movement'; }
    value(4; "Invt. Put-away") { Caption = 'Invt. Put-away'; }
    value(5; "Invt. Pick") { Caption = 'Invt. Pick'; }
    value(6; "Invt. Movement") { Caption = 'Invt. Movement'; }
}
