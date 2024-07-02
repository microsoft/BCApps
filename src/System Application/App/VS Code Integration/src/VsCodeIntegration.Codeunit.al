namespace System.Integration;

using System.Apps;
using System.Reflection;
using System.Tooling;

codeunit 8034 "VS Code Integration"
{
    Access = Public;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        AllObjWithCaption: Record AllObjWithCaption;
        VsCodeIntegrationImpl: Codeunit "VS Code Integration Impl.";

    [Scope('OnPrem')]
    procedure OpenExtensionSource(var PublishedApplication: Record "Published Application")
    begin
        Hyperlink(VsCodeIntegrationImpl.GetUrlToOpenExtensionSource(PublishedApplication));
    end;

    [Scope('OnPrem')]
    procedure NavigateToPageDefinitionInVSCode(var PageInfoAndFields: Record "Page Info And Fields"; var NavAppInstalledApp: Record "NAV App Installed App")
    begin
        Hyperlink(VsCodeIntegrationImpl.GetUrlToNavigateInVSCode(AllObjWithCaption."Object Type"::Page, PageInfoAndFields."Page ID", PageInfoAndFields."Page Name", '', NavAppInstalledApp));
    end;

    [Scope('OnPrem')]
    procedure NavigateFieldDefinitionInVSCode(var PageInfoAndFields: Record "Page Info And Fields"; var NavAppInstalledApp: Record "NAV App Installed App")
    begin
        Hyperlink(VsCodeIntegrationImpl.GetUrlToNavigateInVSCode(AllObjWithCaption."Object Type"::Table, PageInfoAndFields."Source Table No.", PageInfoAndFields."Source Table Name", PageInfoAndFields."Field Name", NavAppInstalledApp));
    end;
}