// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Tooling;

/// <summary>
/// Developer-only viewer for the assembled LLM prompt behind an analysis. Lets a
/// developer verify what is being sent to AOAI without having to attach a debugger
/// or rummage in telemetry.
/// </summary>
page 8433 "Perf. Analysis Debug Prompt"
{
    Caption = 'LLM prompt (debug)';
    PageType = Card;
    Editable = false;
    Extensible = false;
    LinksAllowed = false;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            group(PromptGroup)
            {
                ShowCaption = false;

                field(PromptText; PromptText)
                {
                    ShowCaption = false;
                    MultiLine = true;
                    ApplicationArea = All;
                    ToolTip = 'Specifies the full LLM prompt (system message, instruction and user payload) that the Performance Center would send to Azure OpenAI for this analysis.';
                }
            }
        }
    }

    var
        PromptText: Text;

    /// <summary>
    /// Set the prompt text before running the page.
    /// </summary>
    procedure SetPrompt(NewText: Text)
    begin
        PromptText := NewText;
    end;
}
