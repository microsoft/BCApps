// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

using System.Environment;

page 3318 "PA Trial Guide"
{
    PageType = NavigatePage;
    ApplicationArea = All;
    InherentEntitlements = X;
    InherentPermissions = X;
    Extensible = false;
    Caption = 'Activate Payables Agent', Comment = 'Payables Agent is a term, and should not be translated.';

    layout
    {
        area(Content)
        {
            group(StandardBanner)
            {
                ShowCaption = false;
                Editable = false;
                Visible = BannerVisible;

                field(MediaResourcesStd; MediaResourcesStandard."Media Reference")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ShowCaption = false;
                }
            }
            field(TitleMsg; TitleMsg)
            {
                ApplicationArea = All;
                Style = Strong;
                Editable = false;
                ShowCaption = false;
            }
            field(ParagraphMsg; ParagraphMsg)
            {
                ApplicationArea = All;
                Editable = false;
                ShowCaption = false;
                MultiLine = true;
            }
            field(ParagraphMsg2; Paragraph2Msg)
            {
                ApplicationArea = All;
                Editable = false;
                ShowCaption = false;
                MultiLine = true;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ActionFinish)
            {
                ApplicationArea = All;
                Caption = 'Activate';
                ToolTip = 'Activate the Payables Agent so it can process the invoice you upload.', Comment = 'Payables Agent is a term, and should not be translated.';
                Image = Approve;
                InFooterBar = true;

                trigger OnAction()
                begin
                    ActivationConfirmedByUser := true;
                    CurrPage.Close();
                end;
            }
            action(ActionCancel)
            {
                ApplicationArea = All;
                Caption = 'Cancel';
                ToolTip = 'Close without activating the Payables Agent.', Comment = 'Payables Agent is a term, and should not be translated.';
                Image = Cancel;
                InFooterBar = true;

                trigger OnAction()
                begin
                    CurrPage.Close();
                end;
            }
        }
    }

    var
        MediaResourcesStandard: Record "Media Resources";
        PATrial: Codeunit "PA Trial";
        BannerVisible: Boolean;
        ActivationConfirmedByUser: Boolean;
        ParagraphMsg: Text;
        TitleMsg: Label 'Activate the Payables Agent', Comment = 'Payables Agent is a term, and should not be translated.';
        TrialParagraphMsg: Label 'Activating lets the Payables Agent process the invoices you upload. It also starts your one-time free trial, which can be started only once and cannot be restarted. During the trial the Payables Agent does not consume billable AI credits. When the trial ends, the Payables Agent starts to consume billable AI credits.', Comment = 'Payables Agent is a term, and should not be translated.';
        TrialActiveParagraphMsg: Label 'Activating lets the Payables Agent process the invoices you upload. Your one-time free trial is still running, so the invoices you upload do not consume billable AI credits yet. When the trial ends, the Payables Agent starts to consume billable AI credits.', Comment = 'Payables Agent is a term, and should not be translated.';
        BilledParagraphMsg: Label 'Activating lets the Payables Agent process the invoices you upload. Your free trial is not available, so the invoices you upload consume billable AI credits.', Comment = 'Payables Agent is a term, and should not be translated.';
        Paragraph2Msg: Label 'Uploaded invoices show up in the agent task pane on the right-hand side, where you can track their progress.';

    trigger OnInit()
    begin
        if MediaResourcesStandard.Get('COPILOTNOTAVAILABLE.PNG') then
            BannerVisible := MediaResourcesStandard."Media Reference".HasValue();

        if PATrial.IsEligibleToStart() then
            ParagraphMsg := TrialParagraphMsg
        else
            if PATrial.IsActive() then
                ParagraphMsg := TrialActiveParagraphMsg
            else
                ParagraphMsg := BilledParagraphMsg;
    end;

    internal procedure ActivationConfirmed(): Boolean
    begin
        exit(ActivationConfirmedByUser);
    end;
}
