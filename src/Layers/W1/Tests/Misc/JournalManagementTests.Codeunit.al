codeunit 134931 "Journal Management Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [UT] [Journal Management]
    end;

    var
        LibraryUtility: Codeunit "Library - Utility";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryJob: Codeunit "Library - Job";
        LibraryResource: Codeunit "Library - Resource";
        LibraryCostAccounting: Codeunit "Library - Cost Accounting";
        LibraryFixedAsset: Codeunit "Library - Fixed Asset";
        LibraryPlanning: Codeunit "Library - Planning";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        Assert: Codeunit Assert;
        TemplateFilterErr: Label 'Wrong filter for Field: %1, in %2 with FILTERGROUP: %3.';

    [Test]
    [Scope('OnPrem')]
    procedure OpenJnlBatch_GenJnlManagement_PresetGroup2()
    var
        GenJournalTemplate: array[2] of Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJnlManagement: Codeunit GenJnlManagement;
        ExpectedTemplateName: array[2] of Code[10];
    begin
        // [FEATURE] [General Journal]
        // [SCENARIO 313743] Stan can call GenJnlManagement.OpenJnlBatch despite predefined filters in filtergroup(2)
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate[1]);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate[1].Name);
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate[2]);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate[2].Name);
        Clear(GenJournalBatch);

        GenJournalBatch.FilterGroup(2);
        GenJournalBatch.SetRange("Journal Template Name", GenJournalTemplate[1].Name);
        GenJournalBatch.FilterGroup(0);

        ExpectedTemplateName[1] := '';
        ExpectedTemplateName[2] := GenJournalTemplate[1].Name;

        GenJnlManagement.OpenJnlBatch(GenJournalBatch);

        VerifyFiltersInFilterGroups(GenJournalBatch, GenJournalBatch.FieldNo("Journal Template Name"), ExpectedTemplateName, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OpenJnlBatch_ItemJnlManagement_PresetGroup2()
    var
        ItemJournalTemplate: array[2] of Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJnlManagement: Codeunit ItemJnlManagement;
        ExpectedTemplateName: array[2] of Code[10];
    begin
        // [FEATURE] [Item Journal] [Item]
        // [SCENARIO 313743] Stan can call ItemJnlManagement.OpenJnlBatch despite predefined filters in filtergroup(2)
        LibraryInventory.CreateItemJournalTemplate(ItemJournalTemplate[1]);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate[1].Name);
        LibraryInventory.CreateItemJournalTemplate(ItemJournalTemplate[2]);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate[2].Name);

        ItemJournalBatch.FilterGroup(2);
        ItemJournalBatch.SetRange("Journal Template Name", ItemJournalTemplate[1].Name);
        ItemJournalBatch.FilterGroup(0);

        ExpectedTemplateName[1] := '';
        ExpectedTemplateName[2] := ItemJournalTemplate[1].Name;

        ItemJnlManagement.OpenJnlBatch(ItemJournalBatch);

        VerifyFiltersInFilterGroups(ItemJournalBatch, ItemJournalBatch.FieldNo("Journal Template Name"), ExpectedTemplateName, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OpenJnlBatch_JobJnlManagement_PresetGroup2()
    var
        JobJournalTemplate: array[2] of Record "Job Journal Template";
        JobJournalBatch: Record "Job Journal Batch";
        JobJnlManagement: Codeunit JobJnlManagement;
        ExpectedTemplateName: array[2] of Code[10];
    begin
        // [FEATURE] [Job Journal] [Job]
        // [SCENARIO 313743] Stan can call JobJnlManagement.OpenJnlBatch despite predefined filters in filtergroup(2)
        LibraryJob.CreateJobJournalTemplate(JobJournalTemplate[1]);
        LibraryJob.CreateJobJournalBatch(JobJournalTemplate[1].Name, JobJournalBatch);
        LibraryJob.CreateJobJournalTemplate(JobJournalTemplate[2]);
        LibraryJob.CreateJobJournalBatch(JobJournalTemplate[2].Name, JobJournalBatch);

        JobJournalBatch.FilterGroup(2);
        JobJournalBatch.SetRange("Journal Template Name", JobJournalTemplate[1].Name);
        JobJournalBatch.FilterGroup(0);

        ExpectedTemplateName[1] := '';
        ExpectedTemplateName[2] := JobJournalTemplate[1].Name;

        JobJnlManagement.OpenJnlBatch(JobJournalBatch);

        VerifyFiltersInFilterGroups(JobJournalBatch, JobJournalBatch.FieldNo("Journal Template Name"), ExpectedTemplateName, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OpenJnlBatch_ResJnlManagement_PresetGroup2()
    var
        ResJournalTemplate: array[2] of Record "Res. Journal Template";
        ResJournalBatch: Record "Res. Journal Batch";
        ResJnlManagement: Codeunit ResJnlManagement;
        ExpectedTemplateName: array[2] of Code[10];
    begin
        // [FEATURE] [Resource Journal] [Resource]
        // [SCENARIO 313743] Stan can call ResJnlManagement.OpenJnlBatch despite predefined filters in filtergroup(2)
        LibraryResource.CreateResourceJournalTemplate(ResJournalTemplate[1]);
        LibraryResource.CreateResourceJournalBatch(ResJournalBatch, ResJournalTemplate[1].Name);
        LibraryResource.CreateResourceJournalTemplate(ResJournalTemplate[2]);
        LibraryResource.CreateResourceJournalBatch(ResJournalBatch, ResJournalTemplate[2].Name);

        ResJournalBatch.FilterGroup(2);
        ResJournalBatch.SetRange("Journal Template Name", ResJournalTemplate[1].Name);
        ResJournalBatch.FilterGroup(0);

        ExpectedTemplateName[1] := '';
        ExpectedTemplateName[2] := ResJournalTemplate[1].Name;

        ResJnlManagement.OpenJnlBatch(ResJournalBatch);

        VerifyFiltersInFilterGroups(ResJournalBatch, ResJournalBatch.FieldNo("Journal Template Name"), ExpectedTemplateName, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OpenJnlBatch_ReqJnlManagement_PresetGroup2()
    var
        ReqWkshTemplate: array[2] of Record "Req. Wksh. Template";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        ReqJnlManagement: Codeunit ReqJnlManagement;
        ExpectedTemplateName: array[2] of Code[10];
    begin
        // [FEATURE] [Requisition Worksheet] [Planning]
        // [SCENARIO 313743] Stan can call ReqJnlManagement.OpenJnlBatch despite predefined filters in filtergroup(2)
        CreateReqWorksheetTemplate(ReqWkshTemplate[1]);
        LibraryPlanning.CreateRequisitionWkshName(RequisitionWkshName, ReqWkshTemplate[1].Name);
        CreateReqWorksheetTemplate(ReqWkshTemplate[2]);
        LibraryPlanning.CreateRequisitionWkshName(RequisitionWkshName, ReqWkshTemplate[2].Name);

        RequisitionWkshName.FilterGroup(2);
        RequisitionWkshName.SetRange("Worksheet Template Name", ReqWkshTemplate[1].Name);
        RequisitionWkshName.FilterGroup(0);

        ExpectedTemplateName[1] := '';
        ExpectedTemplateName[2] := ReqWkshTemplate[1].Name;

        ReqJnlManagement.OpenJnlBatch(RequisitionWkshName);

        VerifyFiltersInFilterGroups(RequisitionWkshName, RequisitionWkshName.FieldNo("Worksheet Template Name"), ExpectedTemplateName, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OpenJnlBatch_CostJnlManagement_PresetGroup2()
    var
        CostJournalTemplate: array[2] of Record "Cost Journal Template";
        CostJournalBatch: Record "Cost Journal Batch";
        CostJnlManagement: Codeunit CostJnlManagement;
        ExpectedTemplateName: array[2] of Code[10];
    begin
        // [FEATURE] [Cost Journal] [Cost Accounting]
        // [SCENARIO 313743] Stan can call CostJnlManagement.OpenJnlBatch despite predefined filters in filtergroup(2)
        LibraryCostAccounting.CreateCostJournalTemplate(CostJournalTemplate[1]);
        LibraryCostAccounting.CreateCostJournalBatch(CostJournalBatch, CostJournalTemplate[1].Name);
        LibraryCostAccounting.CreateCostJournalTemplate(CostJournalTemplate[2]);
        LibraryCostAccounting.CreateCostJournalBatch(CostJournalBatch, CostJournalTemplate[2].Name);

        CostJournalBatch.FilterGroup(2);
        CostJournalBatch.SetRange("Journal Template Name", CostJournalTemplate[1].Name);
        CostJournalBatch.FilterGroup(0);

        ExpectedTemplateName[1] := '';
        ExpectedTemplateName[2] := CostJournalTemplate[1].Name;

        CostJnlManagement.OpenJnlBatch(CostJournalBatch);

        VerifyFiltersInFilterGroups(CostJournalBatch, CostJournalBatch.FieldNo("Journal Template Name"), ExpectedTemplateName, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OpenJnlBatch_FAJnlManagement_PresetGroup2()
    var
        FAJournalTemplate: array[2] of Record "FA Journal Template";
        FAJournalBatch: Record "FA Journal Batch";
        FAJnlManagement: Codeunit FAJnlManagement;
        ExpectedTemplateName: array[2] of Code[10];
    begin
        // [FEATURE] [FA Journal] [Fixed Asset]
        // [SCENARIO 313743] Stan can call FAJnlManagement.OpenJnlBatch despite predefined filters in filtergroup(2)
        LibraryFixedAsset.CreateJournalTemplate(FAJournalTemplate[1]);
        LibraryFixedAsset.CreateFAJournalBatch(FAJournalBatch, FAJournalTemplate[1].Name);
        LibraryFixedAsset.CreateJournalTemplate(FAJournalTemplate[2]);
        LibraryFixedAsset.CreateFAJournalBatch(FAJournalBatch, FAJournalTemplate[2].Name);

        FAJournalBatch.FilterGroup(2);
        FAJournalBatch.SetRange("Journal Template Name", FAJournalTemplate[1].Name);
        FAJournalBatch.FilterGroup(0);

        ExpectedTemplateName[1] := '';
        ExpectedTemplateName[2] := FAJournalTemplate[1].Name;

        FAJnlManagement.OpenJnlBatch(FAJournalBatch);

        VerifyFiltersInFilterGroups(FAJournalBatch, FAJournalBatch.FieldNo("Journal Template Name"), ExpectedTemplateName, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OpenJnlBatch_FAReclassJnlManagement_PresetGroup2()
    var
        FAReclassJournalTemplate: array[2] of Record "FA Reclass. Journal Template";
        FAReclassJournalBatch: Record "FA Reclass. Journal Batch";
        FAReclassJnlManagement: Codeunit FAReclassJnlManagement;
        ExpectedTemplateName: array[2] of Code[10];
    begin
        // [FEATURE] [FA Reclassification Journal] [Fixed Asset]
        // [SCENARIO 313743] Stan can call FAReclassJnlManagement.OpenJnlBatch despite predefined filters in filtergroup(2)
        LibraryFixedAsset.CreateFAReclassJournalTemplate(FAReclassJournalTemplate[1]);
        LibraryFixedAsset.CreateFAReclassJournalBatch(FAReclassJournalBatch, FAReclassJournalTemplate[1].Name);
        LibraryFixedAsset.CreateFAReclassJournalTemplate(FAReclassJournalTemplate[2]);
        LibraryFixedAsset.CreateFAReclassJournalBatch(FAReclassJournalBatch, FAReclassJournalTemplate[2].Name);

        FAReclassJournalBatch.FilterGroup(2);
        FAReclassJournalBatch.SetRange("Journal Template Name", FAReclassJournalTemplate[1].Name);
        FAReclassJournalBatch.FilterGroup(0);

        ExpectedTemplateName[1] := '';
        ExpectedTemplateName[2] := FAReclassJournalTemplate[1].Name;

        FAReclassJnlManagement.OpenJnlBatch(FAReclassJournalBatch);

        VerifyFiltersInFilterGroups(
          FAReclassJournalBatch, FAReclassJournalBatch.FieldNo("Journal Template Name"), ExpectedTemplateName, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OpenJnlBatch_InsuranceJnlManagement_PresetGroup2()
    var
        InsuranceJournalTemplate: array[2] of Record "Insurance Journal Template";
        InsuranceJournalBatch: Record "Insurance Journal Batch";
        InsuranceJnlManagement: Codeunit InsuranceJnlManagement;
        ExpectedTemplateName: array[2] of Code[10];
    begin
        // [FEATURE] [Insurance Journal] [Insurance]
        // [SCENARIO 313743] Stan can call InsuranceJnlManagement.OpenJnlBatch despite predefined filters in filtergroup(2)
        LibraryFixedAsset.CreateInsuranceJournalTemplate(InsuranceJournalTemplate[1]);
        LibraryFixedAsset.CreateInsuranceJournalBatch(InsuranceJournalBatch, InsuranceJournalTemplate[1].Name);
        LibraryFixedAsset.CreateInsuranceJournalTemplate(InsuranceJournalTemplate[2]);
        LibraryFixedAsset.CreateInsuranceJournalBatch(InsuranceJournalBatch, InsuranceJournalTemplate[2].Name);

        InsuranceJournalBatch.FilterGroup(2);
        InsuranceJournalBatch.SetRange("Journal Template Name", InsuranceJournalTemplate[1].Name);
        InsuranceJournalBatch.FilterGroup(0);

        ExpectedTemplateName[1] := '';
        ExpectedTemplateName[2] := InsuranceJournalTemplate[1].Name;

        InsuranceJnlManagement.OpenJnlBatch(InsuranceJournalBatch);

        VerifyFiltersInFilterGroups(InsuranceJournalBatch, InsuranceJournalBatch.FieldNo("Journal Template Name"), ExpectedTemplateName, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OpenJnlBatch_GenJnlManagement_PresetGroup0()
    var
        GenJournalTemplate: array[2] of Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJnlManagement: Codeunit GenJnlManagement;
        ExpectedTemplateName: array[2] of Code[10];
    begin
        // [FEATURE] [General Journal]
        // [SCENARIO 313743] Stan can call GenJnlManagement.OpenJnlBatch despite predefined filters in filtergroup(0)
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate[1]);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate[1].Name);
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate[2]);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate[2].Name);
        Clear(GenJournalBatch);

        GenJournalBatch.FilterGroup(0);
        GenJournalBatch.SetRange("Journal Template Name", GenJournalTemplate[1].Name);
        GenJournalBatch.FilterGroup(2);

        ExpectedTemplateName[2] := '';
        ExpectedTemplateName[1] := GenJournalTemplate[1].Name;

        GenJnlManagement.OpenJnlBatch(GenJournalBatch);

        VerifyFiltersInFilterGroups(GenJournalBatch, GenJournalBatch.FieldNo("Journal Template Name"), ExpectedTemplateName, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OpenJnlBatch_ItemJnlManagement_PresetGroup0()
    var
        ItemJournalTemplate: array[2] of Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJnlManagement: Codeunit ItemJnlManagement;
        ExpectedTemplateName: array[2] of Code[10];
    begin
        // [FEATURE] [Item Journal] [Item]
        // [SCENARIO 313743] Stan can call ItemJnlManagement.OpenJnlBatch despite predefined filters in filtergroup(0)
        LibraryInventory.CreateItemJournalTemplate(ItemJournalTemplate[1]);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate[1].Name);
        LibraryInventory.CreateItemJournalTemplate(ItemJournalTemplate[2]);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate[2].Name);

        ItemJournalBatch.FilterGroup(0);
        ItemJournalBatch.SetRange("Journal Template Name", ItemJournalTemplate[1].Name);
        ItemJournalBatch.FilterGroup(2);

        ExpectedTemplateName[2] := '';
        ExpectedTemplateName[1] := ItemJournalTemplate[1].Name;

        ItemJnlManagement.OpenJnlBatch(ItemJournalBatch);

        VerifyFiltersInFilterGroups(ItemJournalBatch, ItemJournalBatch.FieldNo("Journal Template Name"), ExpectedTemplateName, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OpenJnlBatch_JobJnlManagement_PresetGroup0()
    var
        JobJournalTemplate: array[2] of Record "Job Journal Template";
        JobJournalBatch: Record "Job Journal Batch";
        JobJnlManagement: Codeunit JobJnlManagement;
        ExpectedTemplateName: array[2] of Code[10];
    begin
        // [FEATURE] [Job Journal] [Job]
        // [SCENARIO 313743] Stan can call JobJnlManagement.OpenJnlBatch despite predefined filters in filtergroup(0)
        LibraryJob.CreateJobJournalTemplate(JobJournalTemplate[1]);
        LibraryJob.CreateJobJournalBatch(JobJournalTemplate[1].Name, JobJournalBatch);
        LibraryJob.CreateJobJournalTemplate(JobJournalTemplate[2]);
        LibraryJob.CreateJobJournalBatch(JobJournalTemplate[2].Name, JobJournalBatch);

        JobJournalBatch.FilterGroup(0);
        JobJournalBatch.SetRange("Journal Template Name", JobJournalTemplate[1].Name);
        JobJournalBatch.FilterGroup(2);

        ExpectedTemplateName[2] := '';
        ExpectedTemplateName[1] := JobJournalTemplate[1].Name;

        JobJnlManagement.OpenJnlBatch(JobJournalBatch);

        VerifyFiltersInFilterGroups(JobJournalBatch, JobJournalBatch.FieldNo("Journal Template Name"), ExpectedTemplateName, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OpenJnlBatch_ResJnlManagement_PresetGroup0()
    var
        ResJournalTemplate: array[2] of Record "Res. Journal Template";
        ResJournalBatch: Record "Res. Journal Batch";
        ResJnlManagement: Codeunit ResJnlManagement;
        ExpectedTemplateName: array[2] of Code[10];
    begin
        // [FEATURE] [Resource Journal] [Resource]
        // [SCENARIO 313743] Stan can call ResJnlManagement.OpenJnlBatch despite predefined filters in filtergroup(0)
        LibraryResource.CreateResourceJournalTemplate(ResJournalTemplate[1]);
        LibraryResource.CreateResourceJournalBatch(ResJournalBatch, ResJournalTemplate[1].Name);
        LibraryResource.CreateResourceJournalTemplate(ResJournalTemplate[2]);
        LibraryResource.CreateResourceJournalBatch(ResJournalBatch, ResJournalTemplate[2].Name);

        ResJournalBatch.FilterGroup(0);
        ResJournalBatch.SetRange("Journal Template Name", ResJournalTemplate[1].Name);
        ResJournalBatch.FilterGroup(2);

        ExpectedTemplateName[2] := '';
        ExpectedTemplateName[1] := ResJournalTemplate[1].Name;

        ResJnlManagement.OpenJnlBatch(ResJournalBatch);

        VerifyFiltersInFilterGroups(ResJournalBatch, ResJournalBatch.FieldNo("Journal Template Name"), ExpectedTemplateName, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OpenJnlBatch_ReqJnlManagement_PresetGroup0()
    var
        ReqWkshTemplate: array[2] of Record "Req. Wksh. Template";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        ReqJnlManagement: Codeunit ReqJnlManagement;
        ExpectedTemplateName: array[2] of Code[10];
    begin
        // [FEATURE] [Requistion Worksheet] [Planning]
        // [SCENARIO 313743] Stan can call ReqJnlManagement.OpenJnlBatch despite predefined filters in filtergroup(0)
        CreateReqWorksheetTemplate(ReqWkshTemplate[1]);
        LibraryPlanning.CreateRequisitionWkshName(RequisitionWkshName, ReqWkshTemplate[1].Name);
        CreateReqWorksheetTemplate(ReqWkshTemplate[2]);
        LibraryPlanning.CreateRequisitionWkshName(RequisitionWkshName, ReqWkshTemplate[2].Name);

        RequisitionWkshName.FilterGroup(0);
        RequisitionWkshName.SetRange("Worksheet Template Name", ReqWkshTemplate[1].Name);
        RequisitionWkshName.FilterGroup(2);

        ExpectedTemplateName[2] := '';
        ExpectedTemplateName[1] := ReqWkshTemplate[1].Name;

        ReqJnlManagement.OpenJnlBatch(RequisitionWkshName);

        VerifyFiltersInFilterGroups(RequisitionWkshName, RequisitionWkshName.FieldNo("Worksheet Template Name"), ExpectedTemplateName, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OpenJnlBatch_CostJnlManagement_PresetGroup0()
    var
        CostJournalTemplate: array[2] of Record "Cost Journal Template";
        CostJournalBatch: Record "Cost Journal Batch";
        CostJnlManagement: Codeunit CostJnlManagement;
        ExpectedTemplateName: array[2] of Code[10];
    begin
        // [FEATURE] [Cost Journal] [Cost Accounting]
        // [SCENARIO 313743] Stan can call CostJnlManagement.OpenJnlBatch despite predefined filters in filtergroup(0)
        LibraryCostAccounting.CreateCostJournalTemplate(CostJournalTemplate[1]);
        LibraryCostAccounting.CreateCostJournalBatch(CostJournalBatch, CostJournalTemplate[1].Name);
        LibraryCostAccounting.CreateCostJournalTemplate(CostJournalTemplate[2]);
        LibraryCostAccounting.CreateCostJournalBatch(CostJournalBatch, CostJournalTemplate[2].Name);

        CostJournalBatch.FilterGroup(0);
        CostJournalBatch.SetRange("Journal Template Name", CostJournalTemplate[1].Name);
        CostJournalBatch.FilterGroup(2);

        ExpectedTemplateName[2] := '';
        ExpectedTemplateName[1] := CostJournalTemplate[1].Name;

        CostJnlManagement.OpenJnlBatch(CostJournalBatch);

        VerifyFiltersInFilterGroups(CostJournalBatch, CostJournalBatch.FieldNo("Journal Template Name"), ExpectedTemplateName, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OpenJnlBatch_FAJnlManagement_PresetGroup0()
    var
        FAJournalTemplate: array[2] of Record "FA Journal Template";
        FAJournalBatch: Record "FA Journal Batch";
        FAJnlManagement: Codeunit FAJnlManagement;
        ExpectedTemplateName: array[2] of Code[10];
    begin
        // [FEATURE] [FA Journal] [Fixed Asset]
        // [SCENARIO 313743] Stan can call FAJnlManagement.OpenJnlBatch despite predefined filters in filtergroup(0)
        LibraryFixedAsset.CreateJournalTemplate(FAJournalTemplate[1]);
        LibraryFixedAsset.CreateFAJournalBatch(FAJournalBatch, FAJournalTemplate[1].Name);
        LibraryFixedAsset.CreateJournalTemplate(FAJournalTemplate[2]);
        LibraryFixedAsset.CreateFAJournalBatch(FAJournalBatch, FAJournalTemplate[2].Name);

        FAJournalBatch.FilterGroup(0);
        FAJournalBatch.SetRange("Journal Template Name", FAJournalTemplate[1].Name);
        FAJournalBatch.FilterGroup(2);

        ExpectedTemplateName[2] := '';
        ExpectedTemplateName[1] := FAJournalTemplate[1].Name;

        FAJnlManagement.OpenJnlBatch(FAJournalBatch);

        VerifyFiltersInFilterGroups(FAJournalBatch, FAJournalBatch.FieldNo("Journal Template Name"), ExpectedTemplateName, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OpenJnlBatch_FAReclassJnlManagement_PresetGroup0()
    var
        FAReclassJournalTemplate: array[2] of Record "FA Reclass. Journal Template";
        FAReclassJournalBatch: Record "FA Reclass. Journal Batch";
        FAReclassJnlManagement: Codeunit FAReclassJnlManagement;
        ExpectedTemplateName: array[2] of Code[10];
    begin
        // [FEATURE] [FA Reclassifition Journal] [Fixed Asset]
        // [SCENARIO 313743] Stan can call FAReclassJnlManagement.OpenJnlBatch despite predefined filters in filtergroup(0)
        LibraryFixedAsset.CreateFAReclassJournalTemplate(FAReclassJournalTemplate[1]);
        LibraryFixedAsset.CreateFAReclassJournalBatch(FAReclassJournalBatch, FAReclassJournalTemplate[1].Name);
        LibraryFixedAsset.CreateFAReclassJournalTemplate(FAReclassJournalTemplate[2]);
        LibraryFixedAsset.CreateFAReclassJournalBatch(FAReclassJournalBatch, FAReclassJournalTemplate[2].Name);

        FAReclassJournalBatch.FilterGroup(0);
        FAReclassJournalBatch.SetRange("Journal Template Name", FAReclassJournalTemplate[1].Name);
        FAReclassJournalBatch.FilterGroup(2);

        ExpectedTemplateName[2] := '';
        ExpectedTemplateName[1] := FAReclassJournalTemplate[1].Name;

        FAReclassJnlManagement.OpenJnlBatch(FAReclassJournalBatch);

        VerifyFiltersInFilterGroups(
          FAReclassJournalBatch, FAReclassJournalBatch.FieldNo("Journal Template Name"), ExpectedTemplateName, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OpenJnlBatch_InsuranceJnlManagement_PresetGroup0()
    var
        InsuranceJournalTemplate: array[2] of Record "Insurance Journal Template";
        InsuranceJournalBatch: Record "Insurance Journal Batch";
        InsuranceJnlManagement: Codeunit InsuranceJnlManagement;
        ExpectedTemplateName: array[2] of Code[10];
    begin
        // [FEATURE] [Insurance Journal] [Insurance]
        // [SCENARIO 313743] Stan can call InsuranceJnlManagement.OpenJnlBatch despite predefined filters in filtergroup(0)
        LibraryFixedAsset.CreateInsuranceJournalTemplate(InsuranceJournalTemplate[1]);
        LibraryFixedAsset.CreateInsuranceJournalBatch(InsuranceJournalBatch, InsuranceJournalTemplate[1].Name);
        LibraryFixedAsset.CreateInsuranceJournalTemplate(InsuranceJournalTemplate[2]);
        LibraryFixedAsset.CreateInsuranceJournalBatch(InsuranceJournalBatch, InsuranceJournalTemplate[2].Name);

        InsuranceJournalBatch.FilterGroup(0);
        InsuranceJournalBatch.SetRange("Journal Template Name", InsuranceJournalTemplate[1].Name);
        InsuranceJournalBatch.FilterGroup(2);

        ExpectedTemplateName[2] := '';
        ExpectedTemplateName[1] := InsuranceJournalTemplate[1].Name;

        InsuranceJnlManagement.OpenJnlBatch(InsuranceJournalBatch);

        VerifyFiltersInFilterGroups(
          InsuranceJournalBatch, InsuranceJournalBatch.FieldNo("Journal Template Name"), ExpectedTemplateName, 2);
    end;

    [Test]
    [HandlerFunctions('ReqWkshNamesPageHandler,PlanningWorksheetPageHandler')]
    procedure VerifyReqWkshNamesPageOpensCorrectPlanningWorksheetBatches()
    var
        RequisitionWkshName: array[3] of Record "Requisition Wksh. Name";
        ReqWkshTemplate: Record "Req. Wksh. Template";
        ReqWorksheetTemplates: Testpage "Req. Worksheet Templates";
        i: Integer;
    begin
        // [SCENARIO 597476] Verify that the 'Req. Wksh. Names' page opens the correct planning worksheet batches.

        // [GIVEN] Create Requisition Worksheet Template.
        CreateReqWorksheetTemplateWithType(ReqWkshTemplate, ReqWkshTemplate.Type::Planning);

        // [GIVEN] Create Requisition Worksheet Batches.
        for i := 1 to 3 do begin
            LibraryPlanning.CreateRequisitionWkshName(RequisitionWkshName[i], ReqWkshTemplate.Name);
            LibraryVariableStorage.Enqueue(RequisitionWkshName[i].Name);
        end;

        // [GIVEN] Opening the Requisition Worksheet Templates page.
        ReqWorksheetTemplates.OpenEdit();
        ReqWorksheetTemplates.GoToRecord(ReqWkshTemplate);

        // [WHEN] Invoke 'Requisition Worksheet Names' Action.
        ReqWorksheetTemplates."Requisition Worksheet Names".Invoke();
        ReqWorksheetTemplates.OK().Invoke();

        // [THEN] Verify that the 'Req. Wksh. Names' page opens the correct planning worksheet batches when the 'EditWorksheet' action is invoked. 
        // It was verified on the PlanningWorksheetPageHandler.
        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure CreateReqWorksheetTemplate(var ReqWkshTemplate: Record "Req. Wksh. Template")
    begin
        ReqWkshTemplate.Init();
        ReqWkshTemplate.Name := LibraryUtility.GenerateGUID();
        ReqWkshTemplate.Insert();
    end;

    local procedure VerifyFiltersInFilterGroups(RecVar: Variant; TemplateFieldNo: Integer; ExpectedJournalTemplateName: array[2] of Code[10]; ExpectedFilterGroup: Integer)
    var
        RecRef: RecordRef;
        TemplateFieldRef: FieldRef;
    begin
        RecRef.GetTable(RecVar);
        TemplateFieldRef := RecRef.Field(TemplateFieldNo);

        Assert.AreEqual(ExpectedFilterGroup, RecRef.FilterGroup, 'Wrong filter group');

        RecRef.FilterGroup(2);
        Assert.AreEqual(
          ExpectedJournalTemplateName[2],
          TemplateFieldRef.GetFilter,
          StrSubstNo(TemplateFilterErr, TemplateFieldRef.Name, RecRef.Name, RecRef.FilterGroup));

        RecRef.FilterGroup(0);
        Assert.AreEqual(
          ExpectedJournalTemplateName[1],
          TemplateFieldRef.GetFilter,
          StrSubstNo(TemplateFilterErr, TemplateFieldRef.Name, RecRef.Name, RecRef.FilterGroup));
    end;

    local procedure CreateReqWorksheetTemplateWithType(var ReqWkshTemplate: Record "Req. Wksh. Template"; TemplateType: Enum "Req. Worksheet Template Type")
    begin
        CreateReqWorksheetTemplate(ReqWkshTemplate);
        ReqWkshTemplate.Validate(Type, TemplateType);
        ReqWkshTemplate.Validate("Page ID");
        ReqWkshTemplate.Modify(true);
    end;

    [PageHandler]
    procedure ReqWkshNamesPageHandler(var ReqWkshNames: TestPage "Req. Wksh. Names")
    begin
        ReqWkshNames.First();
        ReqWkshNames.Name.AssertEquals(LibraryVariableStorage.DequeueText());
        ReqWkshNames.Next();
        ReqWkshNames.Name.AssertEquals(LibraryVariableStorage.DequeueText());
        ReqWkshNames.Last();
        ReqWkshNames.Name.AssertEquals(LibraryVariableStorage.DequeueText());

        ReqWkshNames.Previous();
        LibraryVariableStorage.Enqueue(ReqWkshNames.Name.Value);
        ReqWkshNames."Edit Worksheet".Invoke();
        Commit();

        ReqWkshNames.OK().Invoke();
    end;

    [PageHandler]
    procedure PlanningWorksheetPageHandler(var PlanningWorksheet: TestPage "Planning Worksheet")
    begin
        PlanningWorksheet.CurrentWkshBatchName.AssertEquals(LibraryVariableStorage.DequeueText());
        PlanningWorksheet.OK().Invoke();
    end;
}

