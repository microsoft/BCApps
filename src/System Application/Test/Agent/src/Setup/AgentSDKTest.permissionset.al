// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Test.Agents;

using System.Agents;
using System.Security.AccessControl;

permissionset 133964 "Agent SDK Test"
{
    Assignable = true;
    Caption = 'Agent SDK Test';

    Permissions =
        codeunit "Agent SDK Test Install" = X,
        codeunit "Library Mock Agent" = X,
        tabledata "Agent Task" = R,
        tabledata "Agent Task Log Entry" = R,
        tabledata "Agent Task Memory Entry" = R,
        tabledata "Agent Task Message" = R,
        tabledata User = R;
}
