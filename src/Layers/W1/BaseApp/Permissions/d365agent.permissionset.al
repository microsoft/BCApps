// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Security.AccessControl;

using System.Agents;

/// <summary>
/// Provides basic access to the agent functionality. 
/// TODO: Move permission set to the System app Agent module when it is introduced
/// </summary>
permissionset 6219 "D365 Agent"
{
    Caption = 'Dynamics 365 Agent';
    Assignable = false;
    Permissions = tabledata Agent = Rimd,
                  tabledata "Agent Task" = RIMd,
                  tabledata "Agent Task File" = RIMd,
                  tabledata "Agent Task Log Entry" = RIMd,
                  tabledata "Agent Task Message" = RIMd,
                  tabledata "Agent Task Message Attachment" = RIMD,
                  tabledata "Agent Access Control" = RIMD,
                  tabledata "Agent Task Memory Entry" = RIMd,
                  tabledata "Agent Task Timeline" = Rimd,
                  tabledata "Agent Task Timeline Step" = Rimd,
                  tabledata "Agent Task Timeline Step Det." = Rimd,
                  system "Manage Agent Tasks" = X;
}