// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Apps;

using System.Environment;
using System.Utilities;

page 1834 "Teams Individual Deployment"
{
    Caption = 'Get the Business Central App for Teams';
    PageType = NavigatePage;
    ApplicationArea = Basic, Suite;
    UsageCategory = Tasks;
    AdditionalSearchTerms = 'Add-in, AddIn, M365, Microsoft 365, Addon, Install Teams, Set up Teams';

    layout
    {
        area(content)
        {
            // Top Banner
            group(TopBannerStandardGrp)
            {
                Editable = false;
                ShowCaption = false;
                Visible = TopBannerVisible;
                field(MediaResourcesTeams; MediaResourcesTeams."Media Reference")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ShowCaption = false;
                }
            }

            // SaaS
            group(SaasContent)
            {
                Caption = '';
                Visible = IsSaaS and not IsPhone;
                group("Para1.1")
                {
                    Caption = '';
                    InstructionalText = 'Make faster decisions by bringing Business Central data into team conversations. The app connects Microsoft Teams to your business data, so you can quickly share details with others, connect with your business contacts, and respond faster to inquiries.';
                }
                group("Para1.1.4")
                {
                    Caption = '';
                    field(LearnMore; LearnMoreLbl)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = '';
                        ShowCaption = false;
                        Editable = false;

                        trigger OnDrillDown()
                        begin
                            Hyperlink(LearnMoreFwdLinkTxt);
                        end;
                    }
                }
            }

            // Mobile variation
            group(MobileContent)
            {
                Caption = '';
                Visible = IsSaaS and IsPhone;
                group("Para2.1")
                {
                    Caption = '';
                    InstructionalText = 'Make faster decisions by bringing Business Central data into team conversations. The app connects Microsoft Teams to your business data, so you can quickly share details with others, connect with your business contacts, and respond faster to inquiries.';
                }
                group("Para2.2")
                {
                    Caption = 'You can’t install from here';
                    InstructionalText = 'You seem to be accessing this page from your mobile device. Teams can only install apps from the Teams desktop app or Teams for the web.';
                }
                group("Para2.3")
                {
                    Caption = '';
                    InstructionalText = 'You can go to your desktop device and either open this page or go directly to https://aka.ms/bcGetTeamsApp';
                }
                label(EmptySpace2)
                {
                    ApplicationArea = Basic, Suite;
                    ShowCaption = false;
                    Caption = '';
                }
                group("Para2.4")
                {
                    Caption = '';
                    field(LearnMoreMobile; LearnMoreLbl)
                    {
                        ApplicationArea = Basic, Suite;
                        ShowCaption = false;
                        Editable = false;

                        trigger OnDrillDown()
                        begin
                            Hyperlink(LearnMoreFwdLinkTxt);
                        end;
                    }
                }
            }

            // On-prem variation
            group(OnPremContent)
            {
                Caption = '';
                Visible = not IsSaaS;
                group("Para3.1")
                {
                    Caption = 'This won’t work';
                    InstructionalText = 'The Business Central app for Teams requires a Business Central online user account. If you’re not sure whether you have an account, contact your company administrator to help you get started.';
                }
                group("Para3.2")
                {
                    Caption = 'Here’s what you’re missing';
                    InstructionalText = 'Make faster decisions by bringing Business Central data into team conversations. The app connects Microsoft Teams to your business data, so you can quickly share details with others, connect with your business contacts, and respond faster to inquiries.';
                }
                group("Para3.3")
                {
                    Caption = '';
                    field(LearnMoreOnPrem; LearnMoreLbl)
                    {
                        ApplicationArea = Basic, Suite;
                        ShowCaption = false;
                        Editable = false;

                        trigger OnDrillDown()
                        begin
                            Hyperlink(LearnMoreFwdLinkTxt);
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
            action(ActionGetFromStore)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Get the app from store';
                Visible = GetFromStoreActionVisible;
                Image = NextRecord;
                InFooterBar = true;

                trigger OnAction()
                begin
                    Hyperlink(GetAppFwdLinkTxt);
                    CurrPage.Close();
                end;
            }
            action(ActionOkay)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Okay';
                Visible = OkayActionVisible;
                Image = NextRecord;
                InFooterBar = true;

                trigger OnAction()
                begin
                    CurrPage.Close();
                end;
            }
        }
    }

    trigger OnInit()
    var
        EnvironmentInformation: Codeunit "Environment Information";
    begin
        LoadTopBanners();
        IsSaaS := EnvironmentInformation.IsSaaS();
        IsPhone := ClientTypeManagement.GetCurrentClientType() = CLIENTTYPE::Phone;
    end;

    trigger OnOpenPage()
    begin
        SetButtonsVisibilty();
    end;

    local procedure SetButtonsVisibilty()
    begin
        if IsSaaS and not isPhone then begin
            GetFromStoreActionVisible := true;
            exit;
        end;
        OkayActionVisible := true;
    end;

    local procedure LoadTopBanners()
    begin
        if MediaRepositoryTeams.Get('TeamsAppIllustration.png', Format(ClientTypeManagement.GetCurrentClientType()))
        then
            if MediaResourcesTeams.Get(MediaRepositoryTeams."Media Resources Ref")
            then
                TopBannerVisible := MediaResourcesTeams."Media Reference".HasValue;
    end;

    var
        MediaRepositoryTeams: Record "Media Repository";
        MediaResourcesTeams: Record "Media Resources";
        ClientTypeManagement: Codeunit "Client Type Management";
        OkayActionVisible: Boolean;
        GetFromStoreActionVisible: Boolean;
        TopBannerVisible: Boolean;
        IsSaaS: Boolean;
        IsPhone: Boolean;
        LearnMoreFwdLinkTxt: Label 'https://go.microsoft.com/fwlink/?linkid=2143571', Locked = true;
        GetAppFwdLinkTxt: Label 'https://aka.ms/bcGetTeamsApp', Locked = true;
        LearnMoreLbl: Label 'Learn more';
}
