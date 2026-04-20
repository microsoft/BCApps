// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Tooling;

/// <summary>
/// Illustrative stub for a chat-based request experience. Not wired up yet. A future
/// iteration will let the user describe the slow scenario in natural language and have
/// Copilot fill in the analysis request, replacing (or complementing) the wizard.
/// </summary>
page 8430 "Perf. Analysis Chat Req. Stub"
{
    Caption = 'Report slow performance (chat, preview)';
    PageType = PromptDialog;
    IsPreview = true;
    Extensible = false;
    ApplicationArea = All;
    Editable = true;
    InherentPermissions = X;
    InherentEntitlements = X;

    layout
    {
        area(Prompt)
        {
            field(UserDescription; UserDescription)
            {
                Caption = 'Describe what is slow';
                InstructionalText = 'Preview only. Describe the slow scenario in natural language. In a future release this will translate into a Performance Analysis request automatically.';
                ShowCaption = false;
                MultiLine = true;
                ApplicationArea = All;
                ToolTip = 'Specifies the natural-language description of the slow scenario.';
            }
        }
        area(Content)
        {
            group(PreviewNotice)
            {
                Caption = 'Preview';

                field(PreviewText; PreviewLbl)
                {
                    ShowCaption = false;
                    MultiLine = true;
                    Editable = false;
                    ApplicationArea = All;
                    ToolTip = 'Explains the preview state.';
                }
            }
        }
    }

    actions
    {
        area(SystemActions)
        {
            systemaction(Ok)
            {
                Caption = 'Open the wizard instead';
                ToolTip = 'Falls back to the guided wizard.';
            }
            systemaction(Cancel)
            {
                ToolTip = 'Close this preview.';
            }
        }
    }

    var
        UserDescription: Text;
        PreviewLbl: Label 'This chat-based request experience is a design preview. For now, please use the guided wizard to request an analysis.';
}
