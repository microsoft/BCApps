// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.TestRunner;

using System.Reflection;

codeunit 130453 "ALTestRunner Reset Environment"
{
    SingleInstance = true;

    trigger OnRun()
    begin
    end;

    procedure Initialize()
    begin
        CurrentWorkDate := WorkDate();
    end;

#if not CLEAN22
#pragma warning disable AA0207
    [Obsolete('The procedure will be made local.', '22.0')]
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Test Runner - Mgt", 'OnBeforeTestMethodRun', '', false, false)]
    procedure BeforeTestMethod(CodeunitID: Integer; CodeunitName: Text[30]; FunctionName: Text[128]; FunctionTestPermissions: TestPermissions; var CurrentTestMethodLine: Record "Test Method Line")
#pragma warning restore AA0207
#else
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Test Runner - Mgt", 'OnBeforeTestMethodRun', '', false, false)]
    local procedure BeforeTestMethod(CodeunitID: Integer; CodeunitName: Text[30]; FunctionName: Text[128]; FunctionTestPermissions: TestPermissions; var CurrentTestMethodLine: Record "Test Method Line")
#endif
    begin
        ClearLastError();
        ApplicationArea('');
        if FunctionName = 'OnRun' then
            exit;

        ClearLegacyLibraries(FunctionTestPermissions);
        BindStopSystemTableChanges();
    end;

#if not CLEAN22
#pragma warning disable AA0207
    [Obsolete('The procedure will be made local.', '22.0')]
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Test Runner - Mgt", 'OnAfterCodeunitRun', '', false, false)]
    procedure AfterTestMethod(var TestMethodLine: Record "Test Method Line")
#pragma warning restore AA0207
#else
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Test Runner - Mgt", 'OnAfterCodeunitRun', '', false, false)]
    local procedure OnAfterCodeunit(var TestMethodLine: Record "Test Method Line")
#endif
    begin
        WorkDate(CurrentWorkDate);
        ApplicationArea('');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Test Runner - Mgt", 'OnAfterTestMethodRun', '', false, false)]
    local procedure OnAfterTestMethodRun(FunctionTestPermissions: TestPermissions; IsSuccess: Boolean)
    begin
        VerifyPermissions(FunctionTestPermissions, IsSuccess);
    end;

    local procedure ClearLegacyLibraries(FunctionTestPermissions: TestPermissions)
    var
        ResetStateCodeunit: Integer;
        SetPermissionsCodeunit: Integer;
    begin
        ResetStateCodeunit := 130301; // codeunit 130301 "Reset State Before Test Run"
        if CodeunitExists(ResetStateCodeunit) then
            Codeunit.Run(ResetStateCodeunit);

        if FunctionTestPermissions = TestPermissions::Disabled then
            exit;

        SetPermissionsCodeunit := 130302; // codeunit 130302 "Set Permissions State Before Test Run"
        if CodeunitExists(SetPermissionsCodeunit) then
            Codeunit.Run(SetPermissionsCodeunit);
    end;

    local procedure VerifyPermissions(FunctionTestPermissions: TestPermissions; IsSuccess: Boolean)
    var
        VerifyPermissionsCodeunit: Integer;
    begin
        if not IsSuccess then
            exit; // Do not verify permissions if the test already failed, otherwise we will overwrite the test error with a permission error. This would make it difficult to troubleshoot your test.

        if FunctionTestPermissions <> TestPermissions::Restrictive then
            exit;

        VerifyPermissionsCodeunit := 132219; // codeunit 132219 "Restrictive Permissions Verification"
        if CodeunitExists(VerifyPermissionsCodeunit) then
            if not Codeunit.Run(VerifyPermissionsCodeunit) then
                Error(GetLastErrorText());
    end;

    local procedure CodeunitExists(CodeunitId: Integer): Boolean
    var
        AllObj: Record AllObj;
    begin
        AllObj.SetRange("Object Type", AllObj."Object Type"::Codeunit);
        AllObj.SetRange("Object ID", CodeunitId);
        exit(not AllObj.IsEmpty());
    end;

    local procedure BindStopSystemTableChanges()
    var
        AllObj: Record AllObj;
        BlockChangestoSystemTables: Integer;
    begin
        BlockChangestoSystemTables := 132553; // codeunit 132553 "Block Changes to System Tables"
        AllObj.SetRange("Object Type", AllObj."Object Type"::Codeunit);
        AllObj.SetRange("Object ID", BlockChangestoSystemTables);
        if not AllObj.IsEmpty() then
            Codeunit.Run(BlockChangestoSystemTables);
    end;


    var
        CurrentWorkDate: Date;
}