codeunit 136354 "UT T Job WIP Method"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [WIP Method] [Job] [UT]
    end;

    var
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";
        Text003Txt: Label 'You cannot modify this field when %1 is %2.', Comment = '%1 - Caption of field "Recognized Costs", %2 - Caption of value "Recognized Costs"::"Usage (Total Cost)"';
        LibraryUtility: Codeunit "Library - Utility";
        LibraryJob: Codeunit "Library - Job";
        WIPMethodQst: Label 'Do you want to set the %1 on every %2 of type %3?', Comment = '%1 = The WIP Method field name; %2 = The name of the Job Task table; %3 = The current job task''s WIP Total type';
        LibraryVariableStorage: Codeunit "Library - Variable Storage";

    [Test]
    [Scope('OnPrem')]
    procedure TestInitialization()
    var
        JobWIPMethod: Record "Job WIP Method";
        LibraryJob: Codeunit "Library - Job";
        Method: Option "Completed Contract","Cost of Sales","Cost Value",POC,"Sales Value";
    begin
        // Verify that Job WIP Method is initialized correctly.
        LibraryJob.GetJobWIPMethod(JobWIPMethod, Method::"Completed Contract");
        if JobWIPMethod.Count <> 1 then
            Assert.Fail('Job WIP Method Completed Contract did not initalize correctly');
        LibraryJob.GetJobWIPMethod(JobWIPMethod, Method::"Cost of Sales");
        if JobWIPMethod.Count <> 1 then
            Assert.Fail('Job WIP Method Cost of Sales did not initalize correctly');
        LibraryJob.GetJobWIPMethod(JobWIPMethod, Method::"Cost Value");
        if JobWIPMethod.Count <> 1 then
            Assert.Fail('Job WIP Method Cost Value did not initalize correctly');
        LibraryJob.GetJobWIPMethod(JobWIPMethod, Method::POC);
        if JobWIPMethod.Count <> 1 then
            Assert.Fail('Job WIP Method POC Contract did not initalize correctly');
        LibraryJob.GetJobWIPMethod(JobWIPMethod, Method::"Sales Value");
        if JobWIPMethod.Count <> 1 then
            Assert.Fail('Job WIP Method Sales Value did not initalize correctly');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDeletion()
    var
        JobWIPMethod: Record "Job WIP Method";
        JobWIPEntry: Record "Job WIP Entry";
        JobsSetup: Record "Jobs Setup";
    begin
        // Verify that system defined entries can't be deleted.
        JobWIPMethod.SetRange("System Defined", true);
        asserterror JobWIPMethod.DeleteAll(true);
        // Verify that user defined entries can be deleted.
        JobWIPMethod.SetRange("System Defined", false);
        CreateUserDefinedEntry(JobWIPMethod);
        Assert.IsTrue(JobWIPMethod.Delete(true), 'User defined Job WIP Method could not be deleted.');
        // Verify that entries with referenced WIP entries can't be deleted.
        CreateUserDefinedEntry(JobWIPMethod);
        JobWIPEntry.Init();
        JobWIPEntry."WIP Method Used" := JobWIPMethod.Code;
        JobWIPEntry.Insert();
        asserterror JobWIPMethod.Delete(true);
        // Verify that the default WIP Method can't be deleted.
        JobsSetup.Get();
        CreateUserDefinedEntry(JobWIPMethod);
        JobsSetup.Validate("Default WIP Method", JobWIPMethod.Code);
        JobsSetup.Modify();
        asserterror JobWIPMethod.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFieldSystemDefined()
    var
        JobWIPMethod: Record "Job WIP Method";
    begin
        // Verify that system defined entries can't be modified.
        JobWIPMethod.SetRange("System Defined", true);
        JobWIPMethod.FindFirst();
        asserterror JobWIPMethod.Validate(Code, 'Test');
        asserterror JobWIPMethod.Validate(Description, 'Test');
        asserterror JobWIPMethod.Validate("WIP Cost", not JobWIPMethod."WIP Cost");
        asserterror JobWIPMethod.Validate("WIP Sales", not JobWIPMethod."WIP Sales");
        asserterror JobWIPMethod.Validate("Recognized Costs", JobWIPMethod."Recognized Costs"::"At Completion");
        asserterror JobWIPMethod.Validate("Recognized Sales", JobWIPMethod."Recognized Sales"::"At Completion");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFieldValid()
    var
        JobWIPMethod: Record "Job WIP Method";
        JobsSetup: Record "Jobs Setup";
    begin
        // Verify that "Valid" from the default WIP Method can't be unchecked.
        JobsSetup.Get();
        CreateUserDefinedEntry(JobWIPMethod);
        JobsSetup.Validate("Default WIP Method", JobWIPMethod.Code);
        JobsSetup.Modify();
        asserterror JobWIPMethod.Validate(Valid, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFieldWIPCost()
    var
        JobWIPMethod: Record "Job WIP Method";
    begin
        // Verify that you can't uncheck WIP Costs, unless "Recognized Costs" is "Usage (Total Cost)"
        CreateUserDefinedEntry(JobWIPMethod);
        JobWIPMethod.SetRange("System Defined", false);
        JobWIPMethod.SetFilter("Recognized Costs", '<> %1', JobWIPMethod."Recognized Costs"::"Usage (Total Cost)");
        if JobWIPMethod.FindFirst() then
            asserterror JobWIPMethod.Validate("WIP Cost", false);
        // Verify that you can uncheck WIP Costs, if "Recognized Costs" is "Usage (Total Cost)"
        JobWIPMethod.Reset();
        CreateUserDefinedEntry(JobWIPMethod);
        JobWIPMethod.SetRange("System Defined", false);
        JobWIPMethod.FindFirst();
        JobWIPMethod.Validate("Recognized Costs", JobWIPMethod."Recognized Costs"::"Usage (Total Cost)");
        JobWIPMethod.Validate("WIP Cost", false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFieldWIPSales()
    var
        JobWIPMethod: Record "Job WIP Method";
    begin
        // Verify that you can't uncheck WIP Sales, unless "Recognized Sales" is "Contract (Invoiced Price)"
        CreateUserDefinedEntry(JobWIPMethod);
        JobWIPMethod.SetRange("System Defined", false);
        JobWIPMethod.SetFilter("Recognized Sales", '<> %1', JobWIPMethod."Recognized Sales"::"Contract (Invoiced Price)");
        if JobWIPMethod.FindFirst() then
            asserterror JobWIPMethod.Validate("WIP Sales", false);
        // Verify that you can uncheck WIP Sales, if "Recognized Sales" is "Contract (Invoiced Price)"
        JobWIPMethod.Reset();
        CreateUserDefinedEntry(JobWIPMethod);
        JobWIPMethod.SetRange("System Defined", false);
        JobWIPMethod.FindFirst();
        JobWIPMethod.Validate("Recognized Sales", JobWIPMethod."Recognized Sales"::"Contract (Invoiced Price)");
        JobWIPMethod.Validate("WIP Sales", false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFieldRecognCosts()
    var
        JobWIPMethod: Record "Job WIP Method";
        JobWIPEntry: Record "Job WIP Entry";
    begin
        // Verify that WIP Cost is checked, if "Recognized Costs" anything else than "Usage (Total Cost)"
        CreateUserDefinedEntry(JobWIPMethod);
        JobWIPMethod.Validate("Recognized Costs", JobWIPMethod."Recognized Costs"::"Usage (Total Cost)");
        JobWIPMethod.Validate("WIP Cost", false);
        JobWIPMethod.Validate("Recognized Costs", JobWIPMethod."Recognized Costs"::"Cost of Sales");
        Assert.IsTrue(JobWIPMethod."WIP Cost", 'WIP Cost is not true after Recognized Costs is set to something else than Usage (Total Cost).');
        // Verify that "Recognized Costs" from the default WIP Method can't be unchecked.
        CreateUserDefinedEntry(JobWIPMethod);
        JobWIPEntry.Init();
        JobWIPEntry."WIP Method Used" := JobWIPMethod.Code;
        JobWIPEntry.Insert();
        asserterror JobWIPMethod.Validate("Recognized Costs", LibraryRandom.RandInt(4));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFieldRecognSales()
    var
        JobWIPMethod: Record "Job WIP Method";
        JobWIPEntry: Record "Job WIP Entry";
    begin
        // Verify that WIP Sales is checked, if "Recognized Sales" anything else than "Contract (Invoiced Price)"
        CreateUserDefinedEntry(JobWIPMethod);
        JobWIPMethod.Validate("Recognized Sales", JobWIPMethod."Recognized Sales"::"Contract (Invoiced Price)");
        JobWIPMethod.Validate("WIP Sales", false);
        JobWIPMethod.Validate("Recognized Sales", JobWIPMethod."Recognized Sales"::"Sales Value");
        Assert.IsTrue(
          JobWIPMethod."WIP Sales",
          'WIP Sales is not true after Recognized Sales is set to something else than Contract (Invoiced Price).');
        // Verify that "Recognized Sales" from the default WIP Method can't be unchecked.
        CreateUserDefinedEntry(JobWIPMethod);
        JobWIPEntry.Init();
        JobWIPEntry."WIP Method Used" := JobWIPMethod.Code;
        JobWIPEntry.Insert();
        asserterror JobWIPMethod.Validate("Recognized Sales", LibraryRandom.RandInt(4));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateUserDefinedEntry()
    var
        JobWIPMethod: Record "Job WIP Method";
    begin
        CreateUserDefinedEntry(JobWIPMethod);
        Assert.IsFalse(JobWIPMethod."System Defined", 'User Defined Entry has System Defined flag set.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UTErrorOnValidateWIPCostJobWIPMethod()
    var
        JobWIPMethod: Record "Job WIP Method";
    begin
        // [SCENARIO 376881] Error must be thrown on validating "Job WIP Method"."WIP Cost" when "Recognized Cost" is not equal to "Usage (Total Cost)"

        // [GIVEN] Record "Job WIP Method" with "Recognized Cost" <> "Usage (Total Cost)"
        JobWIPMethod.Init();
        JobWIPMethod."System Defined" := false;
        JobWIPMethod."Recognized Costs" := "Job WIP Recognized Costs Type".FromInteger(LibraryRandom.RandInt(4));

        // [WHEN] Validate "WIP Cost"
        asserterror JobWIPMethod.Validate("WIP Cost", true);

        // [THEN] Error "You cannot modify this field..." must be thrown
        Assert.ExpectedError(StrSubstNo(Text003Txt, JobWIPMethod.FieldCaption("Recognized Costs"), JobWIPMethod."Recognized Costs"));
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ChangeWIPMethodInJobWhenJobTaskHasTotalCost()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        JobWIPMethod: array[2] of Record "Job WIP Method";
    begin
        // [SCENARIO 351676] Stan can change the "WIP Method" on Job when there is related Job Task with total cost

        LibraryJob.CreateJob(Job);
        CreateUserDefinedEntry(JobWIPMethod[1]);
        Job.Validate("WIP Method", JobWIPMethod[1].Code);
        Job.Modify(true);
        LibraryJob.CreateJobTask(Job, JobTask);
        JobTask.Validate("WIP-Total", JobTask."WIP-Total"::Total);
        JobTask.Modify(true);

        CreateJobLedgerEntry(Job."No.");
        CreateUserDefinedEntry(JobWIPMethod[2]);
        LibraryVariableStorage.Enqueue(StrSubstNo(WIPMethodQst, JobTask.FieldCaption("WIP Method"), JobTask.TableCaption(), JobTask."WIP-Total"::Total));

        Job.Validate("WIP Method", JobWIPMethod[2].Code);
        Job.Modify(true);

        Job.Find();
        Job.TestField("WIP Method", JobWIPMethod[2].Code);
        Job.TestField("Over Budget", true);
        JobTask.Find();
        JobTask.TestField("WIP Method", JobWIPMethod[2].Code);

        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure CreateUserDefinedEntry(var JobWIPMethod: Record "Job WIP Method")
    begin
        JobWIPMethod.Init();
        JobWIPMethod.Code := LibraryUtility.GenerateRandomCode(JobWIPMethod.FieldNo(Code), DATABASE::"Job WIP Method");
        JobWIPMethod.Description := 'WIPTEST';
        JobWIPMethod."WIP Cost" := true;
        JobWIPMethod."WIP Sales" := true;
        JobWIPMethod."Recognized Costs" := "Job WIP Recognized Costs Type".FromInteger(LibraryRandom.RandInt(4));
        JobWIPMethod."Recognized Sales" := "Job WIP Recognized Sales Type".FromInteger(LibraryRandom.RandInt(5));
        JobWIPMethod.Valid := true;
        JobWIPMethod.Insert(true);
    end;

    local procedure CreateJobLedgerEntry(JobNo: Code[20])
    var
        JobLedgerEntry: Record "Job Ledger Entry";
    begin
        JobLedgerEntry.Init();
        JobLedgerEntry."Entry No." :=
          LibraryUtility.GetNewRecNo(JobLedgerEntry, JobLedgerEntry.FieldNo("Entry No."));
        JobLedgerEntry."Job No." := JobNo;
        JobLedgerEntry."Total Cost (LCY)" := LibraryRandom.RandDec(100, 2);
        JobLedgerEntry.Insert();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        Assert.AreEqual(LibraryVariableStorage.DequeueText(), Question, '');
        Reply := true;
    end;
}

