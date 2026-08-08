// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Privacy;
using Microsoft.ExpenseAgent;

page 7078 "Anthropic Privacy Notice"
{
    Caption = 'Please review terms and conditions';
    PageType = NavigatePage;
    SourceTable = "Privacy Notice";
    SourceTableTemporary = true;
    Extensible = false;
    InherentEntitlements = X;
    InherentPermissions = X;

    layout
    {
        area(Content)
        {
            label(AnthropicIntroLabel)
            {
                ApplicationArea = All;
                CaptionClass = AnthropicIntroText;
            }
            label(PrivacyNoticeLabel)
            {
                ApplicationArea = All;
                CaptionClass = PrivacyText;
            }
            label(AnthropicOutroLabel)
            {
                ApplicationArea = All;
                CaptionClass = AnthropicOutroText;
            }
            field(LearnMore; LearnMoreTxt)
            {
                ApplicationArea = All;
                Editable = false;
                ShowCaption = false;
                ToolTip = 'Learn more.';

                trigger OnDrillDown()
                begin
                    Hyperlink(AnthropicLearnMoreLinkTok);
                end;
            }
            field(PrivacyAndCookiesTxt; PrivacyAndCookiesTxt)
            {
                ApplicationArea = All;
                Editable = false;
                ShowCaption = false;
                ToolTip = 'View information about privacy and cookies.';

                trigger OnDrillDown()
                begin
                    Hyperlink(Rec.Link);
                end;
            }
            label(ApproveForOrganization)
            {
                ApplicationArea = All;
                Visible = UserCanApproveForOrganization;
                Caption = 'You are consenting on behalf of your organization.';
                Importance = Promoted;
            }
            label(CannotApproveForOrganization)
            {
                ApplicationArea = All;
                Visible = not UserCanApproveForOrganization;
                Caption = 'Ask your administrator to consent on behalf of your organization.';
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(Reject)
            {
                ApplicationArea = All;
                Caption = 'Disagree';
                ToolTip = 'Disagree to the terms and conditions.';
                Image = PreviousRecord;
                InFooterBar = true;
                Visible = UserCanApproveForOrganization;

                trigger OnAction()
                begin
                    PrivacyNotice.SetApprovalState(Rec.ID, "Privacy Notice Approval State"::Disagreed);
                    CurrPage.Close();
                end;
            }
            action(Accept)
            {
                ApplicationArea = All;
                Caption = 'Agree';
                ToolTip = 'Agree to the terms and conditions.';
                Image = NextRecord;
                InFooterBar = true;
                Visible = UserCanApproveForOrganization;

                trigger OnAction()
                begin
                    PrivacyNotice.SetApprovalState(Rec.ID, "Privacy Notice Approval State"::Agreed);
                    CurrPage.Close();
                end;
            }
        }
    }

    trigger OnOpenPage()
    var
        ExpPrivacyNoticeReg: Codeunit "Exp. Privacy Notice Reg.";
    begin
        PrivacyText := StrSubstNo(AnthropicNotificationPrivacyLbl, ExpPrivacyNoticeReg.GetAnthropicName(), ProductName.Marketing());
        AnthropicIntroText := StrSubstNo(AnthropicIntroPrivacyLbl, ExpPrivacyNoticeReg.GetAnthropicName());
        AnthropicOutroText := AnthropicOutroPrivacyLbl;
        UserCanApproveForOrganization := PrivacyNotice.CanCurrentUserApproveForOrganization();
    end;

    var
        PrivacyNotice: Codeunit "Privacy Notice";
        AnthropicIntroPrivacyLbl: Label 'This feature uses %1, which is an AI provider operating as a Microsoft subprocessor.', Comment = '%1 = The Anthropic service name';
        AnthropicNotificationPrivacyLbl: Label 'By using this feature, you consent to your data being shared with %1 services that might be outside of your organisation''s selected geographic boundaries and might have different compliance and security standards than %2. Your privacy is important to us, and you can choose whether to share data with the service.', Comment = '%1 = The Anthropic service name, %2 = The Business Central service name';
        AnthropicOutroPrivacyLbl: Label 'If you decide not to share data with the service, features that require the service might stop working.';
        AnthropicLearnMoreLinkTok: Label 'https://learn.microsoft.com/microsoft-365/copilot/connect-to-ai-subprocessor', Locked = true;
        LearnMoreTxt: Label 'Learn more';
        PrivacyAndCookiesTxt: Label 'Privacy and Cookies';
        PrivacyText: Text;
        AnthropicIntroText: Text;
        AnthropicOutroText: Text;
        UserCanApproveForOrganization: Boolean;
}
