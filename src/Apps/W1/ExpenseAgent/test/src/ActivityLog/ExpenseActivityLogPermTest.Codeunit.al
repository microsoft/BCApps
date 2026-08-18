// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.ExpenseAgent;

using Microsoft.ExpenseAgent;

codeunit 148344 "Expense Activity Log Perm. Test"
{
    Subtype = Test;
    TestType = UnitTest;
    TestPermissions = Restrictive;

    var
        Assert: Codeunit Assert;
        LibraryExpense: Codeunit "Library - Expense";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;
        ExpenseMgmtEditPermissionSetTok: Label 'Expense Mgmt. Edit', Locked = true;
        ExpenseAgentPermissionSetTok: Label 'Expense Agent', Locked = true;

    [Test]
    procedure ExpenseManagementEditCanInsertActivityIndirectly()
    begin
        VerifyPermissionSetCanInsertActivity(ExpenseMgmtEditPermissionSetTok);
    end;

    [Test]
    procedure ExpenseAgentCanInsertActivityIndirectly()
    begin
        VerifyPermissionSetCanInsertActivity(ExpenseAgentPermissionSetTok);
    end;

    local procedure VerifyPermissionSetCanInsertActivity(PermissionSetId: Code[20])
    var
        ExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseActivityLogEntry: Record "Expense Activity Log Entry";
        ExpenseActivityLogMgt: Codeunit "Expense Activity Log Mgt.";
        EntryNo: BigInteger;
    begin
        Initialize();
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", '', '');

        LibraryLowerPermissions.SetExactPermissionSet(PermissionSetId);
        EntryNo := ExpenseActivityLogMgt.LogExpenseReportEvent(
            ExpenseReportHeader,
            Enum::"Expense Activity Event Type"::Created,
            Enum::"Expense Activity Initiator"::User,
            Enum::"Expense Activity Actor Role"::Submitter,
            ExpenseUser."No.",
            '');
        LibraryLowerPermissions.SetOutsideO365Scope();

        Assert.IsTrue(EntryNo > 0, 'The activity entry must be inserted through indirect permissions.');
        ExpenseActivityLogEntry.Get(EntryNo);
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Expense Activity Log Perm. Test");
        if IsInitialized then
            exit;

        LibraryExpense.SetupNumberSeriesInExpenseMgmt();
        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Expense Activity Log Perm. Test");
    end;
}
