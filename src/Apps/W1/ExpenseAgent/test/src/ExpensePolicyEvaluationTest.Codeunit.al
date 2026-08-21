// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.ExpenseAgent;

using Microsoft.ExpenseAgent;

codeunit 148340 "Expense Policy Evaluation Test"
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
        Commit();

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

    // --- Evaluation insertion + Flagged status -----------------------------------------------------

    [Test]
    procedure EvaluatedReportLineWithNonCompliantEvaluationIsFlagged()
    var
        ExpenseReportLine: Record "Expense Report Line";
        ExpensePolicy: Record "Expense Policy";
        ExpensePolicyEvaluation: Record "Expense Policy Evaluation";
    begin
        // [SCENARIO] A evaluation stamped at the evaluated version makes the report line report Flagged.
        Initialize();
        CreateTestReportLine(ExpenseReportLine);
        CreateTestPolicy(ExpensePolicy, ExpenseReportLine."Expense Category", 'No alcohol on company expenses.');

        // [WHEN] A evaluation is added and the line is then marked evaluated.
        AddEvaluation(ExpensePolicyEvaluation, ExpenseReportLine, ExpensePolicy, 'Receipt includes alcohol.');
        ExpenseReportLine.MarkPoliciesEvaluated(ExpenseReportLine."Policy Eval Version");

        // [THEN] The Policy Evaluations FlowField sees the live evaluation and the status is Flagged.
        ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");
        Assert.AreEqual("Expense Policy Status"::Flagged, ExpenseReportLine.GetPolicyStatus(), 'An evaluated line with a current-version evaluation must report Flagged.');
    end;

    [Test]
    procedure EvaluationValidatedWithSubjectAndPolicyVersion()
    var
        ExpenseReportLine: Record "Expense Report Line";
        ExpensePolicy: Record "Expense Policy";
        ExpensePolicyEvaluation: Record "Expense Policy Evaluation";
    begin
        // [SCENARIO] OnInsert accepts the subject and policy versions returned to the evaluator
        //            when they still match the current records.
        Initialize();
        CreateTestReportLine(ExpenseReportLine);
        CreateTestPolicy(ExpensePolicy, ExpenseReportLine."Expense Category", 'Policy text.');

        // [GIVEN] The policy is modified once so its Version is 1 (not the trivial 0).
        ExpensePolicy."Policy Text" := 'Policy text v2.';
        ExpensePolicy.Modify(true);

        // [GIVEN] The line is evaluated then invalidated once so Policy Eval Version is 1 (not the trivial 0).
        AddCompliantEvaluation(ExpensePolicyEvaluation, ExpenseReportLine, ExpensePolicy, 'Initial evaluation passed.');
        ExpenseReportLine.MarkPoliciesEvaluated(ExpenseReportLine."Policy Eval Version");
        ExpenseReportLine.InvalidatePolicyEvaluation();
        ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");

        // [WHEN] A evaluation is inserted.
        AddEvaluation(ExpensePolicyEvaluation, ExpenseReportLine, ExpensePolicy, 'Some violation.');

        // [THEN] Subject Version equals the line's Policy Eval Version and Policy Version equals the policy's Version.
        Assert.AreEqual(ExpenseReportLine."Policy Eval Version", ExpensePolicyEvaluation."Subject Version", 'The evaluation Subject Version must match the line Policy Eval Version at insert.');
        Assert.AreEqual(1, ExpensePolicyEvaluation."Subject Version", 'Policy Eval Version was 1 at insert, so the evaluation Subject Version must be 1.');
        Assert.AreEqual(ExpensePolicy."Version", ExpensePolicyEvaluation."Policy Version", 'The evaluation Policy Version must match the policy Version at insert.');
        Assert.AreEqual(1, ExpensePolicyEvaluation."Policy Version", 'The policy was modified once, so the evaluation Policy Version must be 1.');
    end;

    [Test]
    procedure EvaluationInsertRejectsChangedReportLineVersion()
    var
        ExpenseReportLine: Record "Expense Report Line";
        ExpensePolicy: Record "Expense Policy";
        ExpensePolicyEvaluation: Record "Expense Policy Evaluation";
        EvaluatedSubjectVersion: Integer;
    begin
        // [SCENARIO] A policy result is rejected when its expense line changed during evaluation.
        Initialize();
        CreateTestReportLine(ExpenseReportLine);
        CreateTestPolicy(ExpensePolicy, ExpenseReportLine."Expense Category", 'Policy text.');
        EvaluatedSubjectVersion := ExpenseReportLine."Policy Eval Version";

        ExpenseReportLine."Merchant Name" := 'Changed after evaluation started';
        ExpenseReportLine.Modify(true);

        ExpensePolicyEvaluation.Init();
        ExpensePolicyEvaluation."Subject System Id" := ExpenseReportLine.SystemId;
        ExpensePolicyEvaluation."Subject Type" := "Expense Policy Subject"::"Expense Report Line";
        ExpensePolicyEvaluation."Subject Version" := EvaluatedSubjectVersion;
        ExpensePolicyEvaluation."Policy System Id" := ExpensePolicy.SystemId;
        ExpensePolicyEvaluation."Policy Version" := ExpensePolicy."Version";

        asserterror ExpensePolicyEvaluation.Insert(true);
        Assert.ExpectedError('expense report line changed after policy evaluation started');
    end;

    [Test]
    procedure EvaluationInsertRejectsChangedPolicyVersion()
    var
        ExpenseReportLine: Record "Expense Report Line";
        ExpensePolicy: Record "Expense Policy";
        ExpensePolicyEvaluation: Record "Expense Policy Evaluation";
        EvaluatedPolicyVersion: Integer;
    begin
        // [SCENARIO] A policy result is rejected when its policy changed during evaluation.
        Initialize();
        CreateTestReportLine(ExpenseReportLine);
        CreateTestPolicy(ExpensePolicy, ExpenseReportLine."Expense Category", 'Policy text.');
        EvaluatedPolicyVersion := ExpensePolicy."Version";

        ExpensePolicy."Policy Text" := 'Changed after evaluation started.';
        ExpensePolicy.Modify(true);

        ExpensePolicyEvaluation.Init();
        ExpensePolicyEvaluation."Subject System Id" := ExpenseReportLine.SystemId;
        ExpensePolicyEvaluation."Subject Type" := "Expense Policy Subject"::"Expense Report Line";
        ExpensePolicyEvaluation."Subject Version" := ExpenseReportLine."Policy Eval Version";
        ExpensePolicyEvaluation."Policy System Id" := ExpensePolicy.SystemId;
        ExpensePolicyEvaluation."Policy Version" := EvaluatedPolicyVersion;

        asserterror ExpensePolicyEvaluation.Insert(true);
        Assert.ExpectedError('expense policy changed after policy evaluation started');
    end;

    [Test]
    procedure EvaluationIsCurrentUntilPolicyChanges()
    var
        ExpenseReportLine: Record "Expense Report Line";
        ExpensePolicy: Record "Expense Policy";
        ExpensePolicyEvaluation: Record "Expense Policy Evaluation";
    begin
        // [SCENARIO] A evaluation reports Is Current while its stored Policy Version matches the live policy,
        //            and stops being current once the policy is modified.
        Initialize();
        CreateTestReportLine(ExpenseReportLine);
        CreateTestPolicy(ExpensePolicy, ExpenseReportLine."Expense Category", 'Policy text.');

        // [GIVEN] A evaluation captured against the current policy version.
        AddEvaluation(ExpensePolicyEvaluation, ExpenseReportLine, ExpensePolicy, 'Some violation.');

        // [THEN] The evaluation is current.
        ExpensePolicyEvaluation.CalcFields("Is Current");
        Assert.IsTrue(ExpensePolicyEvaluation."Is Current", 'A freshly captured evaluation must be current.');

        // [WHEN] The underlying policy changes (its Version bumps).
        ExpensePolicy."Policy Text" := 'Policy text v2.';
        ExpensePolicy.Modify(true);

        // [THEN] The evaluation captured against the older policy version is no longer current.
        ExpensePolicyEvaluation.CalcFields("Is Current");
        Assert.IsFalse(ExpensePolicyEvaluation."Is Current", 'A evaluation captured against an older policy version must not be current.');
    end;

    [Test]
    procedure EvaluationStampedWithPolicyTextAndTimestamp()
    var
        ExpenseReportLine: Record "Expense Report Line";
        ExpensePolicy: Record "Expense Policy";
        ExpensePolicyEvaluation: Record "Expense Policy Evaluation";
        PolicyText: Text[2048];
    begin
        // [SCENARIO] OnInsert copies the linked policy's text and category onto the evaluation and stamps Flagged At.
        Initialize();
        CreateTestReportLine(ExpenseReportLine);
        PolicyText := 'Meals over 50 require an itemized receipt.';
        CreateTestPolicy(ExpensePolicy, ExpenseReportLine."Expense Category", PolicyText);

        // [WHEN] A evaluation is inserted for that policy.
        AddEvaluation(ExpensePolicyEvaluation, ExpenseReportLine, ExpensePolicy, 'Missing itemized receipt.');

        // [THEN] Policy Text and Expense Category Code are copied from the policy and Flagged At is set.
        Assert.AreEqual(PolicyText, ExpensePolicyEvaluation."Policy Text", 'The evaluation must copy the Policy Text from the linked policy.');
        Assert.AreEqual(ExpensePolicy."Expense Category Code", ExpensePolicyEvaluation."Expense Category Code", 'The evaluation must copy the Expense Category Code from the linked policy.');
        Assert.AreNotEqual(0DT, ExpensePolicyEvaluation."Evaluated At", 'Evaluated At must be stamped on insert.');
    end;

    [Test]
    procedure EvaluationInsertOverwritesCallerTimestamp()
    var
        ExpenseReportLine: Record "Expense Report Line";
        ExpensePolicy: Record "Expense Policy";
        ExpensePolicyEvaluation: Record "Expense Policy Evaluation";
        CallerTimestamp: DateTime;
    begin
        // [SCENARIO] The server owns the policy evaluation audit timestamp.
        Initialize();
        CreateTestReportLine(ExpenseReportLine);
        CreateTestPolicy(ExpensePolicy, ExpenseReportLine."Expense Category", 'Policy text.');
        CallerTimestamp := CreateDateTime(DMY2Date(1, 1, 2000), 0T);

        ExpensePolicyEvaluation.Init();
        ExpensePolicyEvaluation."Subject System Id" := ExpenseReportLine.SystemId;
        ExpensePolicyEvaluation."Subject Type" := "Expense Policy Subject"::"Expense Report Line";
        ExpensePolicyEvaluation."Subject Version" := ExpenseReportLine."Policy Eval Version";
        ExpensePolicyEvaluation."Policy System Id" := ExpensePolicy.SystemId;
        ExpensePolicyEvaluation."Policy Version" := ExpensePolicy."Version";
        ExpensePolicyEvaluation."Evaluated At" := CallerTimestamp;
        ExpensePolicyEvaluation.Insert(true);

        Assert.AreNotEqual(CallerTimestamp, ExpensePolicyEvaluation."Evaluated At", 'The server must overwrite a caller-supplied Evaluated At value.');
        Assert.AreNotEqual(0DT, ExpensePolicyEvaluation."Evaluated At", 'The server-generated Evaluated At value must not be blank.');
    end;

    [Test]
    procedure StaleEvaluationHiddenAfterReevaluation()
    var
        ExpenseReportLine: Record "Expense Report Line";
        ExpensePolicy: Record "Expense Policy";
        ExpensePolicyEvaluation: Record "Expense Policy Evaluation";
    begin
        // [SCENARIO] A evaluation from an earlier version is not seen after a re-evaluation at a higher version,
        //            yet the evaluation row is preserved as history.
        Initialize();
        CreateTestReportLine(ExpenseReportLine);
        CreateTestPolicy(ExpensePolicy, ExpenseReportLine."Expense Category", 'Policy text.');

        // [GIVEN] An evaluated, flagged line at version 1.
        AddEvaluation(ExpensePolicyEvaluation, ExpenseReportLine, ExpensePolicy, 'Old violation.');
        ExpenseReportLine.MarkPoliciesEvaluated(ExpenseReportLine."Policy Eval Version");
        ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");
        Assert.AreEqual("Expense Policy Status"::Flagged, ExpenseReportLine.GetPolicyStatus(), 'Precondition: the line should be Flagged at version 1.');

        // [WHEN] A relevant change bumps the version and the line is re-evaluated with a compliant verdict.
        ExpenseReportLine."Merchant Name" := 'Contoso Merchant (policy-relevant change)';
        ExpenseReportLine.Modify(true);
        ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");
        AddCompliantEvaluation(ExpensePolicyEvaluation, ExpenseReportLine, ExpensePolicy, 'Re-evaluation passed.');
        ExpenseReportLine.MarkPoliciesEvaluated(ExpenseReportLine."Policy Eval Version");
        ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");

        // [THEN] The earlier violation is no longer live, the line is Cleared, and both evaluations remain as history.
        Assert.AreEqual("Expense Policy Status"::Cleared, ExpenseReportLine.GetPolicyStatus(), 'A evaluation from an older version must not be seen after re-evaluation.');
        ExpensePolicyEvaluation.SetRange("Subject System Id", ExpenseReportLine.SystemId);
        Assert.RecordCount(ExpensePolicyEvaluation, 2);
    end;

    [Test]
    procedure NewEvaluationSeenAfterReevaluationAtHigherVersion()
    var
        ExpenseReportLine: Record "Expense Report Line";
        ExpensePolicy: Record "Expense Policy";
        ExpensePolicyEvaluation: Record "Expense Policy Evaluation";
    begin
        // [SCENARIO] After a version bump and re-evaluation, a new evaluation stamped at the new version is seen,
        //            and both the old and new evaluation rows coexist as history.
        Initialize();
        CreateTestReportLine(ExpenseReportLine);
        CreateTestPolicy(ExpensePolicy, ExpenseReportLine."Expense Category", 'Policy text.');

        // [GIVEN] An evaluated, flagged line at version 1.
        AddEvaluation(ExpensePolicyEvaluation, ExpenseReportLine, ExpensePolicy, 'Version 1 violation.');
        ExpenseReportLine.MarkPoliciesEvaluated(ExpenseReportLine."Policy Eval Version");
        ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");

        // [WHEN] A relevant field change bumps the version, a new evaluation is stamped at version 2, then re-evaluated.
        ExpenseReportLine."Merchant Name" := 'Contoso Merchant (policy-relevant change)';
        ExpenseReportLine.Modify(true);
        ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");
        AddEvaluation(ExpensePolicyEvaluation, ExpenseReportLine, ExpensePolicy, 'Version 2 violation.');
        ExpenseReportLine.MarkPoliciesEvaluated(ExpenseReportLine."Policy Eval Version");
        ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");

        // [THEN] The line is Flagged (the version-2 evaluation is live) and both evaluation rows are preserved.
        Assert.AreEqual("Expense Policy Status"::Flagged, ExpenseReportLine.GetPolicyStatus(), 'The version-2 evaluation must be seen after re-evaluation.');
        ExpensePolicyEvaluation.SetRange("Subject System Id", ExpenseReportLine.SystemId);
        Assert.RecordCount(ExpensePolicyEvaluation, 2);
    end;

    [Test]
    procedure CompliantEvaluationLeavesLineCleared()
    var
        ExpenseReportLine: Record "Expense Report Line";
        ExpensePolicy: Record "Expense Policy";
        ExpensePolicyEvaluation: Record "Expense Policy Evaluation";
    begin
        // [SCENARIO] A good-to-go (compliant) evaluation is not a violation, so the line stays Cleared.
        Initialize();
        CreateTestReportLine(ExpenseReportLine);
        CreateTestPolicy(ExpensePolicy, ExpenseReportLine."Expense Category", 'No alcohol on company expenses.');

        // [WHEN] A compliant verdict is recorded and the line is marked evaluated.
        AddCompliantEvaluation(ExpensePolicyEvaluation, ExpenseReportLine, ExpensePolicy, 'No alcohol found - compliant.');
        ExpenseReportLine.MarkPoliciesEvaluated(ExpenseReportLine."Policy Eval Version");

        // [THEN] Has Policy Violation is false and the line reports Cleared.
        ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");
        ExpenseReportLine.CalcFields("Has Policy Violation");
        Assert.IsFalse(ExpenseReportLine."Has Policy Violation", 'A compliant evaluation must not raise Has Policy Violation.');
        Assert.AreEqual("Expense Policy Status"::Cleared, ExpenseReportLine.GetPolicyStatus(), 'An evaluated line with only compliant evaluations must report Cleared.');
    end;

    [Test]
    procedure ViolationAmongCompliantEvaluationsFlagsLine()
    var
        ExpenseReportLine: Record "Expense Report Line";
        ExpensePolicyA: Record "Expense Policy";
        ExpensePolicyB: Record "Expense Policy";
        ExpensePolicyEvaluation: Record "Expense Policy Evaluation";
    begin
        // [SCENARIO] With one compliant and one violation verdict at the same version, the line is Flagged.
        Initialize();
        CreateTestReportLine(ExpenseReportLine);
        CreateTestPolicy(ExpensePolicyA, ExpenseReportLine."Expense Category", 'No alcohol on company expenses.');
        CreateTestPolicy(ExpensePolicyB, ExpenseReportLine."Expense Category", 'Meals over 50 require an itemized receipt.');

        // [WHEN] Policy A passes and Policy B is violated, then the line is marked evaluated.
        AddCompliantEvaluation(ExpensePolicyEvaluation, ExpenseReportLine, ExpensePolicyA, 'No alcohol found - compliant.');
        AddEvaluation(ExpensePolicyEvaluation, ExpenseReportLine, ExpensePolicyB, 'Missing itemized receipt.');
        ExpenseReportLine.MarkPoliciesEvaluated(ExpenseReportLine."Policy Eval Version");

        // [THEN] Has Policy Violation is true and the line reports Flagged.
        ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");
        ExpenseReportLine.CalcFields("Has Policy Violation");
        Assert.IsTrue(ExpenseReportLine."Has Policy Violation", 'A single violation among compliant evaluations must raise Has Policy Violation.');
        Assert.AreEqual("Expense Policy Status"::Flagged, ExpenseReportLine.GetPolicyStatus(), 'A line with any violation evaluation must report Flagged.');
    end;

    [Test]
    procedure AddingPolicyForCategoryMakesEvaluatedLineStale()
    var
        ExpenseReportLine: Record "Expense Report Line";
        ExpensePolicy: Record "Expense Policy";
    begin
        // [SCENARIO] Adding a policy makes an evaluated line stale without rewriting the line.
        Initialize();
        CreateTestReportLine(ExpenseReportLine);
        ExpenseReportLine.MarkPoliciesEvaluated(ExpenseReportLine."Policy Eval Version");
        ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");
        Assert.AreEqual("Expense Policy Status"::"No Policies", ExpenseReportLine.GetPolicyStatus(), 'Precondition: with no policy yet the line reports No Policies.');

        // [WHEN] A policy is added for the line's category.
        CreateTestPolicy(ExpensePolicy, ExpenseReportLine."Expense Category", 'No alcohol on company expenses.');

        // [THEN] The line version is unchanged, but the new policy is outstanding so the status is Stale.
        ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");
        Assert.AreEqual(0, ExpenseReportLine."Policy Eval Version", 'Adding a policy must not rewrite the evaluated line.');
        Assert.AreEqual("Expense Policy Status"::Stale, ExpenseReportLine.GetPolicyStatus(), 'Adding a policy for the category must leave the evaluated line Stale.');
    end;

    [Test]
    procedure ChangingPolicyMakesEvaluatedLineStale()
    var
        ExpenseReportLine: Record "Expense Report Line";
        ExpensePolicy: Record "Expense Policy";
        ExpensePolicyEvaluation: Record "Expense Policy Evaluation";
    begin
        // [SCENARIO] Modifying an existing policy makes its current version outstanding without rewriting evaluated lines.
        Initialize();
        CreateTestReportLine(ExpenseReportLine);
        CreateTestPolicy(ExpensePolicy, ExpenseReportLine."Expense Category", 'No alcohol on company expenses.');

        // [GIVEN] The line is evaluated with a compliant verdict after the policy already exists.
        ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");
        AddCompliantEvaluation(ExpensePolicyEvaluation, ExpenseReportLine, ExpensePolicy, 'Initial evaluation passed.');
        ExpenseReportLine.MarkPoliciesEvaluated(ExpenseReportLine."Policy Eval Version");
        ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");
        Assert.AreEqual("Expense Policy Status"::Cleared, ExpenseReportLine.GetPolicyStatus(), 'Precondition: the line should be Cleared.');

        // [WHEN] The policy text changes (bumping its version).
        ExpensePolicy."Policy Text" := 'No alcohol and no minibar on company expenses.';
        ExpensePolicy.Modify(true);

        // [THEN] The line version is unchanged, but the changed policy version is outstanding.
        ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");
        Assert.AreEqual(0, ExpenseReportLine."Policy Eval Version", 'A policy change must not rewrite the evaluated line.');
        Assert.AreEqual("Expense Policy Status"::Stale, ExpenseReportLine.GetPolicyStatus(), 'Changing a policy must leave the evaluated line Stale.');

        // [WHEN] A verdict is recorded for the changed policy.
        AddCompliantEvaluation(ExpensePolicyEvaluation, ExpenseReportLine, ExpensePolicy, 'Updated evaluation passed.');

        // [THEN] The current verdict makes the line Cleared without relying on the audit timestamp.
        ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");
        Assert.AreEqual("Expense Policy Status"::Cleared, ExpenseReportLine.GetPolicyStatus(), 'Submitting a verdict for the current policy version must make the line Cleared.');

        // [WHEN] Evaluation completion is marked for audit.
        ExpenseReportLine.MarkPoliciesEvaluated(ExpenseReportLine."Policy Eval Version");

        // [THEN] Recording the audit timestamp does not change the status.
        ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");
        Assert.AreEqual("Expense Policy Status"::Cleared, ExpenseReportLine.GetPolicyStatus(), 'Recording the evaluation timestamp must leave the current compliant verdict effective.');
    end;

    [Test]
    procedure DeletingOnlyPolicyMakesEvaluatedLineNoPolicies()
    var
        ExpenseReportLine: Record "Expense Report Line";
        ExpensePolicy: Record "Expense Policy";
        ExpensePolicyEvaluation: Record "Expense Policy Evaluation";
    begin
        // [SCENARIO] Deleting the only applicable policy leaves no work to evaluate, and any evaluation
        // left behind for the removed policy is no longer current.
        Initialize();
        CreateTestReportLine(ExpenseReportLine);
        CreateTestPolicy(ExpensePolicy, ExpenseReportLine."Expense Category", 'No alcohol on company expenses.');

        // [GIVEN] The line is evaluated with a evaluation for the policy.
        ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");
        AddEvaluation(ExpensePolicyEvaluation, ExpenseReportLine, ExpensePolicy, 'Alcohol flagged');
        ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");
        ExpenseReportLine.MarkPoliciesEvaluated(ExpenseReportLine."Policy Eval Version");

        // [WHEN] The policy is deleted.
        ExpensePolicy.Delete(true);

        // [THEN] The removed policy no longer participates, so the line reports No Policies.
        ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");
        Assert.AreEqual("Expense Policy Status"::"No Policies", ExpenseReportLine.GetPolicyStatus(), 'Deleting the only applicable policy must leave the line with No Policies.');

        // [THEN] The orphaned evaluation is kept as history but is no longer current.
        ExpensePolicyEvaluation.Get(ExpensePolicyEvaluation."Subject Type", ExpensePolicyEvaluation."Subject System Id", ExpensePolicyEvaluation."Policy System Id", ExpensePolicyEvaluation."Subject Version", ExpensePolicyEvaluation."Policy Version");
        ExpensePolicyEvaluation.CalcFields("Is Current");
        Assert.IsFalse(ExpensePolicyEvaluation."Is Current", 'A evaluation for a deleted policy must not be current.');
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
    procedure MovingPolicyToAnotherCategoryRemovesItFromOldCategoryLine()
    var
        ExpenseReportLine: Record "Expense Report Line";
        ExpensePolicy: Record "Expense Policy";
        ExpensePolicyEvaluation: Record "Expense Policy Evaluation";
        OtherCategory: Record "Expense Category";
    begin
        // [SCENARIO] Moving a policy to a different category removes it from the old category's
        // current policy set without rewriting lines in that category.
        Initialize();
        CreateTestReportLine(ExpenseReportLine);

        // [GIVEN] A policy for the line's category and the line evaluated with a compliant verdict.
        CreateTestPolicy(ExpensePolicy, ExpenseReportLine."Expense Category", 'No alcohol on company expenses.');
        AddCompliantEvaluation(ExpensePolicyEvaluation, ExpenseReportLine, ExpensePolicy, 'Initial evaluation passed.');
        ExpenseReportLine.MarkPoliciesEvaluated(ExpenseReportLine."Policy Eval Version");
        ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");
        Assert.AreEqual("Expense Policy Status"::Cleared, ExpenseReportLine.GetPolicyStatus(), 'Precondition: the evaluated line should be Cleared.');

        // [WHEN] The policy is moved to a different category.
        LibraryExpense.CreateExpenseCategory(OtherCategory, OtherCategory."Reimbursement Type"::"Employee Paid", "Expense Detail Needed"::" ", '');
        ExpensePolicy."Expense Category Code" := OtherCategory.Code;
        ExpensePolicy.Modify(true);

        // [THEN] The line in the old category has no applicable policies and was not rewritten.
        ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");
        Assert.AreEqual(0, ExpenseReportLine."Policy Eval Version", 'Moving a policy must not rewrite lines in its old category.');
        Assert.AreEqual("Expense Policy Status"::"No Policies", ExpenseReportLine.GetPolicyStatus(), 'Moving a policy out of the line''s category must remove it from that line''s current policy set.');
    end;

    [Test]
    procedure SupersededEvaluationDoesNotKeepLineFlagged()
    var
        ExpenseReportLine: Record "Expense Report Line";
        ExpensePolicy: Record "Expense Policy";
        ExpensePolicyEvaluation: Record "Expense Policy Evaluation";
    begin
        // [SCENARIO] A non-compliant evaluation whose captured Policy Version no longer matches the live
        //            policy (Is Current = false) must not keep an up-to-date line Flagged. This
        //            superseded evaluation is inserted raw to isolate the currency check in
        //            HasCurrentPolicyViolation.
        Initialize();
        CreateTestReportLine(ExpenseReportLine);
        CreateTestPolicy(ExpensePolicy, ExpenseReportLine."Expense Category", 'No alcohol on company expenses.');

        // [GIVEN] A non-compliant evaluation stamped at the line's version but against a superseded policy
        //         version (Policy Version ahead of the live policy), inserted raw to bypass the strict
        //         OnInsert snapshot.
        ExpensePolicyEvaluation.Init();
        ExpensePolicyEvaluation."Subject System Id" := ExpenseReportLine.SystemId;
        ExpensePolicyEvaluation."Subject Type" := "Expense Policy Subject"::"Expense Report Line";
        ExpensePolicyEvaluation."Subject Version" := ExpenseReportLine."Policy Eval Version";
        ExpensePolicyEvaluation."Policy System Id" := ExpensePolicy.SystemId;
        ExpensePolicyEvaluation."Policy Version" := ExpensePolicy."Version" + 1;
        ExpensePolicyEvaluation."Compliant" := false;
        ExpensePolicyEvaluation.Insert(false);

        ExpensePolicyEvaluation.CalcFields("Is Current");
        Assert.IsFalse(ExpensePolicyEvaluation."Is Current", 'Precondition: the evaluation must be non-current.');

        // [WHEN] A current compliant verdict is added and the line is marked evaluated.
        AddCompliantEvaluation(ExpensePolicyEvaluation, ExpenseReportLine, ExpensePolicy, 'Current evaluation passed.');
        ExpenseReportLine.MarkPoliciesEvaluated(ExpenseReportLine."Policy Eval Version");
        ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");

        // [THEN] The superseded evaluation does not count as a violation; the line reports Cleared.
        Assert.AreEqual("Expense Policy Status"::Cleared, ExpenseReportLine.GetPolicyStatus(), 'A superseded (non-current) evaluation must not keep the line Flagged.');
    end;

    [Test]
    procedure EvaluationInsertRejectsUnknownReportLine()
    var
        ExpenseReportLine: Record "Expense Report Line";
        ExpensePolicy: Record "Expense Policy";
        ExpensePolicyEvaluation: Record "Expense Policy Evaluation";
    begin
        // [SCENARIO] A evaluation whose subject report line does not exist is rejected on insert.
        Initialize();
        CreateTestReportLine(ExpenseReportLine);
        CreateTestPolicy(ExpensePolicy, ExpenseReportLine."Expense Category", 'Policy text.');

        // [WHEN] A evaluation references a non-existent report line.
        ExpensePolicyEvaluation.Init();
        ExpensePolicyEvaluation."Subject System Id" := CreateGuid();
        ExpensePolicyEvaluation."Subject Type" := "Expense Policy Subject"::"Expense Report Line";
        ExpensePolicyEvaluation."Policy System Id" := ExpensePolicy.SystemId;

        // [THEN] The insert is rejected.
        asserterror ExpensePolicyEvaluation.Insert(true);
        Assert.ExpectedError('does not exist');
    end;

    [Test]
    procedure EvaluationInsertRejectsDisabledPolicy()
    var
        ExpenseReportLine: Record "Expense Report Line";
        ExpensePolicy: Record "Expense Policy";
        ExpensePolicyEvaluation: Record "Expense Policy Evaluation";
    begin
        // [SCENARIO] A evaluation for a disabled policy is rejected on insert.
        Initialize();
        CreateTestReportLine(ExpenseReportLine);
        CreateTestPolicy(ExpensePolicy, ExpenseReportLine."Expense Category", 'Policy text.');

        // [GIVEN] The policy is disabled.
        ExpensePolicy.Validate(Enabled, false);
        ExpensePolicy.Modify(true);

        // [WHEN] A evaluation references the disabled policy.
        ExpensePolicyEvaluation.Init();
        ExpensePolicyEvaluation."Subject System Id" := ExpenseReportLine.SystemId;
        ExpensePolicyEvaluation."Subject Type" := "Expense Policy Subject"::"Expense Report Line";
        ExpensePolicyEvaluation."Policy System Id" := ExpensePolicy.SystemId;

        // [THEN] The insert is rejected.
        asserterror ExpensePolicyEvaluation.Insert(true);
        Assert.ExpectedError('disabled policy');
    end;

    [Test]
    procedure EvaluationInsertRejectsInapplicablePolicy()
    var
        ExpenseReportLine: Record "Expense Report Line";
        ExpensePolicy: Record "Expense Policy";
        ExpensePolicyEvaluation: Record "Expense Policy Evaluation";
        OtherCategory: Record "Expense Category";
    begin
        // [SCENARIO] A evaluation for a policy that does not apply to the line's category is rejected.
        Initialize();
        CreateTestReportLine(ExpenseReportLine);
        LibraryExpense.CreateExpenseCategory(OtherCategory, OtherCategory."Reimbursement Type"::"Employee Paid", "Expense Detail Needed"::" ", '');
        CreateTestPolicy(ExpensePolicy, OtherCategory.Code, 'Policy for another category.');

        // [WHEN] A evaluation references the other-category policy for this line.
        ExpensePolicyEvaluation.Init();
        ExpensePolicyEvaluation."Subject System Id" := ExpenseReportLine.SystemId;
        ExpensePolicyEvaluation."Subject Type" := "Expense Policy Subject"::"Expense Report Line";
        ExpensePolicyEvaluation."Policy System Id" := ExpensePolicy.SystemId;

        // [THEN] The insert is rejected.
        asserterror ExpensePolicyEvaluation.Insert(true);
        Assert.ExpectedError('does not apply');
    end;

    [Test]
    procedure DeletingReportLineRemovesEvaluations()
    var
        ExpenseReportLine: Record "Expense Report Line";
        ExpensePolicy: Record "Expense Policy";
        ExpensePolicyEvaluation: Record "Expense Policy Evaluation";
    begin
        // [SCENARIO] Deleting a report line removes its policy evaluations so none are orphaned.
        Initialize();
        CreateTestReportLine(ExpenseReportLine);
        CreateTestPolicy(ExpensePolicy, ExpenseReportLine."Expense Category", 'Policy text.');
        AddEvaluation(ExpensePolicyEvaluation, ExpenseReportLine, ExpensePolicy, 'Some violation.');

        // [GIVEN] Precondition: a evaluation exists for the line.
        ExpensePolicyEvaluation.SetRange("Subject System Id", ExpenseReportLine.SystemId);
        Assert.RecordCount(ExpensePolicyEvaluation, 1);

        // [WHEN] The report line is deleted.
        ExpenseReportLine.Delete(true);

        // [THEN] The evaluation is gone.
        ExpensePolicyEvaluation.SetRange("Subject System Id", ExpenseReportLine.SystemId);
        Assert.RecordIsEmpty(ExpensePolicyEvaluation);
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
    procedure NeutralParentModifyPreservesChildInvalidation()
    var
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseReportLineParticip: Record "Expense Report Line Particip.";
        EvaluatedAt: DateTime;
    begin
        // [SCENARIO] A stale parent buffer cannot overwrite policy fields that a child trigger updated.
        Initialize();
        CreateTestReportLine(ExpenseReportLine);
        CreateReportLineParticipant(ExpenseReportLineParticip, ExpenseReportLine);
        ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");
        ExpenseReportLine.MarkPoliciesEvaluated(ExpenseReportLine."Policy Eval Version");
        ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");
        EvaluatedAt := ExpenseReportLine."Policies Evaluated At";

        // [GIVEN] The held line is current at version 1, then deleting its child advances the stored line to version 2.
        Assert.AreEqual(1, ExpenseReportLine."Policy Eval Version", 'The participant insert must establish version 1.');
        ExpenseReportLineParticip.Delete(true);

        // [WHEN] The stale held line modifies a policy-neutral field.
        ExpenseReportLine."Applied Rule Id" := CreateGuid();
        ExpenseReportLine.Modify(true);

        // [THEN] The child invalidation and prior evaluation fields are preserved.
        ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");
        Assert.AreEqual(2, ExpenseReportLine."Policy Eval Version", 'A stale parent modify must not overwrite the child-trigger version.');
        Assert.AreEqual(1, ExpenseReportLine."Evaluated Policy Version", 'A stale parent modify must preserve the evaluated version.');
        Assert.AreEqual(EvaluatedAt, ExpenseReportLine."Policies Evaluated At", 'A stale parent modify must preserve the evaluation timestamp.');
        Assert.AreEqual("Expense Policy Status"::Stale, ExpenseReportLine.GetPolicyStatus(), 'The line must remain stale after its child is deleted.');
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
        DisabledPolicy: Record "Expense Policy";
        OfferedPolicy: Record "Expense Policy";
        ExpensePolicyEvaluation: Record "Expense Policy Evaluation";
        OtherCategory: Record "Expense Category";
        TempPolicyToEval: Record "Exp. Policy To Eval Buffer" temporary;
        Builder: Codeunit "Exp. Policies To Eval Builder";
    begin
        // [SCENARIO] The endpoint returns the enabled policies applicable to a line (its category or blank), excluding other categories.
        Initialize();
        CreateTestReportLine(ExpenseReportLine);

        // [GIVEN] Matching and blank-category policies, plus policies that are disabled or belong to another category.
        CreateTestPolicy(MatchingPolicy, ExpenseReportLine."Expense Category", 'Matches the line category');
        CreateTestPolicy(BlankCategoryPolicy, '', 'Applies to every category');
        CreateTestPolicy(DisabledPolicy, ExpenseReportLine."Expense Category", 'Disabled policy');
        DisabledPolicy.Enabled := false;
        DisabledPolicy.Modify(true);
        LibraryExpense.CreateExpenseCategory(OtherCategory, OtherCategory."Reimbursement Type"::"Employee Paid", "Expense Detail Needed"::" ", '');
        CreateTestPolicy(OtherCategoryPolicy, OtherCategory.Code, 'Belongs to another category');

        // [WHEN] The policies-to-evaluate set is built for the line.
        Builder.Build(TempPolicyToEval, Format(ExpenseReportLine.SystemId));

        // [THEN] Only the matching and blank-category policies are returned.
        Assert.AreEqual(2, TempPolicyToEval.Count(), 'Only the applicable policies must be returned.');
        Assert.IsTrue(TempPolicyToEval.Get(ExpenseReportLine.SystemId, MatchingPolicy.SystemId), 'The matching-category policy must be listed.');
        Assert.IsTrue(TempPolicyToEval.Get(ExpenseReportLine.SystemId, BlankCategoryPolicy.SystemId), 'The blank-category policy must be listed.');
        Assert.IsFalse(TempPolicyToEval.Get(ExpenseReportLine.SystemId, OtherCategoryPolicy.SystemId), 'A different-category policy must not be listed.');
        Assert.IsFalse(TempPolicyToEval.Get(ExpenseReportLine.SystemId, DisabledPolicy.SystemId), 'A disabled policy must not be listed.');

        // [THEN] Every policy offered by the builder is accepted by the evaluation-insert guard.
        TempPolicyToEval.Reset();
        if TempPolicyToEval.FindSet() then
            repeat
                OfferedPolicy.GetBySystemId(TempPolicyToEval."Policy System Id");
                AddCompliantEvaluation(ExpensePolicyEvaluation, ExpenseReportLine, OfferedPolicy, 'Accepted builder policy.');
            until TempPolicyToEval.Next() = 0;
        ExpensePolicyEvaluation.SetRange("Subject System Id", ExpenseReportLine.SystemId);
        Assert.RecordCount(ExpensePolicyEvaluation, 2);
    end;

    [Test]
    procedure PoliciesToEvaluateExcludesCurrentlyEvaluatedButReturnsAfterVersionBump()
    var
        ExpenseReportLine: Record "Expense Report Line";
        ExpensePolicy: Record "Expense Policy";
        UnchangedExpensePolicy: Record "Expense Policy";
        ExpensePolicyEvaluation: Record "Expense Policy Evaluation";
        TempPolicyToEval: Record "Exp. Policy To Eval Buffer" temporary;
        Builder: Codeunit "Exp. Policies To Eval Builder";
    begin
        // [SCENARIO] A policy already flagged at the current versions is excluded, but returns once the policy is bumped to a new version.
        Initialize();
        CreateTestReportLine(ExpenseReportLine);
        CreateTestPolicy(ExpensePolicy, ExpenseReportLine."Expense Category", 'Original policy text');
        CreateTestPolicy(UnchangedExpensePolicy, ExpenseReportLine."Expense Category", 'Unchanged policy text');

        // [GIVEN] Evaluations exist for both policies at the current subject and policy versions.
        ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");
        AddEvaluation(ExpensePolicyEvaluation, ExpenseReportLine, ExpensePolicy, 'Already evaluated');
        AddCompliantEvaluation(ExpensePolicyEvaluation, ExpenseReportLine, UnchangedExpensePolicy, 'Also evaluated');

        // [WHEN] The set is built.
        Builder.Build(TempPolicyToEval, Format(ExpenseReportLine.SystemId));

        // [THEN] Neither evaluated policy is returned.
        Assert.IsFalse(TempPolicyToEval.Get(ExpenseReportLine.SystemId, ExpensePolicy.SystemId), 'A policy already flagged at the current version must not be listed.');
        Assert.IsFalse(TempPolicyToEval.Get(ExpenseReportLine.SystemId, UnchangedExpensePolicy.SystemId), 'An unchanged policy already flagged at the current version must not be listed.');

        // [WHEN] The policy is changed, bumping its version.
        ExpensePolicy.Get(ExpensePolicy."Subject Type", ExpensePolicy."Line No.");
        ExpensePolicy."Policy Text" := 'Updated policy text';
        ExpensePolicy.Modify(true);
        Builder.Build(TempPolicyToEval, Format(ExpenseReportLine.SystemId));

        // [THEN] Only the updated policy is listed; the line and unchanged verdict are reused.
        ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");
        Assert.AreEqual(0, ExpenseReportLine."Policy Eval Version", 'Changing a policy must not advance the subject version.');
        Assert.AreEqual(1, TempPolicyToEval.Count(), 'Only the changed policy must require re-evaluation.');
        Assert.IsTrue(TempPolicyToEval.Get(ExpenseReportLine.SystemId, ExpensePolicy.SystemId), 'A policy bumped to a new version must be listed for re-evaluation.');
        Assert.IsFalse(TempPolicyToEval.Get(ExpenseReportLine.SystemId, UnchangedExpensePolicy.SystemId), 'An unchanged policy must keep its current verdict.');
    end;

    // --- Status of never-evaluated lines -----------------------------------------------------

    [Test]
    procedure OutstandingPolicyIsDetectedUntilEvaluated()
    var
        ExpenseReportLine: Record "Expense Report Line";
        ExpensePolicy: Record "Expense Policy";
        ExpensePolicyEvaluation: Record "Expense Policy Evaluation";
        Builder: Codeunit "Exp. Policies To Eval Builder";
    begin
        // [SCENARIO] HasOutstandingPolicies (the mark-evaluated guard) reports true while an applicable
        //            policy has no verdict for the current version, and false once every applicable
        //            policy has a evaluation.
        Initialize();
        CreateTestReportLine(ExpenseReportLine);

        // [GIVEN] No applicable policy - nothing is outstanding.
        Assert.IsFalse(Builder.HasOutstandingPolicies(ExpenseReportLine), 'A line with no applicable policy has nothing outstanding.');

        // [WHEN] An applicable policy exists but has not been evaluated.
        CreateTestPolicy(ExpensePolicy, ExpenseReportLine."Expense Category", 'Must be evaluated.');

        // [THEN] The policy is outstanding and the line cannot be marked evaluated.
        Assert.IsTrue(Builder.HasOutstandingPolicies(ExpenseReportLine), 'An applicable policy without a evaluation must be outstanding.');
        Commit();
        asserterror ExpenseReportLine.MarkPoliciesEvaluated(ExpenseReportLine."Policy Eval Version");
        Assert.ExpectedError('one or more applicable policies have not yet been evaluated');

        // [WHEN] A verdict (evaluation) is recorded for the policy at the current version.
        AddCompliantEvaluation(ExpensePolicyEvaluation, ExpenseReportLine, ExpensePolicy, 'Compliant.');

        // [THEN] Nothing is outstanding anymore.
        Assert.IsFalse(Builder.HasOutstandingPolicies(ExpenseReportLine), 'Once every applicable policy has a evaluation, nothing is outstanding.');
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
        ExpensePolicyEvaluation: Record "Expense Policy Evaluation";
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
        AddCompliantEvaluation(ExpensePolicyEvaluation, ExpenseReportLine, ExpensePolicy, 'No alcohol found - compliant.');
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
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Expense Policy Evaluation Test");
        LibraryExpense.CleanUpBeforeTesting();
        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Expense Policy Evaluation Test");
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

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Expense Policy Evaluation Test");
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
        LibraryExpense.CreateExpensePolicy(ExpensePolicy, ExpenseCategoryCode, PolicyText);
    end;

    local procedure AddEvaluation(var ExpensePolicyEvaluation: Record "Expense Policy Evaluation"; ExpenseReportLine: Record "Expense Report Line"; ExpensePolicy: Record "Expense Policy"; EvaluationReason: Text[2048])
    begin
        AddEvaluation(ExpensePolicyEvaluation, ExpenseReportLine, ExpensePolicy, EvaluationReason, false);
    end;

    local procedure AddCompliantEvaluation(var ExpensePolicyEvaluation: Record "Expense Policy Evaluation"; ExpenseReportLine: Record "Expense Report Line"; ExpensePolicy: Record "Expense Policy"; EvaluationReason: Text[2048])
    begin
        AddEvaluation(ExpensePolicyEvaluation, ExpenseReportLine, ExpensePolicy, EvaluationReason, true);
    end;

    local procedure AddEvaluation(var ExpensePolicyEvaluation: Record "Expense Policy Evaluation"; ExpenseReportLine: Record "Expense Report Line"; ExpensePolicy: Record "Expense Policy"; EvaluationReason: Text[2048]; Compliant: Boolean)
    begin
        LibraryExpense.CreateExpensePolicyEvaluation(ExpensePolicyEvaluation, ExpenseReportLine, ExpensePolicy, EvaluationReason, Compliant);
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
