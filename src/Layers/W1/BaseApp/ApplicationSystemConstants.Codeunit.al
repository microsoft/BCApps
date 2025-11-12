// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Environment;

codeunit 9015 "Application System Constants"
{
    // Be careful when updating this file! All labels are marked something like "!Build ...!".
    // We populate these during the build process and they should not be overwritten containing actual details.


    trigger OnRun()
    begin
    end;

    procedure OriginalApplicationVersion() ApplicationVersion: Text[248]
    begin
        // Should be 'Build Version' with ! on both sides.
        ApplicationVersion := '!Build Version!';
    end;

    procedure ApplicationVersion() ApplicationVersion: Text[248]
    begin
        ApplicationVersion := OriginalApplicationVersion();
        OnAfterGetApplicationVersion(ApplicationVersion);
    end;

    procedure BuildFileVersion() BuildFileVersion: Text[248];
    var
        thisModule: ModuleInfo;
        completeVersion: Version;
    begin
        // Will return a string similar to '14.2.12345.12349'
        NavApp.GetCurrentModuleInfo(thisModule);
        completeVersion := thisModule.AppVersion;

        BuildFileVersion := CopyStr(Format(completeVersion), 1, MaxStrLen(BuildFileVersion));
    end;

    procedure ApplicationBuild(): Text[80]
    var
        thisModule: ModuleInfo;
        completeVersion: Version;
    begin
        // Will return a string similar to '12349'. The return value represents the revision number, for historical reasons.
        NavApp.GetCurrentModuleInfo(thisModule);
        completeVersion := thisModule.AppVersion;
        exit(CopyStr(Format(completeVersion.Revision()), 1, 80));
    end;

    procedure BuildBranch(): Text[250]
    begin
        // Should be 'Build branch' with ! on both sides.
        // Will return a string representing the name of the internal branch that generated the build.
        exit('!Build branch!');
    end;

    procedure PlatformProductVersion(): Text[80]
    begin
        // Should be 'Platform Product Version' with ! on both sides.
        // Will return a string similar to '13.4.98761.98765'.
        exit('!Platform Product Version!');
    end;

    procedure PlatformFileVersion(): Text[80]
    begin
        // Should be 'Platform File Version' with ! on both sides.
        // Will return a string similar to '13.4.98761.98765'.
        exit('!Platform File Version!');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Version Triggers", 'GetApplicationVersion', '', false, false)]
    local procedure GetApplicationVersion(var Version: Text[248])
    begin
        Version := ApplicationVersion();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Version Triggers", 'GetApplicationBuild', '', false, false)]
    local procedure GetApplicationBuild(var Build: Text[80])
    begin
        // Must ever only be the build number of the server building the app.
        Build := ApplicationBuild();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetApplicationVersion(var ApplicationVersion: Text[248])
    begin
    end;
}

