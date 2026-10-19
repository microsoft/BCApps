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
        TestTag: Text;
        SetupTag: Text;

    [Test]
    procedure BeforeMethodEnablesBeforeSubscribersSetTag()
    var
        Suite: Record "AL Test Suite";
        Line: Record "Test Method Line";
        TestRunnerMgt: Codeunit "Test Runner - Mgt";
        Events: Codeunit "Test Input Lifecycle Events";
    begin
        Initialize(Suite, Line);
        Events.Configure(Suite.Name, TestName, SetupTag, false);
        BindSubscription(Events);

        Assert.IsTrue(BeforeMethod(TestRunnerMgt, Line), 'The fixture method should execute.');
        Assert.AreEqual('blank', Events.GetBeforeValue(), 'The before event must see enabled text resolution and a cleared tag.');
        Assert.AreEqual('setup', DataTools.ResolveText(Token()), 'A tag selected by a before subscriber must not be reset afterwards.');
        UnbindSubscription(Events);
    end;

    [Test]
    procedure SkippedMethodDisablesAndClearsTag()
    var
        Suite: Record "AL Test Suite";
        Line: Record "Test Method Line";
        TestRunnerMgt: Codeunit "Test Runner - Mgt";
        Events: Codeunit "Test Input Lifecycle Events";
    begin
        Initialize(Suite, Line);
        Events.Configure(Suite.Name, TestName, SetupTag, true);
        BindSubscription(Events);

        Assert.IsFalse(BeforeMethod(TestRunnerMgt, Line), 'The subscriber should skip the fixture method.');
        Assert.AreEqual('blank', Events.GetBeforeValue(), 'The before event still runs with text resolution enabled.');
        VerifyDisabledAndBlankTag();
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
        VerifyDisabledAndBlankTag();
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
        VerifyDisabledAndBlankTag();
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
        Events.Configure('', TestName, SetupTag, false);
        BindSubscription(Events);
        DataTools.SetTextReplacementsEnabled(false);

        Assert.IsTrue(BeforeMethod(TestRunnerMgt, Line), 'No-logging methods should execute.');
        Assert.AreEqual('blank', DataTools.ResolveText(Token()), 'No-logging methods must enable text resolution.');
        Assert.AreEqual('', Events.GetBeforeValue(), 'The no-logging path must not start publishing the normal before event.');
        DataTools.SetTag(SetupTag);
        TestRunnerMgt.PlatformAfterTestRun(
            Line."Test Codeunit", 'Test Input Lifecycle Tests', Line."Function", TestPermissions::Disabled, false, Suite.Name, '');
        Assert.AreEqual(Token(), Events.GetAfterValue(), 'The no-logging after event must see disabled text resolution.');
        VerifyDisabledAndBlankTag();
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
        VerifyDisabledAndBlankTag();
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
        VerifyDisabledAndBlankTag();
        Cleanup(Suite);
    end;

    local procedure Initialize(var Suite: Record "AL Test Suite"; var Line: Record "Test Method Line")
    begin
        TestTag := DelChr(Format(CreateGuid()), '=', '{}-');
        TestName := 'P' + TestTag;
        SetupTag := TestTag + '-setup';
        DataTools.SetTextReplacementsEnabled(true);
        DataTools.SetTag(TestTag);
        DataTools.SetPlaceholder(TestName, 'tagged');
        DataTools.SetPlaceholder(TestName, 'blank', '');
        DataTools.SetPlaceholder(TestName, 'setup', SetupTag);

        Suite.Init();
        Suite.Name := CopyStr(TestTag, 1, MaxStrLen(Suite.Name));
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
        Events.Configure(Suite.Name, TestName, SetupTag, false);
        BindSubscription(Events);
        Assert.IsTrue(BeforeMethod(TestRunnerMgt, Line), 'The fixture method should execute.');
        ClearLastError();
        TestRunnerMgt.PlatformAfterTestRun(
            Line."Test Codeunit", 'Test Input Lifecycle Tests', Line."Function", TestPermissions::Disabled, not Failed, Suite.Name, '');
        RestorePermissionsMock();
        Assert.AreEqual(Token(), Events.GetAfterValue(), 'After subscribers must see the template rather than replaced text.');
        VerifyDisabledAndBlankTag();
        UnbindSubscription(Events);
        Cleanup(Suite);
    end;

    local procedure VerifyDisabledAndBlankTag()
    var
        Value: Text;
    begin
        Assert.AreEqual(Token(), DataTools.ResolveText(Token()), 'Text replacement must be disabled after cleanup.');
        Assert.IsTrue(DataTools.GetPlaceholder(TestName, Value), 'The blank-tag registration must survive cleanup.');
        Assert.AreEqual('blank', Value, 'Cleanup must clear the active tag.');
        Assert.IsTrue(DataTools.GetPlaceholder(TestName, Value, TestTag), 'Cleanup must retain tagged registrations.');
        Assert.AreEqual('tagged', Value, 'Cleanup must not delete table values.');
    end;

    local procedure Cleanup(var Suite: Record "AL Test Suite")
    var
        Line: Record "Test Method Line";
    begin
        Line.SetRange("Test Suite", Suite.Name);
        Line.DeleteAll(false);
        Suite.Delete(false);
        DataTools.DeletePlaceholder(TestName, TestTag);
        DataTools.DeletePlaceholder(TestName, '');
        DataTools.DeletePlaceholder(TestName, SetupTag);
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
