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
    PageType = Card;
    SourceTable = "NAV App Setting";
    ContextSensitiveHelpPage = 'ui-extensions';
    Permissions = tabledata "Nav App Setting" = rm,
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
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        PublishedApplication: Record "Published Application";
    begin
        PublishedApplication.SetRange(ID, Rec."App ID");
        PublishedApplication.SetRange("Tenant Visible", true);

        if PublishedApplication.FindFirst() then begin
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
        ExtensionInstallationImpl: Codeunit "Extension Installation Impl";
        AppNameValue: Text;
        AppPublisherValue: Text;
        AppIdValue: Text;
        AppVersionDisplay: Text;
        PublishedAs: Text;
        AppIsInstalled: Boolean;
        IsTenantExtension: Boolean;
        AppAllowsDebuggging: Boolean;
        AppAllowsDownloadSource: Boolean;
        AppAllowsDownloadSourceInSymbols: Boolean;
        CanManageExtensions: Boolean;
}