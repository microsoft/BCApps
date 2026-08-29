// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.API.Codeunits.Test;

using Microsoft.API.Codeunits;
using System.Azure.Identity;
using System.DateTime;
using System.Environment;
using System.TestLibraries.Utilities;

codeunit 139930 "API Codeunits Tests"
{
    Subtype = Test;
    TestType = UnitTest;
    TestPermissions = Disabled;

    var
        LibraryAssert: Codeunit "Library Assert";
        APICodeunitsAppIdTok: Label '2573cc59-1cfc-4991-85e4-32d0cc0f60e2', Locked = true;
        AppNotInstalledErr: Label 'The app with ID %1 is not installed.', Comment = '%1 = the app ID';
        UtcTimeZoneIdTok: Label 'UTC', Locked = true;
        PacificTimeZoneIdTok: Label 'Pacific Standard Time', Locked = true;

    [Test]
    procedure EnvironmentInformationMatchesSystemValues()
    var
        EnvironmentAPI: Codeunit "Environment API";
        EnvironmentInformation: Codeunit "Environment Information";
    begin
        LibraryAssert.AreEqual(EnvironmentInformation.GetEnvironmentName(), EnvironmentAPI.GetEnvironmentName(), 'Environment name must match the system value.');
        LibraryAssert.AreEqual(EnvironmentInformation.IsProduction(), EnvironmentAPI.IsProduction(), 'Production status must match the system value.');
        LibraryAssert.AreEqual(EnvironmentInformation.IsSandbox(), EnvironmentAPI.IsSandbox(), 'Sandbox status must match the system value.');
        LibraryAssert.AreEqual(EnvironmentInformation.IsSaaS(), EnvironmentAPI.IsSaaS(), 'SaaS status must match the system value.');
    end;

    [Test]
    procedure EntraTenantIdMatchesSystemValue()
    var
        EnvironmentAPI: Codeunit "Environment API";
        AzureADTenant: Codeunit "Azure AD Tenant";
    begin
        LibraryAssert.AreEqual(AzureADTenant.GetAadTenantId(), EnvironmentAPI.GetEntraTenantId(), 'Entra tenant ID must match the system value.');
    end;

    [Test]
    procedure InstalledAppReturnsFullVersion()
    var
        EnvironmentAPI: Codeunit "Environment API";
        AppInfo: ModuleInfo;
        AppId: Guid;
    begin
        AppId := GetAPICodeunitsAppId();

        LibraryAssert.IsTrue(NavApp.GetModuleInfo(AppId, AppInfo), 'The API - Codeunits app must be installed.');
        LibraryAssert.IsTrue(EnvironmentAPI.IsAppInstalled(AppId), 'The installed app must be reported as installed.');
        LibraryAssert.AreEqual(Format(AppInfo.AppVersion()), EnvironmentAPI.GetAppVersion(AppId), 'The complete app version must be returned.');
    end;

    [Test]
    procedure MissingAppReturnsFalseAndVersionFails()
    var
        EnvironmentAPI: Codeunit "Environment API";
        MissingAppId: Guid;
    begin
        MissingAppId := CreateGuid();

        LibraryAssert.IsFalse(EnvironmentAPI.IsAppInstalled(MissingAppId), 'An unknown app must not be reported as installed.');

        asserterror EnvironmentAPI.GetAppVersion(MissingAppId);
        LibraryAssert.ExpectedError(StrSubstNo(AppNotInstalledErr, MissingAppId));
    end;

    [Test]
    procedure UtcOffsetMatchesSystemTimeZone()
    var
        TimeZoneAPI: Codeunit "Time Zone API";
        TimeZone: Codeunit "Time Zone";
        SourceDateTime: DateTime;
    begin
        SourceDateTime := CreateDateTime(20260701D, 120000T);

        LibraryAssert.AreEqual(
            TimeZone.GetTimezoneOffset(SourceDateTime, UtcTimeZoneIdTok),
            TimeZoneAPI.GetUtcOffset(SourceDateTime, UtcTimeZoneIdTok),
            'UTC offset must match the system time zone calculation.');
    end;

    [Test]
    procedure TimeZoneOffsetMatchesSystemTimeZone()
    var
        TimeZoneAPI: Codeunit "Time Zone API";
        TimeZone: Codeunit "Time Zone";
        SourceDateTime: DateTime;
    begin
        SourceDateTime := CreateDateTime(20260701D, 120000T);

        LibraryAssert.AreEqual(
            TimeZone.GetTimezoneOffset(SourceDateTime, UtcTimeZoneIdTok, PacificTimeZoneIdTok),
            TimeZoneAPI.GetTimeZoneOffset(SourceDateTime, UtcTimeZoneIdTok, PacificTimeZoneIdTok),
            'Offset between time zones must match the system calculation.');
    end;

    [Test]
    procedure DaylightSavingInformationMatchesSystemTimeZone()
    var
        TimeZoneAPI: Codeunit "Time Zone API";
        TimeZone: Codeunit "Time Zone";
        SourceDateTime: DateTime;
    begin
        SourceDateTime := CreateDateTime(20260701D, 120000T);

        LibraryAssert.AreEqual(
            TimeZone.TimeZoneSupportsDaylightSavingTime(PacificTimeZoneIdTok),
            TimeZoneAPI.SupportsDaylightSavingTime(PacificTimeZoneIdTok),
            'Daylight saving support must match the system value.');
        LibraryAssert.AreEqual(
            TimeZone.IsDaylightSavingTime(SourceDateTime, PacificTimeZoneIdTok),
            TimeZoneAPI.IsDaylightSavingTime(SourceDateTime, PacificTimeZoneIdTok),
            'Daylight saving status must match the system value.');
    end;

    local procedure GetAPICodeunitsAppId(): Guid
    var
        AppId: Guid;
    begin
        LibraryAssert.IsTrue(Evaluate(AppId, APICodeunitsAppIdTok), 'The API - Codeunits app ID must be a valid GUID.');
        exit(AppId);
    end;
}
