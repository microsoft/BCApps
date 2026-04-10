// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Resources.Resource;

enum 1562 "Resource Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; Person)
    {
        Caption = 'Person';
    }
    value(1; Machine)
    {
        Caption = 'Machine';
    }
}
