// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
#pragma warning disable AA0247
page 1309 "O365 Getting Started"
{
    Caption = 'Hi!';
    PageType = NavigatePage;
    SourceTable = "O365 Getting Started";
    layout
    {
        area(content)
        {
            group(Control3)
            {
                ShowCaption = false;
                Visible = CurrentPage;
                group(Control4)
                {
                    ShowCaption = false;
                    usercontrol(WelcomeWizard; WelcomeWizard)
                    {
                        ApplicationArea = Basic, Suite;

                        trigger ControlAddInReady()
                        var
                            ExplanationStr: Text;
                            WelcomeToTitle: Text;
                        begin
                            ExplanationStr := StrSubstNo(ExplanationTxt, CompanyName);
                            WelcomeToTitle := StrSubstNo(TitleTxt, PRODUCTNAME.Marketing());

                            CurrAllProfile.SetRecFilter();
                            if CurrAllProfile.FindFirst() then;
                            CurrPage.WelcomeWizard.Initialize(WelcomeToTitle, SubTitleTxt, ExplanationStr, IntroTxt, IntroDescTxt,
                              GetStartedTxt, GetStartedDescTxt, FindHelpTxt, FindHelpDescTxt, RoleCentersTxt, RoleCentersDescTxt, CurrAllProfile.Description,
                              LegalDescriptionTxt);
                        end;

                        trigger ErrorOccurred(error: Text; description: Text)
                        begin
                        end;

                        trigger Refresh()
                        begin
                        end;

                        trigger ThumbnailClicked(selection: Integer)
                        var
                            Video: Codeunit Video;
                        begin
                            case selection of
                                1:
                                    Video.Play('https://go.microsoft.com/fwlink/?linkid=867632');
                                2:
                                    Video.Play('https://go.microsoft.com/fwlink/?linkid=867634');
                                3:
                                    Video.Play('https://go.microsoft.com/fwlink/?linkid=867635');
                                4:
                                    begin
                                        Clear(RoleCenterOverview);
                                        RoleCenterOverview.DelaySessionUpdateRequest();
                                        if RoleCenterOverview.RunModal() = ACTION::OK then begin
                                            RoleCenterOverview.GetSelectedProfile(CurrAllProfile.Scope, CurrAllProfile."App ID", CurrAllProfile."Profile ID");
                                            if RoleCenterOverview.GetAcceptAction() then begin
                                                CurrAllProfile.SetRecFilter();
                                                if CurrAllProfile.FindFirst() then;
                                                CurrPage.WelcomeWizard.UpdateProfileId(CurrAllProfile.Description);
                                            end;
                                        end;
                                    end;
                            end;
                        end;
                    }
                }
            }
        }
    }

    actions
    {
        area(creation)
        {
            action("Get Started")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Get Started';
                InFooterBar = true;

                trigger OnAction()
                var
                    UserPersonalization: Record "User Personalization";
                    AllProfile: Record "All Profile";
                    ConfPersonalizationMgt: Codeunit "Conf./Personalization Mgt.";
                    SessionSet: SessionSettings;
                begin
                    if ConfPersonalizationMgt.IsCurrentProfile(CurrAllProfile.Scope, CurrAllProfile."App ID", CurrAllProfile."Profile ID") then
                        CurrPage.Close();

                    if RoleCenterOverview.GetAcceptAction() then begin
                        if not AllProfile.Get(CurrAllProfile.Scope, CurrAllProfile."App ID", CurrAllProfile."Profile ID") then
                            CurrPage.Close();

                        ConfPersonalizationMgt.SetCurrentProfile(AllProfile);
                        UserPersonalization.Get(UserSecurityId());

                        SessionSet.Init();
                        SessionSet.ProfileId := CurrAllProfile."Profile ID";
                        SessionSet.ProfileAppId := CurrAllProfile."App ID";
#pragma warning disable AL0667
                        SessionSet.ProfileSystemScope := CurrAllProfile.Scope = CurrAllProfile.Scope::System;
#pragma warning restore AL0667
                        SessionSet.LanguageId := UserPersonalization."Language ID";
                        SessionSet.LocaleId := UserPersonalization."Locale ID";
                        SessionSet.Timezone := UserPersonalization."Time Zone";
                        SessionSet.RequestSessionUpdate(true);
                    end;

                    CurrPage.Close();
                end;
            }
        }
    }

    trigger OnClosePage()
    begin
        Rec."Tour in Progress" := false;
        Rec."Tour Completed" := true;
        Rec.Modify();
    end;

    trigger OnInit()
    var
        ConfPersonalizationMgt: Codeunit "Conf./Personalization Mgt.";
    begin
        Rec.SetRange("User ID", UserId);

        ConfPersonalizationMgt.GetCurrentProfileNoError(CurrAllProfile);
    end;

    trigger OnOpenPage()
    begin
        if not Rec.AlreadyShown() then
            Rec.MarkAsShown();

        CurrentPage := true;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        ConfPersonalizationMgt: Codeunit "Conf./Personalization Mgt.";
    begin
        if (not ConfPersonalizationMgt.IsCurrentProfile(CurrAllProfile.Scope, CurrAllProfile."App ID", CurrAllProfile."Profile ID")) and RoleCenterOverview.GetAcceptAction() then
            if not Confirm(RoleNotSavedQst) then
                Error('');
    end;

    var
        RoleCenterOverview: Page "Role Center Overview";
        CurrAllProfile: Record "All Profile";
        RoleNotSavedQst: Label 'Your choice of role center is not saved. Are you sure you want to close?';
        TitleTxt: Label 'Welcome to %1', Comment = '%1 is the branding PRODUCTNAME.MARKETING string constant';
        SubTitleTxt: Label 'Let''s get started';
        ExplanationTxt: Label 'Start with basic business processes, or jump right in to advanced operations. Use our %1 demo company and data, or create a new company and import your own data.', Comment = '%1 - This is the COMPANYNAME. ex. Cronus US Inc.';
        IntroTxt: Label 'Introduction';
        IntroDescTxt: Label 'Get to know Business Central';
        GetStartedTxt: Label 'Get Started';
        GetStartedDescTxt: Label 'See the important first steps';
        FindHelpTxt: Label 'Get Assistance';
        FindHelpDescTxt: Label 'Know where to go for information';
        RoleCentersTxt: Label 'Role Centers';
        RoleCentersDescTxt: Label 'Explore different business roles';
        CurrentPage: Boolean;
        LegalDescriptionTxt: Label 'Demo data is provided for demonstration purposes only and should be used only for evaluation, training and test systems.';

    procedure GetNextPageID(Increment: Integer; CurrentPageID: Integer) NextPageID: Integer
    begin
        NextPageID := CurrentPageID + Increment;
    end;

}
