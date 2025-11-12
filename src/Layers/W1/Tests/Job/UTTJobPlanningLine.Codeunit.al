codeunit 136353 "UT T Job Planning Line"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Planning] [Job] [UT]
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryJob: Codeunit "Library - Job";
        LibraryInventory: Codeunit "Library - Inventory";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryRandom: Codeunit "Library - Random";
        LibraryERM: Codeunit "Library - ERM";
        LibraryResource: Codeunit "Library - Resource";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        CopyFromToPriceListLine: Codeunit CopyFromToPriceListLine;
        IsInitialized: Boolean;
        EmptyLocationCodeErr: Label 'Location Code must have a value in Order Promising Line';
        ActualTxt: Label 'Actual: ';
        TestFieldErrorCodeTxt: Label 'TestWrapped:TestField';
        CannotDeleteResourceErr: Label 'You cannot delete resource %1 because it is used in one or more project planning lines.', Comment = '%1 = Resource No.';
        CannotRemoveJobPlanningLineErr: Label 'It is not possible to deleted project planning line transferred to an invoice.';
        RecordExistErr: Label 'Project Planning Line page should be empty!';
        FBResourceErr: Label 'Wrong Resource Project Planning Lines';
        FBItemErr: Label 'Wrong Item Project Planning Lines';
        FBGLAccErr: Label 'Wrong GL Account Project Planning Lines';
        FBTotalErr: Label 'Wrong Project Planning Lines';
        FBPlanningDrillDownErr: Label 'Wrong Project Planning Lines';
        FBLedgerDrillDownErr: Label 'Wrong Project Ledger Entries';
        RoundingTo0Err: Label 'Rounding of the field';
        NoJobPlanningLineErr: Label '%1 must be %2 in %3', Comment = '%1 = "No." field of Job Planning Line, %2 = Value of "No." field of Item, %3 = Job Planning Line';
        UnitCostLCYErr: Label '%1 must be %2 in %3', Comment = '%1 = Unit Cost (LCY), %2 = Unit Cost of Item, %3 = Job Planning Line';
        UnitCostErr: Label '%1 must be %2 in %3', Comment = '%1 = Unit Cost, %2 = UnitCost variable value, %3 = Job Planning Line';
        ProjectPlanningLinesShouldShowLinesErr: Label 'Project Planning Lines should show lines for the selected job';

    [Test]
    [Scope('OnPrem')]
    procedure TestInitialization()
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        Initialize();
        CreateJobPlanningLine(JobPlanningLine, true);
        // Verify that Quantities, Total Costs and Line Amounts are initialized correctly.
        Assert.AreEqual(JobPlanningLine.Quantity, JobPlanningLine."Remaining Qty.",
          'Remaining Qty. is not initialized correctly.');
        Assert.AreEqual(JobPlanningLine."Quantity (Base)", JobPlanningLine."Remaining Qty. (Base)",
          'Remaining Qty. (Base) is not initialized correctly.');
        Assert.AreEqual(0, JobPlanningLine."Qty. Posted",
          'Qty. Posted is not initialized correctly.');
        Assert.AreEqual(JobPlanningLine.Quantity, JobPlanningLine."Qty. to Transfer to Journal",
          'Qty. to Post is not initialized correctly.');
        Assert.AreEqual(JobPlanningLine."Total Cost", JobPlanningLine."Remaining Total Cost",
          'Remaining Total Cost is not initialized correctly.');
        Assert.AreEqual(JobPlanningLine."Total Cost (LCY)", JobPlanningLine."Remaining Total Cost (LCY)",
          'Remaining Total Cost (LCY) is not initialized correctly.');
        Assert.AreEqual(JobPlanningLine."Line Amount", JobPlanningLine."Remaining Line Amount",
          'Remaining Line Amount is not initialized correctly.');
        Assert.AreEqual(JobPlanningLine."Line Amount (LCY)", JobPlanningLine."Remaining Line Amount (LCY)",
          'Remaining Line Amount (LCY) is not initialized correctly.');
        Assert.AreEqual(0, JobPlanningLine."Posted Total Cost",
          'Posted Total Cost is not initialized correctly.');
        Assert.AreEqual(0, JobPlanningLine."Posted Total Cost (LCY)",
          'Posted Total Cost (LCY) is not initialized correctly.');
        Assert.AreEqual(0, JobPlanningLine."Posted Line Amount",
          'Posted Line Amount is not initialized correctly.');
        Assert.AreEqual(0, JobPlanningLine."Posted Line Amount (LCY)",
          'Posted Line Amount (LCY) is not initialized correctly.');
        Assert.AreEqual(0, JobPlanningLine."Qty. Transferred to Invoice",
          'Qty. Transferred is not initialized correctly.');
        Assert.AreEqual(0, JobPlanningLine."Qty. to Transfer to Invoice",
          'Qty. to Transfer is not initialized correctly.');
        Assert.AreEqual(0, JobPlanningLine."Qty. Invoiced",
          'Qty. Invoiced is not initialized correctly.');
        Assert.AreEqual(0, JobPlanningLine."Qty. to Invoice",
          'Qty. to Invoice is not initialized correctly.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDeletion()
    var
        JobLedgerEntry: Record "Job Ledger Entry";
        JobPlanningLine: Record "Job Planning Line";
        JobUsageLink: Record "Job Usage Link";
        JobPlanningLineInvoice: Record "Job Planning Line Invoice";
    begin
        Initialize();
        CreateJobPlanningLine(JobPlanningLine, true);

        // Validate that a Job Planning Line can be deleted as long as no usage link exists.
        Assert.IsTrue(JobPlanningLine.Delete(true), 'Job Planning Line could not be deleted.');

        CreateJobPlanningLine(JobPlanningLine, true);

        // Validate that a Job Planning Line can't be deleted if a usage link exists.
        JobLedgerEntry.Init();
        JobUsageLink.Create(JobPlanningLine, JobLedgerEntry);
        asserterror JobPlanningLine.Delete(true);

        CreateJobPlanningLine(JobPlanningLine, true);

        // Validate that a Job Planning Line cannot be deleted if the line is transferred.
        CreateJobPlanningLineInvoice(JobPlanningLineInvoice, JobPlanningLine, 1);
        asserterror JobPlanningLine.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDeletionOfAttachedLines()
    var
        JobPlanningLine: Record "Job Planning Line";
        AttachedJobPlanningLine: Record "Job Planning Line";
    begin
        Initialize();
        // [GIVEN] Job Planning Line with attachedcJobhPlanningbLines
        CreateJobPlanningLineWithAttachedLines(JobPlanningLine);
        AttachedJobPlanningLine.SetRange("Job No.", JobPlanningLine."Job No.");
        AttachedJobPlanningLine.SetRange("Job Task No.", JobPlanningLine."Job Task No.");
        AttachedJobPlanningLine.SetRange("Attached to Line No.", JobPlanningLine."Line No.");
        Assert.RecordIsNotEmpty(AttachedJobPlanningLine);

        // [WHEN] Job Planning Line is deleted
        JobPlanningLine.Delete(true);

        // [THEN] Verify Attached Lines are deleted
        Assert.RecordIsEmpty(AttachedJobPlanningLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFieldUsageLinkApplyULTrue()
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        Initialize();
        CreateJobPlanningLine(JobPlanningLine, true);

        // Verify that Usage Link is set to TRUE for Job Planning Lines of Line Type "Schedule" and Jobs with "Apply Usage Link" enabled.
        Assert.IsTrue(JobPlanningLine."Usage Link", 'Usage Link is not TRUE by default.');

        // Verify that Usage Link is set to FALSE when Line Type is set to "Billable".
        JobPlanningLine.Validate("Line Type", JobPlanningLine."Line Type"::Billable);
        Assert.IsFalse(JobPlanningLine."Usage Link", 'Usage Link is not set to FALSE when Line Type changes to Billable.');

        // Verify that Usage Link is re-set to TRUE for Job Planning Lines of Line Type "Both Schedule and Billable".
        JobPlanningLine.Validate("Line Type", JobPlanningLine."Line Type"::"Both Budget and Billable");
        Assert.IsTrue(JobPlanningLine."Usage Link", 'Usage Link is not TRUE when setting type to Both Schedule and Billable.');

        // Verify that Usage Link can't be unchecked if Line Type includes "Schedule".
        JobPlanningLine.Validate("Usage Link", false);
        Assert.IsTrue(JobPlanningLine."Usage Link", 'Usage Link is not TRUE type includes Schedule and Apply Usage Link is checked.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFieldUsageLinkApplyULFalse()
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        Initialize();
        CreateJobPlanningLine(JobPlanningLine, false);

        // Verify that Usage Link is not set on Job Planning Lines of Line Type "Schedule" if the Jobs "Apply Usage Link" is disabled.
        JobPlanningLine.Validate("Usage Link", false);
        JobPlanningLine.Validate("Line Type", JobPlanningLine."Line Type"::Budget);
        Assert.IsFalse(JobPlanningLine."Usage Link",
          'Usage Link is not set to FALSE when Line Type is set to "Schedule" and Jobs "Apply Usage Link" is disabled.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFieldQuantity()
    var
        JobPlanningLineInvoice: Record "Job Planning Line Invoice";
        JobPlanningLine: Record "Job Planning Line";
    begin
        Initialize();
        CreateJobPlanningLine(JobPlanningLine, true);

        // Verify that Quantity cannot be set to less than Quantity Posted.
        JobPlanningLine.Validate("Qty. Posted", LibraryRandom.RandInt(JobPlanningLine.Quantity));
        asserterror JobPlanningLine.Validate(Quantity, JobPlanningLine."Qty. Posted" - 1);

        CreateJobPlanningLine(JobPlanningLine, true);

        // Verify that Quantity cannot be set to less than Qty. Transferred.
        CreateJobPlanningLineInvoice(JobPlanningLineInvoice, JobPlanningLine, LibraryRandom.RandInt(JobPlanningLine.Quantity));
        JobPlanningLine.CalcFields("Qty. Transferred to Invoice");
        asserterror JobPlanningLine.Validate(Quantity, JobPlanningLine."Qty. Transferred to Invoice" - 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFieldRemainingQty()
    var
        JobPlanningLine: Record "Job Planning Line";
        QtyToPost: Decimal;
        QtyDelta: Decimal;
    begin
        Initialize();
        CreateJobPlanningLine(JobPlanningLine, true);
        // Post usage to give Remaining Qty. a value.
        QtyToPost := LibraryRandom.RandInt(JobPlanningLine.Quantity);
        JobPlanningLine.Use(QtyToPost, 0, 0, JobPlanningLine."Currency Date", JobPlanningLine."Currency Factor");
        // Verify that Remaining Qty. changes correctly, when Quantity is increased.
        QtyDelta := LibraryRandom.RandInt(JobPlanningLine.Quantity);
        JobPlanningLine.Validate(Quantity, JobPlanningLine.Quantity + QtyDelta);
        Assert.AreEqual(JobPlanningLine.Quantity - QtyToPost, JobPlanningLine."Remaining Qty.", 'Remaining Qty. has wrong value after increasing Quantity.');
        // Test only valid because no Unit Of Measure Code is defined:
        JobPlanningLine.TestField("Qty. per Unit of Measure", 1);
        Assert.AreEqual(JobPlanningLine."Remaining Qty.", JobPlanningLine."Remaining Qty. (Base)",
          'Remaining Qty. (Base) is not updated correctly');
        // Verify that Remaining Qty. changes correctly, when Quantity is decreased.
        QtyDelta := LibraryRandom.RandInt(JobPlanningLine."Remaining Qty.");
        JobPlanningLine.Validate(Quantity, JobPlanningLine.Quantity - QtyDelta);
        Assert.AreEqual(JobPlanningLine.Quantity - QtyToPost, JobPlanningLine."Remaining Qty.", 'Remaining Qty. has wrong value after decreasing Quantity.');
        // Test only valid because no Unit Of Measure Code is defined:
        JobPlanningLine.TestField("Qty. per Unit of Measure", 1);
        Assert.AreEqual(JobPlanningLine."Remaining Qty.", JobPlanningLine."Remaining Qty. (Base)",
          'Remaining Qty. (Base) is not updated correctly');
        // Verify that Remaining Qty. is reset to 0 when "No." is set to 0.
        JobPlanningLine.Validate("No.", '');
        Assert.AreEqual(0, JobPlanningLine."Remaining Qty.", 'Remaining Qty. is not set to 0 when No. is set to 0.');
        // Test only valid because no Unit Of Measure Code is defined:
        JobPlanningLine.TestField("Qty. per Unit of Measure", 1);
        Assert.AreEqual(JobPlanningLine."Remaining Qty.", JobPlanningLine."Remaining Qty. (Base)",
          'Remaining Qty. (Base) is not updated correctly');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFieldQtyTransferred()
    var
        JobPlanningLineInvoice: Record "Job Planning Line Invoice";
        JobPlanningLine: Record "Job Planning Line";
    begin
        Initialize();
        CreateJobPlanningLine(JobPlanningLine, false);

        JobPlanningLine.Validate("Line Type", JobPlanningLine."Line Type"::Billable);
        CreateJobPlanningLineInvoice(JobPlanningLineInvoice, JobPlanningLine, LibraryRandom.RandInt(JobPlanningLine.Quantity));
        // Verify that the Line Type can be changed as long as the Line Type includes type Billable.
        JobPlanningLine.Validate("Line Type", JobPlanningLine."Line Type"::"Both Budget and Billable");
        Assert.AreEqual(JobPlanningLine."Line Type", JobPlanningLine."Line Type"::"Both Budget and Billable",
          'Line Type was not updated correctly.');
        // Verify that the Line Type cannot be changed if the Line Type does not include type Billable.
        asserterror JobPlanningLine.Validate("Line Type", JobPlanningLine."Line Type"::Budget);

        CreateJobPlanningLine(JobPlanningLine, false);

        JobPlanningLine.Validate("Line Type", JobPlanningLine."Line Type"::Billable);
        CreateJobPlanningLineInvoice(JobPlanningLineInvoice, JobPlanningLine, LibraryRandom.RandInt(JobPlanningLine.Quantity));
        // Verify that the No. cannot be changed if Qty. Transferred <> 0.
        asserterror JobPlanningLine.Validate("No.", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFieldQtyToTransfer()
    var
        JobPlanningLineInvoice: Record "Job Planning Line Invoice";
        JobPlanningLine: Record "Job Planning Line";
    begin
        Initialize();
        CreateJobPlanningLine(JobPlanningLine, false);
        // Verify that Qty. to Transfer is set correctly when Line Type is Billable.
        CreateJobPlanningLineInvoice(JobPlanningLineInvoice, JobPlanningLine, LibraryRandom.RandInt(JobPlanningLine.Quantity));
        JobPlanningLine.Validate("Line Type", JobPlanningLine."Line Type"::Billable);
        Assert.AreEqual(JobPlanningLine."Qty. to Transfer to Invoice", JobPlanningLine.Quantity - JobPlanningLine."Qty. Transferred to Invoice",
          'Qty. to Transfer was not set correctly when Line Type is Billable.');
        // Verify that Qty. to Transfer is updated correctly when Qty. Transferred changes.
        JobPlanningLineInvoice."Quantity Transferred" := LibraryRandom.RandInt(JobPlanningLine.Quantity);
        JobPlanningLineInvoice.Modify();
        JobPlanningLine.UpdateQtyToTransfer();
        Assert.AreEqual(JobPlanningLine."Qty. to Transfer to Invoice", JobPlanningLine.Quantity - JobPlanningLine."Qty. Transferred to Invoice",
          'Qty. to Transfer was not updated correctly when Qty Transferred changed.');
        // Verify that Qty. to Transfer is updated correctly when Quantity changes.
        JobPlanningLine.Validate(Quantity, JobPlanningLineInvoice."Quantity Transferred" + LibraryRandom.RandInt(100));
        Assert.AreEqual(JobPlanningLine."Qty. to Transfer to Invoice", JobPlanningLine.Quantity - JobPlanningLine."Qty. Transferred to Invoice",
          'Qty. to Transfer was not updated correctly when Quantity changed.');
        // Verify that Qty. to Transfer is set correctly when Line Type is Schedule.
        JobPlanningLineInvoice.Delete();
        JobPlanningLine.CalcFields("Qty. Transferred to Invoice", "Qty. Invoiced");
        JobPlanningLine.Validate("Line Type", JobPlanningLine."Line Type"::Budget);
        Assert.AreEqual(JobPlanningLine."Qty. to Transfer to Invoice", 0,
          'Qty. to Transfer was not set correctly when Line Type is Schedule.');
        // Verify that Qty. to Transfer is set correctly when Line Type is Both Schedule and Billable.
        JobPlanningLine.Validate("Line Type", JobPlanningLine."Line Type"::"Both Budget and Billable");
        CreateJobPlanningLineInvoice(JobPlanningLineInvoice, JobPlanningLine, LibraryRandom.RandInt(JobPlanningLine.Quantity));
        Assert.AreEqual(JobPlanningLine."Qty. to Transfer to Invoice", JobPlanningLine.Quantity - JobPlanningLine."Qty. Transferred to Invoice",
          'Qty. to Transfer was not set correctly when Line Type is Both Schedule and Billable.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFieldQtyToInvoice()
    var
        JobPlanningLineInvoice: Record "Job Planning Line Invoice";
        JobPlanningLine: Record "Job Planning Line";
    begin
        Initialize();
        CreateJobPlanningLine(JobPlanningLine, false);
        // Verify that Qty. to Invoice is set correctly when Line Type is Billable.
        CreateJobPlanningLineInvoice(JobPlanningLineInvoice, JobPlanningLine, LibraryRandom.RandInt(JobPlanningLine.Quantity));
        JobPlanningLine.Validate("Line Type", JobPlanningLine."Line Type"::Billable);
        Assert.AreEqual(JobPlanningLine."Qty. to Invoice", JobPlanningLine.Quantity - JobPlanningLine."Qty. Invoiced",
          'Qty. to Invoice was not set correctly when Line Type is Billable.');
        // Verify that Qty. to Invoice is set correctly when Line Type is Schedule.
        JobPlanningLineInvoice.Delete();
        JobPlanningLine.CalcFields("Qty. Transferred to Invoice", "Qty. Invoiced");
        JobPlanningLine.Validate("Line Type", JobPlanningLine."Line Type"::Budget);
        Assert.AreEqual(JobPlanningLine."Qty. to Invoice", 0,
          'Qty. to Invoice was not set correctly when Line Type is Schedule.');
        // Verify that Qty. to Invoice is set correctly when Line Type is Both Schedule and Billable.
        JobPlanningLine.Validate("Line Type", JobPlanningLine."Line Type"::"Both Budget and Billable");
        Assert.AreEqual(JobPlanningLine."Qty. to Invoice", JobPlanningLine.Quantity - JobPlanningLine."Qty. Invoiced",
          'Qty. to Invoice was not set correctly when Line Type is Both Schedule and Billable.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFunctionUse()
    var
        JobPlanningLine: Record "Job Planning Line";
        QtyToPost: Decimal;
        TotalCostToPost: Decimal;
        TotalCostToPostLCY: Decimal;
        LineAmountToPost: Decimal;
        LineAmountToPostLCY: Decimal;
    begin
        Initialize();
        CreateJobPlanningLine(JobPlanningLine, true);

        // Post usage using function Use().
        QtyToPost := LibraryRandom.RandInt(JobPlanningLine.Quantity);
        TotalCostToPost := QtyToPost * JobPlanningLine."Unit Cost";
        TotalCostToPostLCY := QtyToPost * JobPlanningLine."Unit Cost (LCY)";
        LineAmountToPost := HelperCalcLineAmount(JobPlanningLine, QtyToPost);
        LineAmountToPostLCY := HelperCalcLineAmountLCY(JobPlanningLine, QtyToPost);

        JobPlanningLine.Use(
          QtyToPost, TotalCostToPost, LineAmountToPost, JobPlanningLine."Currency Date", JobPlanningLine."Currency Factor");
        // Verify that Quantities, Total Costs and Line Amounts are updated correctly after posting usage.
        Assert.AreEqual(JobPlanningLine.Quantity - JobPlanningLine."Qty. Posted", JobPlanningLine."Remaining Qty.",
          'Remaining Qty. has wrong value after posting usage.');
        Assert.AreEqual(Round(JobPlanningLine."Remaining Qty." * JobPlanningLine."Qty. per Unit of Measure", 0.00001), JobPlanningLine."Remaining Qty. (Base)",
          'Remaining Qty. (Base) has wrong value after posting usage.');
        Assert.AreEqual(QtyToPost, JobPlanningLine."Qty. Posted",
          'Qty. Posted has wrong value after posting usage.');
        Assert.AreEqual(JobPlanningLine.Quantity - JobPlanningLine."Qty. Posted", JobPlanningLine."Qty. to Transfer to Journal",
          'Qty. to Post has wrong value after posting usage.');
        Assert.AreNearlyEqual(JobPlanningLine."Remaining Qty." * JobPlanningLine."Unit Cost", JobPlanningLine."Remaining Total Cost", 0.01,
          'Remaining Total Cost has wrong value after posting usage.');
        Assert.AreNearlyEqual(JobPlanningLine."Remaining Qty." * JobPlanningLine."Unit Cost (LCY)", JobPlanningLine."Remaining Total Cost (LCY)", 0.01,
          'Remaining Total Cost (LCY) has wrong value after posting usage.');
        Assert.AreNearlyEqual(HelperCalcLineAmount(JobPlanningLine, JobPlanningLine."Remaining Qty."), JobPlanningLine."Remaining Line Amount", 0.01,
          'Remaining Line Amount has wrong value after posting usage.');
        Assert.AreNearlyEqual(HelperCalcLineAmountLCY(JobPlanningLine, JobPlanningLine."Remaining Qty."), JobPlanningLine."Remaining Line Amount (LCY)", 0.01,
          'Remaining Line Amount (LCY) has wrong value after posting usage.');
        Assert.AreNearlyEqual(TotalCostToPost, JobPlanningLine."Posted Total Cost", 0.01,
          'Posted Total Cost has wrong value after posting usage.');
        Assert.AreNearlyEqual(TotalCostToPostLCY, JobPlanningLine."Posted Total Cost (LCY)", 0.01,
          'Posted Total Cost (LCY) has wrong value after posting usage.');
        Assert.AreNearlyEqual(LineAmountToPost, JobPlanningLine."Posted Line Amount", 0.01,
          'Posted Line Amount has wrong value after posting usage.');
        Assert.AreNearlyEqual(LineAmountToPostLCY, JobPlanningLine."Posted Line Amount (LCY)", 0.01,
          'Posted Line Amount (LCY) has wrong value after posting usage.');
    end;

    [Test]
    [HandlerFunctions('OrderPromisingModalPagehandler')]
    [Scope('OnPrem')]
    procedure CreateOrderPromisingFromJobPlanningLineWithLocationMandatory()
    var
        JobPlanningLine: Record "Job Planning Line";
        Location: Record Location;
    begin
        // [FEATURE] [Order Promising] [Location Mandatory]
        // [SCENARIO 375033] If Location is set as mandatory, then it should be possible to create Order Promising from Job Planning Line with specified Location
        Initialize();

        // [GIVEN] Inventory Setup, where "Location Mondatory" is Yes
        LibraryInventory.SetLocationMandatory(true);

        // [GIVEN] Job Planning Line with filled "Location Code"
        LibraryWarehouse.CreateLocation(Location);
        CreateJobPlanningLineWithLocation(JobPlanningLine, Location.Code);

        // [WHEN] Open Order Promising page from Job Planning Line
        OpenOrderPromissingPage(JobPlanningLine);

        // [THEN] Order Promising page is successfully opened
        // Is checked in OrderPromisingModalPagehandler
    end;

    [Test]
    [HandlerFunctions('OrderPromisingModalPagehandler')]
    [Scope('OnPrem')]
    procedure CreateOrderPromisingFromJobPlanningLineWithoutLocationMandatoryWhileNeeded()
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        // [FEATURE] [Order Promising] [Location Mandatory]
        // [SCENARIO 375033] If Location is set as mandatory, then it should not be possible to create Order Promising from Job Planning Line without specified Location
        Initialize();

        // [GIVEN] Inventory Setup, where "Location Mondatory" is Yes
        LibraryInventory.SetLocationMandatory(true);

        // [GIVEN] Job Planning Line with blank "Location Code"
        CreateJobPlanningLineWithLocation(JobPlanningLine, '');

        // [WHEN] Open Order Promising page from Job Planning Line
        asserterror OpenOrderPromissingPage(JobPlanningLine);

        // [THEN] Order Promising page is successfully opened
        Assert.IsTrue(StrPos(GetLastErrorText, EmptyLocationCodeErr) > 0, ActualTxt + GetLastErrorText);
        Assert.ExpectedErrorCode(TestFieldErrorCodeTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobPlanningLineUICreationLineTypeBothWithUsageLinkAndCurrency()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        JobTaskLines: TestPage "Job Task Lines";
        JobPlanningLines: TestPage "Job Planning Lines";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 375593] Job Planning Line can be created through UI page with "Line Type"="Both Schedule and Billable" in case of "Apply Usage Link"=TRUE and foreign currency
        Initialize();

        // [GIVEN] Job with "Apply Usage Link"=TRUE, "Currency Code"=USD. Create Job Task.
        CreateJobAndJobTask(Job, JobTask, true, CreateCurrency());

        // [GIVEN]  Open "Job Planning Lines" page from "Job Task Lines" page
        JobTaskLines.OpenEdit();
        JobTaskLines.FILTER.SetFilter("Job No.", Job."No.");
        JobPlanningLines.Trap();
        JobTaskLines.JobPlanningLines.Invoke();

        // [WHEN] Modify "Line Type" = "Both Schedule and Billable" on new line
        JobPlanningLines."Line Type".SetValue(JobPlanningLine."Line Type"::"Both Budget and Billable");

        // [THEN] Job Planning Line is created with "Line Type" = "Both Schedule and Billable"
        JobPlanningLines."Line Type".AssertEquals(JobPlanningLine."Line Type"::"Both Budget and Billable");
        JobPlanningLines.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotRemoveResourceWithJobPlanningLines()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        Resource: Record Resource;
        JobPlanningLine: Record "Job Planning Line";
    begin
        // [FEATURE] [Resouce]
        // [SCENARIO 375530] User is not allowed to remove resource if there are one more job planning lines associated

        Initialize();
        // [GIVEN] Resource "X"
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibraryResource.CreateResource(Resource, VATPostingSetup."VAT Bus. Posting Group");

        // [GIVEN] Job Planning line with Type = Resource and "No." = "X"
        JobPlanningLine.Init();
        JobPlanningLine.Type := JobPlanningLine.Type::Resource;
        JobPlanningLine."No." := Resource."No.";
        JobPlanningLine.Insert();

        // [WHEN] Remove Resource
        asserterror Resource.Delete(true);

        // [THEN] Error message "You cannot delete Resource X" shown
        Assert.ExpectedError(StrSubstNo(CannotDeleteResourceErr, Resource."No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotRemoveTextJobPlanningLineTransferedToInvoice()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        JobPlanningLineInvoice: Record "Job Planning Line Invoice";
    begin
        // [SCENARIO 380580] It is not possible to remove Job Planning Line with Type = "Text" if this line was transfered to Sales Invoice

        Initialize();
        CreateJobAndJobTask(Job, JobTask, false, '');
        CreateSimpleJobPlanningLine(JobPlanningLine, JobTask);
        JobPlanningLine.Validate(Type, JobPlanningLine.Type::Text);
        JobPlanningLine.Modify(true);
        CreateJobPlanningLineInvoice(JobPlanningLineInvoice, JobPlanningLine, 0);

        asserterror JobPlanningLine.Delete(true);

        Assert.ExpectedError(CannotRemoveJobPlanningLineErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LineDiscountPctInJobPlanningLineWhenAllowLineDiscDefinedInCustPriceGroup()
    var
        SalesLineDiscount: Record "Sales Line Discount";
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        CustomerPriceGroupCode: Code[10];
    begin
        // [FEATURE] [Discount] [Line Discount]
        // [SCENARIO 380764] "Line Discount %" of Job Planning Line has value when "Allow Line Disc." in Customer Posting Group is defined

        Initialize();

        // [GIVEN] Job and Job Task with Customer "C"
        CreateJobAndJobTask(Job, JobTask, false, '');

        // [GIVEN] Customer Price Group with "Allow Line Disc." = TRUE defined for Customer "C"
        CustomerPriceGroupCode := SetAllowLineDiscOfCustPostGroup(Job, true);

        // [GIVEN] Item "X"
        // [GIVEN] Sales Line Discount for Item "X", Customer "C" with "Line Discount %" = 10%
        // [GIVEN] Sales Price for Customer Posting Group of Customer "C"
        // [GIVEN] Job Planning Line
        SetupLineDiscScenario(
          JobPlanningLine, SalesLineDiscount, JobTask, Job."Bill-to Customer No.", CustomerPriceGroupCode);

        // [WHEN] Validate Item "X" on Job Planning Line
        JobPlanningLine.Validate("No.", SalesLineDiscount.Code);

        // [THEN] "Line Discount %" in Job Planning Line is 10%
        JobPlanningLine.TestField("Line Discount %", SalesLineDiscount."Line Discount %");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ZeroLineDiscountPctInJobPlanningLineWhenAllowLineDiscNotDefinedInCustPriceGroup()
    var
        SalesLineDiscount: Record "Sales Line Discount";
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        CustomerPriceGroupCode: Code[10];
    begin
        // [FEATURE] [Discount] [Line Discount]
        // [SCENARIO 380764] "Line Discount %" of Job Planning Line is zero when "Allow Line Disc." in Customer Posting Group is not defined

        Initialize();

        // [GIVEN] Job and Job Task with Customer "C"
        CreateJobAndJobTask(Job, JobTask, false, '');

        // [GIVEN] Customer Price Group with "Allow Line Disc." = FALSE defined for Customer "C"
        CustomerPriceGroupCode := SetAllowLineDiscOfCustPostGroup(Job, false);

        // [GIVEN] Item "X"
        // [GIVEN] Sales Line Discount for Item "X", Customer "C" with "Line Discount %" = 10%
        // [GIVEN] Sales Price for Customer Posting Group of Customer "C"
        // [GIVEN] Job Planning Line
        SetupLineDiscScenario(
          JobPlanningLine, SalesLineDiscount, JobTask, Job."Bill-to Customer No.", CustomerPriceGroupCode);

        // [WHEN] Validate Item "X" on Job Planning Line
        JobPlanningLine.Validate("No.", SalesLineDiscount.Code);

        // [THEN] "Line Discount %" in Job Planning Line is zero
        JobPlanningLine.TestField("Line Discount %", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobPlanningLineFromTaskLineWithJobNoFilter()
    var
        JobTaskLines: TestPage "Job Task Lines";
        JobPlanningLines: TestPage "Job Planning Lines";
        JobNo: Code[20];
        SecondJobNo: Code[20];
    begin
        // [FEATURE] [UI]
        // [SCENARIO 381083] Filter for "Job No." is set when "Job Planning Lines" page opened from Job Task Lines.
        // [SCENARIO 578676] User can change "Job No." filter on "Job Planning Lines" page opened from Job Task Lines.
        Initialize();

        // [GIVEN] Job "J", Job Task "JT", where "Job No." = "J"
        // [GIVEN] Job Planning Line "JPL", where "Job No." = "J", "Job Task No." = "JT"
        // [GIVEN] Job "J1", Job Task "JT1", where "Job No." = "J1"
        CreateTwoJobsWithJobPlanningLines(JobNo, SecondJobNo);

        // [GIVEN]  "Job Planning Lines" page opened from "Job Task Lines" page filtered on "J1" Job
        JobTaskLines.OpenEdit();
        JobTaskLines.Filter.SetFilter("Job No.", SecondJobNo);
        JobPlanningLines.Trap();
        JobTaskLines.JobPlanningLines.Invoke();

        // [WHEN] Set JobPlanningLines "Job No." filter to "J"
        JobPlanningLines.Filter.SetFilter("Job No.", JobNo);

        // [THEN] Page JobPlanningLines is filtered on "J" Job, and not empty.
        Assert.IsTrue(JobPlanningLines.First(), ProjectPlanningLinesShouldShowLinesErr);
        JobPlanningLines.Close();
        JobTaskLines.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobPlanningLineFromTaskCardWithJobNoFilter()
    var
        JobCard: TestPage "Job Card";
        JobPlanningLines: TestPage "Job Planning Lines";
        JobNo: Code[20];
        SecondJobNo: Code[20];
    begin
        // [FEATURE] [UI]
        // [SCENARIO 381083] Filter for "Job No." is set when "Job Planning Lines" page opened from Job Card.
        // [SCENARIO 578676] User can change "Job No." filter on "Job Planning Lines" page opened from Job Card.

        // [GIVEN] Job "J", Job Task "JT", where "Job No." = "J"
        // [GIVEN] Job Planning Line "JPL", where "Job No." = "J", "Job Task No." = "JT"
        // [GIVEN] Job "J1", Job Task "JT1", where "Job No." = "J1"
        CreateTwoJobsWithJobPlanningLines(JobNo, SecondJobNo);

        // [GIVEN]  "Job Planning Lines" page opened from "Job Card" page filtered on "J1" Job
        JobCard.OpenEdit();
        JobCard.Filter.SetFilter("No.", SecondJobNo);
        JobPlanningLines.Trap();
        JobCard.JobPlanningLines.Invoke();

        // [WHEN] Set JobPlanningLines "Job No." filter to "J"
        JobPlanningLines.Filter.SetFilter("Job No.", JobNo);

        // [THEN] Page JobPlanningLines is filtered on "J" Job, and not empty.
        Assert.IsTrue(JobPlanningLines.First(), ProjectPlanningLinesShouldShowLinesErr);
        JobPlanningLines.Close();
        JobCard.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobPlanningLinesDrillDownFromJobTaskLines()
    var
        JobTaskLines: TestPage "Job Task Lines";
        JobPlanningLines: TestPage "Job Planning Lines";
        JobTaskStatistics: TestPage "Job Task Statistics";
        JobNo: Code[20];
        SecondJobNo: Code[20];
    begin
        // [FEATURE] [UI]
        // [SCENARIO 381083] Filter for "Job No." is set changeless when Drill Down on Job Task Lines Statistics page.
        Initialize();

        // [GIVEN] Job "J", Job Task "JT", where "Job No." = "J"
        // [GIVEN] Job Planning Line "JPL", where "Job No." = "J", "Job Task No." = "JT"
        // [GIVEN] Job "J1", Job Task "JT1", where "Job No." = "J1"
        CreateTwoJobsWithJobPlanningLines(JobNo, SecondJobNo);

        // [GIVEN]  Drill Down on Job Task Lines Statistic page filtered on "J1" Job
        JobTaskLines.OpenEdit();
        JobTaskLines.FILTER.SetFilter("Job No.", SecondJobNo);
        JobTaskStatistics.Trap();
        JobTaskLines.JobTaskStatistics.Invoke();
        JobPlanningLines.Trap();
        JobTaskStatistics.SchedulePriceLCY.DrillDown();

        // [WHEN] Set JobPlanningLines "Job No." filter to "J"
        JobPlanningLines.FILTER.SetFilter("Job No.", JobNo);

        // [THEN] Page JobPlanningLines is empty
        Assert.IsFalse(JobPlanningLines.First(), RecordExistErr);

        JobPlanningLines.Close();
        JobTaskStatistics.Close();
        JobTaskLines.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobPlanningLinesDrillDownFromJobCard()
    var
        JobCard: TestPage "Job Card";
        JobPlanningLines: TestPage "Job Planning Lines";
        JobStatistics: TestPage "Job Statistics";
        JobNo: Code[20];
        SecondJobNo: Code[20];
    begin
        // [FEATURE] [UI]
        // [SCENARIO 381083] Filter for "Job No." is set changeless when Drill Down on Job Card Statistics page.
        Initialize();

        // [GIVEN] Job "J", Job Task "JT", where "Job No." = "J"
        // [GIVEN] Job Planning Line "JPL", where "Job No." = "J", "Job Task No." = "JT"
        // [GIVEN] Job "J1", Job Task "JT1", where "Job No." = "J1"
        CreateTwoJobsWithJobPlanningLines(JobNo, SecondJobNo);

        // [GIVEN]  Drill Down on Job Card Statistic page filtered on "J1" Job
        JobCard.OpenEdit();
        JobCard.FILTER.SetFilter("No.", SecondJobNo);
        JobStatistics.Trap();
        JobCard."&Statistics".Invoke();
        JobPlanningLines.Trap();
        JobStatistics.SchedulePriceLCY.DrillDown();

        // [WHEN] Set JobPlanningLines "Job No." filter to "J"
        JobPlanningLines.FILTER.SetFilter("Job No.", JobNo);

        // [THEN] Page JobPlanningLines is empty
        Assert.IsFalse(JobPlanningLines.First(), RecordExistErr);

        JobPlanningLines.Close();
        JobStatistics.Close();
        JobCard.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BillablePricesOnJobCardFactbox()
    var
        Job: Record Job;
        JobCostFactbox: TestPage "Job Cost Factbox";
        BillableArrAmount: array[9] of Decimal;
    begin
        // [FEATURE] [UI]
        // [SCENARIO 203577] Job Details Billable Price factbox fields have correct values of price
        Initialize();

        // [GIVEN] Job "J" and Job Planning Lines any types and Line types for this job
        CreateJobPlanningLinesWithMultipleTypesAndLineTypes(Job, BillableArrAmount);

        // [WHEN] Open Job Card on Job "J"
        JobCostFactbox.OpenEdit();
        JobCostFactbox.GotoRecord(Job);

        // [THEN] All Prices in Billable Price part of Job Details Factbox are correct
        VerifyJobDetailsBillablePriceFactbox(JobCostFactbox, BillableArrAmount);
    end;

    [Test]
    [HandlerFunctions('JobPlanningLinesPageHandler')]
    [Scope('OnPrem')]
    procedure BillableResourcePriceDrilldownFromJobCardFactbox()
    var
        Job: Record Job;
        JobCostFactbox: TestPage "Job Cost Factbox";
        ArrAmount: array[9] of Decimal;
    begin
        // [FEATURE] [UI]
        // [SCENARIO 203577] Correct Billable Resource Job Planning Lines are shown when DrillDown on Job Details Billable Price "Resource" factbox field
        Initialize();

        // [GIVEN] Job and Job Planning Lines any types and Line types for this job
        CreateJobPlanningLinesWithMultipleTypesAndLineTypes(Job, ArrAmount);
        LibraryVariableStorage.Enqueue(ArrAmount[1] + ArrAmount[7]);

        // [WHEN] DrillDown on Job Details Billable Price "Resource" factbox field
        JobCostFactbox.OpenEdit();
        JobCostFactbox.GotoRecord(Job);
        JobCostFactbox.BillablePriceLCY.DrillDown();

        // [THEN] Billable Resource Job Planning Lines for Job "J" are shown with correct amounts.
        // Verified in JobPlanningLinesPagehandler Page Handler
    end;

    [Test]
    [HandlerFunctions('JobPlanningLinesPageHandler')]
    [Scope('OnPrem')]
    procedure BillableItemPriceDrilldownFromJobCardFactbox()
    var
        Job: Record Job;
        JobCostFactbox: TestPage "Job Cost Factbox";
        ArrAmount: array[9] of Decimal;
    begin
        // [FEATURE] [UI]
        // [SCENARIO 203577] Correct Billable Item Job Planning Lines are shown when DrillDown on Job Details Billable Price "Item" factbox field
        Initialize();

        // [GIVEN] Job and Job Planning Lines any types and Line types for this job
        CreateJobPlanningLinesWithMultipleTypesAndLineTypes(Job, ArrAmount);
        LibraryVariableStorage.Enqueue(ArrAmount[2] + ArrAmount[8]);

        // [WHEN] DrillDown on Job Details Billable Price "Item" factbox field
        JobCostFactbox.OpenEdit();
        JobCostFactbox.GotoRecord(Job);
        JobCostFactbox.BillablePriceLCYItem.DrillDown();

        // [THEN] Billable Item Job Planning Lines are shown with correct amounts.
        // Verified in JobPlanningLinesPagehandler Page Handler
    end;

    [Test]
    [HandlerFunctions('JobPlanningLinesPageHandler')]
    [Scope('OnPrem')]
    procedure BillableGLAccountPriceDrilldownFromJobCardFactbox()
    var
        Job: Record Job;
        JobCostFactbox: TestPage "Job Cost Factbox";
        ArrAmount: array[9] of Decimal;
    begin
        // [FEATURE] [UI]
        // [SCENARIO 203577] Correct Billable GLAccount Job Planning Lines are shown when DrillDown on Job Details Billable Price "G/L Account" factbox field
        Initialize();

        // [GIVEN] Job and Job Planning Lines any types and Line types for this job
        CreateJobPlanningLinesWithMultipleTypesAndLineTypes(Job, ArrAmount);
        LibraryVariableStorage.Enqueue(ArrAmount[3] + ArrAmount[9]);

        // [WHEN] DrillDown on Job Details Billable Price "G/L Account" factbox field
        JobCostFactbox.OpenEdit();
        JobCostFactbox.GotoRecord(Job);
        JobCostFactbox.BillablePriceLCYGLAcc.DrillDown();

        // [THEN] Billable GLAccount Job Planning Lines are shown with correct amounts.
        // Verified in JobPlanningLinesPagehandler Page Handler
    end;

    [Test]
    [HandlerFunctions('JobPlanningLinesPageHandler')]
    [Scope('OnPrem')]
    procedure BillableTotalPriceDrilldownFromJobCardFactbox()
    var
        Job: Record Job;
        JobCostFactbox: TestPage "Job Cost Factbox";
        ArrAmount: array[9] of Decimal;
    begin
        // [FEATURE] [UI]
        // [SCENARIO 203577] All Billable Job Planning Lines are shown when DrillDown on Job Details Billable Price "Total" factbox field
        Initialize();

        // [GIVEN] Job and Job Planning Lines any types and Line types for this job
        CreateJobPlanningLinesWithMultipleTypesAndLineTypes(Job, ArrAmount);
        LibraryVariableStorage.Enqueue(ArrAmount[1] + ArrAmount[2] + ArrAmount[3] + ArrAmount[7] + ArrAmount[8] + ArrAmount[9]);

        // [WHEN] DrillDown on Job Details Billable Price "Total" factbox field
        JobCostFactbox.OpenEdit();
        JobCostFactbox.GotoRecord(Job);
        JobCostFactbox.BillablePriceLCYTotal.DrillDown();

        // [THEN] All Billable Job Planning Lines are shown with correct amounts
        // Verified in JobPlanningLinesPagehandler Page Handler
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvoicedPricesOnJobCardFactbox()
    var
        Job: Record Job;
        JobCostFactbox: TestPage "Job Cost Factbox";
        InvoiceArrAmount: array[12] of Decimal;
    begin
        // [FEATURE] [UI]
        // [SCENARIO 203577] Job Details Invoiced Price factbox fields have correct values of price
        Initialize();

        // [GIVEN] Job "J" and Job Planning Lines any types and Line types for this job
        CreateJobLedgerEntriesWithMultipleTypesAndLineTypes(Job, InvoiceArrAmount);

        // [WHEN] Open Job Card on Job "J"
        JobCostFactbox.OpenEdit();
        JobCostFactbox.GotoRecord(Job);

        // [THEN] All Prices in Invoiced Price part of Job Details Factbox are correct
        VerifyJobDetailsInvoicedPriceFactbox(JobCostFactbox, InvoiceArrAmount);
    end;

    [Test]
    [HandlerFunctions('JobLedgerEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure InvoicedResourcePriceDrilldownFromJobCardFactbox()
    var
        Job: Record Job;
        JobCostFactbox: TestPage "Job Cost Factbox";
        ArrAmount: array[12] of Decimal;
    begin
        // [FEATURE] [UI]
        // [SCENARIO 203577] Correct Sales Resource Job Ledger Entries are shown when DrillDown on Job Details Invoiced Price "Resource" factbox field
        Initialize();

        // [GIVEN] Job and Job Ledger Entries any types and Line types for this job
        CreateJobLedgerEntriesWithMultipleTypesAndLineTypes(Job, ArrAmount);
        LibraryVariableStorage.Enqueue(ArrAmount[8]);

        // [WHEN] DrillDown on Job Details Invoiced Price "Resource" factbox field
        JobCostFactbox.OpenEdit();
        JobCostFactbox.GotoRecord(Job);
        JobCostFactbox.InvoicedPriceLCY.DrillDown();

        // [THEN] Sales Resource Job Ledger Entries for Job "J" are shown with correct amounts.
        // Verified in JobLedgerEntriesPageHandler Page Handler
    end;

    [Test]
    [HandlerFunctions('JobLedgerEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure InvoicedItemPriceDrilldownFromJobCardFactbox()
    var
        Job: Record Job;
        JobCostFactbox: TestPage "Job Cost Factbox";
        ArrAmount: array[12] of Decimal;
    begin
        // [FEATURE] [UI]
        // [SCENARIO 203577] Correct Invoiced Item Job Ledger Entries are shown when DrillDown on Job Details Invoiced Price "Item" factbox field
        Initialize();

        // [GIVEN] Job and Job Ledger Entries any types and Line types for this job
        CreateJobLedgerEntriesWithMultipleTypesAndLineTypes(Job, ArrAmount);
        LibraryVariableStorage.Enqueue(ArrAmount[10]);

        // [WHEN] DrillDown on Job Details Invoiced Price "Item" factbox field
        JobCostFactbox.OpenEdit();
        JobCostFactbox.GotoRecord(Job);
        JobCostFactbox.InvoicedPriceLCYItem.DrillDown();

        // [THEN] Sales Item Job Ledger Entries are shown with correct amounts.
        // Verified in JobLedgerEntriesPageHandler Page Handler
    end;

    [Test]
    [HandlerFunctions('JobLedgerEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure InvoicedGLAccountPriceDrilldownFromJobCardFactbox()
    var
        Job: Record Job;
        JobCostFactbox: TestPage "Job Cost Factbox";
        ArrAmount: array[12] of Decimal;
    begin
        // [FEATURE] [UI]
        // [SCENARIO 203577] Correct Invoiced GLAccount Job Ledger Entries are shown when DrillDown on Job Details Invoiced Price "G/L Account" factbox field
        Initialize();

        // [GIVEN] Job and Job Ledger Entries any types and Line types for this job
        CreateJobLedgerEntriesWithMultipleTypesAndLineTypes(Job, ArrAmount);
        LibraryVariableStorage.Enqueue(ArrAmount[12]);

        // [WHEN] DrillDown on Job Details Invoiced Price "G/L Account" factbox field
        JobCostFactbox.OpenEdit();
        JobCostFactbox.GotoRecord(Job);
        JobCostFactbox.InvoicedPriceLCYGLAcc.DrillDown();

        // [THEN] Sales GLAccount Job Ledger Entries are shown with correct amounts.
        // Verified in JobLedgerEntriesPageHandler Page Handler
    end;

    [Test]
    [HandlerFunctions('JobLedgerEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure InvoicedTotalPriceDrilldownFromJobCardFactbox()
    var
        Job: Record Job;
        JobCostFactbox: TestPage "Job Cost Factbox";
        ArrAmount: array[12] of Decimal;
    begin
        // [FEATURE] [UI]
        // [SCENARIO 203577] All Invoiced Job Ledger Entries are shown when DrillDown on Job Details Invoiced Price "Total" factbox field
        Initialize();

        // [GIVEN] Job and Job Ledger Entries any types and Line types for this job
        CreateJobLedgerEntriesWithMultipleTypesAndLineTypes(Job, ArrAmount);
        LibraryVariableStorage.Enqueue(ArrAmount[8] + ArrAmount[10] + ArrAmount[12]);

        // [WHEN] DrillDown on Job Details Invoiced Price "Total" factbox field
        JobCostFactbox.OpenEdit();
        JobCostFactbox.GotoRecord(Job);
        JobCostFactbox.InvoicedPriceLCYTotal.DrillDown();

        // [THEN] All Sales Job Ledger Entries are shown with correct amounts
        // Verified in JobLedgerEntriesPageHandler Page Handler
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UI_JobPlanningLinesPageOpensWithFilterFromJobTaskLinesSubpage()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        JobCard: TestPage "Job Card";
        JobPlanningLines: TestPage "Job Planning Lines";
    begin
        // [SCENARIO 206657] "Job Planning Lines" page opens with filter "Job Task" from "Job Task Lines" subpage

        Initialize();

        // [GIVEN] Job Task "X" with one Job Planning Line
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
        LibraryJob.CreateJobPlanningLine(JobPlanningLine."Line Type"::Budget, JobPlanningLine.Type::Item, JobTask, JobPlanningLine);

        // [GIVEN] Job Task "Y" with one Job Planning Line
        LibraryJob.CreateJobTask(Job, JobTask);
        LibraryJob.CreateJobPlanningLine(JobPlanningLine."Line Type"::Budget, JobPlanningLine.Type::Item, JobTask, JobPlanningLine);

        // [GIVEN] "Job Card" page is opened and cursor set on Job Task "Y" on "Job Task Lines" subpage
        JobCard.OpenView();
        JobCard.GotoRecord(Job);
        JobCard.JobTaskLines.GotoRecord(JobTask);
        JobPlanningLines.Trap();

        // [WHEN] Press "Job Planning Lines" on "Job Task Lines" subpage
        JobCard.JobTaskLines.JobPlanningLines.Invoke();

        // [THEN] "Job Planning Lines" is opened and first record has "Job Task No." = "Y"
        JobPlanningLines."Job Task No.".AssertEquals(JobTask."Job Task No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobPlanningLineDescriptionIsCopiedFromItemVariantIfExists()
    var
        ItemVariant: Record "Item Variant";
        JobPlanningLine: Record "Job Planning Line";
    begin
        // [FEATURE] [Item Variant]
        // [SCENARIO 210300] Item Variant description should be copied to Job Planning Line description if Variant Code is not blank.
        Initialize();
        // [GIVEN] Item Variant "X" with Description = "D1" and "Description 2" = "D2".
        LibraryInventory.CreateItemVariant(ItemVariant, LibraryInventory.CreateItemNo());
        ItemVariant.Validate(Description, LibraryUtility.GenerateGUID());
        ItemVariant.Validate("Description 2", LibraryUtility.GenerateGUID());
        ItemVariant.Modify(true);

        // [GIVEN] Job Planning Line.
        CreateJobPlanningLine(JobPlanningLine, false);
        JobPlanningLine.Validate("No.", ItemVariant."Item No.");

        // [WHEN] Validate Item Variant = "X" on the Job Planning Line.
        JobPlanningLine.Validate("Variant Code", ItemVariant.Code);

        // [THEN] Description = "D1", "Description 2" = "D2" on the Job Planning Line.
        JobPlanningLine.TestField(Description, ItemVariant.Description);
        JobPlanningLine.TestField("Description 2", ItemVariant."Description 2");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoLineDiscountInJobPlanningLineWhenNoAllowLineDiscInSalesPriceForAllCustomersAndVariant()
    var
        Customer: Record Customer;
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        SalesLineDiscount: Record "Sales Line Discount";
        CustomerDiscountGroup: Record "Customer Discount Group";
        ItemDiscountGroup: Record "Item Discount Group";
        SalesPrice: Record "Sales Price";
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
    begin
        // [FEATURE] [Discount] [Line Discount] [Item Variant]
        // [SCENARIO 212422] "Line Discount %" of Job Planning Line is zero when "Allow Line Disc." is No in Sales Price for "All Customers", Item with Variant and Customer has "Line Discount" from Customer Discount Group

        Initialize();

        // [GIVEN] Customer Discount Group "CUSTDISC" assigned to Customer "C"
        LibraryERM.CreateCustomerDiscountGroup(CustomerDiscountGroup);
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Customer Disc. Group", CustomerDiscountGroup.Code);
        Customer.Modify(true);

        // [GIVEN] Job and Job Task with Customer "C"
        LibraryJob.CreateJob(Job, Customer."No.");
        LibraryJob.CreateJobTask(Job, JobTask);

        // [GIVEN] Item "X" with Variant "X1" and Item Discount Group "ITEMDISC"
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateVariant(ItemVariant, Item);
        LibraryERM.CreateItemDiscountGroup(ItemDiscountGroup);
        Item.Validate("Item Disc. Group", ItemDiscountGroup.Code);
        Item.Modify(true);

        // [GIVEN] Sales Line Discount with Customer Discount Group "CUSTDISC", Item Discount Group "ITEMDISC" and "Line Discount %" = 10
        LibraryERM.CreateLineDiscForCustomer(
          SalesLineDiscount, SalesLineDiscount.Type::"Item Disc. Group", ItemDiscountGroup.Code,
          SalesLineDiscount."Sales Type"::"Customer Disc. Group", CustomerDiscountGroup.Code, WorkDate(), '', '', '', 0);
        SalesLineDiscount.Validate("Line Discount %", LibraryRandom.RandDec(10, 2));
        SalesLineDiscount.Modify(true);

        // [GIVEN] Sales Price for All Customers for Item "X", Variant "X1" is 50, "Allow Line Disc." = No
        LibrarySales.CreateSalesPrice(
          SalesPrice, Item."No.", SalesPrice."Sales Type"::"All Customers", '',
          WorkDate(), '', ItemVariant.Code, Item."Base Unit of Measure", 0, LibraryRandom.RandDec(100, 2));
        SalesPrice.Validate("Allow Line Disc.", false);
        SalesPrice.Modify(true);

        // [GIVEN] Job Planning Line with Item "X"
        CreateSimpleJobPlanningLine(JobPlanningLine, JobTask);
        JobPlanningLine.Validate(Type, JobPlanningLine.Type::Item);
        JobPlanningLine.Validate("No.", Item."No.");

        // [WHEN] Validate Variant "X1" on Job Planning Line
        JobPlanningLine.Validate("Variant Code", ItemVariant.Code);

        // [THEN] "Line Discount %" in Job Planning Line is 0%
        JobPlanningLine.TestField("Line Discount %", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NotPossibleToValidateResourceInJobPlanningLineWithoutGenProdPostingGroup()
    var
        Resource: Record Resource;
        JobPlanningLine: Record "Job Planning Line";
    begin
        // [FEATURE] [Resource]
        // [SCENARIO 271174] "Gen. Prod. Posting Group" is mandatory when validate Resource in Job Planning Line

        Initialize();
        LibraryResource.CreateResource(Resource, '');
        Resource.Validate("Gen. Prod. Posting Group", '');
        Resource.Modify(true);
        CreateJobPlanningLineWithType(JobPlanningLine, JobPlanningLine.Type::Resource);

        asserterror JobPlanningLine.Validate("No.", Resource."No.");

        Assert.ExpectedErrorCode('TestField');
        Assert.ExpectedError(StrSubstNo('%1 must have a value', Resource.FieldCaption("Gen. Prod. Posting Group")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NotPossibleToValidateItemInJobPlanningLineWithoutGenProdPostingGroup()
    var
        Item: Record Item;
        JobPlanningLine: Record "Job Planning Line";
    begin
        // [FEATURE] [Item]
        // [SCENARIO 271174] "Gen. Prod. Posting Group" is mandatory when validate Item in Job Planning Line

        Initialize();
        LibraryInventory.CreateItem(Item);
        Item.Validate("Gen. Prod. Posting Group", '');
        Item.Modify(true);
        CreateJobPlanningLineWithType(JobPlanningLine, JobPlanningLine.Type::Item);

        asserterror JobPlanningLine.Validate("No.", Item."No.");

        Assert.ExpectedErrorCode('TestField');
        Assert.ExpectedError(StrSubstNo('%1 must have a value', Item.FieldCaption("Gen. Prod. Posting Group")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NotPossibleToValidateGLAccInJobPlanningLineWithoutGenProdPostingGroup()
    var
        GLAccount: Record "G/L Account";
        JobPlanningLine: Record "Job Planning Line";
    begin
        // [FEATURE] [G/L Account]
        // [SCENARIO 271174] "Gen. Prod. Posting Group" is mandatory when validate G/L Account in Job Planning Line

        Initialize();
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Gen. Prod. Posting Group", '');
        GLAccount.Modify(true);
        CreateJobPlanningLineWithType(JobPlanningLine, JobPlanningLine.Type::"G/L Account");

        asserterror JobPlanningLine.Validate("No.", GLAccount."No.");

        Assert.ExpectedErrorCode('TestField');
        Assert.ExpectedError(StrSubstNo('%1 must have a value', GLAccount.FieldCaption("Gen. Prod. Posting Group")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferCountryCodeFromJobToJobPlanningLine()
    var
        JobPlanningLine: Record "Job Planning Line";
        Job: Record Job;
        CountryRegion: Record "Country/Region";
    begin
        // [SCENARIO 311079] Value of "Bill-to Country/Region Code" is copied to "Job Planning Line" from "Job" into InitJobPlanningLine
        Initialize();

        // [GIVEN] Job with "Country/Region Code" = "RU"
        LibraryJob.CreateJob(Job);
        LibraryERM.CreateCountryRegion(CountryRegion);
        Job."Bill-to Country/Region Code" := CountryRegion.Code;
        Job.Modify();

        // [GIVEN] Job Planning Line with "Job No." = Job."No."
        JobPlanningLine.Validate("Job No.", Job."No.");

        // [WHEN] Invoke "Job Planning Line".InitJobPlanningLine
        JobPlanningLine.InitJobPlanningLine();

        // [THEN] "Job Planning Line"."Country/Region Code" = "RU"
        JobPlanningLine.TestField("Country/Region Code", Job."Bill-to Country/Region Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FromPlanningLineToJnlLineSourceCode()
    var
        JobJournalBatch: Record "Job Journal Batch";
        JobJournalTemplate: Record "Job Journal Template";
        JobPlanningLine: Record "Job Planning Line";
        JobJournalLine: Record "Job Journal Line";
        JobTransferLine: Codeunit "Job Transfer Line";
    begin
        // [SCENARIO 319491] Function FromPlanningLineToJnlLine assigns Source Code to resulting Job Journal Line from Job Journal Template
        Initialize();

        // [GIVEN] Job Journal Template with "Source Code" = "S".
        LibraryJob.CreateJobJournalTemplate(JobJournalTemplate);
        JobJournalTemplate."Source Code" := LibraryUtility.GenerateGUID();
        JobJournalTemplate.Modify();
        LibraryJob.CreateJobJournalBatch(JobJournalTemplate.Name, JobJournalBatch);

        // [GIVEN] Job Planning Line with non-zero "Qty. to Transfer to Journal".
        CreateJobPlanningLine(JobPlanningLine, false);
        JobPlanningLine.Validate("Qty. to Transfer to Journal", LibraryRandom.RandInt(10));
        JobPlanningLine.Modify(true);

        // [WHEN] Invoke JobTransferLine.FromPlanningLineToJnlLine for Job Planning Line.
        JobTransferLine.FromPlanningLineToJnlLine(JobPlanningLine, WorkDate(), JobJournalTemplate.Name, JobJournalBatch.Name, JobJournalLine);

        // [THEN] Resulting Job Journal Line has "Source Code" = "S".
        JobJournalLine.TestField("Source Code", JobJournalTemplate."Source Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestValidatePlanningDateForText()
    var
        JobPlanningLine: Record "Job Planning Line";
        StandardText: Record "Standard Text";
    begin
        Initialize();

        // [GIVEN] A job planning line
        CreateJobPlanningLine(JobPlanningLine, false);

        // [GIVEN] The job planning line has Type Text set to a standard text code
        JobPlanningLine.Validate(Type, JobPlanningLine.Type::Text);
        StandardText.Init();
        StandardText.Code := LibraryRandom.RandText(20);
        StandardText.Description := 'Some description';
        StandardText.Insert();
        JobPlanningLine.Validate("No.", StandardText.Code);

        // [WHEN] Planning date is validated
        JobPlanningLine.Validate("Planning Date", CalcDate('<1D>', JobPlanningLine."Planning Date"));

        // [THEN] No Error
    end;

    [Test]
    [HandlerFunctions('MessageHandler,CreateInvoiceRequestHandler')]
    [Scope('OnPrem')]
    procedure TheFieldTypeIsNotEditableForJobPlanningLineWithPostedSalesInvoiceAndTypeText()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        SalesHeader: Record "Sales Header";
        JobCreateInvoice: Codeunit "Job Create-Invoice";
        JobPlanningLines: TestPage "Job Planning Lines";
    begin
        // [SCENARIO 366064] The field "Type" is not editable for Job Planning Line with posted Sales Invoice and Type = Text
        Initialize();

        // [GIVEN] Created Job and Sales Invoice
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Job."Bill-to Customer No.");

        // [GIVEN] Created 2 Job Planning Line: 1 with type = G/L Account abd 1 with Type = Text
        LibraryJob.CreateJobPlanningLine(
          JobPlanningLine."Line Type"::Billable, JobPlanningLine.Type::"G/L Account", JobTask, JobPlanningLine);
        LibraryJob.CreateJobPlanningLine(
          JobPlanningLine."Line Type"::Billable, JobPlanningLine.Type::Text, JobTask, JobPlanningLine);
        Commit();

        // [GIVEN] Added lines to Sales Invoice
        LibraryVariableStorage.Enqueue(SalesHeader."No.");
        JobPlanningLine.SetRange("Job No.", JobTask."Job No.");
        JobPlanningLine.SetRange("Job Task No.", JobTask."Job Task No.");
        JobCreateInvoice.CreateSalesInvoice(JobPlanningLine, false);

        // [GIVEN] Post Sales Invoice
        LibrarySales.PostSalesDocument(SalesHeader, false, false);

        // [WHEN] Open Job Planning Lines
        JobPlanningLines.OpenEdit();
        JobPlanningLines.FILTER.SetFilter("Job No.", JobTask."Job No.");
        JobPlanningLines.FILTER.SetFilter("Job Task No.", JobTask."Job Task No.");
        JobPlanningLines.FILTER.SetFilter(Type, Format(JobPlanningLine.Type::Text));
        JobPlanningLines.First();

        // [THEN] The field "Type" is not editable for the line with "Type" = Text
        Assert.IsFalse(JobPlanningLines.Type.Editable(), '');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('MessageHandler,CreateInvoiceRequestHandler')]
    [Scope('OnPrem')]
    procedure TheFieldTypeIsEditableForJobPlanningLineWithPostedSalesInvoiceAndTypeTextWithoutLinesInJobPlanningLineInvoice()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        SalesHeader: Record "Sales Header";
        JobPlanningLineInvoice: Record "Job Planning Line Invoice";
        JobCreateInvoice: Codeunit "Job Create-Invoice";
        JobPlanningLines: TestPage "Job Planning Lines";
    begin
        // [SCENARIO 366064] The field "Type" is editable for Job Planning Line with posted Sales Invoice and Type = Text,
        // [SCENARIO 366064] with deleted lines from Job Planning Line Invoice
        Initialize();

        // [GIVEN] Created Job and Sales Invoice
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Job."Bill-to Customer No.");

        // [GIVEN] Created 2 Job Planning Line: 1 with type = G/L Account abd 1 with Type = Text
        LibraryJob.CreateJobPlanningLine(
          JobPlanningLine."Line Type"::Billable, JobPlanningLine.Type::"G/L Account", JobTask, JobPlanningLine);
        LibraryJob.CreateJobPlanningLine(
          JobPlanningLine."Line Type"::Billable, JobPlanningLine.Type::Text, JobTask, JobPlanningLine);
        Commit();

        // [GIVEN] Added lines to Sales Invoice
        LibraryVariableStorage.Enqueue(SalesHeader."No.");
        JobPlanningLine.SetRange("Job No.", JobTask."Job No.");
        JobPlanningLine.SetRange("Job Task No.", JobTask."Job Task No.");
        JobCreateInvoice.CreateSalesInvoice(JobPlanningLine, false);

        // [GIVEN] Post Sales Invoice
        LibrarySales.PostSalesDocument(SalesHeader, false, false);

        // [GIVEN] Delete created Job Planning Line Invoice for type "Text"
        JobPlanningLine.SetRange(Type, JobPlanningLine.Type::Text);
        JobPlanningLine.FindFirst();
        JobPlanningLineInvoice.SetRange("Job No.", Job."No.");
        JobPlanningLineInvoice.SetRange("Job Task No.", JobTask."Job Task No.");
        JobPlanningLineInvoice.SetRange("Job Planning Line No.", JobPlanningLine."Line No.");
        JobPlanningLineInvoice.DeleteAll();

        // [WHEN] Open Job Planning Lines
        JobPlanningLines.OpenEdit();
        JobPlanningLines.FILTER.SetFilter("Job No.", JobTask."Job No.");
        JobPlanningLines.FILTER.SetFilter("Job Task No.", JobTask."Job Task No.");
        JobPlanningLines.FILTER.SetFilter(Type, Format(JobPlanningLine.Type::Text));
        JobPlanningLines.First();

        // [THEN] The field "Type" is editable for the line with "Type" = Text
        Assert.IsTrue(JobPlanningLines.Type.Editable(), '');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorThrownWhenBaseQtyIsRoundedTo0OnJobPlanningLine()
    var
        JobPlanningLine: Record "Job Planning Line";
        Item: Record Item;
        ItemUOM: Record "Item Unit of Measure";
        NonBaseUOM: Record "Unit of Measure";
        BaseUOM: Record "Unit of Measure";
        NonBaseQtyPerUOM: Decimal;
        QtyRoundingPrecision: Decimal;
    begin
        // [FEATURE] [Job Planning Line - Rounding Precision]
        // [SCENARIO] Error is thrown when rounding precision causes the base quantity to be rounded to 0.
        Initialize();

        // [GIVEN] An item with 2 unit of measures and qty. rounding precision on the base item unit of measure set.
        QtyRoundingPrecision := Round(1 / LibraryRandom.RandIntInRange(2, 10), 0.00001);
        NonBaseQtyPerUOM := Round(LibraryRandom.RandIntInRange(2, 10), QtyRoundingPrecision);

        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateUnitOfMeasureCode(BaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, Item."No.", BaseUOM.Code, 1);
        ItemUOM."Qty. Rounding Precision" := QtyRoundingPrecision;
        ItemUOM.Modify();
        Item.Validate("Base Unit of Measure", ItemUOM.Code);
        Item.Modify();

        LibraryInventory.CreateUnitOfMeasureCode(NonBaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, Item."No.", NonBaseUOM.Code, NonBaseQtyPerUOM);

        // [GIVEN] A Job Planning Line where the unit of measure code is set to the non-base unit of measure.
        CreateJobPlanningLineWithType(JobPlanningLine, JobPlanningLine.Type::Item);
        JobPlanningLine.Validate("No.", Item."No.");
        JobPlanningLine.Validate("Unit of Measure Code", NonBaseUOM.Code);

        // [WHEN] Quantity is set to a value that rounds the base quantity to 0
        asserterror JobPlanningLine.Validate(Quantity, 1 / (LibraryRandom.RandIntInRange(300, 1000)));

        // [THEN] Error is thrown
        Assert.ExpectedError(RoundingTo0Err);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BaseQtyIsRoundedWithRoundingPrecisionSpecifiedOnJobPlanningLine()
    var
        JobPlanningLine: Record "Job Planning Line";
        Item: Record Item;
        ItemUOM: Record "Item Unit of Measure";
        NonBaseUOM: Record "Unit of Measure";
        BaseUOM: Record "Unit of Measure";
        NonBaseQtyPerUOM: Decimal;
        QtyRoundingPrecision: Decimal;
        QtyToSet: Decimal;
    begin
        // [FEATURE] [Job Planning Line - Rounding Precision]
        // [SCENARIO] Quantity (Base) is rounded with the specified rounding precision.
        Initialize();

        // [GIVEN] An item with 2 unit of measures and qty. rounding precision on the base item unit of measure set.
        QtyRoundingPrecision := Round(1 / LibraryRandom.RandIntInRange(2, 10), 0.00001);
        NonBaseQtyPerUOM := Round(LibraryRandom.RandIntInRange(2, 10), QtyRoundingPrecision);
        QtyToSet := LibraryRandom.RandDec(10, 2);

        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateUnitOfMeasureCode(BaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, Item."No.", BaseUOM.Code, 1);
        ItemUOM."Qty. Rounding Precision" := QtyRoundingPrecision;
        ItemUOM.Modify();
        Item.Validate("Base Unit of Measure", ItemUOM.Code);
        Item.Modify();
        LibraryInventory.CreateUnitOfMeasureCode(NonBaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, Item."No.", NonBaseUOM.Code, NonBaseQtyPerUOM);

        // [GIVEN] A Job Planning Line where the unit of measure code is set to the non-base unit of measure.
        CreateJobPlanningLineWithType(JobPlanningLine, JobPlanningLine.Type::Item);
        JobPlanningLine.Validate("No.", Item."No.");
        JobPlanningLine.Validate("Unit of Measure Code", NonBaseUOM.Code);

        // [WHEN] Quantity is set to a value that rounds the base quantity to 0
        JobPlanningLine.Validate(Quantity, QtyToSet);

        // [THEN] Quantity (Base) is rounded with the specified rounding precision
        Assert.AreEqual(Round(NonBaseQtyPerUOM * QtyToSet, QtyRoundingPrecision), JobPlanningLine."Quantity (Base)", 'Base quantity is not rounded correctly.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BaseQtyIsRoundedWithRoundingPrecisionUnspecifiedOnJobPlanningLine()
    var
        JobPlanningLine: Record "Job Planning Line";
        Item: Record Item;
        ItemUOM: Record "Item Unit of Measure";
        NonBaseUOM: Record "Unit of Measure";
        BaseUOM: Record "Unit of Measure";
        NonBaseQtyPerUOM: Decimal;
        QtyToSet: Decimal;
    begin
        // [FEATURE] [Job Planning Line - Rounding Precision]
        // [SCENARIO] Quantity (Base) is rounded with the default rounding precision when rounding precision is not specified.
        Initialize();

        // [GIVEN] An item with 2 unit of measures and qty. rounding precision on the base item unit of measure set.
        NonBaseQtyPerUOM := LibraryRandom.RandIntInRange(2, 10);
        QtyToSet := LibraryRandom.RandDec(10, 7);

        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateUnitOfMeasureCode(BaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, Item."No.", BaseUOM.Code, 1);
        Item.Validate("Base Unit of Measure", ItemUOM.Code);
        Item.Modify();
        LibraryInventory.CreateUnitOfMeasureCode(NonBaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, Item."No.", NonBaseUOM.Code, NonBaseQtyPerUOM);

        // [GIVEN] A Job Planning Line where the unit of measure code is set to the non-base unit of measure.
        CreateJobPlanningLineWithType(JobPlanningLine, JobPlanningLine.Type::Item);
        JobPlanningLine.Validate("No.", Item."No.");
        JobPlanningLine.Validate("Unit of Measure Code", NonBaseUOM.Code);

        // [WHEN] Quantity is set to a value that rounds the base quantity to 0
        JobPlanningLine.Validate(Quantity, QtyToSet);

        // [THEN] Quantity is rounded with the default rounding precision
        Assert.AreEqual(Round(QtyToSet, 0.00001), JobPlanningLine.Quantity, 'Qty. is not rounded correctly.');

        // [THEN] Quantity (Base) is rounded with the default rounding precision
        Assert.AreEqual(Round(NonBaseQtyPerUOM * JobPlanningLine.Quantity, 0.00001),
                        JobPlanningLine."Quantity (Base)", 'Base qty. is not rounded correctly.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BaseQtyIsRoundedWithRoundingPrecisionOnJobPlanningLine()
    var
        JobPlanningLine: Record "Job Planning Line";
        Item: Record Item;
        ItemUOM: Record "Item Unit of Measure";
        NonBaseUOM: Record "Unit of Measure";
        BaseUOM: Record "Unit of Measure";
        NonBaseQtyPerUOM: Decimal;
        QtyRoundingPrecision: Decimal;
    begin
        // [FEATURE] [Job Planning Line - Rounding Precision]
        // [SCENARIO] Quantity (Base) is rounded with the specified rounding precision.
        Initialize();

        // [GIVEN] An item with 2 unit of measures and qty. rounding precision on the base item unit of measure set.
        QtyRoundingPrecision := Round(1 / LibraryRandom.RandIntInRange(2, 10), 0.00001);
        NonBaseQtyPerUOM := Round(LibraryRandom.RandIntInRange(5, 10), QtyRoundingPrecision);

        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateUnitOfMeasureCode(BaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, Item."No.", BaseUOM.Code, 1);
        ItemUOM."Qty. Rounding Precision" := QtyRoundingPrecision;
        ItemUOM.Modify();
        Item.Validate("Base Unit of Measure", ItemUOM.Code);
        Item.Modify();
        LibraryInventory.CreateUnitOfMeasureCode(NonBaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, Item."No.", NonBaseUOM.Code, NonBaseQtyPerUOM);

        // [GIVEN] A Job Planning Line where the unit of measure code is set to the non-base unit of measure.
        CreateJobPlanningLineWithType(JobPlanningLine, JobPlanningLine.Type::Item);
        JobPlanningLine.Validate("No.", Item."No.");
        JobPlanningLine.Validate("Unit of Measure Code", NonBaseUOM.Code);

        // [WHEN] Quantity is set to a value that rounds the base quantity to 0
        JobPlanningLine.Validate(Quantity, (NonBaseQtyPerUOM - 1) / NonBaseQtyPerUOM);

        // [THEN] Quantity (Base) is rounded with the specified rounding precision
        Assert.AreEqual(Round(NonBaseQtyPerUOM - 1, QtyRoundingPrecision),
                        JobPlanningLine."Quantity (Base)", 'Base quantity is not rounded correctly.');
    end;

    [Test]
    procedure QuantityValidationUpdatesUnitPriceByCostFactor()
    var
        Item: Record Item;
        Job: Record Job;
        JobTask: Record "Job Task";
        JobItemPrice: Record "Job Item Price";
        JobPlanningLine: Record "Job Planning Line";
        CostFactor: Decimal;
        UnitPrice: Decimal;
    begin
        // [SCENARIO 405107] Quantity modification updates "Unit Price calculated by "Cost Factor"
        Initialize();
        // [GIVEN] A job with a job task
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
        LibraryJob.CreateJobPlanningLine(
            JobPlanningLine."Line Type"::Budget, JobPlanningLine.Type::Item, JobTask, JobPlanningLine);

        // [GIVEN] Price line for Job and Item, where "Cost Factor" is set
        CostFactor := LibraryRandom.RandDec(10, 1);
        Item.Get(JobPlanningLine."No.");
        LibraryJob.CreateJobItemPrice(
            JobItemPrice, Job."No.", JobTask."Job Task No.", JobPlanningLine."No.", '', '', Item."Base Unit of Measure");
        JobItemPrice.Validate("Unit Cost Factor", CostFactor);
        JobItemPrice.Modify();

        // [GIVEN] Job planning line, where "Unit Price" is 15, calculated by "Cost Factor"
        JobPlanningLine.Validate(Quantity, 1);
        JobPlanningLine.TestField("Cost Factor", CostFactor);
        UnitPrice := JobPlanningLine."Unit Price";

        // [WHEN] Increase Quantity by 3
        JobPlanningLine.Validate(Quantity, JobPlanningLine.Quantity + 3);

        // [THEN] "Unit Price" is still 15
        JobPlanningLine.TestField("Unit Price", UnitPrice);
    end;

    [Test]
    procedure LocationForNonInventoryItemsAllowed()
    var
        ServiceItem: Record Item;
        NonInventoryItem: Record Item;
        Job: Record Job;
        JobTask: Record "Job Task";
        Location: Record Location;
        JobPlanningLine1: Record "Job Planning Line";
        JobPlanningLine2: Record "Job Planning Line";
        JobJournalTemplate: Record "Job Journal Template";
        JobJournalBatch: Record "Job Journal Batch";
        JobJournalLine1: Record "Job Journal Line";
        JobJournalLine2: Record "Job Journal Line";
        JobTransferLine: Codeunit "Job Transfer Line";
    begin
        // [SCENARIO] Job planning lines for non-inventory items with location set.
        // Location should be transfered to job journal lines.
        Initialize();

        // [GIVEN] A non-inventory item and a service item.
        LibraryInventory.CreateServiceTypeItem(ServiceItem);
        LibraryInventory.CreateNonInventoryTypeItem(NonInventoryItem);

        // [GIVEN] A Location.
        LibraryWarehouse.CreateLocation(Location);

        // [GIVEN] A job with job tasks containing two job planning lines for the non-inventory items with location set.
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
        LibraryJob.CreateJobPlanningLine(
            JobPlanningLine1."Line Type"::Budget, JobPlanningLine1.Type::Item, JobTask, JobPlanningLine1);
        LibraryJob.CreateJobPlanningLine(
            JobPlanningLine2."Line Type"::Budget, JobPlanningLine2.Type::Item, JobTask, JobPlanningLine2);

        JobPlanningLine1.Validate("No.", ServiceItem."No.");
        JobPlanningLine1.Validate(Quantity, 1);
        JobPlanningLine1.Validate("Location Code", Location.Code);
        JobPlanningLine1.Modify(true);

        JobPlanningLine2.Validate("No.", NonInventoryItem."No.");
        JobPlanningLine2.Validate(Quantity, 1);
        JobPlanningLine2.Validate("Location Code", Location.Code);
        JobPlanningLine2.Modify(true);

        // [WHEN] Creating job journal lines from the job planning lines.
        LibraryJob.GetJobJournalTemplate(JobJournalTemplate);
        LibraryJob.CreateJobJournalBatch(LibraryJob.GetJobJournalTemplate(JobJournalTemplate), JobJournalBatch);
        JobTransferLine.FromPlanningLineToJnlLine(
            JobPlanningLine1, WorkDate(), JobJournalTemplate.Name, JobJournalBatch.Name, JobJournalLine1);
        JobTransferLine.FromPlanningLineToJnlLine(
            JobPlanningLine2, WorkDate(), JobJournalTemplate.Name, JobJournalBatch.Name, JobJournalLine2);

        // [THEN] The location is transfered to the job journal lines for each non-inventory item.
        Assert.AreEqual(ServiceItem."No.", JobJournalLine1."No.", 'Expected service item to be transfered');
        Assert.AreEqual(Location.Code, JobJournalLine1."Location Code", 'Expected location code to be transfered');

        Assert.AreEqual(NonInventoryItem."No.", JobJournalLine2."No.", 'Expected non-inventory item to be transfered');
        Assert.AreEqual(Location.Code, JobJournalLine2."Location Code", 'Expected location code to be transfered');
    end;

    [Test]
    procedure BinCodeNotAllowedForNonInventoryItems()
    var
        Item: Record Item;
        ServiceItem: Record Item;
        NonInventoryItem: Record Item;
        Job: Record Job;
        JobTask: Record "Job Task";
        Location: Record Location;
        Bin: Record Bin;
        BinContent: Record "Bin Content";
        JobPlanningLine1: Record "Job Planning Line";
        JobPlanningLine2: Record "Job Planning Line";
        JobPlanningLine3: Record "Job Planning Line";
    begin
        // [SCENARIO] Bin code is not allowed for non-inventory items in job planning line.
        Initialize();

        // [GIVEN] A non-inventory item and a service item.
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateServiceTypeItem(ServiceItem);
        LibraryInventory.CreateNonInventoryTypeItem(NonInventoryItem);

        // [GIVEN] A location with require bin and a default bin code.
        LibraryWarehouse.CreateLocationWMS(Location, true, false, false, false, false);
        LibraryWarehouse.CreateBin(Bin, Location.Code, '', '', '');
        LibraryWarehouse.CreateBinContent(
            BinContent, Bin."Location Code", '', Bin.Code, Item."No.", '', Item."Base Unit of Measure"
        );
        BinContent.Validate(Default, true);
        BinContent.Modify(true);
        Location.Validate("Default Bin Code", Bin.Code);
        Location.Modify(true);

        // [GIVEN] A job with job tasks containing 3 job planning lines for for the item and non-inventory items.
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
        LibraryJob.CreateJobPlanningLine(
            JobPlanningLine1."Line Type"::Budget, JobPlanningLine1.Type::Item, JobTask, JobPlanningLine1);
        LibraryJob.CreateJobPlanningLine(
            JobPlanningLine2."Line Type"::Budget, JobPlanningLine2.Type::Item, JobTask, JobPlanningLine2);
        LibraryJob.CreateJobPlanningLine(
            JobPlanningLine3."Line Type"::Budget, JobPlanningLine3.Type::Item, JobTask, JobPlanningLine3);

        // [WHEN] Settings the location code for the job planning lines.
        JobPlanningLine1.Validate("No.", Item."No.");
        JobPlanningLine1.Validate(Quantity, 1);
        JobPlanningLine1.Validate("Location Code", Location.Code);
        JobPlanningLine2.Modify(true);

        JobPlanningLine2.Validate("No.", ServiceItem."No.");
        JobPlanningLine2.Validate(Quantity, 1);
        JobPlanningLine2.Validate("Location Code", Location.Code);
        JobPlanningLine2.Modify(true);

        JobPlanningLine3.Validate("No.", NonInventoryItem."No.");
        JobPlanningLine3.Validate(Quantity, 1);
        JobPlanningLine3.Validate("Location Code", Location.Code);
        JobPlanningLine3.Modify(true);

        // [THEN] Bin code is set for the item.
        Assert.AreEqual(Bin.Code, JobPlanningLine1."Bin Code", 'Expected bin code to be set');
        Assert.AreEqual('', JobPlanningLine2."Bin Code", 'Expected no bin code set');
        Assert.AreEqual('', JobPlanningLine3."Bin Code", 'Expected no bin code set');

        // [WHEN] Setting bin code on non-inventory items.
        asserterror JobPlanningLine2.Validate("Bin Code", Bin.Code);
        asserterror JobPlanningLine3.Validate("Bin Code", Bin.Code);

        // [THEN] An error is thrown.
    end;

    [Test]
    procedure OpenJobPlanningLinesForJobNo20CharsWithSpecialSymbols()
    var
        Job: Record Job;
        JobCard: TestPage "Job Card";
        JobPlanningLines: TestPage "Job Planning Lines";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 404933] Open job planning lines for the job having 20 chars "No." including symbol "&"

        // [GIVEN] Job card with "No." = "ACTPT&G-CRM-GM (T&M)"
        Job.Init();
        Job.Validate("No.", 'ACTPT&G-CRM-GM (T&M)');
        Job.Insert(true);
        Job.Validate("Bill-to Customer No.", LibrarySales.CreateCustomerNo());
        Job.Modify(true);

        // [WHEN] Invoke action on Job Card Lines -> Job -> Job Planning Lines
        Job.SetRecFilter();
        JobCard.Trap();
        Page.Run(Page::"Job Card", Job);
        JobPlanningLines.Trap();
        JobCard.JobTaskLines.JobPlanningLines.Invoke();

        // [THEN] Job plannig lines is opened
        JobPlanningLines.Close();
        JobCard.Close();
    end;

    [Test]
    procedure JobPlanningLineFindJTPriceForGLAccountNotUpdateUnitPrice()
    var
        JobPlanningLine: Record "Job Planning Line";
        JobTask: Record "Job Task";
        Job: Record Job;
        SalesPriceCalcMgt: Codeunit "Sales Price Calc. Mgt.";
        UnitCost: Decimal;
    begin
        // [SCENARIO 408052] "Sales Price Calc. Mgt".JobPlanningLineFindJTPrice do not update "Job Planning Line"."Unit Price" if "Job G/L Account Price" is not found
        Initialize();

        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
        LibraryJob.CreateJobPlanningLine(JobPlanningLine."Line Type"::Budget,
            JobPlanningLine.Type::"G/L Account", JobTask, JobPlanningLine);
        UnitCost := JobPlanningLine."Unit Cost";

        SalesPriceCalcMgt.JobPlanningLineFindJTPrice(JobPlanningLine);

        JobPlanningLine.TestField("Unit Cost", UnitCost);
    end;

    [Test]
    procedure JobPlanningLineFindJTPriceForGLAccountUpdateUnitPrice()
    var
        JobPlanningLine: Record "Job Planning Line";
        JobTask: Record "Job Task";
        Job: Record Job;
        JobGLAccountPrice: Record "Job G/L Account Price";
        SalesPriceCalcMgt: Codeunit "Sales Price Calc. Mgt.";
        UnitCost: Decimal;
    begin
        // [SCENARIO 408052] "Sales Price Calc. Mgt".JobPlanningLineFindJTPrice update "Job Planning Line"."Unit Price"
        Initialize();

        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
        LibraryJob.CreateJobPlanningLine(JobPlanningLine."Line Type"::Budget,
            JobPlanningLine.Type::"G/L Account", JobTask, JobPlanningLine);
        CreateJobGLAccPrice(JobGLAccountPrice, Job."No.", '', JobPlanningLine."No.");
        UnitCost := JobGLAccountPrice."Unit Cost";

        SalesPriceCalcMgt.JobPlanningLineFindJTPrice(JobPlanningLine);

        JobPlanningLine.TestField("Unit Cost", UnitCost);
    end;

    [Test]
    procedure PlanningDateOnInitJobPlanningLine()
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        // [SCENARIO 413747] Validate Planning Date after iniialize Job Planning Line
        JobPlanningLine.Init();
        JobPlanningLine.Validate("Planning Date", WorkDate());
        JobPlanningLine.TestField("Planning Due Date", WorkDate());
    end;

    [Test]
    procedure NoCostingQuantityInformationOnJobPlanningLineOfTypeText()
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        // [SCENARIO] It should not be possible to enter costing/quantity information on job planning lines of type text.
        JobPlanningLine.Init();
        JobPlanningLine.Validate(Type, JobPlanningLine.Type::Text);

        asserterror JobPlanningLine.Validate(Quantity, 1);
        asserterror JobPlanningLine.Validate("Quantity (Base)", 1);

        asserterror JobPlanningLine.Validate("Qty. to Transfer to Invoice", 1);
        asserterror JobPlanningLine.Validate("Qty. to Transfer to Journal", 1);

        asserterror JobPlanningLine.Validate("Unit Cost", 1);
        asserterror JobPlanningLine.Validate("Unit Cost (LCY)", 1);
        asserterror JobPlanningLine.Validate("Direct Unit Cost (LCY)", 1);

        asserterror JobPlanningLine.Validate("Unit Price", 1);
        asserterror JobPlanningLine.Validate("Unit Price (LCY)", 1);

        asserterror JobPlanningLine.Validate("Line Amount", 1);
        asserterror JobPlanningLine.Validate("Line Amount (LCY)", 1);
    end;

    [Test]
    procedure VerifyDescriptionOnJobPlanningLineForVariantWithItemTranslation()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ItemTranslation: Record "Item Translation";
        Language: Record Language;
        JobPlanningLine: Record "Job Planning Line";
        Job: Record Job;
        JobTask: Record "Job Task";
    begin
        // [SCENARIO 480325] Verify Description on Job Planning Line for Variant with Item Translation
        Initialize();

        // [GIVEN] Create Item
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create Variant
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");

        // [GIVEN] Create Item Translation
        Language.FindFirst();
        CreateItemTranslation(ItemTranslation, Item."No.", Language.Code, ItemVariant.Code);

        // [GIVEN] Create Job, Job Task
        CreateJobAndJobTask(Job, JobTask, false, '');

        // [GIVEN] Update Language Code on Job
        Job.Validate("Language Code", Language.Code);
        Job.Modify(true);

        // [GIVEN] Create Job Planning Line
        LibraryJob.CreateJobPlanningLine(JobPlanningLine."Line Type"::Budget,
            JobPlanningLine.Type::Item, JobTask, JobPlanningLine);
        JobPlanningLine.Validate("No.", Item."No.");

        // [WHEN] Validate Variant on Job Planning Line
        JobPlanningLine.Validate("Variant Code", ItemVariant.Code);

        // [THEN] Verify Description on Job Planning Line
        JobPlanningLine.TestField(Description, ItemTranslation.Description);
    end;

    [Test]
    procedure NoOfItemIsValidatedEvenIfEnterDescriptionOfItemInNoOfJobPlanningLineHavingTypeAsItem()
    var
        Item: Record Item;
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
    begin
        // [SCENARIO 547563] When Stan enters the Description of an Item in "No." field of
        // Job Planning Line having Type selected as Item, then "No." field of Job Planning Line
        // Is updated with the value of "No." field of the Item without any error.
        Initialize();

        // [GIVEN] Create an Item and Validate Description.
        LibraryInventory.CreateItem(Item);
        Item.Validate(Description, LibraryUtility.GenerateRandomText(MaxStrLen(Item."No.")));
        Item.Modify(true);

        // [GIVEN] Create a Job and a Job task.
        CreateJobAndJobTask(Job, JobTask, false, '');

        // [WHEN] Create a Job Planning Line and Validate Type and No.
        CreateSimpleJobPlanningLine(JobPlanningLine, JobTask);
        JobPlanningLine.Validate(Type, JobPlanningLine.Type::Item);
        JobPlanningLine.Validate("No.", Item.Description);
        JobPlanningLine.Modify(true);

        // [THEN] No. of Job Planning Line must be equal to No. of Item.
        Assert.AreEqual(
            Item."No.",
            JobPlanningLine."No.",
            StrSubstNo(
                NoJobPlanningLineErr,
                JobPlanningLine.FieldCaption("No."),
                Item."No.",
                JobPlanningLine.TableCaption()));
    end;

    [Test]
    procedure UnitCostLCYIsNotChangedWhenUnitPriceIsChangedInJobPlanningLine()
    var
        Currency: Record Currency;
        Item: Record Item;
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine, JobPlanningLine2 : Record "Job Planning Line";
        JobPlanningLines: TestPage "Job Planning Lines";
    begin
        // [SCENARIO 550707] Unit Cost (LCY) in Job Planning Line is not changed when Unit Price is changed.
        Initialize();

        // [GIVEN] Create a Currency.
        LibraryERM.CreateCurrency(Currency);

        // [GIVEN] Create a Random Currency Exchange Rate.
        LibraryERM.CreateRandomExchangeRate(Currency.Code);

        // [GIVEN] Validate Unit-Amount Rounding Precision.
        Currency.Validate("Unit-Amount Rounding Precision", 0.01);
        Currency.Modify(true);

        // [GIVEN] Create an Item and Validate Unit Cost.
        LibraryInventory.CreateItem(Item);
        Item.Validate("Unit Cost", LibraryRandom.RandDecInDecimalRange(0.37, 0.37, 2));
        Item.Modify(true);

        // [GIVEN] Create a Job and a Job task.
        CreateJobAndJobTask(Job, JobTask, false, Currency.Code);

        // [GIVEN] Create a Job Planning Line and Validate Type and No.
        CreateSimpleJobPlanningLine(JobPlanningLine, JobTask);
        JobPlanningLine.Validate(Type, JobPlanningLine.Type::Item);
        JobPlanningLine.Validate("No.", Item."No.");
        JobPlanningLine.Modify(true);

        // [GIVEN] Open Job Planning Lines page and set value in Unit Price.
        JobPlanningLines.OpenEdit();
        JobPlanningLines.GoToRecord(JobPlanningLine);
        JobPlanningLines."Unit Price".SetValue(LibraryRandom.RandIntInRange(5, 5));
        JobPlanningLines.Close();

        // [WHEN] Find Job Planning Line.
        JobPlanningLine2.Get(
            JobPlanningLine."Job No.",
            JobPlanningLine."Job Task No.",
            JobPlanningLine."Line No.");

        // [THEN] Unit Cost (LCY) of Job Planning Line is equal to Unit Cost of Item.
        Assert.AreEqual(
            Item."Unit Cost",
            JobPlanningLine2."Unit Cost (LCY)",
            StrSubstNo(
                UnitCostLCYErr,
                JobPlanningLine2.FieldCaption("Unit Cost (LCY)"),
                Item."Unit Cost",
                JobPlanningLine2.TableCaption()));
    end;

    [Test]
    procedure PlanningDateAndDocumentNoDataAreTransferedOnPlanningLinesOnInsertExtendedTextFromItem()
    var
        Item: Record Item;
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        TextJobPlanningLine: Record "Job Planning Line";
        ExtendedTextHeader: Record "Extended Text Header";
        ExtendedTextLine: Record "Extended Text Line";
        JobPlanningLines: TestPage "Job Planning Lines";
        DocumentNo: Code[20];
    begin
        // [SCENARIO 556639] Planning Date and Document No. data are transfered on Planning Lines on Insert Extended Text
        Initialize();

        // [GIVEN] Create Item with Automatic Ext. Text
        CreateItemWithAutomaticExtText(Item);

        // [GIVEN] Create Extended Text for the Item
        UpdateAllLanguagesCodeOnExtendedTextHeader(ExtendedTextHeader, Item."No.");
        LibraryInventory.CreateExtendedTextLineItem(ExtendedTextLine, ExtendedTextHeader);
        ExtendedTextLine.Validate(Text, ExtendedTextHeader."No.");
        ExtendedTextLine.Modify(true);

        // [GIVEN] Create Job and Job Task
        CreateJobAndJobTask(Job, JobTask, false, '');

        // [GIVEN] Create Job Planning Line
        LibraryJob.CreateJobPlanningLine(JobPlanningLine."Line Type"::Budget,
            JobPlanningLine.Type::Item, JobTask, JobPlanningLine);

        // [GIVEN] Add Document No. on Job Planning Line
        DocumentNo := LibraryUtility.GenerateRandomText(20);
        JobPlanningLine.Validate("Document No.", DocumentNo);
        JobPlanningLine.Modify(true);

        // [WHEN] Open Job Planning Lines page and set Item No.
        JobPlanningLines.OpenEdit();
        JobPlanningLines.GotoRecord(JobPlanningLine);
        JobPlanningLines."No.".SetValue(Item."No.");

        // [THEN] Verify Planning Date and Document No. Planning Line
        FindJobPlanningLine(TextJobPlanningLine, JobTask, Job, JobPlanningLine.Type::Text);
        Assert.AreEqual(TextJobPlanningLine."Planning Date", JobPlanningLine."Planning Date", 'Planning Date is not equal');
        Assert.AreEqual(TextJobPlanningLine."Planned Delivery Date", JobPlanningLine."Planned Delivery Date", 'Planned Delivery Date is not equal');
        Assert.AreEqual(TextJobPlanningLine."Document No.", JobPlanningLine."Document No.", 'Document No. is not equal');
    end;

    [Test]
    [HandlerFunctions('ItemListLookForItem')]
    procedure ExtendedTextLineIsCreatedOnSelectItemsActionFromProjectPlanningLines()
    var
        Item: Record Item;
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        TextJobPlanningLine: Record "Job Planning Line";
        ExtendedTextHeader: Record "Extended Text Header";
        ExtendedTextLine: Record "Extended Text Line";
        JobPlanningLines: TestPage "Job Planning Lines";
    begin
        // [SCENARIO 556635] Extended Text Line is created on Select Items action from Project Planning Lines
        Initialize();

        // [GIVEN] Create Item with Automatic Ext. Text
        CreateItemWithAutomaticExtText(Item);

        // [GIVEN] Create Extended Text for the Item
        UpdateAllLanguagesCodeOnExtendedTextHeader(ExtendedTextHeader, Item."No.");
        LibraryInventory.CreateExtendedTextLineItem(ExtendedTextLine, ExtendedTextHeader);
        ExtendedTextLine.Validate(Text, ExtendedTextHeader."No.");
        ExtendedTextLine.Modify(true);

        // [GIVEN] Create Job and Job Task
        CreateJobAndJobTask(Job, JobTask, false, '');

        // [GIVEN] Create Job Planning Line
        LibraryJob.CreateJobPlanningLine(JobPlanningLine."Line Type"::Budget,
            JobPlanningLine.Type::Item, JobTask, JobPlanningLine);

        // [GIVEN] Enqueue Item No.
        LibraryVariableStorage.Enqueue(Item."No.");

        // [WHEN] Open Job Planning Lines page and set Item No.
        JobPlanningLines.OpenEdit();
        JobPlanningLines.GotoRecord(JobPlanningLine);
        JobPlanningLines.SelectMultiItems.Invoke();

        // [THEN] Verify Planning Date and Document No. Planning Line
        FindJobPlanningLine(TextJobPlanningLine, JobTask, Job, JobPlanningLine.Type::Text);
        Assert.RecordIsNotEmpty(TextJobPlanningLine, CompanyName);
    end;

    [Test]
    procedure UnitCostIsNotChangedWhenUnitPriceIsChangedInJobPlanningLine()
    var
        Item: Record Item;
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        JobPlanningLines: TestPage "Job Planning Lines";
        UnitCost: Decimal;
    begin
        // [SCENARIO 561139] Unit Cost in Job Planning Line is not changed when Unit Price is changed.
        Initialize();

        // [GIVEN] Create an Item and Validate Costing Method and Unit Cost.
        LibraryInventory.CreateItem(Item);
        Item.Validate("Costing Method", Item."Costing Method"::Standard);
        Item.Validate("Unit Cost", LibraryRandom.RandInt(100));
        Item.Modify(true);

        // [GIVEN] Create a Job and a Job task.
        CreateJobAndJobTask(Job, JobTask, false, '');

        // [GIVEN] Create a Job Planning Line and Validate Type and No.
        CreateSimpleJobPlanningLine(JobPlanningLine, JobTask);
        JobPlanningLine.Validate(Type, JobPlanningLine.Type::Item);
        JobPlanningLine.Validate("No.", Item."No.");
        JobPlanningLine.Modify(true);

        // [GIVEN] Generate and save Unit Cost in a Variable.
        UnitCost := LibraryRandom.RandInt(50);

        // [GIVEN] Open Job Planning Lines page and set value in Unit Cost.
        JobPlanningLines.OpenEdit();
        JobPlanningLines.GoToRecord(JobPlanningLine);
        JobPlanningLines."Unit Cost".SetValue(UnitCost);
        JobPlanningLines.Close();

        // [GIVEN] Find Job Planning Line.
        JobPlanningLine.Get(
            JobPlanningLine."Job No.",
            JobPlanningLine."Job Task No.",
            JobPlanningLine."Line No.");

        // [GIVEN] Open Job Planning Lines page and set value in Unit Price.
        JobPlanningLines.OpenEdit();
        JobPlanningLines.GoToRecord(JobPlanningLine);
        JobPlanningLines."Unit Price".SetValue(LibraryRandom.RandInt(100));
        JobPlanningLines.Close();

        // [WHEN] Find Job Planning Line.
        JobPlanningLine.Get(
            JobPlanningLine."Job No.",
            JobPlanningLine."Job Task No.",
            JobPlanningLine."Line No.");

        // [THEN] Unit Cost of Job Planning Line is equal to UnitCost.
        Assert.AreEqual(
            UnitCost,
            JobPlanningLine."Unit Cost",
            StrSubstNo(
                UnitCostErr,
                JobPlanningLine.FieldCaption("Unit Cost"),
                UnitCost,
                JobPlanningLine.TableCaption()));
    end;

    [Test]
    procedure UnitCostIsNotChangedWhenUnitPriceIsChangedInJobPlanningLineHavingFIFOCostingMethodItem()
    var
        Item: Record Item;
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        JobPlanningLines: TestPage "Job Planning Lines";
        UnitCost: Decimal;
    begin
        // [SCENARIO 561139] Unit Cost and Unit Cost (LCY) in Job Planning Line is not changed when Unit Price is changed.
        Initialize();

        // [GIVEN] Create an Item and Validate Costing Method and Unit Cost.
        LibraryInventory.CreateItem(Item);
        Item.Validate("Costing Method", Item."Costing Method"::FIFO);
        Item.Validate("Unit Cost", LibraryRandom.RandInt(100));
        Item.Modify(true);

        // [GIVEN] Create a Job and a Job task.
        CreateJobAndJobTask(Job, JobTask, false, '');

        // [GIVEN] Create a Job Planning Line and Validate Type and No.
        CreateSimpleJobPlanningLine(JobPlanningLine, JobTask);
        JobPlanningLine.Validate(Type, JobPlanningLine.Type::Item);
        JobPlanningLine.Validate("No.", Item."No.");
        JobPlanningLine.Modify(true);

        // [GIVEN] Generate and save Unit Cost in a Variable.
        UnitCost := LibraryRandom.RandInt(50);

        // [GIVEN] Open Job Planning Lines page and set value in Unit Cost.
        JobPlanningLines.OpenEdit();
        JobPlanningLines.GoToRecord(JobPlanningLine);
        JobPlanningLines."Unit Cost".SetValue(UnitCost);
        JobPlanningLines.Close();

        // [GIVEN] Find Job Planning Line.
        JobPlanningLine.Get(
            JobPlanningLine."Job No.",
            JobPlanningLine."Job Task No.",
            JobPlanningLine."Line No.");

        // [GIVEN] Open Job Planning Lines page and set value in Unit Price.
        JobPlanningLines.OpenEdit();
        JobPlanningLines.GoToRecord(JobPlanningLine);
        JobPlanningLines."Unit Price".SetValue(LibraryRandom.RandInt(100));
        JobPlanningLines.Close();

        // [WHEN] Find Job Planning Line.
        JobPlanningLine.Get(
            JobPlanningLine."Job No.",
            JobPlanningLine."Job Task No.",
            JobPlanningLine."Line No.");

        // [THEN] Unit Cost of Job Planning Line is equal to UnitCost.
        Assert.AreEqual(
            UnitCost,
            JobPlanningLine."Unit Cost",
            StrSubstNo(
                UnitCostErr,
                JobPlanningLine.FieldCaption("Unit Cost"),
                UnitCost,
                JobPlanningLine.TableCaption()));

        // [THEN] Unit Cost (LCY) of Job Planning Line is equal to UnitCost.
        Assert.AreEqual(
            UnitCost,
            JobPlanningLine."Unit Cost (LCY)",
            StrSubstNo(
                UnitCostErr,
                JobPlanningLine.FieldCaption("Unit Cost (LCY)"),
                UnitCost,
                JobPlanningLine.TableCaption()));
    end;

    [Test]
    procedure UnitCostIsNotUpdatedWhenUnitPriceIsChangedInJobPlanningLine()
    var
        Item: Record Item;
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        JobPlanningLines: TestPage "Job Planning Lines";
        UnitCost: Decimal;
        UnitCostLCY: Decimal;
    begin
        // [SCENARIO 561139] Unit Cost in Job Planning Line is not changed when Unit Price is changed.
        Initialize();

        // [GIVEN] Create an Item and Validate Costing Method and Unit Cost.
        LibraryInventory.CreateItem(Item);
        Item.Validate("Costing Method", Item."Costing Method"::Standard);
        Item.Validate("Unit Cost", LibraryRandom.RandInt(100));
        Item.Modify(true);

        // [GIVEN] Create a Job and a Job task.
        CreateJobAndJobTask(Job, JobTask, false, CreateCurrency());

        // [GIVEN] Generate and save Unit Cost in a Variable.
        UnitCost := LibraryRandom.RandInt(50);

        // [GIVEN] Create a Job Planning Line and Validate Type and No.
        CreateSimpleJobPlanningLine(JobPlanningLine, JobTask);
        JobPlanningLine.Validate(Type, JobPlanningLine.Type::Item);
        JobPlanningLine.Validate("No.", Item."No.");
        JobPlanningLine.Validate("Unit Cost", UnitCost);
        JobPlanningLine.Modify(true);

        // [GIVEN] Save value in variable
        UnitCostLCY := JobPlanningLine."Unit Cost (LCY)";

        // [GIVEN] Find Job Planning Line.
        JobPlanningLine.Get(
            JobPlanningLine."Job No.",
            JobPlanningLine."Job Task No.",
            JobPlanningLine."Line No.");

        // [GIVEN] Open Job Planning Lines page and set value in Unit Price.
        JobPlanningLines.OpenEdit();
        JobPlanningLines.GoToRecord(JobPlanningLine);
        JobPlanningLines."Unit Price".SetValue(LibraryRandom.RandInt(100));
        JobPlanningLines.Close();

        // [WHEN] Find Job Planning Line.
        JobPlanningLine.Get(
            JobPlanningLine."Job No.",
            JobPlanningLine."Job Task No.",
            JobPlanningLine."Line No.");

        // [THEN] Unit Cost of Job Planning Line is equal to UnitCost.
        Assert.AreEqual(
            UnitCost,
            JobPlanningLine."Unit Cost",
            StrSubstNo(
                UnitCostErr,
                JobPlanningLine.FieldCaption("Unit Cost"),
                UnitCost,
                JobPlanningLine.TableCaption()));

        // [THEN] Unit Cost (LCY) of Job Planning Line is equal to Unit Cost of Item.
        Assert.AreEqual(
            UnitCostLCY,
            JobPlanningLine."Unit Cost (LCY)",
            StrSubstNo(
                UnitCostLCYErr,
                JobPlanningLine.FieldCaption("Unit Cost (LCY)"),
                UnitCostLCY,
                JobPlanningLine.TableCaption()));
    end;

    [Test]
    procedure RenameItemUpdateJobPlanningLine()
    var
        Item: Record Item;
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        NewItemNo: Code[20];
    begin
        // [SCENARIO 574025] When Renaming an Item, the Job Planning Line is updated with the new Item No.
        Initialize();

        // [GIVEN] Create Item
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create Job and Job Task
        CreateJobAndJobTask(Job, JobTask, false, '');

        // [GIVEN] Create Job Planning Line and Validate No.
        LibraryJob.CreateJobPlanningLine(JobPlanningLine."Line Type"::Budget,
            JobPlanningLine.Type::Item, JobTask, JobPlanningLine);
        JobPlanningLine.Validate("No.", Item."No.");
        JobPlanningLine.Modify(true);

        // [WHEN] Rename Item No.
        RenameItem(Item."No.", NewItemNo);

        // [THEN] Find Job Planning Line and validate No.
        FindJobPlanningLine(JobPlanningLine, JobTask, Job, JobPlanningLine.Type::Item);
        Assert.AreEqual(
            NewItemNo,
            JobPlanningLine."No.",
            StrSubstNo(
                NoJobPlanningLineErr,
                JobPlanningLine.FieldCaption("No."),
                NewItemNo,
                JobPlanningLine.TableCaption()));
    end;

    [Test]
    procedure RenameResourceUpdateJobPlanningLine()
    var
        Resource: Record Resource;
        VATPostingSetup: Record "VAT Posting Setup";
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        NewResourceNo: Code[20];
    begin
        // [SCENARIO 574025] Renaming a Resource updates the Job Planning Line with the new Resource No.
        Initialize();

        // [GIVEN] Create Resource
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibraryResource.CreateResource(Resource, VATPostingSetup."VAT Bus. Posting Group");

        // [GIVEN] Create Job and Job Task
        CreateJobAndJobTask(Job, JobTask, false, '');

        // [GIVEN] Create Job Planning Line and Validate No.
        LibraryJob.CreateJobPlanningLine(JobPlanningLine."Line Type"::Budget,
            JobPlanningLine.Type::Resource, JobTask, JobPlanningLine);
        JobPlanningLine.Validate("No.", Resource."No.");
        JobPlanningLine.Modify(true);

        // [WHEN] Rename Resource No.
        RenameResource(Resource."No.", NewResourceNo);

        // [THEN] Find Job Planning Line and validate No.
        FindJobPlanningLine(JobPlanningLine, JobTask, Job, JobPlanningLine.Type::Resource);
        Assert.AreEqual(
            NewResourceNo,
            JobPlanningLine."No.",
            StrSubstNo(
                NoJobPlanningLineErr,
                JobPlanningLine.FieldCaption("No."),
                NewResourceNo,
                JobPlanningLine.TableCaption()));
    end;

    [Test]
    procedure RenameGLAccountUpdateJobPlanningLine()
    var
        GLAccount: Record "G/L Account";
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        NewGLAccountNo: Code[20];
    begin
        // [SCENARIO 574025] Renaming a GLAccount updates the Job Planning Line with the new GLAccount No.
        Initialize();

        // [GIVEN] Create GLAccount
        NewGLAccountNo := LibraryERM.CreateGLAccountWithSalesSetup();
        GLAccount.Get(NewGLAccountNo);

        // [GIVEN] Create Job and Job Task
        CreateJobAndJobTask(Job, JobTask, false, '');

        // [GIVEN] Create Job Planning Line and Validate No.
        LibraryJob.CreateJobPlanningLine(JobPlanningLine."Line Type"::Budget,
            JobPlanningLine.Type::"G/L Account", JobTask, JobPlanningLine);
        JobPlanningLine.Validate("No.", GLAccount."No.");
        JobPlanningLine.Modify(true);

        // [WHEN] Rename GLAccount No.
        RenameGLAccount(GLAccount."No.", NewGLAccountNo);

        // [THEN] Find Job Planning Line and validate No.
        FindJobPlanningLine(JobPlanningLine, JobTask, Job, JobPlanningLine.Type::"G/L Account");
        Assert.AreEqual(
            NewGLAccountNo,
            JobPlanningLine."No.",
            StrSubstNo(
                NoJobPlanningLineErr,
                JobPlanningLine.FieldCaption("No."),
                NewGLAccountNo,
                JobPlanningLine.TableCaption()));
    end;

    [Test]
    procedure RenameStandardTextUpdateJobPlanningLine()
    var
        StandardText: Record "Standard Text";
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        NewStandardTextNo: Code[20];
    begin
        // [SCENARIO 574025] Renaming a StandardText updates the Job Planning Line with the new StandardText No.
        Initialize();

        // [GIVEN] Create ResStandardTextource
        LibrarySales.CreateStandardText(StandardText);

        // [GIVEN] Create Job and Job Task
        CreateJobAndJobTask(Job, JobTask, false, '');

        // [GIVEN] Create Job Planning Line and Validate No.
        LibraryJob.CreateJobPlanningLine(JobPlanningLine."Line Type"::Budget,
            JobPlanningLine.Type::Text, JobTask, JobPlanningLine);
        JobPlanningLine.Validate("No.", StandardText.Code);
        JobPlanningLine.Modify(true);

        // [WHEN] Rename Resource No.
        RenameStandardText(StandardText.Code, NewStandardTextNo);

        // [THEN] Find Job Planning Line and validate No.
        FindJobPlanningLine(JobPlanningLine, JobTask, Job, JobPlanningLine.Type::Text);
        Assert.AreEqual(
            NewStandardTextNo,
            JobPlanningLine."No.",
            StrSubstNo(
                NoJobPlanningLineErr,
                JobPlanningLine.FieldCaption("No."),
                NewStandardTextNo,
                JobPlanningLine.TableCaption()));
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"UT T Job Planning Line");
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"UT T Job Planning Line");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();

        IsInitialized := true;

        LibrarySetupStorage.Save(DATABASE::"Inventory Setup");
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"UT T Job Planning Line");
    end;

    local procedure SetupLineDiscScenario(var JobPlanningLine: Record "Job Planning Line"; var SalesLineDiscount: Record "Sales Line Discount"; JobTask: Record "Job Task"; CustNo: Code[20]; CustomerPriceGroupCode: Code[10])
    var
        Item: Record Item;
        SalesPrice: Record "Sales Price";
        PriceListLine: Record "Price List Line";
    begin
        LibraryInventory.CreateItem(Item);
        CreateLineDiscForCustomer(SalesLineDiscount, Item, CustNo);
        LibrarySales.CreateSalesPrice(
          SalesPrice, Item."No.", SalesPrice."Sales Type"::"Customer Price Group", CustomerPriceGroupCode,
          WorkDate(), '', '', Item."Base Unit of Measure", 0, LibraryRandom.RandDec(100, 2));
        CopyFromToPriceListLine.CopyFrom(SalesLineDiscount, PriceListLine);
        CopyFromToPriceListLine.CopyFrom(SalesPrice, PriceListLine);

        CreateSimpleJobPlanningLine(JobPlanningLine, JobTask);
        JobPlanningLine.Validate(Type, JobPlanningLine.Type::Item);
    end;

    local procedure CreateJobPlanningLine(var JobPlanningLine: Record "Job Planning Line"; ApplyUsageLink: Boolean)
    var
        Job: Record Job;
        JobTask: Record "Job Task";
    begin
        LibraryJob.CreateJob(Job);
        Job.Validate("Apply Usage Link", ApplyUsageLink);
        Job.Modify();

        LibraryJob.CreateJobTask(Job, JobTask);

        LibraryJob.CreateJobPlanningLine(JobPlanningLine."Line Type"::Budget, JobPlanningLine.Type::Item, JobTask, JobPlanningLine);
        JobPlanningLine.Validate("Unit Price", JobPlanningLine."Unit Cost" * (1 + LibraryRandom.RandInt(100) / 100));
        JobPlanningLine.Modify();
    end;

    local procedure CreateJobPlanningLineWithAttachedLines(var JobPlanningLine: Record "Job Planning Line")
    begin
        CreateJobPlanningLine(JobPlanningLine, true);
        CreateAttachedJobPlanningLine(JobPlanningLine);
    end;

    local procedure CreateAttachedJobPlanningLine(AttachedToJobPlanningLine: Record "Job Planning Line")
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        JobPlanningLine.Init();
        JobPlanningLine.Validate("Job No.", AttachedToJobPlanningLine."Job No.");
        JobPlanningLine.Validate("Job Task No.", AttachedToJobPlanningLine."Job Task No.");
        JobPlanningLine.Validate("Line No.", LibraryJob.GetNextLineNo(JobPlanningLine));
        JobPlanningLine.Validate(Type, JobPlanningLine.Type::Text);
        JobPlanningLine."Attached to Line No." := AttachedToJobPlanningLine."Line No.";
        JobPlanningLine.Insert(true);
    end;

    local procedure CreateTwoJobsWithJobPlanningLines(var JobNo: Code[20]; var SecondJobNo: Code[20])
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
    begin
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
        LibraryJob.CreateJobPlanningLine(
          JobPlanningLine."Line Type"::"Both Budget and Billable", JobPlanningLine.Type::Resource, JobTask, JobPlanningLine);
        JobNo := Job."No.";
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
        SecondJobNo := Job."No.";
    end;

    local procedure HelperCalcLineAmount(JobPlanningLine: Record "Job Planning Line"; Qty: Decimal): Decimal
    var
        TotalPrice: Decimal;
    begin
        TotalPrice := Round(Qty * JobPlanningLine."Unit Price", 0.01);
        exit(TotalPrice - Round(TotalPrice * JobPlanningLine."Line Discount %" / 100, 0.01));
    end;

    local procedure HelperCalcLineAmountLCY(JobPlanningLine: Record "Job Planning Line"; Qty: Decimal): Decimal
    var
        TotalPrice: Decimal;
    begin
        TotalPrice := Round(Qty * JobPlanningLine."Unit Price (LCY)", 0.01);
        exit(TotalPrice - Round(TotalPrice * JobPlanningLine."Line Discount %" / 100, 0.01));
    end;

    local procedure CreateJobAndJobTask(var Job: Record Job; var JobTask: Record "Job Task"; ApplyUsageLink: Boolean; CurrencyCode: Code[10])
    begin
        LibraryJob.CreateJob(Job);
        Job.Validate("Apply Usage Link", ApplyUsageLink);
        Job.Validate("Currency Code", CurrencyCode);
        Job.Modify(true);
        LibraryJob.CreateJobTask(Job, JobTask);
    end;

    local procedure CreateJobPlanningLineInvoice(var JobPlanningLineInvoice: Record "Job Planning Line Invoice"; var JobPlanningLine: Record "Job Planning Line"; Qty: Decimal)
    begin
        JobPlanningLineInvoice.Init();
        JobPlanningLineInvoice."Job No." := JobPlanningLine."Job No.";
        JobPlanningLineInvoice."Job Task No." := JobPlanningLine."Job Task No.";
        JobPlanningLineInvoice."Job Planning Line No." := JobPlanningLine."Line No.";
        JobPlanningLineInvoice."Document Type" := JobPlanningLineInvoice."Document Type"::"Posted Invoice";
        JobPlanningLineInvoice."Document No." := 'TEST';
        JobPlanningLineInvoice."Line No." := 10000;
        JobPlanningLineInvoice."Quantity Transferred" := Qty;
        JobPlanningLineInvoice."Transferred Date" := WorkDate();
        JobPlanningLineInvoice.Insert();
    end;

    local procedure CreateJobPlanningLineWithLocation(var JobPlanningLine: Record "Job Planning Line"; LocationCode: Code[10])
    var
        Job: Record Job;
        JobTask: Record "Job Task";
    begin
        CreateJobAndJobTask(Job, JobTask, false, '');
        LibraryJob.CreateJobPlanningLine(JobPlanningLine."Line Type"::Budget, JobPlanningLine.Type::Item, JobTask, JobPlanningLine);
        JobPlanningLine.Validate("Location Code", LocationCode);
        JobPlanningLine.Validate("Remaining Qty.", LibraryRandom.RandIntInRange(1, 10));
        JobPlanningLine.Modify();
    end;

    local procedure CreateCurrency(): Code[10]
    begin
        exit(LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(100, 2), LibraryRandom.RandDec(100, 2)));
    end;

    local procedure CreateSimpleJobPlanningLine(var JobPlanningLine: Record "Job Planning Line"; JobTask: Record "Job Task")
    begin
        JobPlanningLine.Init();
        JobPlanningLine.Validate("Job No.", JobTask."Job No.");
        JobPlanningLine.Validate("Job Task No.", JobTask."Job Task No.");
        JobPlanningLine.Validate("Line No.", LibraryJob.GetNextLineNo(JobPlanningLine));
        JobPlanningLine.Insert(true);
    end;

    local procedure CreateJobPlanningLinesWithMultipleTypesAndLineTypes(var Job: Record Job; var ArrAmount: array[9] of Decimal)
    var
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
    begin
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
        LibraryJob.CreateJobPlanningLine(
          JobPlanningLine."Line Type"::"Both Budget and Billable", JobPlanningLine.Type::Resource, JobTask, JobPlanningLine);
        ArrAmount[1] := JobPlanningLine."Line Amount";
        LibraryJob.CreateJobPlanningLine(
          JobPlanningLine."Line Type"::"Both Budget and Billable", JobPlanningLine.Type::Item, JobTask, JobPlanningLine);
        ArrAmount[2] := JobPlanningLine."Line Amount";
        LibraryJob.CreateJobPlanningLine(
          JobPlanningLine."Line Type"::"Both Budget and Billable", JobPlanningLine.Type::"G/L Account", JobTask, JobPlanningLine);
        ArrAmount[3] := JobPlanningLine."Line Amount";
        LibraryJob.CreateJobPlanningLine(
          JobPlanningLine."Line Type"::Budget, JobPlanningLine.Type::Resource, JobTask, JobPlanningLine);
        ArrAmount[4] := JobPlanningLine."Line Amount";
        LibraryJob.CreateJobPlanningLine(
          JobPlanningLine."Line Type"::Budget, JobPlanningLine.Type::Item, JobTask, JobPlanningLine);
        ArrAmount[5] := JobPlanningLine."Line Amount";
        LibraryJob.CreateJobPlanningLine(
          JobPlanningLine."Line Type"::Budget, JobPlanningLine.Type::"G/L Account", JobTask, JobPlanningLine);
        ArrAmount[6] := JobPlanningLine."Line Amount";
        LibraryJob.CreateJobPlanningLine(
          JobPlanningLine."Line Type"::Billable, JobPlanningLine.Type::Resource, JobTask, JobPlanningLine);
        ArrAmount[7] := JobPlanningLine."Line Amount";
        LibraryJob.CreateJobPlanningLine(
          JobPlanningLine."Line Type"::Billable, JobPlanningLine.Type::Item, JobTask, JobPlanningLine);
        ArrAmount[8] := JobPlanningLine."Line Amount";
        LibraryJob.CreateJobPlanningLine(
          JobPlanningLine."Line Type"::Billable, JobPlanningLine.Type::"G/L Account", JobTask, JobPlanningLine);
        ArrAmount[9] := JobPlanningLine."Line Amount";
    end;

    local procedure CreateJobGLAccPrice(var JobGLAccountPrice: Record "Job G/L Account Price"; JobNo: Code[20]; JobTaskNo: Code[20]; GLAccountNo: Code[20])
    begin
        LibraryJob.CreateJobGLAccountPrice(
            JobGLAccountPrice, JobNo, JobTaskNo, GLAccountNo, '');
        JobGLAccountPrice."Unit Price" := LibraryRandom.RandIntInRange(1, 10);
        JobGLAccountPrice."Line Discount %" := LibraryRandom.RandIntInRange(1, 10);
        JobGLAccountPrice."Unit Cost" := LibraryRandom.RandIntInRange(1, 10);
        JobGLAccountPrice.Modify();
    end;

    local procedure CreateJobLedgerEntriesWithMultipleTypesAndLineTypes(var Job: Record Job; var ArrAmount: array[12] of Decimal)
    var
        JobTask: Record "Job Task";
        JobLedgerEntry: Record "Job Ledger Entry";
        I: Integer;
    begin
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
        for I := 1 to 12 do
            ArrAmount[I] := LibraryRandom.RandDec(1000, 2);
        MockJobLedgEntry(Job."No.", ArrAmount[1], ArrAmount[2], JobLedgerEntry.Type::Resource, JobLedgerEntry."Entry Type"::Usage);
        MockJobLedgEntry(Job."No.", ArrAmount[3], ArrAmount[4], JobLedgerEntry.Type::Item, JobLedgerEntry."Entry Type"::Usage);
        MockJobLedgEntry(Job."No.", ArrAmount[5], ArrAmount[6], JobLedgerEntry.Type::"G/L Account", JobLedgerEntry."Entry Type"::Usage);
        MockJobLedgEntry(Job."No.", ArrAmount[7], -ArrAmount[8], JobLedgerEntry.Type::Resource, JobLedgerEntry."Entry Type"::Sale);
        MockJobLedgEntry(Job."No.", ArrAmount[9], -ArrAmount[10], JobLedgerEntry.Type::Item, JobLedgerEntry."Entry Type"::Sale);
        MockJobLedgEntry(Job."No.", ArrAmount[11], -ArrAmount[12], JobLedgerEntry.Type::"G/L Account", JobLedgerEntry."Entry Type"::Sale);
    end;

    local procedure CreateLineDiscForCustomer(var SalesLineDiscount: Record "Sales Line Discount"; Item: Record Item; CustNo: Code[20])
    begin
        LibraryERM.CreateLineDiscForCustomer(
          SalesLineDiscount, SalesLineDiscount.Type::Item, Item."No.", SalesLineDiscount."Sales Type"::Customer,
          CustNo, WorkDate(), '', '', Item."Base Unit of Measure", 0);
        SalesLineDiscount.Validate("Line Discount %", LibraryRandom.RandDec(10, 2));
        SalesLineDiscount.Modify(true);
    end;

    local procedure CreateJobPlanningLineWithType(var JobPlanningLine: Record "Job Planning Line"; ConsumableType: Enum "Job Planning Line Type")
    var
        Job: Record Job;
        JobTask: Record "Job Task";
    begin
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
        LibraryJob.CreateJobPlanningLine(JobPlanningLine."Line Type"::Budget, ConsumableType, JobTask, JobPlanningLine);
    end;

    local procedure MockJobLedgEntry(JobNo: Code[20]; JLCost: Decimal; JLAmount: Decimal; ConsumableType: Enum "Job Planning Line Type"; JLEntryType: Enum "Job Journal Line Entry Type")
    var
        JobLedgEntry: Record "Job Ledger Entry";
    begin
        JobLedgEntry.Init();
        JobLedgEntry."Entry No." :=
          LibraryUtility.GetNewRecNo(JobLedgEntry, JobLedgEntry.FieldNo("Entry No."));
        JobLedgEntry."Job No." := JobNo;
        JobLedgEntry."Total Cost" := JLCost;
        JobLedgEntry."Total Cost (LCY)" := JLCost;
        JobLedgEntry."Line Amount" := JLAmount;
        JobLedgEntry."Line Amount (LCY)" := JLAmount;
        JobLedgEntry.Type := ConsumableType;
        JobLedgEntry."Entry Type" := JLEntryType;
        JobLedgEntry.Insert();
    end;

    local procedure SetAllowLineDiscOfCustPostGroup(var Job: Record Job; AllowLineDisc: Boolean): Code[10]
    var
        CustomerPriceGroup: Record "Customer Price Group";
    begin
        LibrarySales.CreateCustomerPriceGroup(CustomerPriceGroup);
        CustomerPriceGroup.Validate("Allow Line Disc.", AllowLineDisc);
        CustomerPriceGroup.Modify(true);
        Job.Validate("Customer Price Group", CustomerPriceGroup.Code);
        Job.Modify(true);
        exit(CustomerPriceGroup.Code);
    end;

    local procedure OpenOrderPromissingPage(var JobPlanningLine: Record "Job Planning Line")
    var
        JobPlanningLines: TestPage "Job Planning Lines";
    begin
        JobPlanningLines.OpenEdit();
        JobPlanningLines.GotoRecord(JobPlanningLine);
        LibraryVariableStorage.Enqueue(JobPlanningLine."Job No.");
        JobPlanningLines.OrderPromising.Invoke();
    end;

    local procedure VerifyJobDetailsBillablePriceFactbox(JobCostFactbox: TestPage "Job Cost Factbox"; BillableArrAmount: array[9] of Decimal)
    begin
        Assert.AreEqual(JobCostFactbox.BillablePriceLCY.AsDecimal(), BillableArrAmount[1] + BillableArrAmount[7], FBResourceErr);
        Assert.AreEqual(JobCostFactbox.BillablePriceLCYItem.AsDecimal(), BillableArrAmount[2] + BillableArrAmount[8], FBItemErr);
        Assert.AreEqual(JobCostFactbox.BillablePriceLCYGLAcc.AsDecimal(), BillableArrAmount[3] + BillableArrAmount[9], FBGLAccErr);
        Assert.AreEqual(
          JobCostFactbox.BillablePriceLCYTotal.AsDecimal(),
          BillableArrAmount[1] + BillableArrAmount[2] + BillableArrAmount[3] +
          BillableArrAmount[7] + BillableArrAmount[8] + BillableArrAmount[9], FBTotalErr);
    end;

    local procedure VerifyJobDetailsInvoicedPriceFactbox(JobCostFactbox: TestPage "Job Cost Factbox"; InvoiceArrAmount: array[12] of Decimal)
    begin
        Assert.AreEqual(JobCostFactbox.InvoicedPriceLCY.AsDecimal(), InvoiceArrAmount[8], FBResourceErr);
        Assert.AreEqual(JobCostFactbox.InvoicedPriceLCYItem.AsDecimal(), InvoiceArrAmount[10], FBItemErr);
        Assert.AreEqual(JobCostFactbox.InvoicedPriceLCYGLAcc.AsDecimal(), InvoiceArrAmount[12], FBGLAccErr);
        Assert.AreEqual(
          JobCostFactbox.InvoicedPriceLCYTotal.AsDecimal(),
          InvoiceArrAmount[8] + InvoiceArrAmount[10] + InvoiceArrAmount[12], FBTotalErr);
    end;

    local procedure CreateItemTranslation(var ItemTranslation: Record "Item Translation"; ItemNo: Code[20]; LanguageCode: Code[10]; VariantCode: Code[10])
    begin
        ItemTranslation.Init();
        ItemTranslation.Validate("Item No.", ItemNo);
        ItemTranslation.Validate("Language Code", LanguageCode);
        ItemTranslation.Validate("Variant Code", VariantCode);
        ItemTranslation.Validate(Description, LibraryUtility.GenerateGUID());
        ItemTranslation.Validate("Description 2", LibraryUtility.GenerateGUID());
        ItemTranslation.Insert(true);
    end;

    local procedure FindJobPlanningLine(var JobPlanningLine: Record "Job Planning Line"; JobTask: Record "Job Task"; Job: Record Job; Type: Enum "Job Planning Line Type")
    begin
        JobPlanningLine.SetRange("Job No.", Job."No.");
        JobPlanningLine.SetRange("Job Task No.", JobTask."Job Task No.");
        JobPlanningLine.SetRange(Type, Type);
        JobPlanningLine.FindFirst();
    end;

    local procedure CreateItemWithAutomaticExtText(var Item: Record Item)
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Automatic Ext. Texts", true);
        Item.Modify(true);
    end;

    local procedure UpdateAllLanguagesCodeOnExtendedTextHeader(var ExtendedTextHeader: Record "Extended Text Header"; ItemNo: Code[20])
    begin
        LibraryInventory.CreateExtendedTextHeaderItem(ExtendedTextHeader, ItemNo);
        ExtendedTextHeader.Validate("All Language Codes", true);
        ExtendedTextHeader.Modify(true);
    end;

    local procedure RenameItem(ItemCode: Code[20]; var NewKey: Code[20])
    var
        Item: Record Item;
    begin
        Item.Get(ItemCode);
        NewKey := CopyStr(LibraryRandom.RandText(20), 1, 20);
        Item.Rename(NewKey);
    end;

    local procedure RenameResource(ResourceCode: Code[20]; var NewKey: Code[20])
    var
        Resource: Record Resource;
    begin
        Resource.Get(ResourceCode);
        NewKey := CopyStr(LibraryRandom.RandText(20), 1, 20);
        Resource.Rename(NewKey);
    end;

    local procedure RenameGLAccount(GLAccountCode: Code[20]; var NewKey: Code[20])
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount.Get(GLAccountCode);
        NewKey := CopyStr(LibraryRandom.RandText(20), 1, 20);
        GLAccount.Rename(NewKey);
    end;

    local procedure RenameStandardText(StandardTextCode: Code[20]; var NewKey: Code[20])
    var
        StandardText: Record "Standard Text";
    begin
        StandardText.Get(StandardTextCode);
        NewKey := CopyStr(LibraryRandom.RandText(20), 1, 20);
        StandardText.Rename(NewKey);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure OrderPromisingModalPagehandler(var OrderPromisingLines: TestPage "Order Promising Lines")
    begin
        Assert.AreEqual(LibraryVariableStorage.DequeueText(), OrderPromisingLines.FILTER.GetFilter("Source ID"), '');
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure JobPlanningLinesPageHandler(var JobPlanningLines: TestPage "Job Planning Lines")
    var
        SumLineAmount: Decimal;
    begin
        SumLineAmount := 0;
        JobPlanningLines.First();
        repeat
            SumLineAmount += JobPlanningLines."Line Amount".AsDecimal();
        until not JobPlanningLines.Next();

        Assert.AreEqual(LibraryVariableStorage.DequeueDecimal(), SumLineAmount, FBPlanningDrillDownErr);
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure JobLedgerEntriesPageHandler(var JobLedgerEntries: TestPage "Job Ledger Entries")
    var
        SumLineAmount: Decimal;
    begin
        SumLineAmount := 0;
        JobLedgerEntries.First();
        repeat
            SumLineAmount -= JobLedgerEntries."Line Amount".AsDecimal();
        until not JobLedgerEntries.Next();

        Assert.AreEqual(LibraryVariableStorage.DequeueDecimal(), SumLineAmount, FBLedgerDrillDownErr);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        // For handle message
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CreateInvoiceRequestHandler(var JobTransfertoSalesInvoice: TestRequestPage "Job Transfer to Sales Invoice")
    begin
        JobTransfertoSalesInvoice.CreateNewInvoice.SetValue(false);
        JobTransfertoSalesInvoice.AppendToSalesInvoiceNo.SetValue(LibraryVariableStorage.DequeueText());
        JobTransfertoSalesInvoice.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure ItemListLookForItem(var ItemList: TestPage "Item List")
    begin
        ItemList.Filter.SetFilter("No.", LibraryVariableStorage.DequeueText());
        ItemList.OK().Invoke();
    end;
}
