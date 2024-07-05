// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.NoSeries;

using System.Environment.Configuration;

pageextension 324 "No. Series Ext." extends "No. Series"
{
    actions
    {
        addfirst(Prompting)
        {
            action("Generate With Copilot Prompting")
            {
                Caption = 'Generate';
                ToolTip = 'Generate No. Series using Copilot';
                Image = Sparkle;
                ApplicationArea = All;
                Visible = CopilotActionsVisible;

                trigger OnAction()
                var
                    NoSeriesCopilotImpl: Codeunit "No. Series Copilot Impl.";
                begin
                    NoSeriesCopilotImpl.GetNoSeriesSuggestions();
                end;
            }
        }

        addlast(Processing) // TODO: Remove this action when the feature is enabled, as it is a duplicate of the action above
        {
            action("Generate With Copilot")
            {
                Caption = 'Generate';
                ToolTip = 'Generate No. Series using Copilot';
                Image = Sparkle;
                ApplicationArea = All;
                Visible = CopilotActionsVisible;

                trigger OnAction()
                var
                    NoSeriesCopilotImpl: Codeunit "No. Series Copilot Impl.";
                begin
                    NoSeriesCopilotImpl.GetNoSeriesSuggestions();
                end;
            }
        }
    }

    trigger OnOpenPage()
    var
        NumberSeriesCopilotImpl: Codeunit "No. Series Copilot Impl.";
    begin
        CopilotActionsVisible := NumberSeriesCopilotImpl.IsCopilotVisible();
    end;

    var
        CopilotActionsVisible: Boolean;

}