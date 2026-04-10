// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Resources;

enum 5958 "Resource Skill Assigned From"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; " ")
    {
        Caption = ' ';
    }
    value(1; "Service Item Group")
    {
        Caption = 'Service Item Group';
    }
    value(2; Item)
    {
        Caption = 'Item';
    }
}
