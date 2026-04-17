// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Tooling;

/// <summary>
/// PromptDialog page for chatting with a concluded performance analysis.
/// </summary>
page 5496 "Perf. Analysis Chat"
{
    Caption = 'Chat with the analysis report';
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
            field(UserQuestion; UserQuestion)
            {
                Caption = 'Your question';
                InstructionalText = 'Ask a follow-up question about the analysis, for example: "Is this only slow when someone else is posting at the same time?"';
                ShowCaption = false;
                MultiLine = true;
                ApplicationArea = All;
                ToolTip = 'Specifies the follow-up question to send to the AI.';
            }
        }
        area(Content)
        {
            group(ConclusionGroup)
            {
                Caption = 'Conclusion';

                field(ConclusionBox; ConclusionText)
                {
                    ShowCaption = false;
                    MultiLine = true;
                    Editable = false;
                    ApplicationArea = All;
                    ToolTip = 'Shows the AI-generated conclusion for this analysis.';
                }
            }
            group(ReplyGroup)
            {
                Caption = 'Reply';
                Visible = ReplyText <> '';

                field(ReplyBox; ReplyText)
                {
                    ShowCaption = false;
                    MultiLine = true;
                    Editable = false;
                    ApplicationArea = All;
                    ToolTip = 'Shows the latest AI reply.';
                }
            }
        }
    }

    actions
    {
        area(SystemActions)
        {
            systemaction(Generate)
            {
                Caption = 'Ask';
                ToolTip = 'Send your question to the AI.';

                trigger OnAction()
                begin
                    AskAi();
                end;
            }
            systemaction(Regenerate)
            {
                Caption = 'Ask again';
                ToolTip = 'Send your question again.';

                trigger OnAction()
                begin
                    AskAi();
                end;
            }
            systemaction(Ok)
            {
                Caption = 'Done';
                ToolTip = 'Close the chat.';
            }
            systemaction(Cancel)
            {
                ToolTip = 'Close the chat without doing anything else.';
            }
        }
    }

    var
        Analysis: Record "Performance Analysis";
        ChatImpl: Codeunit "Perf. Analysis Chat Impl.";
        UserQuestion: Text;
        ReplyText: Text;
        ConclusionText: Text;
        AnalysisSet: Boolean;

    procedure SetAnalysis(var AnalysisRec: Record "Performance Analysis")
    begin
        Analysis := AnalysisRec;
        AnalysisSet := true;
    end;

    trigger OnOpenPage()
    begin
        if not AnalysisSet then
            exit;
        ConclusionText := Analysis.GetConclusion();
        ChatImpl.Initialize(Analysis);
    end;

    local procedure AskAi()
    begin
        if UserQuestion = '' then
            exit;
        ReplyText := ChatImpl.Ask(UserQuestion);
    end;
}
