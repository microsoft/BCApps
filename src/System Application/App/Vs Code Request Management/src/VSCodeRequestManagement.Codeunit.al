namespace System.Integration;

using System.Apps;
using System.Reflection;
using System.Utilities;

codeunit 8033 "VS Code Request Management"
{
    Access = Public;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        AllObjWithCaption: Record AllObjWithCaption;
        UriBuilder: Codeunit "Uri Builder";
        VSCodeRequestHelper: DotNet VSCodeRequestHelper;
        AlExtensionUriTxt: Label 'vscode://ms-dynamics-smb.al', Locked = true;
        BaseApplicationIdTxt: Label '437dbf0e-84ff-417a-965d-ed2bb9650972', Locked = true;
        SystemApplicationIdTxt: Label '63ca2fa4-4f03-4f2b-a480-172fef340d3f', Locked = true;
        ApplicationIdTxt: Label 'c1335042-3002-4257-bf8a-75c898ccb1b8', Locked = true;

    [Scope('OnPrem')]
    procedure GetUrlToOpenExtensionSource(RepositoryUrl: Text[250]; CommitId: Text): Text
    var
        Url: Text;
    begin
        if Text.StrLen(RepositoryUrl) <> 0 then begin
            UriBuilder.Init(AlExtensionUriTxt + '/sourceSync');
            UriBuilder.AddQueryParameter('repoUrl', RepositoryUrl);
            if Text.StrLen(CommitId) <> 0 then
                UriBuilder.AddQueryParameter('commitId', CommitId);

            Url := GetAbsoluteUri();
            if DoesExceedCharLimit(Url) then
                // If the URL length exceeds 2000 characters then it will crash the page, so we truncate it.
                exit(AlExtensionUriTxt + '/truncated');
        end;

        exit(Url);
    end;

    [Scope('OnPrem')]
    procedure GetUrlToNavigateInVSCode(ObjectType: Option; ObjectId: Integer; ObjectName: Text; ControlName: Text; Dependencies: Text): Text
    var
        Url: Text;
    begin
        UriBuilder.Init(AlExtensionUriTxt + '/navigateTo');

        UriBuilder.AddQueryParameter('type', FormatObjectType(ObjectType));
        UriBuilder.AddQueryParameter('id', Format(ObjectId));
        UriBuilder.AddQueryParameter('name', ObjectName);
        if Text.StrLen(ControlName) <> 0 then
            UriBuilder.AddQueryParameter('fieldName', Format(ControlName));
        UriBuilder.AddQueryParameter('appid', GetAppIdForObject(ObjectType, ObjectId));
        UriBuilder.SetQuery(UriBuilder.GetQuery() + '&' + VSCodeRequestHelper.GetLaunchInformationQueryPart());
        UriBuilder.AddQueryParameter('sessionId', Format(SessionId()));

        // If the URL length exceeds 2000 characters when adding the dependencies, then it will crash the page, so we truncate the dependency list.
        if DoesExceedCharLimit(GetAbsoluteUri() + Dependencies) then
            Dependencies := 'truncated';
        UriBuilder.AddQueryParameter('dependencies', Dependencies);

        Url := GetAbsoluteUri();
        if DoesExceedCharLimit(Url) then
            // If the URL length exceeds 2000 characters then it will crash the page, so we truncate the whole URL.
            exit(AlExtensionUriTxt + '/truncated');

        exit(Url);
    end;

    [Scope('OnPrem')]
    procedure GetFormattedDependencies(var NavAppInstalledApp: Record "NAV App Installed App"): Text
    var
        DependencyList: TextBuilder;
    begin
        if NavAppInstalledApp.FindSet() then
            repeat
                DependencyList.Append(FormatDependency(NavAppInstalledApp));
            until NavAppInstalledApp.Next() = 0;

        exit(DependencyList.ToText());
    end;

    [Scope('OnPrem')]
    local procedure FormatDependency(NavAppInstalledApp: Record "NAV App Installed App"): Text
    var
        AppVersion: Text;
        AppVersionLbl: Label '%1.%2.%3.%4', Comment = '%1 = major, %2 = minor, %3 = build, %4 = revision', Locked = true;
        DependencyFormatLbl: Label '%1,%2,%3,%4;', Comment = '%1 = Id, %2 = Name, %3 = Publisher, %4 = Version', Locked = true;
    begin
        // Skip System and Base app
        case NavAppInstalledApp."App ID" of
            SystemApplicationIdTxt, BaseApplicationIdTxt, ApplicationIdTxt:
                exit('')
            else
                AppVersion := StrSubstNo(AppVersionLbl, NavAppInstalledApp."Version Major", NavAppInstalledApp."Version Minor", NavAppInstalledApp."Version Build", NavAppInstalledApp."Version Revision");
                exit(StrSubstNo(DependencyFormatLbl, Format(NavAppInstalledApp."App ID", 0, 4), NavAppInstalledApp.Name, NavAppInstalledApp.Publisher, AppVersion));
        end;
    end;

    [Scope('OnPrem')]
    local procedure FormatObjectType(ObjectType: Option): Text
    begin
        case ObjectType of
            AllObjWithCaption."Object Type"::Page:
                exit('page');
            AllObjWithCaption."Object Type"::Table:
                exit('table');
            else
                Error('ObjectType not supported');
        end;
    end;

    [Scope('OnPrem')]
    local procedure GetAppIdForObject(ObjectType: Option; ObjectId: Integer): Text
    var
        NavAppInstalledApp: Record "NAV App Installed App";
    begin
        if AllObjWithCaption.ReadPermission() then begin
            AllObjWithCaption.Reset();
            AllObjWithCaption.SetRange("Object Type", ObjectType);
            AllObjWithCaption.SetRange("Object ID", ObjectId);

            if AllObjWithCaption.FindFirst() then begin
                NavAppInstalledApp.Reset();
                NavAppInstalledApp.SetRange("Package ID", AllObjWithCaption."App Runtime Package ID");
                if NavAppInstalledApp.FindFirst() then
                    exit(NavAppInstalledApp."App ID");
            end;
        end;
    end;

    [Scope('OnPrem')]
    local procedure GetAbsoluteUri(): Text
    var
        Uri: Codeunit Uri;
    begin
        UriBuilder.GetUri(Uri);
        exit(Uri.GetAbsoluteUri());
    end;

    [Scope('OnPrem')]
    local procedure DoesExceedCharLimit(Url: Text): Boolean
    begin
        exit(StrLen(Url) > 2000);
    end;
}