// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Tracking;

enum 341 "Inventory Planning Flexibility"
{
    AssignmentCompatibility = true;
    Extensible = true;

    value(0; "Unlimited") { Caption = 'Unlimited'; }
    value(1; "None") { Caption = 'None'; }
    value(2; "Reduce Only") { Caption = 'Reduce Only'; }
}
