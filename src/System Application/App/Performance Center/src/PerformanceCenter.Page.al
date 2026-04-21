// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Tooling;

using System.PerformanceProfile;
using System.Security.User;

/// <summary>
/// Performance Center hub. Simple part is always visible. Advanced part is visible to
/// users who can manage other users on the tenant.
/// </summary>
page 8423 "Performance Center"
{
    Caption = 'Performance Center';
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;
    AboutTitle = 'About the Performance Center';
    AboutText = 'The Performance Center helps you troubleshoot slowness in Business Central. Analyze a problem to schedule an AI-assisted capture, or dig into recent activity if you are a power user.';
    Permissions = tabledata "Performance Analysis" = R,
                  tabledata "Performance Profile Scheduler" = R;

    layout
    {
        area(Content)
        {
            group(Simple)
            {
                Caption = 'Analyze a performance problem';

                field(SimpleHint; SimpleHintLbl)
                {
                    ShowCaption = false;
                    Editable = false;
                    MultiLine = true;
                    ApplicationArea = All;
                    ToolTip = 'Describes what the Performance Center does for an end user.';
                }
                field(AiDisabled; AiDisabledHintLbl)
                {
                    ShowCaption = false;
                    Editable = false;
                    MultiLine = true;
                    Visible = not IsAiAvailable;
                    Style = Ambiguous;
                    ApplicationArea = All;
                    ToolTip = 'Explains that AI-assisted analysis requires the Copilot capability to be enabled.';
                }
            }
            part(Analyses; "Perf. Analysis List Part")
            {
                Caption = 'Performance analyses';
                ApplicationArea = All;
                SubPageView = sorting("Requested At") order(descending);
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(StartWizard)
            {
                Caption = 'Analyze slow performance';
                ToolTip = 'Open a guided wizard to describe a slow scenario and schedule a performance analysis.';
                Image = Start;
                ApplicationArea = All;
                Enabled = IsAiAvailable;

                trigger OnAction()
                var
                    Wizard: Page "Perf. Analysis Wizard";
                begin
                    Wizard.RunModal();
                end;
            }
            action(StartChatRequest)
            {
                Caption = 'Analyze slow performance (chat preview)';
                ToolTip = 'Preview of a chat-based request experience. Not yet wired up.';
                Image = Comment;
                ApplicationArea = All;
                Visible = IsAdvanced;
                Enabled = IsAiAvailable;

                trigger OnAction()
                var
                    ChatStub: Page "Perf. Analysis Chat Req. Stub";
                begin
                    ChatStub.RunModal();
                end;
            }
            group(Debug)
            {
                Caption = 'Debug';
                action(SlowOperationTest)
                {
                    Caption = 'Run operation (test)';
                    ToolTip = 'Run a test operation. Use this to produce a captured profile while a performance analysis is actively monitoring.';
                    Image = TestFile;
                    ApplicationArea = All;

                    trigger OnAction()
                    var
                        SlowOp: Codeunit "Perf. Analysis Slow Op Test";
                    begin
                        SlowOp.SlowOperation();
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';
                actionref(StartWizard_Promoted; StartWizard) { }
            }
        }
    }

    var
        IsAdvanced: Boolean;
        IsAiAvailable: Boolean;
        SimpleHintLbl: Label 'Is something slow in Business Central? Describe what is slow, how often it happens and how long it takes. We will then monitor performance for a while behind the scenes and use AI to explain what was going on.';
        AiDisabledHintLbl: Label 'AI-assisted analysis is currently disabled for this environment. You can still schedule a capture, but the analysis and chat actions will be unavailable until the "AI-assisted performance analysis in Performance Center" Copilot capability is enabled.';

    trigger OnOpenPage()
    var
        AnalysesFilter: Record "Performance Analysis";
        UserPermissions: Codeunit "User Permissions";
        Ai: Codeunit "Perf. Analysis AI";
    begin
        IsAdvanced := UserPermissions.CanManageUsersOnTenant(UserSecurityId());
        IsAiAvailable := Ai.IsAvailable();

        if not IsAdvanced then
            AnalysesFilter.SetRange("Requested By", UserSecurityId());
        CurrPage.Analyses.Page.SetTableView(AnalysesFilter);
    end;
}
