// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.ExpenseAgent;

using Microsoft.ExpenseAgent;

codeunit 148339 "Expense Policy Flag Test"
{
    Subtype = Test;
    TestType = IntegrationTest;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        LibraryExpense: Codeunit "Library - Expense";
        LibraryRandom: Codeunit "Library - Random";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryUtility: Codeunit "Library - Utility";
        IsInitialized: Boolean;

    // --- Version-counter lifecycle -----------------------------------------------------------

    [Test]
    procedure NewReportLineStartsNotEvaluated()
    var
        ExpenseReportLine: Record "Expense Report Line";
        ExpensePolicy: Record "Expense Policy";
    begin
        // [SCENARIO] A freshly inserted report line with an applicable policy starts at Policy Eval Version 0, unevaluated, status Not Evaluated.
        Initialize();

        // [WHEN] A report line is created and a policy targets its category.
        CreateTestReportLine(ExpenseReportLine);
        CreateTestPolicy(ExpensePolicy, ExpenseReportLine."Expense Category", 'Applies to the line category');
        ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");

        // [THEN] Policy Eval Version is 0, no evaluation timestamp, and the status is Not Evaluated.
        Assert.AreEqual(0, ExpenseReportLine."Policy Eval Version", 'Policy Eval Version should be 0 on insert.');
        Assert.AreEqual(0DT, ExpenseReportLine."Policies Evaluated At", 'Policies Evaluated At should be blank before any evaluation.');
        Assert.AreEqual("Expense Policy Status"::"Not Evaluated", ExpenseReportLine.GetPolicyStatus(), 'A never-evaluated report line must report Not Evaluated.');
    end;

    [Test]
    procedure MarkPoliciesEvaluatedNoPoliciesWhenNoApplicablePolicy()
    var
        ExpenseReportLine: Record "Expense Report Line";
    begin
        // [SCENARIO] MarkPoliciesEvaluated advances Evaluated to Current and stamps the timestamp; with no
        //            applicable policy the line reports No Policies (a stable "nothing to check" signal), not Cleared.
        Initialize();
        CreateTestReportLine(ExpenseReportLine);

        // [WHEN] The report line is marked evaluated.
        ExpenseReportLine.MarkPoliciesEvaluated(ExpenseReportLine."Policy Eval Version");

        // [THEN] Evaluated equals Current, the timestamp is set, and the status is No Policies.
        Assert.AreEqual(ExpenseReportLine."Policy Eval Version", ExpenseReportLine."Evaluated Policy Version", 'Evaluated must catch up to Policy Eval Version after MarkPoliciesEvaluated.');
        Assert.AreNotEqual(0DT, ExpenseReportLine."Policies Evaluated At", 'Policies Evaluated At must be stamped.');
        Assert.AreEqual("Expense Policy Status"::"No Policies", ExpenseReportLine.GetPolicyStatus(), 'An evaluated line with no applicable policy must report No Policies.');
    end;

    [Test]
    procedure MarkPoliciesEvaluatedRejectsChangedReportLine()
    var
        ExpenseReportLine: Record "Expense Report Line";
        EvaluatedSubjectVersion: Integer;
    begin
        // [SCENARIO] Evaluation completion is rejected when the report line changed after evaluation started.
        Initialize();
        CreateTestReportLine(ExpenseReportLine);
        EvaluatedSubjectVersion := ExpenseReportLine."Policy Eval Version";

        // [GIVEN] A policy-relevant field changes after the caller captured the subject version.
        ExpenseReportLine."Merchant Name" := 'Changed after evaluation started';
        ExpenseReportLine.Modify(true);

        // [WHEN] The caller tries to complete the older evaluation.
        asserterror ExpenseReportLine.MarkPoliciesEvaluated(EvaluatedSubjectVersion);

        // [THEN] The stale completion is rejected and no evaluation timestamp is recorded.
        Assert.ExpectedError('changed after policy evaluation started');
        ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");
        Assert.AreEqual(0DT, ExpenseReportLine."Policies Evaluated At", 'A stale evaluation must not be marked complete.');
    end;

    [Test]
    procedure RelevantFieldChangeMakesStale()
    var
        ExpenseReportLine: Record "Expense Report Line";
    begin
        // [SCENARIO] Changing a policy-relevant field after evaluation bumps Current, leaving the line Stale.
        Initialize();
        CreateTestReportLine(ExpenseReportLine);
        ExpenseReportLine.MarkPoliciesEvaluated(ExpenseReportLine."Policy Eval Version");

        // [WHEN] A policy-relevant field (Merchant Name) changes to a guaranteed-different value.
        ExpenseReportLine."Merchant Name" := 'Contoso Merchant (policy-relevant change)';
        ExpenseReportLine.Modify(true);

        // [THEN] Current is bumped past Evaluated and the status is Stale.
        ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");
        Assert.AreEqual(1, ExpenseReportLine."Policy Eval Version", 'A relevant field change must bump Policy Eval Version.');
        Assert.AreEqual(0, ExpenseReportLine."Evaluated Policy Version", 'Evaluated must not move on a plain modify.');
        Assert.AreEqual("Expense Policy Status"::Stale, ExpenseReportLine.GetPolicyStatus(), 'A relevant change after evaluation must report Stale.');
    end;

    [Test]
    procedure NeutralFieldChangeDoesNotStale()
    var
        ExpenseReportLine: Record "Expense Report Line";
    begin
        // [SCENARIO] Changing only a policy-neutral field after evaluation must NOT bump Current; the line
        //            does not go Stale (with no applicable policy it stays at the stable No Policies signal).
        Initialize();
        CreateTestReportLine(ExpenseReportLine);
        ExpenseReportLine.MarkPoliciesEvaluated(ExpenseReportLine."Policy Eval Version");

        // [WHEN] Only a neutral field (Applied Rule Id) changes.
        ExpenseReportLine."Applied Rule Id" := CreateGuid();
        ExpenseReportLine.Modify(true);

        // [THEN] Current is unchanged and the status has not gone Stale.
        ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");
        Assert.AreEqual(0, ExpenseReportLine."Policy Eval Version", 'A neutral field change must not bump Policy Eval Version.');
        Assert.AreEqual("Expense Policy Status"::"No Policies", ExpenseReportLine.GetPolicyStatus(), 'A neutral change must not stale the line.');
    end;

    [Test]
    procedure InvalidatePolicyEvaluationMakesStale()
    var
        ExpenseReportLine: Record "Expense Report Line";
    begin
        // [SCENARIO] InvalidatePolicyEvaluation bumps Current directly, leaving an evaluated line Stale.
        Initialize();
        CreateTestReportLine(ExpenseReportLine);
        ExpenseReportLine.MarkPoliciesEvaluated(ExpenseReportLine."Policy Eval Version");

        // [WHEN] The evaluation is invalidated.
        ExpenseReportLine.InvalidatePolicyEvaluation();

        // [THEN] Current is ahead of Evaluated and the status is Stale.
        ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");
        Assert.AreEqual(1, ExpenseReportLine."Policy Eval Version", 'InvalidatePolicyEvaluation must bump Policy Eval Version.');
        Assert.AreEqual("Expense Policy Status"::Stale, ExpenseReportLine.GetPolicyStatus(), 'After invalidation an evaluated line must report Stale.');
    end;

    [Test]
    procedure InvalidateBeforeEvaluationAdvancesVersion()
    var
        ExpenseReportLine: Record "Expense Report Line";
        ExpensePolicy: Record "Expense Policy";
    begin
        // [SCENARIO] Invalidation before the first evaluation advances the subject version.
        Initialize();
        CreateTestReportLine(ExpenseReportLine);
        CreateTestPolicy(ExpensePolicy, ExpenseReportLine."Expense Category", 'Applies to the line category');
        ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");

        // [WHEN] The evaluation is invalidated before any evaluation ever happened.
        ExpenseReportLine.InvalidatePolicyEvaluation();

        // [THEN] Current advances and the status stays Not Evaluated.
        ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");
        Assert.AreEqual(1, ExpenseReportLine."Policy Eval Version", 'Invalidation before evaluation must bump Policy Eval Version.');
        Assert.AreEqual("Expense Policy Status"::"Not Evaluated", ExpenseReportLine.GetPolicyStatus(), 'Invalidation before evaluation must leave the line Not Evaluated.');
    end;

    [Test]
    procedure RepeatedInvalidationAdvancesVersion()
    var
        ExpenseReportLine: Record "Expense Report Line";
    begin
        // [SCENARIO] Every policy-relevant change receives a distinct subject version.
        Initialize();
        CreateTestReportLine(ExpenseReportLine);

        ExpenseReportLine.InvalidatePolicyEvaluation();
        ExpenseReportLine.InvalidatePolicyEvaluation();

        ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");
        Assert.AreEqual(2, ExpenseReportLine."Policy Eval Version", 'Repeated invalidation must advance the version for every change.');
    end;

    // --- Flag insertion + Flagged status -----------------------------------------------------

    [Test]
    procedure EvaluatedReportLineWithFlagIsFlagged()
    var
        ExpenseReportLine: Record "Expense Report Line";
        ExpensePolicy: Record "Expense Policy";
        ExpensePolicyFlag: Record "Expense Policy Flag";
    begin
        // [SCENARIO] A flag stamped at the evaluated version makes the report line report Flagged.
        Initialize();
        CreateTestReportLine(ExpenseReportLine);
        CreateTestPolicy(ExpensePolicy, ExpenseReportLine."Expense Category", 'No alcohol on company expenses.');

        // [WHEN] A flag is added and the line is then marked evaluated.
        AddFlag(ExpensePolicyFlag, ExpenseReportLine, ExpensePolicy, 'Receipt includes alcohol.');
        ExpenseReportLine.MarkPoliciesEvaluated(ExpenseReportLine."Policy Eval Version");

        // [THEN] The Policy Flags FlowField sees the live flag and the status is Flagged.
        ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");
        Assert.AreEqual("Expense Policy Status"::Flagged, ExpenseReportLine.GetPolicyStatus(), 'An evaluated line with a current-version flag must report Flagged.');
    end;

    [Test]
    procedure FlagValidatedWithSubjectAndPolicyVersion()
    var
        ExpenseReportLine: Record "Expense Report Line";
        ExpensePolicy: Record "Expense Policy";
        ExpensePolicyFlag: Record "Expense Policy Flag";
    begin
        // [SCENARIO] OnInsert accepts the subject and policy versions returned to the evaluator
        //            when they still match the current records.
        Initialize();
        CreateTestReportLine(ExpenseReportLine);
        CreateTestPolicy(ExpensePolicy, ExpenseReportLine."Expense Category", 'Policy text.');

        // [GIVEN] The line is evaluated then invalidated once so Policy Eval Version is 1 (not the trivial 0).
        ExpenseReportLine.MarkPoliciesEvaluated(ExpenseReportLine."Policy Eval Version");
        ExpenseReportLine.InvalidatePolicyEvaluation();
        ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");

        // [GIVEN] The policy is modified once so its Version is 1 (not the trivial 0).
        ExpensePolicy."Policy Text" := 'Policy text v2.';
        ExpensePolicy.Modify(true);

        // [WHEN] A flag is inserted.
        AddFlag(ExpensePolicyFlag, ExpenseReportLine, ExpensePolicy, 'Some violation.');

        // [THEN] Subject Version equals the line's Policy Eval Version and Policy Version equals the policy's Version.
        Assert.AreEqual(ExpenseReportLine."Policy Eval Version", ExpensePolicyFlag."Subject Version", 'The flag Subject Version must match the line Policy Eval Version at insert.');
        Assert.AreEqual(1, ExpensePolicyFlag."Subject Version", 'Policy Eval Version was 1 at insert, so the flag Subject Version must be 1.');
        Assert.AreEqual(ExpensePolicy."Version", ExpensePolicyFlag."Policy Version", 'The flag Policy Version must match the policy Version at insert.');
        Assert.AreEqual(1, ExpensePolicyFlag."Policy Version", 'The policy was modified once, so the flag Policy Version must be 1.');
    end;

    [Test]
    procedure FlagInsertRejectsChangedReportLineVersion()
    var
        ExpenseReportLine: Record "Expense Report Line";
        ExpensePolicy: Record "Expense Policy";
        ExpensePolicyFlag: Record "Expense Policy Flag";
        EvaluatedSubjectVersion: Integer;
    begin
        // [SCENARIO] A policy result is rejected when its expense line changed during evaluation.
        Initialize();
        CreateTestReportLine(ExpenseReportLine);
        CreateTestPolicy(ExpensePolicy, ExpenseReportLine."Expense Category", 'Policy text.');
        EvaluatedSubjectVersion := ExpenseReportLine."Policy Eval Version";

        ExpenseReportLine."Merchant Name" := 'Changed after evaluation started';
        ExpenseReportLine.Modify(true);

        ExpensePolicyFlag.Init();
        ExpensePolicyFlag."Subject System Id" := ExpenseReportLine.SystemId;
        ExpensePolicyFlag."Subject Type" := "Expense Policy Subject"::"Expense Report Line";
        ExpensePolicyFlag."Subject Version" := EvaluatedSubjectVersion;
        ExpensePolicyFlag."Policy System Id" := ExpensePolicy.SystemId;
        ExpensePolicyFlag."Policy Version" := ExpensePolicy."Version";

        asserterror ExpensePolicyFlag.Insert(true);
        Assert.ExpectedError('expense report line changed after policy evaluation started');
    end;

    [Test]
    procedure FlagInsertRejectsChangedPolicyVersion()
    var
        ExpenseReportLine: Record "Expense Report Line";
        ExpensePolicy: Record "Expense Policy";
        ExpensePolicyFlag: Record "Expense Policy Flag";
        EvaluatedPolicyVersion: Integer;
    begin
        // [SCENARIO] A policy result is rejected when its policy changed during evaluation.
        Initialize();
        CreateTestReportLine(ExpenseReportLine);
        CreateTestPolicy(ExpensePolicy, ExpenseReportLine."Expense Category", 'Policy text.');
        EvaluatedPolicyVersion := ExpensePolicy."Version";

        ExpensePolicy."Policy Text" := 'Changed after evaluation started.';
        ExpensePolicy.Modify(true);

        ExpensePolicyFlag.Init();
        ExpensePolicyFlag."Subject System Id" := ExpenseReportLine.SystemId;
        ExpensePolicyFlag."Subject Type" := "Expense Policy Subject"::"Expense Report Line";
        ExpensePolicyFlag."Subject Version" := ExpenseReportLine."Policy Eval Version";
        ExpensePolicyFlag."Policy System Id" := ExpensePolicy.SystemId;
        ExpensePolicyFlag."Policy Version" := EvaluatedPolicyVersion;

        asserterror ExpensePolicyFlag.Insert(true);
        Assert.ExpectedError('expense policy changed after policy evaluation started');
    end;

    [Test]
    procedure FlagIsCurrentUntilPolicyChanges()
    var
        ExpenseReportLine: Record "Expense Report Line";
        ExpensePolicy: Record "Expense Policy";
        ExpensePolicyFlag: Record "Expense Policy Flag";
    begin
        // [SCENARIO] A flag reports Is Current while its stored Policy Version matches the live policy,
        //            and stops being current once the policy is modified.
        Initialize();
        CreateTestReportLine(ExpenseReportLine);
        CreateTestPolicy(ExpensePolicy, ExpenseReportLine."Expense Category", 'Policy text.');

        // [GIVEN] A flag captured against the current policy version.
        AddFlag(ExpensePolicyFlag, ExpenseReportLine, ExpensePolicy, 'Some violation.');

        // [THEN] The flag is current.
        ExpensePolicyFlag.CalcFields("Is Current");
        Assert.IsTrue(ExpensePolicyFlag."Is Current", 'A freshly captured flag must be current.');

        // [WHEN] The underlying policy changes (its Version bumps).
        ExpensePolicy."Policy Text" := 'Policy text v2.';
        ExpensePolicy.Modify(true);

        // [THEN] The flag captured against the older policy version is no longer current.
        ExpensePolicyFlag.CalcFields("Is Current");
        Assert.IsFalse(ExpensePolicyFlag."Is Current", 'A flag captured against an older policy version must not be current.');
    end;

    [Test]
    procedure FlagStampedWithPolicyTextAndTimestamp()
    var
        ExpenseReportLine: Record "Expense Report Line";
        ExpensePolicy: Record "Expense Policy";
        ExpensePolicyFlag: Record "Expense Policy Flag";
        PolicyText: Text[2048];
    begin
        // [SCENARIO] OnInsert copies the linked policy's text and category onto the flag and stamps Flagged At.
        Initialize();
        CreateTestReportLine(ExpenseReportLine);
        PolicyText := 'Meals over 50 require an itemized receipt.';
        CreateTestPolicy(ExpensePolicy, ExpenseReportLine."Expense Category", PolicyText);

        // [WHEN] A flag is inserted for that policy.
        AddFlag(ExpensePolicyFlag, ExpenseReportLine, ExpensePolicy, 'Missing itemized receipt.');

        // [THEN] Policy Text and Expense Category Code are copied from the policy and Flagged At is set.
        Assert.AreEqual(PolicyText, ExpensePolicyFlag."Policy Text", 'The flag must copy the Policy Text from the linked policy.');
        Assert.AreEqual(ExpensePolicy."Expense Category Code", ExpensePolicyFlag."Expense Category Code", 'The flag must copy the Expense Category Code from the linked policy.');
        Assert.AreNotEqual(0DT, ExpensePolicyFlag."Flagged At", 'Flagged At must be stamped on insert.');
    end;

    [Test]
    procedure FlagInsertOverwritesCallerTimestamp()
    var
        ExpenseReportLine: Record "Expense Report Line";
        ExpensePolicy: Record "Expense Policy";
        ExpensePolicyFlag: Record "Expense Policy Flag";
        CallerTimestamp: DateTime;
    begin
        // [SCENARIO] The server owns the policy flag audit timestamp.
        Initialize();
        CreateTestReportLine(ExpenseReportLine);
        CreateTestPolicy(ExpensePolicy, ExpenseReportLine."Expense Category", 'Policy text.');
        CallerTimestamp := CreateDateTime(DMY2Date(1, 1, 2000), 0T);

        ExpensePolicyFlag.Init();
        ExpensePolicyFlag."Subject System Id" := ExpenseReportLine.SystemId;
        ExpensePolicyFlag."Subject Type" := "Expense Policy Subject"::"Expense Report Line";
        ExpensePolicyFlag."Subject Version" := ExpenseReportLine."Policy Eval Version";
        ExpensePolicyFlag."Policy System Id" := ExpensePolicy.SystemId;
        ExpensePolicyFlag."Policy Version" := ExpensePolicy."Version";
        ExpensePolicyFlag."Flagged At" := CallerTimestamp;
        ExpensePolicyFlag.Insert(true);

        Assert.AreNotEqual(CallerTimestamp, ExpensePolicyFlag."Flagged At", 'The server must overwrite a caller-supplied Flagged At value.');
        Assert.AreNotEqual(0DT, ExpensePolicyFlag."Flagged At", 'The server-generated Flagged At value must not be blank.');
    end;

    [Test]
    procedure StaleFlagHiddenAfterReevaluation()
    var
        ExpenseReportLine: Record "Expense Report Line";
        ExpensePolicy: Record "Expense Policy";
        ExpensePolicyFlag: Record "Expense Policy Flag";
    begin
        // [SCENARIO] A flag from an earlier version is not seen after a re-evaluation at a higher version,
        //            yet the flag row is preserved as history.
        Initialize();
        CreateTestReportLine(ExpenseReportLine);
        CreateTestPolicy(ExpensePolicy, ExpenseReportLine."Expense Category", 'Policy text.');

        // [GIVEN] An evaluated, flagged line at version 1.
        AddFlag(ExpensePolicyFlag, ExpenseReportLine, ExpensePolicy, 'Old violation.');
        ExpenseReportLine.MarkPoliciesEvaluated(ExpenseReportLine."Policy Eval Version");
        ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");
        Assert.AreEqual("Expense Policy Status"::Flagged, ExpenseReportLine.GetPolicyStatus(), 'Precondition: the line should be Flagged at version 1.');

        // [WHEN] A relevant change bumps the version and the line is re-evaluated with no new flags.
        ExpenseReportLine."Merchant Name" := 'Contoso Merchant (policy-relevant change)';
        ExpenseReportLine.Modify(true);
        ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");
        ExpenseReportLine.MarkPoliciesEvaluated(ExpenseReportLine."Policy Eval Version");
        ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");

        // [THEN] The version-1 flag is no longer live (status Cleared) but the row still exists.
        Assert.AreEqual("Expense Policy Status"::Cleared, ExpenseReportLine.GetPolicyStatus(), 'A flag from an older version must not be seen after re-evaluation.');
        ExpensePolicyFlag.SetRange("Subject System Id", ExpenseReportLine.SystemId);
        Assert.RecordCount(ExpensePolicyFlag, 1);
    end;

    [Test]
    procedure NewFlagSeenAfterReevaluationAtHigherVersion()
    var
        ExpenseReportLine: Record "Expense Report Line";
        ExpensePolicy: Record "Expense Policy";
        ExpensePolicyFlag: Record "Expense Policy Flag";
    begin
        // [SCENARIO] After a version bump and re-evaluation, a new flag stamped at the new version is seen,
        //            and both the old and new flag rows coexist as history.
        Initialize();
        CreateTestReportLine(ExpenseReportLine);
        CreateTestPolicy(ExpensePolicy, ExpenseReportLine."Expense Category", 'Policy text.');

        // [GIVEN] An evaluated, flagged line at version 1.
        AddFlag(ExpensePolicyFlag, ExpenseReportLine, ExpensePolicy, 'Version 1 violation.');
        ExpenseReportLine.MarkPoliciesEvaluated(ExpenseReportLine."Policy Eval Version");
        ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");

        // [WHEN] A relevant field change bumps the version, a new flag is stamped at version 2, then re-evaluated.
        ExpenseReportLine."Merchant Name" := 'Contoso Merchant (policy-relevant change)';
        ExpenseReportLine.Modify(true);
        ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");
        AddFlag(ExpensePolicyFlag, ExpenseReportLine, ExpensePolicy, 'Version 2 violation.');
        ExpenseReportLine.MarkPoliciesEvaluated(ExpenseReportLine."Policy Eval Version");
        ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");

        // [THEN] The line is Flagged (the version-2 flag is live) and both flag rows are preserved.
        Assert.AreEqual("Expense Policy Status"::Flagged, ExpenseReportLine.GetPolicyStatus(), 'The version-2 flag must be seen after re-evaluation.');
        ExpensePolicyFlag.SetRange("Subject System Id", ExpenseReportLine.SystemId);
        Assert.RecordCount(ExpensePolicyFlag, 2);
    end;

    [Test]
    procedure CompliantFlagLeavesLineCleared()
    var
        ExpenseReportLine: Record "Expense Report Line";
        ExpensePolicy: Record "Expense Policy";
        ExpensePolicyFlag: Record "Expense Policy Flag";
    begin
        // [SCENARIO] A good-to-go (compliant) flag is not a violation, so the line stays Cleared.
        Initialize();
        CreateTestReportLine(ExpenseReportLine);
        CreateTestPolicy(ExpensePolicy, ExpenseReportLine."Expense Category", 'No alcohol on company expenses.');

        // [WHEN] A compliant verdict is recorded and the line is marked evaluated.
        AddCompliantFlag(ExpensePolicyFlag, ExpenseReportLine, ExpensePolicy, 'No alcohol found - compliant.');
        ExpenseReportLine.MarkPoliciesEvaluated(ExpenseReportLine."Policy Eval Version");

        // [THEN] Has Policy Violation is false and the line reports Cleared.
        ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");
        ExpenseReportLine.CalcFields("Has Policy Violation");
        Assert.IsFalse(ExpenseReportLine."Has Policy Violation", 'A compliant flag must not raise Has Policy Violation.');
        Assert.AreEqual("Expense Policy Status"::Cleared, ExpenseReportLine.GetPolicyStatus(), 'An evaluated line with only compliant flags must report Cleared.');
    end;

    [Test]
    procedure ViolationAmongCompliantFlagsFlagsLine()
    var
        ExpenseReportLine: Record "Expense Report Line";
        ExpensePolicyA: Record "Expense Policy";
        ExpensePolicyB: Record "Expense Policy";
        ExpensePolicyFlag: Record "Expense Policy Flag";
    begin
        // [SCENARIO] With one compliant and one violation verdict at the same version, the line is Flagged.
        Initialize();
        CreateTestReportLine(ExpenseReportLine);
        CreateTestPolicy(ExpensePolicyA, ExpenseReportLine."Expense Category", 'No alcohol on company expenses.');
        CreateTestPolicy(ExpensePolicyB, ExpenseReportLine."Expense Category", 'Meals over 50 require an itemized receipt.');

        // [WHEN] Policy A passes and Policy B is violated, then the line is marked evaluated.
        AddCompliantFlag(ExpensePolicyFlag, ExpenseReportLine, ExpensePolicyA, 'No alcohol found - compliant.');
        AddFlag(ExpensePolicyFlag, ExpenseReportLine, ExpensePolicyB, 'Missing itemized receipt.');
        ExpenseReportLine.MarkPoliciesEvaluated(ExpenseReportLine."Policy Eval Version");

        // [THEN] Has Policy Violation is true and the line reports Flagged.
        ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");
        ExpenseReportLine.CalcFields("Has Policy Violation");
        Assert.IsTrue(ExpenseReportLine."Has Policy Violation", 'A single violation among compliant flags must raise Has Policy Violation.');
        Assert.AreEqual("Expense Policy Status"::Flagged, ExpenseReportLine.GetPolicyStatus(), 'A line with any violation flag must report Flagged.');
    end;

    [Test]
    procedure AddingPolicyForCategoryMakesEvaluatedLineStale()
    var
        ExpenseReportLine: Record "Expense Report Line";
        ExpensePolicy: Record "Expense Policy";
    begin
        // [SCENARIO] Adding a policy for a category invalidates lines of that category that were already evaluated.
        Initialize();
        CreateTestReportLine(ExpenseReportLine);
        ExpenseReportLine.MarkPoliciesEvaluated(ExpenseReportLine."Policy Eval Version");
        ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");
        Assert.AreEqual("Expense Policy Status"::"No Policies", ExpenseReportLine.GetPolicyStatus(), 'Precondition: with no policy yet the line reports No Policies.');

        // [WHEN] A policy is added for the line's category.
        CreateTestPolicy(ExpensePolicy, ExpenseReportLine."Expense Category", 'No alcohol on company expenses.');

        // [THEN] The evaluated line is invalidated and reports Stale.
        ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");
        Assert.AreEqual(1, ExpenseReportLine."Policy Eval Version", 'Adding a policy for the category must bump the evaluated line.');
        Assert.AreEqual("Expense Policy Status"::Stale, ExpenseReportLine.GetPolicyStatus(), 'Adding a policy for the category must leave the evaluated line Stale.');
    end;

    [Test]
    procedure ChangingPolicyMakesEvaluatedLineStale()
    var
        ExpenseReportLine: Record "Expense Report Line";
        ExpensePolicy: Record "Expense Policy";
    begin
        // [SCENARIO] Modifying an existing policy invalidates already-evaluated lines of its category.
        Initialize();
        CreateTestReportLine(ExpenseReportLine);
        CreateTestPolicy(ExpensePolicy, ExpenseReportLine."Expense Category", 'No alcohol on company expenses.');

        // [GIVEN] The line is evaluated (Cleared) after the policy already exists.
        ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");
        ExpenseReportLine.MarkPoliciesEvaluated(ExpenseReportLine."Policy Eval Version");
        ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");
        Assert.AreEqual("Expense Policy Status"::Cleared, ExpenseReportLine.GetPolicyStatus(), 'Precondition: the line should be Cleared.');

        // [WHEN] The policy text changes (bumping its version).
        ExpensePolicy."Policy Text" := 'No alcohol and no minibar on company expenses.';
        ExpensePolicy.Modify(true);

        // [THEN] The evaluated line is invalidated and reports Stale.
        ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");
        Assert.AreEqual(1, ExpenseReportLine."Policy Eval Version", 'The first policy change must advance the line version.');
        Assert.AreEqual("Expense Policy Status"::Stale, ExpenseReportLine.GetPolicyStatus(), 'Changing a policy must leave the evaluated line Stale.');

        // [WHEN] The policy changes again while the line is already stale.
        ExpensePolicy."Policy Text" := 'No alcohol, minibar, or room service alcohol.';
        ExpensePolicy.Modify(true);

        // [THEN] The second change receives another distinct line version.
        ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");
        Assert.AreEqual(2, ExpenseReportLine."Policy Eval Version", 'Each policy change must advance the line version.');
    end;

    [Test]
    procedure DeletingPolicyMakesEvaluatedLineStale()
    var
        ExpenseReportLine: Record "Expense Report Line";
        ExpensePolicy: Record "Expense Policy";
        ExpensePolicyFlag: Record "Expense Policy Flag";
    begin
        // [SCENARIO] Deleting a policy invalidates already-evaluated lines of its category, and any
        // flag left behind for the removed policy is no longer current.
        Initialize();
        CreateTestReportLine(ExpenseReportLine);
        CreateTestPolicy(ExpensePolicy, ExpenseReportLine."Expense Category", 'No alcohol on company expenses.');

        // [GIVEN] The line is evaluated with a flag for the policy.
        ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");
        AddFlag(ExpensePolicyFlag, ExpenseReportLine, ExpensePolicy, 'Alcohol flagged');
        ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");
        ExpenseReportLine.MarkPoliciesEvaluated(ExpenseReportLine."Policy Eval Version");

        // [WHEN] The policy is deleted.
        ExpensePolicy.Delete(true);

        // [THEN] The evaluated line is invalidated and reports Stale.
        ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");
        Assert.AreEqual("Expense Policy Status"::Stale, ExpenseReportLine.GetPolicyStatus(), 'Deleting a policy must leave the evaluated line Stale.');

        // [THEN] The orphaned flag is kept as history but is no longer current.
        ExpensePolicyFlag.Get(ExpensePolicyFlag."Subject Type", ExpensePolicyFlag."Subject System Id", ExpensePolicyFlag."Policy System Id", ExpensePolicyFlag."Subject Version", ExpensePolicyFlag."Policy Version");
        ExpensePolicyFlag.CalcFields("Is Current");
        Assert.IsFalse(ExpensePolicyFlag."Is Current", 'A flag for a deleted policy must not be current.');
    end;

    [Test]
    procedure PolicyChangeLeavesOtherCategoryLineUntouched()
    var
        ExpenseReportLine: Record "Expense Report Line";
        ExpensePolicy: Record "Expense Policy";
    begin
        // [SCENARIO] A policy for one category does not invalidate lines of a different category.
        Initialize();
        CreateTestReportLine(ExpenseReportLine);
        ExpenseReportLine.MarkPoliciesEvaluated(ExpenseReportLine."Policy Eval Version");
        ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");

        // [WHEN] A policy is added for a different category than the line's.
        CreateTestPolicy(ExpensePolicy, CopyStr(ExpenseReportLine."Expense Category" + 'X', 1, 20), 'Unrelated policy.');

        // [THEN] The line for the original category has no applicable policy, so it reports No Policies (not staled).
        ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");
        Assert.AreEqual("Expense Policy Status"::"No Policies", ExpenseReportLine.GetPolicyStatus(), 'A policy for another category must not invalidate this line.');
    end;

    [Test]
    procedure MovingPolicyToAnotherCategoryStalesOldCategoryLine()
    var
        ExpenseReportLine: Record "Expense Report Line";
        ExpensePolicy: Record "Expense Policy";
        OtherCategory: Record "Expense Category";
    begin
        // [SCENARIO] Moving a policy to a different category invalidates the lines in the policy's
        //            previous category, not only the new one. Otherwise those lines keep a verdict
        //            from a policy that no longer applies to them and stay incorrectly Current.
        Initialize();
        CreateTestReportLine(ExpenseReportLine);

        // [GIVEN] A policy for the line's category and the line evaluated (Cleared, no flags).
        CreateTestPolicy(ExpensePolicy, ExpenseReportLine."Expense Category", 'No alcohol on company expenses.');
        ExpenseReportLine.MarkPoliciesEvaluated(ExpenseReportLine."Policy Eval Version");
        ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");
        Assert.AreEqual("Expense Policy Status"::Cleared, ExpenseReportLine.GetPolicyStatus(), 'Precondition: the evaluated line should be Cleared.');

        // [WHEN] The policy is moved to a different category.
        LibraryExpense.CreateExpenseCategory(OtherCategory, OtherCategory."Reimbursement Type"::"Employee Paid", "Expense Detail Needed"::" ", '');
        ExpensePolicy."Expense Category Code" := OtherCategory.Code;
        ExpensePolicy.Modify(true);

        // [THEN] The line in the policy's OLD category is invalidated and reports Stale.
        ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");
        Assert.AreEqual("Expense Policy Status"::Stale, ExpenseReportLine.GetPolicyStatus(), 'Moving a policy out of the line''s category must invalidate the line in the old category.');
    end;

    [Test]
    procedure SupersededFlagDoesNotKeepLineFlagged()
    var
        ExpenseReportLine: Record "Expense Report Line";
        ExpensePolicy: Record "Expense Policy";
        ExpensePolicyFlag: Record "Expense Policy Flag";
    begin
        // [SCENARIO] A non-compliant flag whose captured Policy Version no longer matches the live
        //            policy (Is Current = false) must not keep an up-to-date line Flagged. The normal
        //            trigger flow always re-stales a line when its applicable policy changes, so this
        //            superseded-flag-on-a-current-line state is forced with a raw insert to isolate the
        //            currency check in HasCurrentPolicyViolation (defense in depth).
        Initialize();
        CreateTestReportLine(ExpenseReportLine);
        CreateTestPolicy(ExpensePolicy, ExpenseReportLine."Expense Category", 'No alcohol on company expenses.');

        // [GIVEN] A non-compliant flag stamped at the line's version but against a superseded policy
        //         version (Policy Version ahead of the live policy), inserted raw to bypass the strict
        //         OnInsert snapshot.
        ExpensePolicyFlag.Init();
        ExpensePolicyFlag."Subject System Id" := ExpenseReportLine.SystemId;
        ExpensePolicyFlag."Subject Type" := "Expense Policy Subject"::"Expense Report Line";
        ExpensePolicyFlag."Subject Version" := ExpenseReportLine."Policy Eval Version";
        ExpensePolicyFlag."Policy System Id" := ExpensePolicy.SystemId;
        ExpensePolicyFlag."Policy Version" := ExpensePolicy."Version" + 1;
        ExpensePolicyFlag."Compliant" := false;
        ExpensePolicyFlag.Insert(false);

        ExpensePolicyFlag.CalcFields("Is Current");
        Assert.IsFalse(ExpensePolicyFlag."Is Current", 'Precondition: the flag must be non-current.');

        // [WHEN] The line is marked evaluated so its status is read from flags.
        ExpenseReportLine.MarkPoliciesEvaluated(ExpenseReportLine."Policy Eval Version");
        ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");

        // [THEN] The superseded flag does not count as a violation; the line reports Cleared.
        Assert.AreEqual("Expense Policy Status"::Cleared, ExpenseReportLine.GetPolicyStatus(), 'A superseded (non-current) flag must not keep the line Flagged.');
    end;

    [Test]
    procedure FlagInsertRejectsUnknownReportLine()
    var
        ExpenseReportLine: Record "Expense Report Line";
        ExpensePolicy: Record "Expense Policy";
        ExpensePolicyFlag: Record "Expense Policy Flag";
    begin
        // [SCENARIO] A flag whose subject report line does not exist is rejected on insert.
        Initialize();
        CreateTestReportLine(ExpenseReportLine);
        CreateTestPolicy(ExpensePolicy, ExpenseReportLine."Expense Category", 'Policy text.');

        // [WHEN] A flag references a non-existent report line.
        ExpensePolicyFlag.Init();
        ExpensePolicyFlag."Subject System Id" := CreateGuid();
        ExpensePolicyFlag."Subject Type" := "Expense Policy Subject"::"Expense Report Line";
        ExpensePolicyFlag."Policy System Id" := ExpensePolicy.SystemId;

        // [THEN] The insert is rejected.
        asserterror ExpensePolicyFlag.Insert(true);
        Assert.ExpectedError('does not exist');
    end;

    [Test]
    procedure FlagInsertRejectsDisabledPolicy()
    var
        ExpenseReportLine: Record "Expense Report Line";
        ExpensePolicy: Record "Expense Policy";
        ExpensePolicyFlag: Record "Expense Policy Flag";
    begin
        // [SCENARIO] A flag for a disabled policy is rejected on insert.
        Initialize();
        CreateTestReportLine(ExpenseReportLine);
        CreateTestPolicy(ExpensePolicy, ExpenseReportLine."Expense Category", 'Policy text.');

        // [GIVEN] The policy is disabled.
        ExpensePolicy.Validate(Enabled, false);
        ExpensePolicy.Modify(true);

        // [WHEN] A flag references the disabled policy.
        ExpensePolicyFlag.Init();
        ExpensePolicyFlag."Subject System Id" := ExpenseReportLine.SystemId;
        ExpensePolicyFlag."Subject Type" := "Expense Policy Subject"::"Expense Report Line";
        ExpensePolicyFlag."Policy System Id" := ExpensePolicy.SystemId;

        // [THEN] The insert is rejected.
        asserterror ExpensePolicyFlag.Insert(true);
        Assert.ExpectedError('disabled policy');
    end;

    [Test]
    procedure FlagInsertRejectsInapplicablePolicy()
    var
        ExpenseReportLine: Record "Expense Report Line";
        ExpensePolicy: Record "Expense Policy";
        ExpensePolicyFlag: Record "Expense Policy Flag";
        OtherCategory: Record "Expense Category";
    begin
        // [SCENARIO] A flag for a policy that does not apply to the line's category is rejected.
        Initialize();
        CreateTestReportLine(ExpenseReportLine);
        LibraryExpense.CreateExpenseCategory(OtherCategory, OtherCategory."Reimbursement Type"::"Employee Paid", "Expense Detail Needed"::" ", '');
        CreateTestPolicy(ExpensePolicy, OtherCategory.Code, 'Policy for another category.');

        // [WHEN] A flag references the other-category policy for this line.
        ExpensePolicyFlag.Init();
        ExpensePolicyFlag."Subject System Id" := ExpenseReportLine.SystemId;
        ExpensePolicyFlag."Subject Type" := "Expense Policy Subject"::"Expense Report Line";
        ExpensePolicyFlag."Policy System Id" := ExpensePolicy.SystemId;

        // [THEN] The insert is rejected.
        asserterror ExpensePolicyFlag.Insert(true);
        Assert.ExpectedError('does not apply');
    end;

    [Test]
    procedure DeletingReportLineRemovesFlags()
    var
        ExpenseReportLine: Record "Expense Report Line";
        ExpensePolicy: Record "Expense Policy";
        ExpensePolicyFlag: Record "Expense Policy Flag";
    begin
        // [SCENARIO] Deleting a report line removes its policy flags so none are orphaned.
        Initialize();
        CreateTestReportLine(ExpenseReportLine);
        CreateTestPolicy(ExpensePolicy, ExpenseReportLine."Expense Category", 'Policy text.');
        AddFlag(ExpensePolicyFlag, ExpenseReportLine, ExpensePolicy, 'Some violation.');

        // [GIVEN] Precondition: a flag exists for the line.
        ExpensePolicyFlag.SetRange("Subject System Id", ExpenseReportLine.SystemId);
        Assert.RecordCount(ExpensePolicyFlag, 1);

        // [WHEN] The report line is deleted.
        ExpenseReportLine.Delete(true);

        // [THEN] The flag is gone.
        ExpensePolicyFlag.SetRange("Subject System Id", ExpenseReportLine.SystemId);
        Assert.RecordIsEmpty(ExpensePolicyFlag);
    end;

    // --- Child-record invalidation -----------------------------------------------------------

    [Test]
    procedure AddingParticipantInvalidatesParent()
    var
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseReportLineParticip: Record "Expense Report Line Particip.";
    begin
        // [SCENARIO] Inserting a child participant invalidates the parent line's evaluation.
        Initialize();
        CreateTestReportLine(ExpenseReportLine);
        ExpenseReportLine.MarkPoliciesEvaluated(ExpenseReportLine."Policy Eval Version");
        ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");
        Assert.AreEqual("Expense Policy Status"::"No Policies", ExpenseReportLine.GetPolicyStatus(), 'Precondition: with no policy the line reports No Policies.');

        // [WHEN] A participant is added to the line.
        CreateReportLineParticipant(ExpenseReportLineParticip, ExpenseReportLine);

        // [THEN] The parent's Policy Eval Version is bumped and the status becomes Stale.
        ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");
        Assert.AreEqual(1, ExpenseReportLine."Policy Eval Version", 'Adding a child participant must invalidate (bump) the parent.');
        Assert.AreEqual("Expense Policy Status"::Stale, ExpenseReportLine.GetPolicyStatus(), 'A child insert after evaluation must leave the parent Stale.');
    end;

    [Test]
    procedure AddingParticipantWhileStaleAdvancesVersionAgain()
    var
        ExpenseReportLine: Record "Expense Report Line";
        FirstParticipant: Record "Expense Report Line Particip.";
        SecondParticipant: Record "Expense Report Line Particip.";
    begin
        // [SCENARIO] A second child change advances the version even while the parent is already stale.
        Initialize();
        CreateTestReportLine(ExpenseReportLine);
        ExpenseReportLine.MarkPoliciesEvaluated(ExpenseReportLine."Policy Eval Version");

        CreateReportLineParticipant(FirstParticipant, ExpenseReportLine);
        CreateReportLineParticipant(SecondParticipant, ExpenseReportLine);

        ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");
        Assert.AreEqual(2, ExpenseReportLine."Policy Eval Version", 'Each child insert must advance the parent policy version.');
        Assert.AreEqual("Expense Policy Status"::Stale, ExpenseReportLine.GetPolicyStatus(), 'Repeated child changes must leave the parent Stale.');
    end;

    [Test]
    procedure DeletingParticipantInvalidatesParent()
    var
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseReportLineParticip: Record "Expense Report Line Particip.";
    begin
        // [SCENARIO] Deleting a child participant invalidates the parent line's evaluation.
        Initialize();
        CreateTestReportLine(ExpenseReportLine);
        CreateReportLineParticipant(ExpenseReportLineParticip, ExpenseReportLine);
        ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");
        ExpenseReportLine.MarkPoliciesEvaluated(ExpenseReportLine."Policy Eval Version");
        ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");

        // [WHEN] The participant is deleted.
        ExpenseReportLineParticip.Delete(true);

        // [THEN] The parent is invalidated and reports Stale.
        ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");
        Assert.AreEqual("Expense Policy Status"::Stale, ExpenseReportLine.GetPolicyStatus(), 'Deleting a child participant must invalidate the parent.');
    end;

    [Test]
    procedure AddingItemizationInvalidatesParent()
    var
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseReportLineItemization: Record "Expense Report Line Item";
        ExpenseSubcategory: Record "Expense Subcategory";
    begin
        // [SCENARIO] Inserting a child itemization invalidates the parent line's evaluation.
        Initialize();
        CreateTestReportLine(ExpenseReportLine);
        ExpenseReportLine.MarkPoliciesEvaluated(ExpenseReportLine."Policy Eval Version");
        ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");

        // [WHEN] An itemization is added to the line.
        LibraryExpense.CreateExpenseSubCategory(ExpenseSubcategory, ExpenseReportLine."Expense Category", true);
        LibraryExpense.CreateExpenseReportLineItemization(ExpenseReportLineItemization, ExpenseReportLine, ExpenseReportLine."Expense Category", ExpenseSubcategory.Code, WorkDate(), LibraryRandom.RandIntInRange(10, 100), 1);

        // [THEN] The parent is invalidated and reports Stale.
        ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");
        Assert.AreEqual(1, ExpenseReportLine."Policy Eval Version", 'Adding a child itemization must invalidate (bump) the parent.');
        Assert.AreEqual("Expense Policy Status"::Stale, ExpenseReportLine.GetPolicyStatus(), 'A child itemization insert after evaluation must leave the parent Stale.');
    end;

    [Test]
    procedure AddingPerDiemInvalidatesParent()
    var
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseReportLinePerDiem: Record "Expense Report Line Per Diem";
        ExpenseSubcategory: Record "Expense Subcategory";
    begin
        // [SCENARIO] Inserting a child per diem invalidates the parent line's evaluation.
        Initialize();
        CreateTestReportLine(ExpenseReportLine);
        ExpenseReportLine.MarkPoliciesEvaluated(ExpenseReportLine."Policy Eval Version");
        ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");

        // [WHEN] A per diem is added to the line.
        LibraryExpense.CreateExpenseSubCategory(ExpenseSubcategory, ExpenseReportLine."Expense Category", true);
        LibraryExpense.CreateExpenseReportLinePerDiem(ExpenseReportLinePerDiem, ExpenseReportLine, ExpenseReportLine."Expense Category", ExpenseSubcategory.Code, '', WorkDate(), true, true, true, LibraryRandom.RandIntInRange(10, 100));

        // [THEN] The parent is invalidated and reports Stale.
        ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");
        Assert.AreEqual(1, ExpenseReportLine."Policy Eval Version", 'Adding a child per diem must invalidate (bump) the parent.');
        Assert.AreEqual("Expense Policy Status"::Stale, ExpenseReportLine.GetPolicyStatus(), 'A child per diem insert after evaluation must leave the parent Stale.');
    end;

    // --- Policies to evaluate endpoint ------------------------------------------------------

    [Test]
    procedure PoliciesToEvaluateListsApplicableUnevaluatedPolicies()
    var
        ExpenseReportLine: Record "Expense Report Line";
        MatchingPolicy: Record "Expense Policy";
        BlankCategoryPolicy: Record "Expense Policy";
        OtherCategoryPolicy: Record "Expense Policy";
        OtherCategory: Record "Expense Category";
        TempPolicyToEval: Record "Exp. Policy To Eval Buffer" temporary;
        Builder: Codeunit "Exp. Policies To Eval Builder";
    begin
        // [SCENARIO] The endpoint returns the enabled policies applicable to a line (its category or blank), excluding other categories.
        Initialize();
        CreateTestReportLine(ExpenseReportLine);

        // [GIVEN] A policy for the line's category, a blank-category policy, and a policy for a different category.
        CreateTestPolicy(MatchingPolicy, ExpenseReportLine."Expense Category", 'Matches the line category');
        CreateTestPolicy(BlankCategoryPolicy, '', 'Applies to every category');
        LibraryExpense.CreateExpenseCategory(OtherCategory, OtherCategory."Reimbursement Type"::"Employee Paid", "Expense Detail Needed"::" ", '');
        CreateTestPolicy(OtherCategoryPolicy, OtherCategory.Code, 'Belongs to another category');

        // [WHEN] The policies-to-evaluate set is built for the line.
        Builder.Build(TempPolicyToEval, Format(ExpenseReportLine.SystemId));

        // [THEN] Only the matching and blank-category policies are returned.
        Assert.AreEqual(2, TempPolicyToEval.Count(), 'Only the applicable policies must be returned.');
        Assert.IsTrue(TempPolicyToEval.Get(ExpenseReportLine.SystemId, MatchingPolicy.SystemId), 'The matching-category policy must be listed.');
        Assert.IsTrue(TempPolicyToEval.Get(ExpenseReportLine.SystemId, BlankCategoryPolicy.SystemId), 'The blank-category policy must be listed.');
        Assert.IsFalse(TempPolicyToEval.Get(ExpenseReportLine.SystemId, OtherCategoryPolicy.SystemId), 'A different-category policy must not be listed.');
    end;

    [Test]
    procedure PoliciesToEvaluateExcludesCurrentlyFlaggedButReturnsAfterVersionBump()
    var
        ExpenseReportLine: Record "Expense Report Line";
        ExpensePolicy: Record "Expense Policy";
        ExpensePolicyFlag: Record "Expense Policy Flag";
        TempPolicyToEval: Record "Exp. Policy To Eval Buffer" temporary;
        Builder: Codeunit "Exp. Policies To Eval Builder";
    begin
        // [SCENARIO] A policy already flagged at the current versions is excluded, but returns once the policy is bumped to a new version.
        Initialize();
        CreateTestReportLine(ExpenseReportLine);
        CreateTestPolicy(ExpensePolicy, ExpenseReportLine."Expense Category", 'Original policy text');

        // [GIVEN] A flag exists for the line at the current subject and policy version.
        ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");
        AddFlag(ExpensePolicyFlag, ExpenseReportLine, ExpensePolicy, 'Already evaluated');

        // [WHEN] The set is built.
        Builder.Build(TempPolicyToEval, Format(ExpenseReportLine.SystemId));

        // [THEN] The freshly evaluated policy is not returned.
        Assert.IsFalse(TempPolicyToEval.Get(ExpenseReportLine.SystemId, ExpensePolicy.SystemId), 'A policy already flagged at the current version must not be listed.');

        // [WHEN] The policy is changed, bumping its version.
        ExpensePolicy.Get(ExpensePolicy."Subject Type", ExpensePolicy."Line No.");
        ExpensePolicy."Policy Text" := 'Updated policy text';
        ExpensePolicy.Modify(true);
        Builder.Build(TempPolicyToEval, Format(ExpenseReportLine.SystemId));

        // [THEN] The updated policy is listed again as needing evaluation.
        Assert.IsTrue(TempPolicyToEval.Get(ExpenseReportLine.SystemId, ExpensePolicy.SystemId), 'A policy bumped to a new version must be listed for re-evaluation.');
    end;

    // --- Status of never-evaluated lines -----------------------------------------------------

    [Test]
    procedure OutstandingPolicyIsDetectedUntilFlagged()
    var
        ExpenseReportLine: Record "Expense Report Line";
        ExpensePolicy: Record "Expense Policy";
        ExpensePolicyFlag: Record "Expense Policy Flag";
        Builder: Codeunit "Exp. Policies To Eval Builder";
    begin
        // [SCENARIO] HasOutstandingPolicies (the mark-evaluated guard) reports true while an applicable
        //            policy has no verdict for the current version, and false once every applicable
        //            policy has a flag.
        Initialize();
        CreateTestReportLine(ExpenseReportLine);

        // [GIVEN] No applicable policy - nothing is outstanding.
        Assert.IsFalse(Builder.HasOutstandingPolicies(ExpenseReportLine), 'A line with no applicable policy has nothing outstanding.');

        // [WHEN] An applicable policy exists but has not been evaluated.
        CreateTestPolicy(ExpensePolicy, ExpenseReportLine."Expense Category", 'Must be evaluated.');

        // [THEN] The policy is outstanding.
        Assert.IsTrue(Builder.HasOutstandingPolicies(ExpenseReportLine), 'An applicable policy without a flag must be outstanding.');

        // [WHEN] A verdict (flag) is recorded for the policy at the current version.
        AddCompliantFlag(ExpensePolicyFlag, ExpenseReportLine, ExpensePolicy, 'Compliant.');

        // [THEN] Nothing is outstanding anymore.
        Assert.IsFalse(Builder.HasOutstandingPolicies(ExpenseReportLine), 'Once every applicable policy has a flag, nothing is outstanding.');
    end;

    [Test]
    procedure UnevaluatedLineWithNoApplicablePoliciesIsNoPolicies()
    var
        ExpenseReportLine: Record "Expense Report Line";
    begin
        // [SCENARIO] A never-evaluated line whose category has no policy reports No Policies, not "Not Evaluated".
        Initialize();

        // [GIVEN] A fresh report line and no policies at all.
        CreateTestReportLine(ExpenseReportLine);
        ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");

        // [THEN] The line reports No Policies because nothing needs to be evaluated against it.
        Assert.AreEqual("Expense Policy Status"::"No Policies", ExpenseReportLine.GetPolicyStatus(), 'A never-evaluated line with no applicable policy must be No Policies.');
    end;

    [Test]
    procedure UnevaluatedLineWithApplicablePolicyIsNotEvaluated()
    var
        ExpenseReportLine: Record "Expense Report Line";
        MatchingPolicy: Record "Expense Policy";
    begin
        // [SCENARIO] A never-evaluated line whose category has an applicable policy is "Not Evaluated".
        Initialize();
        CreateTestReportLine(ExpenseReportLine);

        // [GIVEN] An enabled policy that targets the line's category.
        CreateTestPolicy(MatchingPolicy, ExpenseReportLine."Expense Category", 'Matches the line category');

        // [THEN] The line is "Not Evaluated" because a policy still needs to run against it.
        ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");
        Assert.AreEqual("Expense Policy Status"::"Not Evaluated", ExpenseReportLine.GetPolicyStatus(), 'A never-evaluated line with an applicable policy must be Not Evaluated.');
    end;

    [Test]
    procedure UnevaluatedLineWithBlankCategoryPolicyIsNotEvaluated()
    var
        ExpenseReportLine: Record "Expense Report Line";
        BlankCategoryPolicy: Record "Expense Policy";
    begin
        // [SCENARIO] A blank-category policy applies to every line, so a never-evaluated line is "Not Evaluated".
        Initialize();
        CreateTestReportLine(ExpenseReportLine);

        // [GIVEN] An enabled policy with a blank category (applies to all categories).
        CreateTestPolicy(BlankCategoryPolicy, '', 'Applies to every category');

        // [THEN] The line is "Not Evaluated" because the blank-category policy applies to it.
        ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");
        Assert.AreEqual("Expense Policy Status"::"Not Evaluated", ExpenseReportLine.GetPolicyStatus(), 'A never-evaluated line with a blank-category policy must be Not Evaluated.');
    end;

    [Test]
    procedure UnevaluatedLineWithOnlyOtherCategoryPolicyIsNoPolicies()
    var
        ExpenseReportLine: Record "Expense Report Line";
        OtherCategoryPolicy: Record "Expense Policy";
        OtherCategory: Record "Expense Category";
    begin
        // [SCENARIO] A policy for a different category does not apply, so a never-evaluated line reports No Policies.
        Initialize();
        CreateTestReportLine(ExpenseReportLine);

        // [GIVEN] An enabled policy that targets a different category only.
        LibraryExpense.CreateExpenseCategory(OtherCategory, OtherCategory."Reimbursement Type"::"Employee Paid", "Expense Detail Needed"::" ", '');
        CreateTestPolicy(OtherCategoryPolicy, OtherCategory.Code, 'Belongs to another category');

        // [THEN] The line reports No Policies because no policy targets its category.
        ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");
        Assert.AreEqual("Expense Policy Status"::"No Policies", ExpenseReportLine.GetPolicyStatus(), 'A never-evaluated line with only a different-category policy must be No Policies.');
    end;

    [Test]
    procedure UnevaluatedLineWithDisabledPolicyIsNoPolicies()
    var
        ExpenseReportLine: Record "Expense Report Line";
        DisabledPolicy: Record "Expense Policy";
    begin
        // [SCENARIO] A disabled policy is not applicable, so a never-evaluated line reports No Policies.
        Initialize();
        CreateTestReportLine(ExpenseReportLine);

        // [GIVEN] A policy for the line's category that is disabled.
        CreateTestPolicy(DisabledPolicy, ExpenseReportLine."Expense Category", 'Disabled policy');
        DisabledPolicy.Get(DisabledPolicy."Subject Type", DisabledPolicy."Line No.");
        DisabledPolicy.Enabled := false;
        DisabledPolicy.Modify(true);

        // [THEN] The line reports No Policies because the only matching policy is disabled.
        ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");
        Assert.AreEqual("Expense Policy Status"::"No Policies", ExpenseReportLine.GetPolicyStatus(), 'A never-evaluated line whose only matching policy is disabled must be No Policies.');
    end;

    [Test]
    procedure NoPoliciesIsDistinctFromClearedAcrossLifecycle()
    var
        ExpenseReportLine: Record "Expense Report Line";
        ExpensePolicy: Record "Expense Policy";
        ExpensePolicyFlag: Record "Expense Policy Flag";
    begin
        // [SCENARIO] The frontend must be able to tell "no policy to evaluate" apart from "evaluated and
        //            cleared". A line with no applicable policy reports No Policies (stable, even after a
        //            check run); the same line, once a policy applies and is evaluated with no violation,
        //            reports Cleared.
        Initialize();

        // [GIVEN] A line with no applicable policy.
        CreateTestReportLine(ExpenseReportLine);
        ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");
        Assert.AreEqual("Expense Policy Status"::"No Policies", ExpenseReportLine.GetPolicyStatus(), 'With no applicable policy the line must report No Policies.');

        // [WHEN] The line is marked evaluated even though nothing applies (the check run marks every line).
        ExpenseReportLine.MarkPoliciesEvaluated(ExpenseReportLine."Policy Eval Version");
        ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");

        // [THEN] The signal is stable: an evaluated line with no applicable policy still reports No Policies,
        //        never masquerading as Cleared.
        Assert.AreEqual("Expense Policy Status"::"No Policies", ExpenseReportLine.GetPolicyStatus(), 'An evaluated line with no applicable policy must stay No Policies, not flip to Cleared.');

        // [WHEN] A policy now targets the line's category.
        CreateTestPolicy(ExpensePolicy, ExpenseReportLine."Expense Category", 'No alcohol on company expenses.');
        ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");

        // [THEN] The line needs a recheck (a policy appeared after evaluation).
        Assert.AreEqual("Expense Policy Status"::Stale, ExpenseReportLine.GetPolicyStatus(), 'A newly applicable policy after evaluation must make the line Stale.');

        // [WHEN] The applicable policy is evaluated with a compliant verdict.
        AddCompliantFlag(ExpensePolicyFlag, ExpenseReportLine, ExpensePolicy, 'No alcohol found - compliant.');
        ExpenseReportLine.MarkPoliciesEvaluated(ExpenseReportLine."Policy Eval Version");
        ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");

        // [THEN] Now the line is genuinely evaluated-and-passed: Cleared, distinct from No Policies.
        Assert.AreEqual("Expense Policy Status"::Cleared, ExpenseReportLine.GetPolicyStatus(), 'An applicable policy evaluated with no violation must report Cleared.');
    end;

    // --- Fixtures ----------------------------------------------------------------------------

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Expense Policy Flag Test");
        LibraryExpense.CleanUpBeforeTesting();
        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Expense Policy Flag Test");
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);
        LibraryExpense.SetupNumberSeriesInExpenseMgmt();
        LibraryExpense.InitializeExpenseSourceCode();
        LibraryExpense.UpdateDefaultUnitOfMeasureInAgentSetup();
        LibraryExpense.UpdateUseRulesInAgentSetup(false);
        IsInitialized := true;

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Expense Policy Flag Test");
    end;

    local procedure CreateTestReportLine(var ExpenseReportLine: Record "Expense Report Line")
    var
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpensePaymentMethod: Record "Expense Payment Method";
    begin
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        LibraryExpense.FindExpensePaymentMethod(ExpensePaymentMethod, ExpensePaymentMethod."Reimbursement Type"::"Employee Paid");
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", "Expense Detail Needed"::" ", ExpensePaymentMethod.Code);
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", '', '');
        LibraryExpense.CreateExpenseReportLine(ExpenseReportLine, ExpenseReportHeader, ExpenseUser."No.", ExpenseCategory.Code, ExpensePaymentMethod.Code, true, '', LibraryRandom.RandIntInRange(10, 100));
    end;

    local procedure CreateTestPolicy(var ExpensePolicy: Record "Expense Policy"; ExpenseCategoryCode: Code[20]; PolicyText: Text[2048])
    begin
        ExpensePolicy.Init();
        ExpensePolicy."Expense Category Code" := ExpenseCategoryCode;
        ExpensePolicy."Policy Text" := PolicyText;
        ExpensePolicy.Enabled := true;
        ExpensePolicy."Subject Type" := "Expense Policy Subject"::"Expense Report Line";
        ExpensePolicy.Insert(true);
    end;

    local procedure AddFlag(var ExpensePolicyFlag: Record "Expense Policy Flag"; ExpenseReportLine: Record "Expense Report Line"; ExpensePolicy: Record "Expense Policy"; FlagDescription: Text[2048])
    begin
        AddFlag(ExpensePolicyFlag, ExpenseReportLine, ExpensePolicy, FlagDescription, false);
    end;

    local procedure AddCompliantFlag(var ExpensePolicyFlag: Record "Expense Policy Flag"; ExpenseReportLine: Record "Expense Report Line"; ExpensePolicy: Record "Expense Policy"; FlagDescription: Text[2048])
    begin
        AddFlag(ExpensePolicyFlag, ExpenseReportLine, ExpensePolicy, FlagDescription, true);
    end;

    local procedure AddFlag(var ExpensePolicyFlag: Record "Expense Policy Flag"; ExpenseReportLine: Record "Expense Report Line"; ExpensePolicy: Record "Expense Policy"; FlagDescription: Text[2048]; Compliant: Boolean)
    begin
        ExpensePolicyFlag.Init();
        ExpensePolicyFlag."Subject System Id" := ExpenseReportLine.SystemId;
        ExpensePolicyFlag."Subject Type" := "Expense Policy Subject"::"Expense Report Line";
        ExpensePolicyFlag."Subject Version" := ExpenseReportLine."Policy Eval Version";
        ExpensePolicyFlag."Policy System Id" := ExpensePolicy.SystemId;
        ExpensePolicyFlag."Policy Version" := ExpensePolicy."Version";
        ExpensePolicyFlag.Reason := FlagDescription;
        ExpensePolicyFlag."Compliant" := Compliant;
        ExpensePolicyFlag.Insert(true);
    end;

    local procedure CreateReportLineParticipant(var ExpenseReportLineParticip: Record "Expense Report Line Particip."; ExpenseReportLine: Record "Expense Report Line")
    var
        RecordRef: RecordRef;
    begin
        ExpenseReportLineParticip.Init();
        ExpenseReportLineParticip.Validate("Expense Report No.", ExpenseReportLine."Document No.");
        ExpenseReportLineParticip.Validate("Expense Report Line No.", ExpenseReportLine."Line No.");
        RecordRef.GetTable(ExpenseReportLineParticip);
        ExpenseReportLineParticip.Validate("Line No.", LibraryUtility.GetNewLineNo(RecordRef, ExpenseReportLineParticip.FieldNo("Line No.")));
        ExpenseReportLineParticip.Insert(true);
    end;
}
