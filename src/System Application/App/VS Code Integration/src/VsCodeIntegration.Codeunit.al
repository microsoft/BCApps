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