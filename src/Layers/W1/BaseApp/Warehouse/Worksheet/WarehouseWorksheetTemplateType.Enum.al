// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Worksheet;

#pragma warning disable AL0659
enum 7312 "Warehouse Worksheet Template Type"
#pragma warning restore AL0659
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Put-away") { Caption = 'Put-away'; }
    value(1; "Pick") { Caption = 'Pick'; }
    value(2; "Movement") { Caption = 'Movement'; }
}
