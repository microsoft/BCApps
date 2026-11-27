// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestLibraries.Security.AccessControl;

using System.Testability;

codeunit 131034 "Permissions Mock Test Handler" implements ITestHandler
{
    Access = Internal;
    SingleInstance = true;

    var
        PermissionsMock: Codeunit "Permissions Mock";
        OwnsScope: Boolean;

    procedure OnBeforeTestCodeunitRun(Context: TestHandlerContext)
    begin
        StopOwnedScope();
    end;

    procedure OnAfterTestCodeunitRun(Context: TestHandlerContext)
    begin
        StopOwnedScope();
    end;

    procedure OnBeforeTestProcedureRun(Context: TestHandlerContext)
    begin
        // Skipped procedures can omit their after hook.
        StopOwnedScope();
        StartScope();
    end;

    procedure OnAfterTestProcedureRun(Context: TestHandlerContext)
    begin
        StopOwnedScope();
    end;

    procedure OnBeforeTestCaseRun(Context: TestHandlerContext)
    begin
        // Skipped cases can omit their after hook.
        StopOwnedScope();
        StartScope();
    end;

    procedure OnAfterTestCaseRun(Context: TestHandlerContext)
    begin
        StopOwnedScope();
    end;

    local procedure StartScope()
    begin
        if PermissionsMock.IsStarted() then
            exit;

        PermissionsMock.Start();
        OwnsScope := true;
    end;

    local procedure StopOwnedScope()
    begin
        if not OwnsScope then
            exit;

        PermissionsMock.Stop();
        OwnsScope := false;
    end;
}
