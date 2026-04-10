codeunit 134465 "ERM Increment Batch Name Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Journal Batch]
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryJob: Codeunit "Library - Job";
        LibraryResource: Codeunit "Library - Resource";
        IsInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure TestGeneralJournalWithIncrement()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        AccountNo: Code[20];
        BalAccountNo: Code[20];
        BatchName: Code[10];
    begin
        Initialize();

        // [GIVEN] Journal Batch 'BATCH00001', where "Increment Batch Name" is 'Yes'
        AccountNo := LibraryERM.CreateGLAccountNoWithDirectPosting();
        BalAccountNo := LibraryERM.CreateGLAccountNoWithDirectPosting();
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        GenJournalTemplate."Increment Batch Name" := true;
        GenJournalTemplate.Modify();

        // [GIVEN] Journal Line in the Batch 'BATCH00001'
        CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        BatchName := GenJournalBatch.Name;
        LibraryERM.CreateGeneralJnlLineWithBalAcc(
          GenJournalLine, GenJournalTemplate.Name, GenJournalBatch.Name, "Gen. Journal Document Type"::" ",
          GenJournalLine."Account Type"::"G/L Account", AccountNo,
          GenJournalLine."Bal. Account Type"::"G/L Account", BalAccountNo, 100);

        // [WHEN] Post the batch 'BATCH00001'
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Batch 'BATCH001' does not exist, batch 'BATCH002' does exist.
        Assert.IsFalse(
          GenJournalBatch.Get(GenJournalTemplate.Name, BatchName), StrSubstNo('%1 should be deleted.', BatchName));
        Assert.IsTrue(
          GenJournalBatch.Get(GenJournalTemplate.Name, IncStr(BatchName)), StrSubstNo('%1 should be created.', IncStr(BatchName)));

        // CLEAR
        GenJournalTemplate.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGeneralJournalWithoutIncrement()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        AccountNo: Code[20];
        BalAccountNo: Code[20];
        BatchName: Code[10];
    begin
        Initialize();

        // [GIVEN] Journal Batch 'BATCH00001', where "Increment Batch Name" is 'No'
        AccountNo := LibraryERM.CreateGLAccountNoWithDirectPosting();
        BalAccountNo := LibraryERM.CreateGLAccountNoWithDirectPosting();
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);

        // [GIVEN] Journal Line in the Batch 'BATCH00001'
        CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        BatchName := GenJournalBatch.Name;
        LibraryERM.CreateGeneralJnlLineWithBalAcc(
          GenJournalLine, GenJournalTemplate.Name, GenJournalBatch.Name, "Gen. Journal Document Type"::" ",
          GenJournalLine."Account Type"::"G/L Account", AccountNo,
          GenJournalLine."Bal. Account Type"::"G/L Account", BalAccountNo, 100);

        // [WHEN] Post the batch 'BATCH00001'
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Batch 'BATCH001' does exist, batch 'BATCH002' does not exist.
        Assert.IsTrue(
          GenJournalBatch.Get(GenJournalTemplate.Name, BatchName), StrSubstNo('%1 should exists.', BatchName));
        Assert.IsFalse(
          GenJournalBatch.Get(GenJournalTemplate.Name, IncStr(BatchName)), StrSubstNo('%1 should not exists.', IncStr(BatchName)));

        // CLEAR
        GenJournalTemplate.Delete(true);
    end;

    // [Test]
    // [Scope('OnPrem')]
    procedure TestItemJournalWithIncrement()
    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalBatch: Record "Item Journal Batch";
        BatchName: Code[10];
    begin
        Initialize();

        // [GIVEN] Journal Batch 'BATCH00001', where "Increment Batch Name" is 'Yes'
        LibraryInventory.CreateItemJournalTemplate(ItemJournalTemplate);
        ItemJournalTemplate."Increment Batch Name" := true;
        ItemJournalTemplate.Modify();

        // [GIVEN] Journal Line in the Batch 'BATCH00001'
        CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);
        BatchName := ItemJournalBatch.Name;
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name, "Item Ledger Entry Type"::" ",
          LibraryInventory.CreateItemNo(), 100);

        // [WHEN] Post the batch 'BATCH00001'
        LibraryInventory.PostItemJournalLine(ItemJournalTemplate.Name, ItemJournalBatch.Name);

        // [THEN] Batch 'BATCH001' does not exist, batch 'BATCH002' does exist.
        Assert.IsFalse(
          ItemJournalBatch.Get(ItemJournalTemplate.Name, BatchName), StrSubstNo('%1 should be deleted.', BatchName));
        Assert.IsTrue(
          ItemJournalBatch.Get(ItemJournalTemplate.Name, IncStr(BatchName)), StrSubstNo('%1 should be created.', IncStr(BatchName)));

        // CLEAR
        ItemJournalTemplate.Delete(true);
    end;

    // [Test]
    // [Scope('OnPrem')]
    procedure TestItemJournalWithoutIncrement()
    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalBatch: Record "Item Journal Batch";
        BatchName: Code[10];
    begin
        Initialize();

        // [GIVEN] Journal Batch 'BATCH00001', where "Increment Batch Name" is 'No'
        LibraryInventory.CreateItemJournalTemplate(ItemJournalTemplate);

        // [GIVEN] Journal Line in the Batch 'BATCH00001'
        CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);
        BatchName := ItemJournalBatch.Name;
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name, "Item Ledger Entry Type"::" ",
          LibraryInventory.CreateItemNo(), 100);

        // [WHEN] Post the batch 'BATCH00001'
        LibraryInventory.PostItemJournalLine(ItemJournalTemplate.Name, ItemJournalBatch.Name);

        // [THEN] Batch 'BATCH001' exists, batch 'BATCH002' does not exist.
        Assert.IsTrue(
          ItemJournalBatch.Get(ItemJournalTemplate.Name, BatchName), StrSubstNo('%1 should exists.', BatchName));
        Assert.IsFalse(
          ItemJournalBatch.Get(ItemJournalTemplate.Name, IncStr(BatchName)), StrSubstNo('%1 should not exists.', IncStr(BatchName)));

        // CLEAR
        ItemJournalTemplate.Delete(true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure TestResourceJournalWithIncrement()
    var
        ResJournalTemplate: Record "Res. Journal Template";
        ResJournalLine: Record "Res. Journal Line";
        ResJournalBatch: Record "Res. Journal Batch";
        BatchName: Code[10];
    begin
        Initialize();

        // [GIVEN] Journal Batch 'BATCH00001', where "Increment Batch Name" is 'Yes'
        LibraryResource.CreateResourceJournalTemplate(ResJournalTemplate);
        ResJournalTemplate."Increment Batch Name" := true;
        ResJournalTemplate.Modify();

        // [GIVEN] Journal Line in the Batch 'BATCH00001'
        CreateResJournalBatch(ResJournalBatch, ResJournalTemplate.Name);
        BatchName := ResJournalBatch.Name;
        LibraryResource.CreateResJournalLine(ResJournalLine, ResJournalTemplate.Name, ResJournalBatch.Name);
        ResJournalLine.Validate("Posting Date", WorkDate());
        ResJournalLine.Validate("Entry Type", ResJournalLine."Entry Type"::Sale);
        ResJournalLine.Validate("Resource No.", LibraryResource.CreateResourceNo());
        ResJournalLine.Validate("Document No.", ResJournalLine."Resource No.");
        ResJournalLine.Validate("Unit Price", 100);
        ResJournalLine.Modify(true);

        // [WHEN] Post the batch 'BATCH00001'
        LibraryResource.PostResourceJournalLine(ResJournalLine);

        // [THEN] Batch 'BATCH001' does not exist, batch 'BATCH002' does exist.
        Assert.IsFalse(
          ResJournalBatch.Get(ResJournalTemplate.Name, BatchName), StrSubstNo('%1 should be deleted.', BatchName));
        Assert.IsTrue(
          ResJournalBatch.Get(ResJournalTemplate.Name, IncStr(BatchName)), StrSubstNo('%1 should be created.', IncStr(BatchName)));

        // CLEAR
        ResJournalTemplate.Delete(true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure TestResourceJournalWithoutIncrement()
    var
        ResJournalTemplate: Record "Res. Journal Template";
        ResJournalLine: Record "Res. Journal Line";
        ResJournalBatch: Record "Res. Journal Batch";
        BatchName: Code[10];
    begin
        Initialize();

        // [GIVEN] Journal Batch 'BATCH00001', where "Increment Batch Name" is 'No'
        LibraryResource.CreateResourceJournalTemplate(ResJournalTemplate);

        // [GIVEN] Journal Line in the Batch 'BATCH00001'
        CreateResJournalBatch(ResJournalBatch, ResJournalTemplate.Name);
        BatchName := ResJournalBatch.Name;
        LibraryResource.CreateResJournalLine(ResJournalLine, ResJournalTemplate.Name, ResJournalBatch.Name);
        ResJournalLine.Validate("Posting Date", WorkDate());
        ResJournalLine.Validate("Entry Type", ResJournalLine."Entry Type"::Sale);
        ResJournalLine.Validate("Resource No.", LibraryResource.CreateResourceNo());
        ResJournalLine.Validate("Document No.", ResJournalLine."Resource No.");
        ResJournalLine.Validate("Unit Price", 100);
        ResJournalLine.Modify(true);

        // [WHEN] Post the batch 'BATCH00001'
        LibraryResource.PostResourceJournalLine(ResJournalLine);

        // [THEN] Batch 'BATCH001' exists, batch 'BATCH002' does not exist.
        Assert.IsTrue(
          ResJournalBatch.Get(ResJournalTemplate.Name, BatchName), StrSubstNo('%1 should exists.', BatchName));
        Assert.IsFalse(
          ResJournalBatch.Get(ResJournalTemplate.Name, IncStr(BatchName)), StrSubstNo('%1 should not exist.', IncStr(BatchName)));

        // CLEAR
        ResJournalTemplate.Delete(true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure TestJobJournalWithIncrement()
    var
        Job: Record Job;
        JobJournalTemplate: Record "Job Journal Template";
        JobJournalLine: Record "Job Journal Line";
        JobJournalBatch: Record "Job Journal Batch";
        JobTask: Record "Job Task";
        BatchName: Code[10];
    begin
        Initialize();

        // [GIVEN] Create job and post journal line
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
        LibraryJob.CreateJobJournalLine(JobJournalLine."Line Type"::" ", JobTask, JobJournalLine);
        JobJournalLine.Validate("No.", LibraryResource.CreateResourceNo());
        JobJournalLine.Validate(Quantity, 1);
        JobJournalLine.Validate("Unit Price (LCY)", 100);
        JobJournalLine.Modify(true);

        // [GIVEN] Journal Batch 'BATCH00001', where "Increment Batch Name" is 'Yes'
        JobJournalTemplate.Get(JobJournalLine."Journal Template Name");
        JobJournalTemplate."Increment Batch Name" := true;
        JobJournalTemplate.Modify();
        BatchName := JobJournalLine."Journal Batch Name";

        // [WHEN] Post the batch 'BATCH00001'
        LibraryJob.PostJobJournal(JobJournalLine);

        // [THEN] Batch 'BATCH001' does not exist, batch 'BATCH002' does exist.
        Assert.IsFalse(
          JobJournalBatch.Get(JobJournalTemplate.Name, BatchName), StrSubstNo('%1 should be deleted.', BatchName));
        Assert.IsTrue(
          JobJournalBatch.Get(JobJournalTemplate.Name, IncStr(BatchName)), StrSubstNo('%1 should be created.', IncStr(BatchName)));

        // CLEAR
        JobJournalTemplate.Delete(true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure TestJobJournalWithoutIncrement()
    var
        Job: Record Job;
        JobJournalTemplate: Record "Job Journal Template";
        JobJournalLine: Record "Job Journal Line";
        JobJournalBatch: Record "Job Journal Batch";
        JobTask: Record "Job Task";
        BatchName: Code[10];
    begin
        Initialize();

        // [GIVEN] Create job and post journal line
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
        LibraryJob.CreateJobJournalLine(JobJournalLine."Line Type", JobTask, JobJournalLine);
        JobJournalLine.Validate("No.", LibraryResource.CreateResourceNo());
        JobJournalLine.Validate(Quantity, 1);
        JobJournalLine.Validate("Unit Price (LCY)", 100);
        JobJournalLine.Modify(true);

        // [GIVEN] Journal Batch 'BATCH00001', where "Increment Batch Name" is 'No'
        JobJournalTemplate.Get(JobJournalLine."Journal Template Name");
        BatchName := JobJournalLine."Journal Batch Name";

        // [WHEN] Post the batch 'BATCH00001'
        LibraryJob.PostJobJournal(JobJournalLine);

        // [THEN] Batch 'BATCH001' exists, batch 'BATCH002' does not exist.
        Assert.IsTrue(
          JobJournalBatch.Get(JobJournalTemplate.Name, BatchName), StrSubstNo('%1 should exists.', BatchName));
        Assert.IsFalse(
          JobJournalBatch.Get(JobJournalTemplate.Name, IncStr(BatchName)), StrSubstNo('%1 should not exist.', IncStr(BatchName)));

        // CLEAR
        JobJournalTemplate.Delete(true);
    end;

    local procedure Initialize()
    begin
        if IsInitialized then
            exit;

        IsInitialized := true;
        Commit();
    end;

    local procedure CreateGenJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch"; JournalTemplateName: Code[10])
    begin
        GenJournalBatch.Init();
        GenJournalBatch.Validate("Journal Template Name", JournalTemplateName);
        GenJournalBatch.Validate(Name, 'BATCH00001');
        GenJournalBatch.Validate(Description, GenJournalBatch.Name);
        GenJournalBatch.Insert();
    end;

    local procedure CreateItemJournalBatch(var ItemJournalBatch: Record "Item Journal Batch"; JournalTemplateName: Code[10])
    begin
        ItemJournalBatch.Init();
        ItemJournalBatch.Validate("Journal Template Name", JournalTemplateName);
        ItemJournalBatch.Validate(Name, 'BATCH00001');
        ItemJournalBatch.Validate(Description, ItemJournalBatch.Name);
        ItemJournalBatch.Insert();
    end;

    local procedure CreateResJournalBatch(var ResJournalBatch: Record "Res. Journal Batch"; JournalTemplateName: Code[10])
    begin
        ResJournalBatch.Init();
        ResJournalBatch.Validate("Journal Template Name", JournalTemplateName);
        ResJournalBatch.Validate(Name, 'BATCH00001');
        ResJournalBatch.Validate(Description, ResJournalBatch.Name);
        ResJournalBatch.Insert();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;
}

