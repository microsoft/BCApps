// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Planning;

enum 5527 "Planning Create Transfer Order"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; " ") { Caption = ' '; }
    value(1; "Make Trans. Orders") { Caption = 'Make Trans. Orders'; }
    value(2; "Make Trans. Order & Print") { Caption = 'Make Trans. Order & Print'; }
    value(3; "Copy to Req. Wksh") { Caption = 'Copy to Req. Wksh'; }
}
