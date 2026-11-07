namespace System.Tooling;

using System.Apps;
using System.Integration;
using System.Reflection;

codeunit 5378 "Page Inspection VS Code Helper"
{
    Access = Internal;

    var
        NavAppInstalledApp: Record "NAV App Installed App";
        VSCodeIntegration: Codeunit "VS Code Integration";

    [Scope('OnPrem')]
    procedure NavigateToPageDefinitionInVSCode(var PageInfoAndFields: Record "Page Info And Fields"; UpdateDependencies: Boolean)
    begin
        // There's a performance overhead when computing dependencies, only do when necessary, 
        if UpdateDependencies then
            FilterForExtAffectingPage(PageInfoAndFields."Page ID", PageInfoAndFields."Source Table No.", NavAppInstalledApp);
        VSCodeIntegration.NavigateToPageDefinitionInVSCode(PageInfoAndFields, NavAppInstalledApp);
    end;

    [Scope('OnPrem')]
    procedure NavigateFieldDefinitionInVSCode(var PageInfoAndFields: Record "Page Info And Fields"; UpdateDependencies: Boolean): Text
    begin
        if UpdateDependencies then
            FilterForExtAffectingPage(PageInfoAndFields."Page ID", PageInfoAndFields."Source Table No.", NavAppInstalledApp);
        VSCodeIntegration.NavigateFieldDefinitionInVSCode(PageInfoAndFields, NavAppInstalledApp);
    end;

    [Scope('OnPrem')]
    procedure OpenExtensionSourceInVSCode(var PublishedApplication: Record "Published Application"): Text
    begin
        VSCodeIntegration.OpenExtensionSourceInVSCode(PublishedApplication);
    end;

    [Scope('OnPrem')]
    procedure FindPublishedApplication(var InstalledApp: Record "NAV App Installed App"; var PublishedApplication: Record "Published Application"): Boolean
    begin
        if PublishedApplication.ReadPermission() then begin
            PublishedApplication.Reset();
            PublishedApplication.SetRange("Package ID", InstalledApp."Package ID");
            exit(PublishedApplication.FindFirst());
        end;

        exit(false);
    end;

    [Scope('OnPrem')]
    procedure FilterForExtAffectingPage(PageId: Integer; TableId: Integer; var InstalledApp: Record "NAV App Installed App")
    var
        AllObjWithCaption: Record AllObjWithCaption;
        TempGuid: Guid;
        OrFilterFmtLbl: Label '%1|', Locked = true;
        FilterConditions: Text;
    begin
        if AllObjWithCaption.ReadPermission() then begin
            // check if this page was added by extension
            AllObjWithCaption.Reset();
            AllObjWithCaption.SetRange("Object Type", AllObjWithCaption."Object Type"::Page);
            AllObjWithCaption.SetRange("Object ID", PageId);
            if AllObjWithCaption.Find('-') then
                repeat
                    FilterConditions := FilterConditions + StrSubstNo(OrFilterFmtLbl, AllObjWithCaption."App Package ID");
                until AllObjWithCaption.Next() = 0;

            // check if page was extended
            AllObjWithCaption.Reset();
            AllObjWithCaption.SetRange("Object Type", AllObjWithCaption."Object Type"::PageExtension);
            AllObjWithCaption.SetRange("Object Subtype", Format(PageId));
            if AllObjWithCaption.Find('-') then
                repeat
                    FilterConditions := FilterConditions + StrSubstNo(OrFilterFmtLbl, AllObjWithCaption."App Package ID");
                until AllObjWithCaption.Next() = 0;

            // check if source table was added by extension
            AllObjWithCaption.Reset();
            AllObjWithCaption.SetRange("Object Type", AllObjWithCaption."Object Type"::Table);
            AllObjWithCaption.SetRange("Object ID", TableId);
            if AllObjWithCaption.Find('-') then
                repeat
                    FilterConditions := FilterConditions + StrSubstNo(OrFilterFmtLbl, AllObjWithCaption."App Package ID");
                until AllObjWithCaption.Next() = 0;

            // check if source table was extended by extension
            AllObjWithCaption.Reset();
            AllObjWithCaption.SetRange("Object Type", AllObjWithCaption."Object Type"::TableExtension);
            AllObjWithCaption.SetRange("Object Subtype", Format(TableId));
            if AllObjWithCaption.Find('-') then
                repeat
                    FilterConditions := FilterConditions + StrSubstNo(OrFilterFmtLbl, AllObjWithCaption."App Package ID");
                until AllObjWithCaption.Next() = 0;

        end;

        InstalledApp.Reset();
        if FilterConditions <> '' then begin
            FilterConditions := DelChr(FilterConditions, '>', '|');
            InstalledApp.SetFilter(InstalledApp."Package ID", FilterConditions);
        end else begin
            TempGuid := CreateGuid();
            Clear(TempGuid);
            InstalledApp.SetFilter(InstalledApp."Package ID", '%1', TempGuid);
        end;
    end;
}