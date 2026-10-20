// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.TestRunner;

using System.TestLibraries.Security.AccessControl;
using System.TestLibraries.Utilities;

codeunit 130483 "Test Input Lifecycle Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        DataTools: Codeunit "Test Input Data Tools";
        Assert: Codeunit "Library Assert";
        TestName: Text;

    [Test]
    procedure BeforeMethodEnablesBeforeSubscribersRegisterValues()
    var
        Suite: Record "AL Test Suite";
        Line: Record "Test Method Line";
        TestRunnerMgt: Codeunit "Test Runner - Mgt";
        Events: Codeunit "Test Input Lifecycle Events";
    begin
        Initialize(Suite, Line);
        Events.Configure(Suite.Name, TestName, false);
        BindSubscription(Events);

        Assert.IsTrue(BeforeMethod(TestRunnerMgt, Line), 'The fixture method should execute.');
        Assert.AreEqual('initial', Events.GetBeforeValue(), 'The before event must see enabled text resolution and the existing value.');
        Assert.AreEqual('setup', DataTools.ResolveText(Token()), 'A value registered by a before subscriber must remain available afterwards.');
        UnbindSubscription(Events);
    end;

    [Test]
    procedure SkippedMethodDisablesAndPreservesValues()
    var
        Suite: Record "AL Test Suite";
        Line: Record "Test Method Line";
        TestRunnerMgt: Codeunit "Test Runner - Mgt";
        Events: Codeunit "Test Input Lifecycle Events";
    begin
        Initialize(Suite, Line);
        Events.Configure(Suite.Name, TestName, true);
        BindSubscription(Events);

        Assert.IsFalse(BeforeMethod(TestRunnerMgt, Line), 'The subscriber should skip the fixture method.');
        Assert.AreEqual('initial', Events.GetBeforeValue(), 'The before event still runs with text resolution enabled.');
        VerifyDisabledAndValues('setup');
        UnbindSubscription(Events);
    end;

    [Test]
    procedure UnselectedMethodDoesNotEnableReplacement()
    var
        Suite: Record "AL Test Suite";
        Line: Record "Test Method Line";
        TestRunnerMgt: Codeunit "Test Runner - Mgt";
    begin
        Initialize(Suite, Line);
        Line.Run := false;
        Line.Modify();
        DataTools.SetTextReplacementsEnabled(false);
        Assert.IsFalse(BeforeMethod(TestRunnerMgt, Line), 'An unselected method should not execute.');
        VerifyDisabledAndValues('initial');
    end;

    [Test]
    procedure CodeunitNotificationsDoNotEnableReplacement()
    var
        Suite: Record "AL Test Suite";
        Line: Record "Test Method Line";
        TestRunnerMgt: Codeunit "Test Runner - Mgt";
    begin
        Initialize(Suite, Line);
        DataTools.SetTextReplacementsEnabled(false);
        Assert.IsTrue(
            TestRunnerMgt.PlatformBeforeTestRun(
                Line."Test Codeunit", 'Test Input Lifecycle Tests', 'OnRun', TestPermissions::Disabled, Suite.Name, ''),
            'Codeunit notifications should retain their existing run decision.');
        TestRunnerMgt.PlatformAfterTestRun(
            Line."Test Codeunit", 'Test Input Lifecycle Tests', 'OnRun', TestPermissions::Disabled, true, Suite.Name, '');
        VerifyDisabledAndValues('initial');
    end;

    [Test]
    procedure NoLoggingPathEnablesAndDisablesReplacement()
    var
        Suite: Record "AL Test Suite";
        Line: Record "Test Method Line";
        NoLoggingLine: Record "Test Method Line";
        TestRunnerMgt: Codeunit "Test Runner - Mgt";
        Events: Codeunit "Test Input Lifecycle Events";
    begin
        Initialize(Suite, Line);
        NoLoggingLine."Test Codeunit" := Codeunit::"Test Runner - Mgt";
        TestRunnerMgt.RunTestsWithoutLoggingResults(NoLoggingLine);
        Events.Configure('', TestName, false);
        BindSubscription(Events);
        DataTools.SetTextReplacementsEnabled(false);

        Assert.IsTrue(BeforeMethod(TestRunnerMgt, Line), 'No-logging methods should execute.');
        Assert.AreEqual('initial', DataTools.ResolveText(Token()), 'No-logging methods must enable text resolution.');
        Assert.AreEqual('', Events.GetBeforeValue(), 'The no-logging path must not start publishing the normal before event.');
        DataTools.SetPlaceholder(TestName, 'updated');
        TestRunnerMgt.PlatformAfterTestRun(
            Line."Test Codeunit", 'Test Input Lifecycle Tests', Line."Function", TestPermissions::Disabled, false, Suite.Name, '');
        Assert.AreEqual(Token(), Events.GetAfterValue(), 'The no-logging after event must see disabled text resolution.');
        VerifyDisabledAndValues('updated');
        UnbindSubscription(Events);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure SuccessfulMethodDisablesBeforeAfterSubscribers()
    begin
        VerifyAfterMethod(false);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure FailedMethodDisablesBeforeAfterSubscribers()
    begin
        VerifyAfterMethod(true);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure CleanupRunsBeforeLoggingFailure()
    var
        Suite: Record "AL Test Suite";
        Line: Record "Test Method Line";
        TestRunnerMgt: Codeunit "Test Runner - Mgt";
    begin
        Initialize(Suite, Line);
        Line.Delete(false);
        Commit();

        asserterror TestRunnerMgt.PlatformAfterTestRun(
            Line."Test Codeunit", 'Test Input Lifecycle Tests', Line."Function", TestPermissions::Disabled, true, Suite.Name, '');
        Assert.IsTrue(GetLastErrorText() <> '', 'Missing fixture metadata should cause logging to fail.');
        RestorePermissionsMock();
        VerifyDisabledAndValues('initial');
        Cleanup(Suite);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure SuiteCompletionDisablesReplacementWithoutDeletingValues()
    var
        Suite: Record "AL Test Suite";
        Line: Record "Test Method Line";
        TestRunnerMgt: Codeunit "Test Runner - Mgt";
    begin
        Initialize(Suite, Line);
        TestRunnerMgt.RunTests(Line);
        RestorePermissionsMock();
        VerifyDisabledAndValues('initial');
        Cleanup(Suite);
    end;

    local procedure Initialize(var Suite: Record "AL Test Suite"; var Line: Record "Test Method Line")
    begin
        TestName := 'P' + DelChr(Format(CreateGuid()), '=', '{}-');
        DataTools.SetTextReplacementsEnabled(true);
        DataTools.SetPlaceholder(TestName, 'initial');
        DataTools.SetPlaceholder(TestName + '-other', 'other');

        Suite.Init();
        Suite.Name := CopyStr(TestName, 1, MaxStrLen(Suite.Name));
        Suite.Insert(true);
        Line.Init();
        Line."Test Suite" := Suite.Name;
        Line."Line Type" := Line."Line Type"::"Function";
        Line."Test Codeunit" := Codeunit::"Test Input Lifecycle Tests";
        Line."Function" := 'PlaceholderProbe';
        Line.Run := true;
        Line.Insert();
    end;

    local procedure BeforeMethod(var TestRunnerMgt: Codeunit "Test Runner - Mgt"; Line: Record "Test Method Line"): Boolean
    var
        ShouldRun: Boolean;
    begin
        ShouldRun := TestRunnerMgt.PlatformBeforeTestRun(
            Line."Test Codeunit", 'Test Input Lifecycle Tests', Line."Function", TestPermissions::Disabled, Line."Test Suite", '');
        RestorePermissionsMock();
        exit(ShouldRun);
    end;

    local procedure VerifyAfterMethod(Failed: Boolean)
    var
        Suite: Record "AL Test Suite";
        Line: Record "Test Method Line";
        TestRunnerMgt: Codeunit "Test Runner - Mgt";
        Events: Codeunit "Test Input Lifecycle Events";
    begin
        Initialize(Suite, Line);
        Events.Configure(Suite.Name, TestName, false);
        BindSubscription(Events);
        Assert.IsTrue(BeforeMethod(TestRunnerMgt, Line), 'The fixture method should execute.');
        ClearLastError();
        TestRunnerMgt.PlatformAfterTestRun(
            Line."Test Codeunit", 'Test Input Lifecycle Tests', Line."Function", TestPermissions::Disabled, not Failed, Suite.Name, '');
        RestorePermissionsMock();
        Assert.AreEqual(Token(), Events.GetAfterValue(), 'After subscribers must see the template rather than replaced text.');
        VerifyDisabledAndValues('setup');
        UnbindSubscription(Events);
        Cleanup(Suite);
    end;

    local procedure VerifyDisabledAndValues(ExpectedValue: Text)
    var
        Value: Text;
    begin
        Assert.AreEqual(Token(), DataTools.ResolveText(Token()), 'Text replacement must be disabled after cleanup.');
        Assert.IsTrue(DataTools.GetPlaceholder(TestName, Value), 'The registration must survive lifecycle cleanup.');
        Assert.AreEqual(ExpectedValue, Value, 'Lifecycle cleanup must not change the registered value.');
        Assert.IsTrue(DataTools.GetPlaceholder(TestName + '-other', Value), 'Lifecycle cleanup must retain other names.');
        Assert.AreEqual('other', Value, 'Lifecycle cleanup must not delete table values.');
    end;

    local procedure Cleanup(var Suite: Record "AL Test Suite")
    var
        Line: Record "Test Method Line";
    begin
        Line.SetRange("Test Suite", Suite.Name);
        Line.DeleteAll(false);
        Suite.Delete(false);
        DataTools.DeletePlaceholder(TestName);
        DataTools.DeletePlaceholder(TestName + '-other');
    end;

    local procedure Token(): Text
    begin
        exit('$Placeholder-' + TestName + '$');
    end;

    local procedure RestorePermissionsMock()
    var
        PermissionsMock: Codeunit "Permissions Mock";
    begin
        // Synthetic callbacks must not invert the outer runner's permission-mock lifecycle.
        if not PermissionsMock.IsStarted() then
            PermissionsMock.Start();
    end;
}
