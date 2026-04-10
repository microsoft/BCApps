codeunit 136358 "UT T Purchase Line Usage Link"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Purchase] [Job]
    end;

    var
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        LibraryPurchase: Codeunit "Library - Purchase";
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        Text001: Label 'Rolling back changes.';
        IsInitialized: Boolean;

    [Normal]
    local procedure SetUp()
    var
        Item: Record Item;
        LibraryJob: Codeunit "Library - Job";
        LibraryInventory: Codeunit "Library - Inventory";
    begin
        LibraryJob.CreateJob(Job);
        Job.Validate("Apply Usage Link", true);
        Job.Modify();
        LibraryJob.CreateJobTask(Job, JobTask);
        LibraryJob.CreateJobPlanningLine(JobPlanningLine."Line Type"::Budget, JobPlanningLine.Type::Item, JobTask, JobPlanningLine);
        JobPlanningLine.Validate("No.", LibraryInventory.CreateItem(Item));
        JobPlanningLine.Validate(Quantity, LibraryRandom.RandInt(1000));
        JobPlanningLine.Modify();

        LibraryPurchase.CreateVendor(Vendor);

        PurchaseHeader.Init();
        PurchaseHeader.Validate("Document Type", PurchaseHeader."Document Type"::Order);
        PurchaseHeader.Validate("Buy-from Vendor No.", Vendor."No.");
        PurchaseHeader.Insert(true);

        PurchaseLine.Init();
        PurchaseLine.Validate("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.Validate("Document No.", PurchaseHeader."No.");
        case JobPlanningLine.Type of
            JobPlanningLine.Type::Item:
                PurchaseLine.Validate(Type, PurchaseLine.Type::Item);
            JobPlanningLine.Type::"G/L Account":
                PurchaseLine.Validate(Type, PurchaseLine.Type::"G/L Account");
        end;
        PurchaseLine.Validate("No.", JobPlanningLine."No.");
        PurchaseLine.Validate("Job No.", Job."No.");
        PurchaseLine.Validate("Job Task No.", JobTask."Job Task No.");
        PurchaseLine.Validate("Job Line Type", PurchaseLine."Job Line Type"::Budget);
        PurchaseLine.Insert(true);
    end;

    [Normal]
    local procedure TearDown()
    begin
        Clear(Job);
        Clear(JobTask);
        Clear(JobPlanningLine);
        Clear(PurchaseHeader);
        Clear(PurchaseLine);
        Clear(Vendor);

        asserterror Error(Text001);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestInitialization()
    begin
        Initialize();

        SetUp();

        // Verify that "Job Planning Line No." is initialized correctly.
        Assert.AreEqual(0, PurchaseLine."Job Planning Line No.", 'Job Planning Line No. is not 0 by default.');

        // Verify that "Remaining Qty." is initialized correctly.
        Assert.AreEqual(0, PurchaseLine."Job Remaining Qty.", 'Remaining Qty. is not 0 by default.');

        // Verify that "Remaining Qty." is initialized correctly.
        Assert.AreEqual(0, PurchaseLine."Job Remaining Qty. (Base)", 'Remaining Qty. is not 0 by default.');

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFieldLineType()
    begin
        Initialize();

        SetUp();

        // Verify that "Line Type" is set to the correct value when a "Job Planning Line No." is set.
        PurchaseLine.Validate("Job Line Type", 0);
        PurchaseLine.Validate("Job Planning Line No.", JobPlanningLine."Line No.");
        Assert.AreEqual(JobPlanningLine."Line Type", PurchaseLine."Job Line Type".AsInteger() - 1,
          'Line type is not set correctly when Job Planning Line No. is defined.');

        // Verify that "Line Type" can't be changed if a "Job Planning Line No." is defined.
        asserterror PurchaseLine.Validate("Job Line Type", 0);

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFieldJobPlanningLineNo()
    begin
        Initialize();

        SetUp();

        // Verify that "Job Planning Line No." and "Remaining Qty." are blanked when the No. changes.
        PurchaseLine.Validate("Job Planning Line No.", JobPlanningLine."Line No.");
        PurchaseLine.TestField("Job Planning Line No.");
        PurchaseLine.Validate("No.", '');
        Assert.AreEqual(0, PurchaseLine."Job Planning Line No.", 'Job Planning Line No. is not 0 when No. changes.');
        Assert.AreEqual(0, PurchaseLine."Job Remaining Qty.", 'Remaining Qty. is not 0 when No. changes.');
        Assert.AreEqual(0, PurchaseLine."Job Remaining Qty. (Base)", 'Remaining Qty. (Base) is not 0 when No. changes.');

        TearDown();

        SetUp();

        // Verify that "Job Planning Line No." is blanked when the Job No. changes.
        PurchaseLine.Validate("Job Planning Line No.", JobPlanningLine."Line No.");
        PurchaseLine.TestField("Job Planning Line No.");
        PurchaseLine.Validate("Job No.", '');
        Assert.AreEqual(0, PurchaseLine."Job Planning Line No.", 'Job Planning Line No. is not 0 when Job No. changes.');

        // Remaining test for this field are found in test function TestFieldRemainingQty.

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFieldRemainingQty()
    var
        QtyDelta: Decimal;
        OldRemainingQty: Decimal;
    begin
        Initialize();

        SetUp();

        // Verify that "Remaining Qty." can't be set if "Job Planning Line No." isn't set.
        asserterror PurchaseLine.Validate("Job Remaining Qty.", LibraryRandom.RandInt(Round(PurchaseLine.Quantity, 1)));

        TearDown();

        SetUp();

        // Verify that "Remaining Qty." is set correctly when a "Job Planning Line No." is defined.
        PurchaseLine.TestField("Job Planning Line No.", 0);
        PurchaseLine.TestField("Job Remaining Qty.", 0);
        PurchaseLine.TestField("Job Remaining Qty. (Base)", 0);
        PurchaseLine.TestField(Quantity, 0);
        PurchaseLine.Validate("Job Planning Line No.", JobPlanningLine."Line No.");
        PurchaseLine.TestField("Job Remaining Qty.", JobPlanningLine."Remaining Qty.");
        PurchaseLine.TestField("Job Remaining Qty. (Base)",
          Round(PurchaseLine."Job Remaining Qty." * PurchaseLine."Qty. per Unit of Measure", 0.00001));

        // Verify that "Remaining Qty." changes correctly when Quantity is changed.
        OldRemainingQty := PurchaseLine."Job Remaining Qty.";
        QtyDelta := LibraryRandom.RandInt(Round(PurchaseLine."Job Remaining Qty.", 1));
        PurchaseLine.Validate(Quantity, PurchaseLine.Quantity + QtyDelta);
        PurchaseLine.TestField("Job Remaining Qty.", OldRemainingQty - QtyDelta);
        PurchaseLine.TestField("Job Remaining Qty. (Base)",
          Round(PurchaseLine."Job Remaining Qty." * PurchaseLine."Qty. per Unit of Measure", 0.00001));

        TearDown();
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"UT T Purchase Line Usage Link");

        if IsInitialized then
            exit;

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        IsInitialized := true;
        Commit();
    end;
}

