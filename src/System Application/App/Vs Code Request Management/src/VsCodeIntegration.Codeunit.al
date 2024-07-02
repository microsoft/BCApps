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
    procedure OpenExtensionSource(PublishedApplication: Record "Published Application")
    begin
        Hyperlink(VsCodeIntegrationImpl.GetUrlToOpenExtensionSource(PublishedApplication));
    end;

    [Scope('OnPrem')]
    procedure NavigatePageInVSCode(PageInfoAndFields: Record "Page Info And Fields"; NavAppInstalledApp: Record "NAV App Installed App")
    begin
        Hyperlink(VsCodeIntegrationImpl.GetUrlToNavigateInVSCode(AllObjWithCaption."Object Type"::Page, PageInfoAndFields."Page ID", PageInfoAndFields."Page Name", '', NavAppInstalledApp));
    end;

    [Scope('OnPrem')]
    procedure NavigateFieldInVSCode(PageInfoAndFields: Record "Page Info And Fields"; NavAppInstalledApp: Record "NAV App Installed App")
    begin
        Hyperlink(VsCodeIntegrationImpl.GetUrlToNavigateInVSCode(AllObjWithCaption."Object Type"::Table, PageInfoAndFields."Source Table No.", PageInfoAndFields."Source Table Name", PageInfoAndFields."Field Name", NavAppInstalledApp));
    end;
}