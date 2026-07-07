// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Planning;

enum 5525 "Planning Create Purchase Order"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; " ") { Caption = ' '; }
    value(1; "Make Purch. Orders") { Caption = 'Make Purch. Orders'; }
    value(2; "Make Purch. Orders & Print") { Caption = 'Make Purch. Orders & Print'; }
    value(3; "Copy to Req. Wksh") { Caption = 'Copy to Req. Wksh'; }
}
