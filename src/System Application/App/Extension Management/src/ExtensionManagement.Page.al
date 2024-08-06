// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Apps;

using System.Environment;
using System.Environment.Configuration;
using System.Integration;

/// <summary>
/// Lists the available extensions, and provides features for managing them.
/// </summary>
page 2500 "Extension Management"
{
    Caption = 'Extension Management';
    AdditionalSearchTerms = 'app,add-in,customize,plug-in,appsource';
    ApplicationArea = All;
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    RefreshOnActivate = true;
    SourceTable = "Published Application";
    SourceTableView = sorting(Name)
                      order(ascending)
                      where(Name = filter(<> '_Exclude_*'),
                            "Package Type" = filter(= Extension | Designer),
                            "Tenant Visible" = const(true));
    UsageCategory = Administration;
    ContextSensitiveHelpPage = 'ui-extensions';
    Permissions = tabledata "Published Application" = r;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                Editable = false;
                field(Logo; Rec.Logo)
                {
                    Caption = 'Logo';
                    ToolTip = 'Specifies the logo of the extension, such as the logo of the service provider.';
                }
                field(Name; Rec.Name)
                {
                    ToolTip = 'Specifies the name of the extension.';
                }
                field(Publisher; Rec.Publisher)
                {
                    ToolTip = 'Specifies the publisher of the extension.';
                }
                field(Version; VersionDisplay)
                {
                    Caption = 'Version';
                    ToolTip = 'Specifies the version of the extension.';
                }
                field("Is Installed"; IsInstalled)
                {
                    Caption = 'Is Installed';
                    Style = Favorable;
                    StyleExpr = InfoStyle;
                    ToolTip = 'Specifies whether the extension is installed.';
                }
                field("Source"; AllowsDownloadSource)
                {
                    Caption = 'Source';
                    StyleExpr = AllowsDownloadSourceStyleExpr;
                    ToolTip = 'Specifies whether the extension allows the source to be downloaded.';
                    OptionCaption = ' ,Yes,No';
                }
                field("Published As"; Rec."Published As")
                {
                    Caption = 'Published As';
                    ToolTip = 'Specifies whether the extension is published as a per-tenant, development, or a global extension.';
                }

                label(Control18)
                {
                    Enabled = IsSaaS;
                    HideValue = true;
                    ShowCaption = false;
                    Caption = '';
                    Style = Favorable;
                    StyleExpr = true;
                    ToolTip = 'Specifies a spacer for ''Brick'' view mode.';
                    Visible = not IsOnPremDisplay;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            group(ActionGroup13)
            {
                Caption = 'Process';
                action(View)
                {
                    Caption = 'View';
                    Enabled = ActionsEnabled;
                    Image = View;
                    ShortcutKey = 'Return';
                    ToolTip = 'View extension details.';
                    RunObject = page "Extension Settings";
                    RunPageLink = "App ID" = field(ID);
                    Scope = Repeater;
                }
                action(Install)
                {
                    Caption = 'Install';
                    Enabled = ActionsEnabled and (not IsInstalled);
                    Image = NewRow;
                    Scope = Repeater;
                    ToolTip = 'Install the extension for the current tenant.';

                    trigger OnAction()
                    begin
                        if ExtensionInstallationImpl.RunExtensionInstallation(Rec) then
                            CurrPage.Update(false);
                    end;
                }
                action(Uninstall)
                {
                    Caption = 'Uninstall';
                    Enabled = ActionsEnabled and IsInstalled;
                    Image = RemoveLine;
                    Scope = Repeater;
                    ToolTip = 'Remove the extension from the current tenant.';

                    trigger OnAction()
                    begin
                        if ExtensionInstallationImpl.RunExtensionInstallation(Rec) then
                            CurrPage.Update(false);
                    end;
                }
                action(Unpublish)
                {
                    Caption = 'Unpublish';
                    Enabled = ActionsEnabled and IsTenantExtension and (not IsInstalled);
                    Image = RemoveLine;
                    Scope = Repeater;
                    ToolTip = 'Unpublish the extension from the tenant.';

                    trigger OnAction()
                    begin
                        if ExtensionInstallationImpl.IsInstalledByPackageId(Rec."Package ID") then begin
                            Message(CannotUnpublishIfInstalledMsg, Rec.Name);
                            exit;
                        end;

                        ExtensionOperationImpl.UnpublishUninstalledPerTenantExtension(Rec."Package ID");
                    end;
                }
                action(SetupApp)
                {
                    Caption = 'Set up';
                    Image = SetupList;
                    Enabled = ActionsEnabled and IsInstalled;
                    Scope = Repeater;
                    ToolTip = 'Runs the setup page that has been marked as primary for the selected app.';

                    trigger OnAction()
                    var
                        PublishedApplication: Record "Published Application";
                    begin
                        CurrPage.SetSelectionFilter(PublishedApplication);

                        if PublishedApplication.Count > 1 then
                            Error(MultiSelectNotSupportedErr);

                        ExtensionInstallationImpl.RunExtensionSetup(Rec.ID);
                    end;
                }
                action("Download Source")
                {
                    Caption = 'Download Source';
                    Enabled = IsTenantExtension;
                    Image = ExportFile;
                    Scope = Repeater;
                    ToolTip = 'Download the source code for the extension.';

                    trigger OnAction()
                    begin
                        ExtensionOperationImpl.DownloadExtensionSource(Rec."Package ID");
                    end;
                }
                action("Open Source in VS Code")
                {
                    Caption = 'Open Source in VS Code';
                    Enabled = IsSourceSpecificationAvailable;
                    Image = Download;
                    Scope = Repeater;
                    ToolTip = 'Open the source code for the extension based on the source control information.';

                    trigger OnAction()
                    begin
                        VsCodeIntegration.OpenExtensionSourceInVSCode(Rec);
                    end;
                }
                action("Learn More")
                {
                    Caption = 'Learn More';
                    Visible = HelpActionVisible;
                    Enabled = ActionsEnabled;
                    Image = Info;
                    Scope = Repeater;
                    ToolTip = 'View information from the extension provider.';

                    trigger OnAction()
                    begin
                        HyperLink(Rec.Help);
                    end;
                }
                action(Refresh)
                {
                    Caption = 'Refresh';
                    Image = Refresh;
                    ToolTip = 'Refresh the list of extensions.';

                    trigger OnAction()
                    begin
                        ActionsEnabled := false;
                        CurrPage.Update(false);
                    end;
                }
#if not CLEAN25
                action("Extension Marketplace")
                {
                    Caption = 'Extension Marketplace';
                    Enabled = IsSaaS;
                    Image = NewItem;
                    ToolTip = 'Browse the extension marketplace for new extensions to install.';
                    Visible = false;
                    ObsoleteState = Pending;
                    ObsoleteReason = 'This action will be obsoleted. Microsoft AppSource apps feature will replace the Extension Marketplace.';
                    ObsoleteTag = '25.0';

                    trigger OnAction()
                    begin
                        Hyperlink('https://aka.ms/bcappsource');
                    end;
                }
#endif
                action("Upload Extension")
                {
                    Caption = 'Upload Extension';
                    Image = Import;
                    RunObject = page "Upload And Deploy Extension";
                    ToolTip = 'Upload an extension to your application.';
                    Ellipsis = true;
                    Visible = IsSaaS;
                }
                action("Deployment Status")
                {
                    Caption = 'Installation Status';
                    Image = Status;
                    RunObject = page "Extension Deployment Status";
                    ToolTip = 'Check status for upload process for extensions.';
                    Visible = IsSaaS;
                }
                action("Delete Orphaned Extension Data")
                {

                    Caption = 'Delete Orphaned Extension Data';
                    Image = Delete;
                    RunObject = page "Delete Orphaned Extension Data";
                    ToolTip = 'Delete the data of orphaned extensions.';
                }
            }
        }
        area(Promoted)
        {
            group(Category_Category5)
            {
                Caption = 'Manage', Comment = 'Generated from the PromotedActionCategories property index 4.';
#if not CLEAN25
#pragma warning disable AL0432
                actionref("Extension Marketplace_Promoted"; "Extension Marketplace")
#pragma warning restore AL0432
                {
                    ObsoleteState = Pending;
                    ObsoleteReason = 'This action will be obsoleted. Microsoft AppSource apps feature will replace the Extension Marketplace.';
                    ObsoleteTag = '25.0';
                    Visible = false;
                }
#endif                
                actionref("Upload Extension_Promoted"; "Upload Extension") { }
                actionref("Deployment Status_Promoted"; "Deployment Status") { }
                actionref(View_Promoted; View) { }
                actionref(Install_Promoted; Install) { }
                actionref(Uninstall_Promoted; Uninstall) { }
                actionref(Unpublish_Promoted; Unpublish) { }
                actionref(SetupApp_Promoted; SetupApp) { }
                actionref("Download Source_Promoted"; "Download Source") { }
                actionref("Open Source in VS Code_Promoted"; "Open Source in VS Code") { }
                actionref("Learn More_Promoted"; "Learn More") { }
                actionref(Refresh_Promoted; Refresh) { }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        // Reenable page actions when record has been loaded/selected
        ActionsEnabled := true;

        DetermineExtensionConfigurations();

        VersionDisplay := ExtensionInstallationImpl.GetVersionDisplayString(Rec);
        SetInfoStyleForIsInstalled();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        HelpActionVisible := StrLen(Rec.Help) > 0;
    end;

    trigger OnOpenPage()
    begin
        DetermineEnvironmentConfigurations();
        SetExtensionManagementFilter();
        if not IsInstallAllowed then
            CurrPage.Caption(SaaSCaptionTxt);

        // Temporary disable the page actions until extension is loaded/selected (OnAfterGetRecord)
        ActionsEnabled := false;

        HelpActionVisible := false;
    end;

    var
        ExtensionInstallationImpl: Codeunit "Extension Installation Impl";
        ExtensionOperationImpl: Codeunit "Extension Operation Impl";
        VsCodeIntegration: Codeunit "VS Code Integration";
        AllowsDownloadSource: Option " ","Yes","No";
        VersionDisplay: Text;
        AllowsDownloadSourceStyleExpr: Text;
        ActionsEnabled: Boolean;
        IsSaaS: Boolean;
        SaaSCaptionTxt: Label 'Installed Extensions', Comment = 'The caption to display when on SaaS';
        IsTenantExtension: Boolean;
        CannotUnpublishIfInstalledMsg: Label 'The extension %1 cannot be unpublished because it is installed.', Comment = '%1 = name of extension';
        MultiSelectNotSupportedErr: Label 'Multi-select is not supported on this action';
        IsMarketplaceEnabled: Boolean;
        IsOnPremDisplay: Boolean;
        IsInstalled: Boolean;
        IsInstallAllowed: Boolean;
        InfoStyle: Boolean;
        HelpActionVisible: Boolean;
        IsSourceSpecificationAvailable: Boolean;

    protected procedure IsSaasEnvironment(): boolean
    begin
        exit(IsSaaS)
    end;

    protected procedure IsOnPremDisplayTarget(): boolean
    begin
        exit(IsOnPremDisplay)
    end;

    local procedure SetExtensionManagementFilter()
    begin
        // Set installed filter if we are not displaying like on-prem
        Rec.FilterGroup(2);
        if not IsInstallAllowed then
            Rec.SetRange("PerTenant Or Installed", true);
        Rec.FilterGroup(0);
    end;

    local procedure DetermineEnvironmentConfigurations()
    var
        EnvironmentInformation: Codeunit "Environment Information";
        ExtensionMarketplace: Codeunit "Extension Marketplace";
        ServerSetting: Codeunit "Server Setting";
        IsSaaSInstallAllowed: Boolean;
    begin
        IsSaaS := EnvironmentInformation.IsSaaS();
        IsSaaSInstallAllowed := ServerSetting.GetEnableSaaSExtensionInstallSetting();

        IsMarketplaceEnabled := ExtensionMarketplace.IsMarketplaceEnabled();

        // Composed configurations for the simplicity of representation
        IsOnPremDisplay := not IsMarketplaceEnabled or not IsSaaS;
        IsInstallAllowed := IsOnPremDisplay or IsSaaSInstallAllowed;
    end;

    local procedure DetermineExtensionConfigurations()
    begin
        // Determining Record and Styling Configurations
        IsInstalled := ExtensionInstallationImpl.IsInstalledByPackageId(Rec."Package ID");
        IsTenantExtension := Rec."Published As" <> Rec."Published As"::Global;

        AllowsDownloadSource := AllowsDownloadSource::" ";
        if IsTenantExtension then
            if ExtensionInstallationImpl.AllowsDownloadSource(Rec."Resource Exposure Policy") then begin
                AllowsDownloadSource := AllowsDownloadSource::Yes;
                AllowsDownloadSourceStyleExpr := Format(PageStyle::Favorable);
            end else begin
                AllowsDownloadSource := AllowsDownloadSource::No;
                AllowsDownloadSourceStyleExpr := Format(PageStyle::Unfavorable);
            end;

        IsSourceSpecificationAvailable := StrLen(Rec."Source Repository Url") > 0;
    end;

    local procedure SetInfoStyleForIsInstalled()
    begin
        InfoStyle := IsInstalled and IsInstallAllowed;
    end;
}