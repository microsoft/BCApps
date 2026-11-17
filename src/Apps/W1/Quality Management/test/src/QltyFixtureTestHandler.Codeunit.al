// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.QualityManagement;

using System.Security.AccessControl;
using System.Testability;

codeunit 139977 "Qlty. Fixture Test Handler" implements ITestHandler
{
    Access = Internal;
    EventSubscriberInstance = Manual;
    SingleInstance = true;

    var
        FailureRoleID: Code[20];

    procedure FailOnRole(RoleID: Code[20])
    begin
        FailureRoleID := RoleID;
    end;

    procedure OnAfterTestCodeunitRun(Context: TestHandlerContext)
    begin
        CleanupFixture(Context);
    end;

    procedure OnAfterTestProcedureRun(Context: TestHandlerContext)
    begin
        CleanupFixture(Context);
    end;

    local procedure CleanupFixture(Context: TestHandlerContext)
    var
        QltyPermissionTestFixture: Codeunit "Qlty. Permission Test Fixture";
        QltyFixtureTestHandler: Codeunit "Qlty. Fixture Test Handler";
    begin
        if UnbindSubscription(QltyFixtureTestHandler) then;
        Clear(FailureRoleID);
        QltyPermissionTestFixture.OnAfterTestCodeunitRun(Context);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Access Control", OnBeforeInsertEvent, '', false, false)]
    local procedure FailBeforePermissionAssignment(var Rec: Record "Access Control"; RunTrigger: Boolean)
    begin
        if Rec."Role ID" = FailureRoleID then
            Error('Quality fixture assignment failure.');
    end;
}
