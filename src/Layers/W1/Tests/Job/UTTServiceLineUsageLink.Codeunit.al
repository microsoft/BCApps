codeunit 136360 "UT T Service Line Usage Link"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Service] [Job]
    end;

    var
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        Customer: Record Customer;
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryJob: Codeunit "Library - Job";
        LibraryInventory: Codeunit "Library - Inventory";
        Assert: Codeunit Assert;
        Text001: Label 'Rolling back changes.';

    [Normal]
    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        Item: Record Item;
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"UT T Service Line Usage Link");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();

        LibraryJob.CreateJob(Job);
        Job.Validate("Apply Usage Link", true);
        Job.Modify();
        LibraryJob.CreateJobTask(Job, JobTask);
        LibraryJob.CreateJobPlanningLine(JobPlanningLine."Line Type"::Budget, JobPlanningLine.Type::Item, JobTask, JobPlanningLine);
        JobPlanningLine.Validate("No.", LibraryInventory.CreateItem(Item));
        JobPlanningLine.Validate(Quantity, LibraryRandom.RandInt(1000));
        JobPlanningLine.Modify();

        LibrarySales.CreateCustomer(Customer);

        ServiceHeader.Init();
        ServiceHeader.SetHideValidationDialog(true);
        ServiceHeader.Validate("Document Type", ServiceHeader."Document Type"::Order);
        ServiceHeader.Validate("Customer No.", Customer."No.");
        ServiceHeader.Insert(true);

        ServiceLine.Init();
        ServiceLine.Validate("Document Type", ServiceHeader."Document Type");
        ServiceLine.Validate("Document No.", ServiceHeader."No.");
        case JobPlanningLine.Type of
            JobPlanningLine.Type::Item:
                ServiceLine.Validate(Type, ServiceLine.Type::Item);
            JobPlanningLine.Type::Resource:
                ServiceLine.Validate(Type, ServiceLine.Type::Resource);
            JobPlanningLine.Type::"G/L Account":
                ServiceLine.Validate(Type, ServiceLine.Type::"G/L Account");
        end;
        ServiceLine.Validate("No.", JobPlanningLine."No.");
        ServiceLine."Job No." := Job."No.";
        ServiceLine."Job Task No." := JobTask."Job Task No.";
        ServiceLine."Job Line Type" := ServiceLine."Job Line Type"::Budget;
        ServiceLine.Insert(true);
    end;

    [Normal]
    local procedure TearDown()
    begin
        Clear(Job);
        Clear(JobTask);
        Clear(JobPlanningLine);
        Clear(ServiceHeader);
        Clear(ServiceLine);
        Clear(Customer);

        asserterror Error(Text001);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestInitialization()
    begin
        Initialize();

        // Verify that "Job Planning Line No." is initialized correctly.
        Assert.AreEqual(0, ServiceLine."Job Planning Line No.", 'Job Planning Line No. is not 0 by default.');

        // Verify that "Remaining Qty." is initialized correctly.
        Assert.AreEqual(0, ServiceLine."Job Remaining Qty.", 'Remaining Qty. is not 0 by default.');

        // Verify that "Remaining Qty." is initialized correctly.
        Assert.AreEqual(0, ServiceLine."Job Remaining Qty. (Base)", 'Remaining Qty. is not 0 by default.');

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFieldLineType()
    begin
        Initialize();

        // Verify that "Line Type" is set to the correct value when a "Job Planning Line No." is set.
        ServiceLine.Validate("Job Line Type", 0);
        ServiceLine.Validate("Job Planning Line No.", JobPlanningLine."Line No.");
        Assert.AreEqual(JobPlanningLine."Line Type", ServiceLine."Job Line Type".AsInteger() - 1,
          'Line type is not set correctly when Job Planning Line No. is defined.');

        // Verify that "Line Type" can't be changed if a "Job Planning Line No." is defined.
        asserterror ServiceLine.Validate("Job Line Type", 0);

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFieldJobPlanningLineNo()
    begin
        Initialize();

        // Verify that "Job Planning Line No." and "Remaining Qty." are blanked when the No. changes.
        ServiceLine.Validate("Job Planning Line No.", JobPlanningLine."Line No.");
        ServiceLine.TestField("Job Planning Line No.");
        ServiceLine.Validate("No.", '');
        Assert.AreEqual(0, ServiceLine."Job Planning Line No.", 'Job Planning Line No. is not 0 when No. changes.');
        Assert.AreEqual(0, ServiceLine."Job Remaining Qty.", 'Remaining Qty. is not 0 when No. changes.');
        Assert.AreEqual(0, ServiceLine."Job Remaining Qty. (Base)", 'Remaining Qty. (Base) is not 0 when No. changes.');

        TearDown();

        Initialize();

        // Verify that "Job Planning Line No." is blanked when the Job No. changes.
        ServiceLine.Validate("Job Planning Line No.", JobPlanningLine."Line No.");
        ServiceLine.TestField("Job Planning Line No.");
        ServiceLine.Validate("Job No.", '');
        Assert.AreEqual(0, ServiceLine."Job Planning Line No.", 'Job Planning Line No. is not 0 when Job No. changes.');

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

        // Verify that "Remaining Qty." can't be set if "Job Planning Line No." isn't set.
        asserterror ServiceLine.Validate("Job Remaining Qty.", LibraryRandom.RandInt(Round(ServiceLine.Quantity, 1)));

        TearDown();

        Initialize();

        // Verify that "Remaining Qty." is set correctly when a "Job Planning Line No." is defined.
        ServiceLine.TestField("Job Planning Line No.", 0);
        ServiceLine.TestField("Job Remaining Qty.", 0);
        ServiceLine.TestField("Job Remaining Qty. (Base)", 0);
        ServiceLine.TestField(Quantity, 0);
        ServiceLine.Validate("Job Planning Line No.", JobPlanningLine."Line No.");
        Assert.AreEqual(JobPlanningLine."Remaining Qty.", ServiceLine."Job Remaining Qty.", 'Remaining Qty. is not set correctly');
        Assert.AreEqual(JobPlanningLine."Remaining Qty. (Base)", ServiceLine."Job Remaining Qty. (Base)",
          'Remaining Qty. (Base) is not set correctly');

        Assert.AreNearlyEqual(ServiceLine."Job Remaining Qty." * ServiceLine."Unit Cost", ServiceLine."Job Remaining Total Cost", 0.01,
          'Remaining Total Cost has wrong value after Remaining Qty is set.');
        Assert.AreNearlyEqual(ServiceLine."Job Remaining Qty." * ServiceLine."Unit Cost (LCY)", ServiceLine."Job Remaining Total Cost (LCY)", 0.01,
          'Remaining Total Cost (LCY) has wrong value after Remaining Qty is set.');
        Assert.AreNearlyEqual(HelperCalcLineAmount(ServiceLine."Job Remaining Qty."), ServiceLine."Job Remaining Line Amount", 0.01,
          'Remaining Line Amount has wrong value after Remaining Qty is set.');

        // Verify that "Remaining Qty." changes correctly when Quantity is changed.
        OldRemainingQty := ServiceLine."Job Remaining Qty.";
        QtyDelta := LibraryRandom.RandInt(Round(ServiceLine."Job Remaining Qty.", 1));
        ServiceLine.Validate(Quantity, ServiceLine.Quantity + QtyDelta);
        Assert.AreEqual(OldRemainingQty - QtyDelta, ServiceLine."Job Remaining Qty.",
          'Remaining Qty. is not updated correctly');
        // Test only valid because no Unit Of Measure Code is defined:
        ServiceLine.TestField("Qty. per Unit of Measure", 1);
        Assert.AreEqual(ServiceLine."Job Remaining Qty.", ServiceLine."Job Remaining Qty. (Base)",
          'Remaining Qty. (Base) is not updated correctly');

        TearDown();
    end;

    [Normal]
    local procedure HelperCalcLineAmount(Qty: Decimal): Decimal
    var
        TotalPrice: Decimal;
    begin
        TotalPrice := Round(Qty * ServiceLine."Unit Price", 0.01);
        exit(TotalPrice - Round(TotalPrice * ServiceLine."Line Discount %" / 100, 0.01));
    end;
}

