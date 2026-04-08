// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Test.Agents;

permissionset 133964 "Agent SDK Test"
{
    Assignable = true;
    Caption = 'Agent SDK Test';

    Permissions =
        codeunit "Agent SDK Test Install" = X,
        codeunit "Library Mock Agent" = X;
}
