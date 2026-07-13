// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Tracking;

enum 100 "Reserve Method"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Never") { Caption = 'Never'; }
    value(1; "Optional") { Caption = 'Optional'; }
    value(2; "Always") { Caption = 'Always'; }
}
