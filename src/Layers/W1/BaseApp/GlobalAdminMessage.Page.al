// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Environment;

using System.Azure.Identity;
using System.Utilities;

/// <summary>
/// The page displays a warning message to users with the Global Administrator or Dynamics 365 Administrator role but without a Business Central license.
/// </summary>
/// <remarks>This page is not supposed to be referenced in extensions.</remarks>

page 1459 "Global Admin Message"
{
    PageType = NavigatePage;
    Extensible = false;
    Caption = ' '; // Do not show the caption

    layout
    {
        area(Content)
        {
            group(IconGroup)
            {
                Enabled = false;
                ShowCaption = false;
                Visible = IconVisible;

                field(Icon; MediaResources."Media Reference")
                {
                    ApplicationArea = All;
                    Enabled = false;
                    ShowCaption = false;
                    ToolTip = ' '; // Do not show tooltip
                }
            }

            label(Title)
            {
                ApplicationArea = All;
                CaptionClass = TitleTxt;
                Style = Strong;
            }

            label(FirstLine)
            {
                ApplicationArea = All;
                Caption = 'Without a license for Business Central you can only manage user information and export data.';
            }

            label(SecondLine)
            {
                ApplicationArea = All;
                Caption = 'This role does not provide access to business capabilities, such as creating documents or installing extensions. To use other Business Central capabilities, you must be assigned to a license that will give you the permissions you need.';
            }

            field(LearnMore; LearnMoreTxt)
            {
                ApplicationArea = All;
                Caption = ' '; // Added because of CodeCop
                Editable = false;
                ShowCaption = false;
                ToolTip = 'Go to the official documentation to learn more.';

                trigger OnDrillDown()
                begin
                    HyperLink('https://go.microsoft.com/fwlink/?linkid=2121503');

                    Session.LogMessage('0000C0V', 'User opened internal admin documentation.', Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', InternalAdminNotificationCategoryTok);
                end;
            }

            label(ThirdLine)
            {
                ApplicationArea = All;
                Caption = 'If you''ve purchased a license and assigned it to a user you should update the user''s information in Business Central.';
            }

            field(LinkToUpdateUsersWizard; LinkToUpdateUsersWizardTxt)
            {
                ApplicationArea = All;
                Editable = false;
                ShowCaption = false;
                Caption = ' ';
                ToolTip = 'Update all user names, authentication email addresses, contact email addresses, plans, and so on, from Microsoft 365.';

                trigger OnDrillDown()
                begin
                    Page.Run(Page::"Azure AD User Update Wizard");
                end;
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(Ok)
            {
                ApplicationArea = All;
                Caption = 'Got it!';
                Image = Info;
                InFooterBar = true;
                ToolTip = 'Close the page.';

                trigger OnAction()
                begin
                    CurrPage.Close();
                end;
            }

        }
    }

    trigger OnInit()
    begin
        // Load icon
        if MediaRepository.GetForCurrentClientType('AssistedSetupInfo-NoText.png') then
            if MediaResources.Get(MediaRepository."Media Resources Ref") then
                IconVisible := true;
    end;

    internal procedure SetIsGlobalAdmin(IsUserGlobalAdmin: Boolean)
    begin
        if IsUserGlobalAdmin then
            TitleTxt := StrSubstNo(TitleLbl, GlobalAdminLbl)
        else
            TitleTxt := StrSubstNo(TitleLbl, D365AdminLbl)
    end;

    var
        MediaRepository: Record "Media Repository";
        MediaResources: Record "Media Resources";
        LearnMoreTxt: Label 'Learn more';
        LinkToUpdateUsersWizardTxt: Label 'Update user information from Microsoft 365';
        InternalAdminNotificationCategoryTok: Label 'Internal Admin Notification', Locked = true;
        TitleLbl: Label '3,You have signed in as %1 but you are not assigned to a product license.', Comment = '%1 - The assigned role, either the GlobalAdminLbl or D365AdminLbl';
        GlobalAdminLbl: Label 'Global Administrator', Comment = 'Refers to the Global Administrator role of Microsoft Entra ID';
        D365AdminLbl: Label 'Dynamics 365 Administrator', Comment = 'Refers to the Dynamics 365 Administrator role of Microsoft Entra ID';
        TitleTxt: Text;
        IconVisible: Boolean;
}
