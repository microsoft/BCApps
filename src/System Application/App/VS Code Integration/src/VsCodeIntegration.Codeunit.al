// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Integration;

using System.Apps;
using System.Reflection;
using System.Tooling;

/// <summary>
/// Provides functionality to embed hyperlinks that send requests to VS Code to navigate to an object's definition in source code
/// and to open the source code of an extension from Git.
/// </summary>
codeunit 8334 "VS Code Integration"
{
    Access = Public;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        AllObjWithCaption: Record AllObjWithCaption;
        VsCodeIntegrationImpl: Codeunit "VS Code Integration Impl.";

    /// <summary>
    /// Opens an URL that sends a request to VS Code to retrieve and open the source code of the provided extension from Git.
    /// </summary>
    /// <param name="PublishedApplication">The extension to open in VS Code.</param>
    [Scope('OnPrem')]
    procedure OpenExtensionSourceInVSCode(var PublishedApplication: Record "Published Application")
    begin
        VsCodeIntegrationImpl.OpenExtensionSourceInVSCode(PublishedApplication);
    end;

    /// <summary>
    /// Opens an URL that sends a request to VS Code to update the launch configurations to match the current environment to publish and debug.
    /// </summary>
    [Scope('OnPrem')]
    procedure UpdateConfigurationsInVSCode()
    begin
        VsCodeIntegrationImpl.UpdateConfigurationsInVSCode();
    end;

    /// <summary>
    /// Opens an URL that sends a request to VS Code to add and download the selected extensions as dependencies.
    /// </summary>
    /// <param name="PublishedApplication">The selected extensions.</param>
    [Scope('OnPrem')]
    procedure UpdateDependenciesInVSCode(var PublishedApplication: Record "Published Application")
    begin
        VsCodeIntegrationImpl.UpdateDependenciesInVSCode(PublishedApplication);
    end;

    /// <summary>
    /// Returns the selected extensions as a JSON array of dependencies.
    /// </summary>
    /// <param name="PublishedApplication">The selected extensions.</param>
    /// <returns>The JSON array.</returns>
    [Scope('OnPrem')]
    procedure GetDependenciesAsJson(var PublishedApplication: Record "Published Application"): Text
    begin
        exit(VsCodeIntegrationImpl.GetDependenciesAsSerializedJsonArray(PublishedApplication));
    end;

    /// <summary>
    /// Opens an URL that sends a request to VS Code to navigate to the source definition of the given page and to download the dependent symbols.
    /// </summary>
    /// <param name="PageInfoAndFields">The page to navigate to.</param>
    /// <param name="NavAppInstalledApp">The dependency extensions for the page.</param>
    [Scope('OnPrem')]
    procedure NavigateToPageDefinitionInVSCode(var PageInfoAndFields: Record "Page Info And Fields"; var NavAppInstalledApp: Record "NAV App Installed App")
    begin
        VsCodeIntegrationImpl.NavigateToObjectDefinitionInVSCode(AllObjWithCaption."Object Type"::Page, PageInfoAndFields."Page ID", PageInfoAndFields."Page Name", '', NavAppInstalledApp);
    end;

    /// <summary>
    /// Opens an URL that sends a request to VS Code to navigate to the source definition of the given table field and to download the dependent symbols.
    /// </summary>
    /// <param name="PageInfoAndFields">The table field to navigate to.</param>
    /// <param name="NavAppInstalledApp">The dependency extensions for the table.</param>
    [Scope('OnPrem')]
    procedure NavigateFieldDefinitionInVSCode(var PageInfoAndFields: Record "Page Info And Fields"; var NavAppInstalledApp: Record "NAV App Installed App")
    begin
        VsCodeIntegrationImpl.NavigateToObjectDefinitionInVSCode(AllObjWithCaption."Object Type"::Table, PageInfoAndFields."Source Table No.", PageInfoAndFields."Source Table Name", PageInfoAndFields."Field Name", NavAppInstalledApp);
    end;
}