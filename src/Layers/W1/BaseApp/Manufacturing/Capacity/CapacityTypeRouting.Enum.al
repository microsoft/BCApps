// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Capacity;

enum 5872 "Capacity Type Routing"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Work Center") { Caption = 'Work Center'; }
    value(1; "Machine Center") { Caption = 'Machine Center'; }
    value(2; " ") { Caption = ' '; }
}
