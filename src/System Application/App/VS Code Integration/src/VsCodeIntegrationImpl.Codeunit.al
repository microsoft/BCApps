namespace System.Integration;

using System.Apps;
using System.Reflection;
using System.Utilities;
using System.Text.Json;

codeunit 8333 "VS Code Integration Impl."
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        UriBuilder: Codeunit "Uri Builder";
        VSCodeRequestHelper: DotNet VSCodeRequestHelper;
        AlExtensionUriTxt: Label 'vscode://ms-dynamics-smb.al', Locked = true;
        BaseApplicationIdTxt: Label '437dbf0e-84ff-417a-965d-ed2bb9650972', Locked = true;
        SystemApplicationIdTxt: Label '63ca2fa4-4f03-4f2b-a480-172fef340d3f', Locked = true;
        ApplicationIdTxt: Label 'c1335042-3002-4257-bf8a-75c898ccb1b8', Locked = true;
        NotSufficientPermissionErr: Label 'You do not have sufficient permissions to interact with the source code of extensions. Please contact your administrator.';

    [Scope('OnPrem')]
    procedure OpenExtensionSourceInVSCode(var PublishedApplication: Record "Published Application")
    var
        Url: Text;
    begin
        CheckPermissions();

        if Text.StrLen(PublishedApplication."Source Repository Url") <> 0 then begin
            UriBuilder.Init(AlExtensionUriTxt + '/sourceSync');
            UriBuilder.AddQueryParameter('repoUrl', PublishedApplication."Source Repository Url");
            if Text.StrLen(PublishedApplication."Source Commit ID") <> 0 then
                UriBuilder.AddQueryParameter('commitId', PublishedApplication."Source Commit ID");
            UriBuilder.AddQueryParameter('appid', Format(PublishedApplication.ID, 0, 4));

            Url := GetAbsoluteUri();
            if DoesExceedCharLimit(Url) then
                // If the URL length exceeds 2000 characters then it will crash the page, so we truncate it.
                Hyperlink(AlExtensionUriTxt + '/truncated')
            else
                HyperLink(Url);
        end;
    end;

    [Scope('OnPrem')]
    procedure UpdateConfigurationsInVSCode()
    var
        Url: Text;
    begin
        CheckPermissions();

        UriBuilder.Init(AlExtensionUriTxt + '/configure');
        UriBuilder.SetQuery(VSCodeRequestHelper.GetLaunchInformationQueryPart());
        UriBuilder.AddQueryParameter('sessionId', Format(SessionId()));

        Url := GetAbsoluteUri();
        HyperLink(Url);
    end;

    [Scope('OnPrem')]
    procedure UpdateDependenciesInVSCode(var PublishedApplication: Record "Published Application")
    var
        NavAppInstalledApp: Record "NAV App Installed App";
        Url: Text;
    begin
        CheckPermissions();

        NavAppInstalledApp.Reset();
        if PublishedApplication.FindSet() then
            repeat
                if NavAppInstalledApp.Get(PublishedApplication.ID) then
                    NavAppInstalledApp.Mark := true;
            until PublishedApplication.Next() = 0;
        NavAppInstalledApp.MarkedOnly(true);

        UriBuilder.Init(AlExtensionUriTxt + '/addDependencies');
        UriBuilder.SetQuery(VSCodeRequestHelper.GetLaunchInformationQueryPart());
        UriBuilder.AddQueryParameter('dependencies', GetDependenciesAsParameter(NavAppInstalledApp));

        Url := GetAbsoluteUri();
        if DoesExceedCharLimit(Url) then
            // If the URL length exceeds 2000 characters then it will crash the page, so we truncate it.
            Error('The number of dependencies exceeds the limit that can be sent to VS Code.')
        else
            HyperLink(Url);
    end;

    [Scope('OnPrem')]
    procedure NavigateToObjectDefinitionInVSCode(ObjectType: Option; ObjectId: Integer; ObjectName: Text; ControlName: Text; var NavAppInstalledApp: Record "NAV App Installed App")
    var
        Url: Text;
    begin
        CheckPermissions();

        UriBuilder.Init(AlExtensionUriTxt + '/navigateTo');

        UriBuilder.AddQueryParameter('type', FormatObjectType(ObjectType));
        UriBuilder.AddQueryParameter('id', Format(ObjectId));
        UriBuilder.AddQueryParameter('name', ObjectName);
        UriBuilder.AddQueryParameter('appid', GetAppIdForObject(ObjectType, ObjectId));
        if Text.StrLen(ControlName) <> 0 then
            UriBuilder.AddQueryParameter('fieldName', Format(ControlName));
        UriBuilder.SetQuery(UriBuilder.GetQuery() + '&' + VSCodeRequestHelper.GetLaunchInformationQueryPart());
        UriBuilder.AddQueryParameter('sessionId', Format(SessionId()));
        UriBuilder.AddQueryParameter('dependencies', GetDependenciesAsParameter(NavAppInstalledApp));

        Url := GetAbsoluteUri();
        if DoesExceedCharLimit(Url) then
            // If the URL length exceeds 2000 characters then it will crash the page, so we truncate it.
            Hyperlink(AlExtensionUriTxt + '/truncated')
        else
            HyperLink(Url);
    end;

    [Scope('OnPrem')]
    local procedure GetDependenciesAsParameter(var NavAppInstalledApp: Record "NAV App Installed App"): Text
    var
        DependencyList: TextBuilder;
    begin
        if NavAppInstalledApp.FindSet() then
            repeat
                DependencyList.Append(FormatDependencyAsParameter(NavAppInstalledApp));
            until NavAppInstalledApp.Next() = 0;

        if DoesExceedCharLimit(GetAbsoluteUri() + DependencyList.ToText()) then
            exit('truncated');

        exit(DependencyList.ToText());
    end;

    [Scope('OnPrem')]
    local procedure FormatDependencyAsParameter(var NavAppInstalledApp: Record "NAV App Installed App"): Text
    var
        AppVersion: Text;
        DependencyFormatLbl: Label '%1,%2,%3,%4;', Comment = '%1 = Id, %2 = Name, %3 = Publisher, %4 = Version', Locked = true;
    begin
        // Skip System and Base app
        case NavAppInstalledApp."App ID" of
            SystemApplicationIdTxt, BaseApplicationIdTxt, ApplicationIdTxt:
                exit('')
            else
                AppVersion := FormatDependencyVersion(NavAppInstalledApp."Version Major", NavAppInstalledApp."Version Minor", NavAppInstalledApp."Version Build", NavAppInstalledApp."Version Revision");
                exit(StrSubstNo(DependencyFormatLbl, Format(NavAppInstalledApp."App ID", 0, 4), NavAppInstalledApp.Name, NavAppInstalledApp.Publisher, AppVersion));
        end;
    end;

    [Scope('OnPrem')]
    procedure GetDependenciesAsSerializedJsonArray(var PublishedApplication: Record "Published Application"): Text
    var
        Json: Codeunit Json;
    begin
        Json.InitializeCollection('');
        if PublishedApplication.FindSet() then
            repeat
                Json.AddJObjectToCollection(FormatDependencyAsSerializedJsonObject(PublishedApplication));
            until PublishedApplication.Next() = 0;

        exit(Json.GetCollectionAsText(true));
    end;

    [Scope('OnPrem')]
    local procedure FormatDependencyAsSerializedJsonObject(var PublishedApplication: Record "Published Application") Value: Text
    var
        AppVersion: Text;
        Dependency: JsonObject;
    begin
        Dependency.Add('id', PublishedApplication.ID);
        Dependency.Add('name', PublishedApplication.Name);
        Dependency.Add('publisher', PublishedApplication.Publisher);
        AppVersion := FormatDependencyVersion(PublishedApplication."Version Major", PublishedApplication."Version Minor", PublishedApplication."Version Build", PublishedApplication."Version Revision");
        Dependency.Add('version', AppVersion);

        Dependency.WriteTo(Value);
    end;

    [Scope('OnPrem')]
    local procedure FormatDependencyVersion(Major: Integer; Minor: Integer; Build: Integer; Revision: Integer): Text
    var
        AppVersionLbl: Label '%1.%2.%3.%4', Comment = '%1 = major, %2 = minor, %3 = build, %4 = revision', Locked = true;
    begin
        exit(StrSubstNo(AppVersionLbl, Major, Minor, Build, Revision));
    end;

    [Scope('OnPrem')]
    local procedure FormatObjectType(ObjectType: Option): Text
    var
        AllObjWithCaption: Record AllObjWithCaption;
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
        AllObjWithCaption: Record AllObjWithCaption;
        NavAppInstalledApp: Record "NAV App Installed App";
        EmptyGuid: Guid;
    begin
        // Objects in the system app range
        if ObjectId >= 2000000000 then
            exit(EmptyGuid);

        if AllObjWithCaption.ReadPermission() then begin
            AllObjWithCaption.SetRange("Object Type", ObjectType);
            AllObjWithCaption.SetRange("Object ID", ObjectId);

            if AllObjWithCaption.FindFirst() then begin
                NavAppInstalledApp.Reset();
                NavAppInstalledApp.SetRange("Package ID", AllObjWithCaption."App Package ID");
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

    local procedure CheckPermissions()
    begin
        if not CanInteractWithSourceCode() then
            Error(NotSufficientPermissionErr);
    end;

    local procedure CanInteractWithSourceCode(): Boolean
    var
        ApplicationObjectMetadata: Record "Application Object Metadata";
    begin
        exit(ApplicationObjectMetadata.ReadPermission());
    end;
}