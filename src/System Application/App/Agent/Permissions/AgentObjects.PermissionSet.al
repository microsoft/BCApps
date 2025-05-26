// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Agents;

permissionset 4300 "Agent - Objects"
{
    Access = Internal;
    Assignable = false;

    Permissions = codeunit "Agent Task Impl." = X,
                  page "Agent Access Control" = X,
                  page "Agent Card" = X,
                  page "Agent List" = X,
                  page "Agent Task List" = X,
                  page "Agent Task Message Card" = X,
                  page "Agent Task Message List" = X,
                  page "Agent Task Log Entry List" = X,
                  page "Agent User Settings" = X,
                  codeunit "Agent Impl." = X,
                  codeunit "Agent Task Builder" = X,
                  codeunit "Agent Task Message Builder" = X;
}