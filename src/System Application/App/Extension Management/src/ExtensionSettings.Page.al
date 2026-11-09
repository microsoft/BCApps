// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Apps;

using System.Environment.Configuration;

/// <summary>
/// Displays settings for the selected extension, and allows users to edit them.
/// </summary>
page 2511 "Extension Settings"
{
    ApplicationArea = All;
    Extensible = false;
    DataCaptionExpression = AppNameValue;
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Card;
    RefreshOnActivate = true;
    SourceTable = "NAV App Setting";
    ContextSensitiveHelpPage = 'ui-extensions';
    Permissions = tabledata "Nav App Setting" = rim,
                  tabledata "Published Application" = r;

    layout
    {
        area(Content)
        {
            group(Group)
            {
                Caption = 'General';

                field(AppId; AppIdValue)
                {
                    Caption = 'App ID';
                    Editable = false;
                    ToolTip = 'Specifies the App ID of the extension.';
                }
                field(AppName; AppNameValue)
                {
                    Caption = 'Name';
                    Editable = false;
                    ToolTip = 'Specifies the name of the extension.';
                }
                field(AppVersion; AppVersionDisplay)
                {
                    Caption = 'Version';
                    Editable = false;
                    ToolTip = 'Specifies the version of the extension.';
                }
                field(AppPublisher; AppPublisherValue)
                {
                    Caption = 'Publisher';
                    Editable = false;
                    ToolTip = 'Specifies the publisher of the extension.';
                }
                field("Published As"; PublishedAs)
                {
                    Caption = 'Published As';
                    Editable = false;
                    ToolTip = 'Specifies whether the extension is published as a per-tenant, development, or a global extension.';
                }
                field(AppIsInstalled; AppIsInstalled)
                {
                    Caption = 'Is Installed';
                    Editable = false;
                    ToolTip = 'Specifies whether the extension is installed.';
                }
                field(AllowHttpClientRequests; Rec."Allow HttpClient Requests")
                {
                    Caption = 'Allow HttpClient Requests';
                    Editable = CanManageExtensions;
                    ToolTip = 'Specifies whether the runtime should allow this extension to make HTTP requests through the HttpClient data type when running in a non-production environment.';
                }
            }

            group("Resource protection policies")
            {
                Caption = 'Resource Protection Policies defined by the extension';
                Visible = IsTenantExtension;

                field(AppAllowsDebuggging; AppAllowsDebuggging)
                {
                    Caption = 'Allow Debugging';
                    Editable = false;
                    ToolTip = 'Specifies whether the publisher permits the runtime to debug this extension .';
                }
                field(AppAllowsDownloadSource; AppAllowsDownloadSource)
                {
                    Caption = 'Allow Download Source';
                    Editable = false;
                    ToolTip = 'Specifies if the publisher allows the source code and any media files to be downloaded.';
                }
                field(AppAllowsDownloadSourceInSymbols; AppAllowsDownloadSourceInSymbols)
                {
                    Caption = 'Source In Symbols Download';
                    Editable = false;
                    ToolTip = 'Specifies if the publisher allows a symbol package download will contain the source code and all other resources that were part of the extension package.';
                }
            }

            group("Source control details")
            {
                Caption = 'Source control details';
                Visible = IsSourceInformationAvailable;

                field(RepositoryUrl; RepositoryUrl)
                {
                    Caption = 'Repository URL';
                    Editable = false;
                    ToolTip = 'Specifies the URL of the repository where the source code of the project can be found.';
                    ExtendedDatatype = URL;
                }
                field(CommitId; CommitId)
                {
                    Caption = 'Commit ID';
                    Editable = false;
                    ToolTip = 'Specifies the commit ID of the source code for the current version of the project.';
                }
            }

            group("Build app metadata")
            {
                Caption = 'Build app metadata';
                Visible = IsBuildInformationAvailable;

                field(BuildBy; BuildBy)
                {
                    Caption = 'Build by';
                    Editable = false;
                    ToolTip = 'Specifies the name of the system that orchestrated the build.';
                }
                field(BuildUrl; BuildUrl)
                {
                    Caption = 'Build URL';
                    Editable = false;
                    ToolTip = 'Specifies the URL to the build system invocation where the build can be found.';
                    ExtendedDatatype = URL;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Install)
            {
                Caption = 'Install';
                Enabled = ActionsEnabled and CanManageExtensions and (not AppIsInstalled);
                Image = NewRow;
                ToolTip = 'Install the extension for the current tenant.';

                trigger OnAction()
                begin
                    ExtensionInstallationImpl.CheckPermissions();
                    if ExtensionInstallationImpl.RunExtensionInstallation(PublishedApplication) then
                        CurrPage.Update(false);
                end;
            }
            action(Uninstall)
            {
                Caption = 'Uninstall';
                Enabled = ActionsEnabled and CanManageExtensions and AppIsInstalled;
                Image = RemoveLine;
                ToolTip = 'Remove the extension from the current tenant.';

                trigger OnAction()
                begin
                    ExtensionInstallationImpl.CheckPermissions();
                    if ExtensionInstallationImpl.RunExtensionInstallation(PublishedApplication) then
                        CurrPage.Update(false);
                end;
            }
            action(Unpublish)
            {
                Caption = 'Unpublish';
                Enabled = ActionsEnabled and CanManageExtensions and IsTenantExtension and (not AppIsInstalled);
                Image = RemoveLine;
                ToolTip = 'Unpublish the extension from the tenant.';

                trigger OnAction()
                begin
                    ExtensionInstallationImpl.CheckPermissions();
                    if ExtensionInstallationImpl.IsInstalledByPackageId(PublishedApplication."Package ID") then begin
                        Message(CannotUnpublishIfInstalledMsg, PublishedApplication.Name);
                        exit;
                    end;

                    ExtensionOperationImpl.UnpublishUninstalledPerTenantExtension(PublishedApplication."Package ID");
                    CurrPage.Close();
                end;
            }
            action(SetupApp)
            {
                Caption = 'Set up';
                Enabled = ActionsEnabled and CanManageExtensions and AppIsInstalled;
                Image = SetupList;
                ToolTip = 'Runs the setup page that has been marked as primary for the selected app.';

                trigger OnAction()
                begin
                    ExtensionInstallationImpl.CheckPermissions();
                    ExtensionInstallationImpl.RunExtensionSetup(PublishedApplication.ID);
                end;
            }
            action("Download Source")
            {
                Caption = 'Download source';
                Enabled = ActionsEnabled and CanManageExtensions and IsTenantExtension;
                Image = ExportFile;
                ToolTip = 'Download the source code for the extension.';

                trigger OnAction()
                begin
                    ExtensionInstallationImpl.CheckPermissions();
                    ExtensionOperationImpl.DownloadExtensionSource(PublishedApplication."Package ID");
                end;
            }
            action("Learn More")
            {
                Caption = 'Learn more';
                Enabled = ActionsEnabled;
                Visible = HelpActionVisible;
                Image = Info;
                ToolTip = 'View information from the extension provider.';

                trigger OnAction()
                begin
                    HyperLink(PublishedApplication.Help);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Home)
            {
                Caption = 'Home';
                actionref(Install_Promoted; Install) { }
                actionref(Uninstall_Promoted; Uninstall) { }
                actionref(Unpublish_Promoted; Unpublish) { }
                actionref(SetupApp_Promoted; SetupApp) { }
                actionref("Download Source_Promoted"; "Download Source") { }
                actionref("Learn More_Promoted"; "Learn More") { }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        NavAppInstalledApp: Record "NAV App Installed App";
    begin
        ActionsEnabled := false;
        AppIsInstalled := false;
        IsTenantExtension := false;
        HelpActionVisible := false;
        PublishedApplication.Reset();
        PublishedApplication.SetRange(ID, Rec."App ID");
        PublishedApplication.SetRange("Tenant Visible", true);

        // If the app is installed on the tenant, filter by this app package. Otherwise, retrieve the first occurrence of the app.
        if NavAppInstalledApp.Get(Rec."App ID") then
            PublishedApplication.SetRange("Package ID", NavAppInstalledApp."Package ID");

        if PublishedApplication.FindFirst() then begin
            ActionsEnabled := true;
            HelpActionVisible := PublishedApplication.Help <> '';
            AppNameValue := PublishedApplication.Name;
            AppPublisherValue := PublishedApplication.Publisher;
            AppIdValue := LowerCase(DelChr(Format(PublishedApplication.ID), '=', '{}'));
            AppVersionDisplay := ExtensionInstallationImpl.GetVersionDisplayString(PublishedApplication);
            AppIsInstalled := ExtensionInstallationImpl.IsInstalledByPackageId(PublishedApplication."Package ID");
            PublishedAs := Format(PublishedApplication."Published As");
            IsTenantExtension := PublishedApplication."Published As" <> PublishedApplication."Published As"::Global;
            AppAllowsDebuggging := IsTenantExtension and ExtensionInstallationImpl.AllowsDebug(PublishedApplication."Resource Exposure Policy");
            AppAllowsDownloadSource := IsTenantExtension and ExtensionInstallationImpl.AllowsDownloadSource(PublishedApplication."Resource Exposure Policy");
            AppAllowsDownloadSourceInSymbols := IsTenantExtension and ExtensionInstallationImpl.AllowsDownloadSourceInSymbols(PublishedApplication."Resource Exposure Policy");
            RepositoryUrl := PublishedApplication."Source Repository Url";
            CommitId := PublishedApplication."Source Commit ID";
            IsSourceInformationAvailable := RepositoryUrl <> '';
            BuildBy := PublishedApplication."Build By";
            BuildUrl := PublishedApplication."Build Url";
            IsBuildInformationAvailable := BuildBy + BuildUrl <> '';
        end;
    end;

    trigger OnOpenPage()
    begin
        if Rec.GetFilter("App ID") = '' then
            exit;

        Rec."App ID" := Rec.GetRangeMin("App ID");
        if not Rec.FindFirst() then begin
            Rec.Init();
            Rec.Insert();
        end;

        CanManageExtensions := ExtensionInstallationImpl.CanManageExtensions();
    end;

    var
        PublishedApplication: Record "Published Application";
        ExtensionInstallationImpl: Codeunit "Extension Installation Impl";
        ExtensionOperationImpl: Codeunit "Extension Operation Impl";
        CannotUnpublishIfInstalledMsg: Label 'The extension %1 cannot be unpublished because it is installed.', Comment = '%1 = name of extension';
        ActionsEnabled: Boolean;
        HelpActionVisible: Boolean;
        AppNameValue: Text;
        AppPublisherValue: Text;
        AppIdValue: Text;
        AppVersionDisplay: Text;
        PublishedAs: Text;
        RepositoryUrl: Text;
        CommitId: Text;
        BuildBy: Text;
        BuildUrl: Text;
        AppIsInstalled: Boolean;
        IsTenantExtension: Boolean;
        AppAllowsDebuggging: Boolean;
        AppAllowsDownloadSource: Boolean;
        AppAllowsDownloadSourceInSymbols: Boolean;
        CanManageExtensions: Boolean;
        IsSourceInformationAvailable: Boolean;
        IsBuildInformationAvailable: Boolean;
}
