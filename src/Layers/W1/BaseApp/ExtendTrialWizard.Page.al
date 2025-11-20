// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft;

using Microsoft.RoleCenters;
using System.Environment;
using System.Utilities;

page 1828 "Extend Trial Wizard"
{
    Caption = 'Extend Trial';
    PageType = NavigatePage;

    layout
    {
        area(content)
        {
            group(Control96)
            {
                Editable = false;
                ShowCaption = false;
                Visible = TopBannerVisible;
#pragma warning disable AA0100
                field("MediaResourcesStandard.""Media Reference"""; MediaResourcesStandard."Media Reference")
#pragma warning restore AA0100
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    Editable = false;
                    ShowCaption = false;
                }
            }
            group("<MediaRepositoryDone>")
            {
                Visible = ExtendVisible;
                group("Need more time to try things out?")
                {
                    Caption = 'Need more time to try things out?';
                    field(ExtendTrialTxt; ExtendTrialTxt)
                    {
                        ApplicationArea = Invoicing, Basic, Suite;
                        Editable = false;
                        Enabled = false;
                        MultiLine = true;
                        ShowCaption = false;
                    }
                }
                group("Ready to subscribe?")
                {
                    Caption = 'Ready to subscribe?';
                    InstructionalText = 'Subscribing is fast and easy, and you can quickly get back to what you were doing.';
                    Visible = not IsPreview;
                    field(SubscribeNowLbl; SubscribeNowLbl)
                    {
                        ApplicationArea = Invoicing, Basic, Suite;
                        Editable = false;
                        ShowCaption = false;

                        trigger OnDrillDown()
                        begin
                            BuySubscription();
                        end;
                    }
                }
                group("Got a question?")
                {
                    Caption = 'Got a question?';
                    InstructionalText = 'If you are not sure what this is about, get more information about extending trial periods.';
                    field(LearnMoreLbl; LearnMoreLbl)
                    {
                        ApplicationArea = Invoicing, Basic, Suite;
                        Editable = false;
                        ShowCaption = false;

                        trigger OnDrillDown()
                        begin
                            Documentation();
                        end;
                    }
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(ActionExtendTrial)
            {
                ApplicationArea = Invoicing, Basic, Suite;
                Caption = 'Extend Trial';
                Image = Approve;
                InFooterBar = true;
                Visible = ExtendVisible;

                trigger OnAction()
                var
                    Answer: Boolean;
                begin
                    Answer := Confirm(ExtendTrialConfirmQst);
                    if Answer then
                        ExtendTrialAction();
                end;
            }
        }
    }

    trigger OnInit()
    begin
        LoadTopBanners();
        OnIsRunningPreview(IsPreview);
    end;

    trigger OnOpenPage()
    var
        TenantLicenseState: Codeunit "Tenant License State";
        RemainingDays: Integer;
    begin
        ExtendVisible := true;
        RemainingDays := 0;

        if TenantLicenseState.IsTrialMode() then
            RemainingDays := RoleCenterNotifMgt.GetLicenseRemainingDays();

        ExtendTrialTxt := StrSubstNo(ExtendTrialMessageTxt, RemainingDays);
    end;

    var
        MediaRepositoryStandard: Record "Media Repository";
        MediaResourcesStandard: Record "Media Resources";
        ClientTypeManagement: Codeunit "Client Type Management";
        RoleCenterNotifMgt: Codeunit "Role Center Notification Mgt.";
        TopBannerVisible: Boolean;
        IsPreview: Boolean;
        SubscribeNowLbl: Label 'Subscribe now';
        LearnMoreLbl: Label 'Learn more';
        ExtendVisible: Boolean;
        ExtendTrialMessageTxt: Label 'It''s a big decision, so don''t rush. You can use this guide one time to add 30 days to your trial period. You still have %1 days remaining in your current period. The new 30 day period starts the moment you choose Extend Trial.', Comment = '%1=Count of days until trial expires';
        ExtendTrialTxt: Text;
        ExtendTrialConfirmQst: Label 'You''ll have 30 days from right now. Are you sure?';
        ExtendedTrialSuccessMsg: Label 'Congratulations, your trial period has been extended. The new expiration date is %1.', Comment = '%1=New expiration date';
        DocumentationURLTxt: Label 'https://go.microsoft.com/fwlink/?linkid=2039763', Locked = true;
        BuyThroughPartnerURLTxt: Label 'https://go.microsoft.com/fwlink/?linkid=860971', Locked = true;

    local procedure ExtendTrialAction()
    var
        TenantLicenseState: Codeunit "Tenant License State";
        EndDate: DateTime;
    begin
        TenantLicenseState.ExtendTrialLicense();
        EndDate := TenantLicenseState.GetEndDate();
        Message(StrSubstNo(ExtendedTrialSuccessMsg, Format(DT2Date(EndDate))));

        CurrPage.Close();
    end;

    local procedure LoadTopBanners()
    begin
        if MediaRepositoryStandard.Get('AssistedSetupInfo-NoText.png', Format(ClientTypeManagement.GetCurrentClientType()))
        then
            if MediaResourcesStandard.Get(MediaRepositoryStandard."Media Resources Ref")
            then
                TopBannerVisible := MediaResourcesStandard."Media Reference".HasValue;
    end;

    local procedure Documentation()
    begin
        HyperLink(DocumentationURLTxt);
    end;

    local procedure BuySubscription()
    begin
        HyperLink(BuyThroughPartnerURLTxt);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnIsRunningPreview(var isPreview: Boolean)
    begin
    end;
}

