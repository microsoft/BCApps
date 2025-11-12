namespace System.Tooling;

using System.Apps;
using System.Reflection;
using System.Integration;

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
            FilterForExtAffectingPage(PageInfoAndFields."Page ID", PageInfoAndFields."Source Table No.", PageInfoAndFields."Current Form ID", NavAppInstalledApp);
        VSCodeIntegration.NavigateToPageDefinitionInVSCode(PageInfoAndFields, NavAppInstalledApp);
    end;

    [Scope('OnPrem')]
    procedure NavigateFieldDefinitionInVSCode(var PageInfoAndFields: Record "Page Info And Fields"; UpdateDependencies: Boolean): Text
    begin
        if UpdateDependencies then
            FilterForExtAffectingPage(PageInfoAndFields."Page ID", PageInfoAndFields."Source Table No.", PageInfoAndFields."Current Form ID", NavAppInstalledApp);
        VSCodeIntegration.NavigateFieldDefinitionInVSCode(PageInfoAndFields, NavAppInstalledApp);
    end;

    [Scope('OnPrem')]
    procedure OpenExtensionSourceInVSCode(var PublishedApplication: Record "Published Application"): Text
    begin
        VSCodeIntegration.OpenExtensionSourceInVSCode(PublishedApplication);
    end;

    [Scope('OnPrem')]
    procedure FindPublishedApplication(var NAVAppInstalledApp: Record "NAV App Installed App"; var PublishedApplication: Record "Published Application"): Boolean
    begin
        if PublishedApplication.ReadPermission() then begin
            PublishedApplication.Reset();
            PublishedApplication.SetRange("Package ID", NAVAppInstalledApp."Package ID");
            exit(PublishedApplication.FindFirst());
        end;

        exit(false);
    end;

    [Scope('OnPrem')]
    procedure FilterForExtAffectingPage(PageId: Integer; TableId: Integer; FormId: Guid; var NAVAppInstalledApp: Record "NAV App Installed App")
    var
        ExtensionExecutionInfo: Record "Extension Execution Info";
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

            // Add filters for arbitrary code which has executed on the form
            if ExtensionExecutionInfo.ReadPermission() then begin
                ExtensionExecutionInfo.SetRange("Form ID", FormId);
                if ExtensionExecutionInfo.Find('-') then
                    repeat
                        AllObjWithCaption.Reset();
                        AllObjWithCaption.SetRange("App Runtime Package ID", ExtensionExecutionInfo."Runtime Package ID");
                        if AllObjWithCaption.FindFirst() then
                            FilterConditions := FilterConditions + StrSubstNo(OrFilterFmtLbl, AllObjWithCaption."App Package ID");
                    until ExtensionExecutionInfo.Next() = 0;
            end;
        end;

        NAVAppInstalledApp.Reset();
        if FilterConditions <> '' then begin
            FilterConditions := DelChr(FilterConditions, '>', '|');
            NAVAppInstalledApp.SetFilter(NAVAppInstalledApp."Package ID", FilterConditions);
        end else begin
            TempGuid := CreateGuid();
            Clear(TempGuid);
            NAVAppInstalledApp.SetFilter(NAVAppInstalledApp."Package ID", '%1', TempGuid);
        end;
    end;
}