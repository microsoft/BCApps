// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Agents;

page 4326 "Agent Creation Control"
{
    AboutTitle = 'About agent configuration rights';
    AboutText = 'Use this page to control which users can create agents. If no rules exist, only agent administrators can create agents.';
    AdditionalSearchTerms = 'agent creation control,allow agent creation,block agent creation';
    ApplicationArea = All;
    Caption = 'Agent Configuration Rights';
    DataCaptionExpression = '';
    InherentEntitlements = X;
    PageType = ListPlus;
    InsertAllowed = false;
    DeleteAllowed = false;
    UsageCategory = Administration;
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            label(Info)
            {
                Caption = 'Grant agent creation capability to non-administrator users. Users must also have the required permissions for the agent type.';
            }
            part(AgentCreationControlPart; "Agent Creation Control Part")
            {
            }
        }
    }
}