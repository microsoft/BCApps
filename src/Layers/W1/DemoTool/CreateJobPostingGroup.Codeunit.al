codeunit 101208 "Create Job Posting Group"
{

    trigger OnRun()
    begin
        InsertData(
          XSETTINGUP, XSettingUpFurnitureTxt,
          '992231', '992232', '997180', '997180', '997480', '997280', '997181',
          '996610', '992211', '992212', '996190', '996191', '997620', '996620')
    end;

    var
        JobPostingGroup: Record "Job Posting Group";
        CA: Codeunit "Make Adjustments";
        XSETTINGUP: Label 'SETTING UP';
        XSettingUpFurnitureTxt: Label 'Setting up furniture';

    procedure InsertData("Code": Code[20]; PostingGroupDescription: Text[50]; WIPCostsAccount: Code[20]; WIPAccruedCostsAccount: Code[20]; JobCostsAppliedAccount: Code[20]; ItemCostsAppliedAccount: Code[20]; ResourceCostsAppliedAccount: Code[20]; GLCostsAppliedAccount: Code[20]; JobCostsAdjustmentAccount: Code[20]; GLExpenseAccContract: Code[20]; WIPAccruedSalesAccount: Code[20]; WIPInvoicedSalesAccount: Code[20]; JobSalesAppliedAccount: Code[20]; JobSalesAdjustmentAccount: Code[20]; RecognizedCostsAccount: Code[20]; RecognizedSalesAccount: Code[20])
    begin
        JobPostingGroup.Init();
        JobPostingGroup.Validate(Code, Code);
        JobPostingGroup.Validate(Description, PostingGroupDescription);
        JobPostingGroup.Validate("WIP Costs Account", CA.Convert(WIPCostsAccount));
        JobPostingGroup.Validate("WIP Accrued Costs Account", CA.Convert(WIPAccruedCostsAccount));
        JobPostingGroup.Validate("Job Costs Applied Account", CA.Convert(JobCostsAppliedAccount));
        JobPostingGroup.Validate("Item Costs Applied Account", CA.Convert(ItemCostsAppliedAccount));
        JobPostingGroup.Validate("Resource Costs Applied Account", CA.Convert(ResourceCostsAppliedAccount));
        JobPostingGroup.Validate("G/L Costs Applied Account", CA.Convert(GLCostsAppliedAccount));
        JobPostingGroup.Validate("Job Costs Adjustment Account", CA.Convert(JobCostsAdjustmentAccount));
        JobPostingGroup.Validate("G/L Expense Acc. (Contract)", CA.Convert(GLExpenseAccContract));
        JobPostingGroup.Validate("WIP Accrued Sales Account", CA.Convert(WIPAccruedSalesAccount));
        JobPostingGroup.Validate("WIP Invoiced Sales Account", CA.Convert(WIPInvoicedSalesAccount));
        JobPostingGroup.Validate("Job Sales Applied Account", CA.Convert(JobSalesAppliedAccount));
        JobPostingGroup.Validate("Job Sales Adjustment Account", CA.Convert(JobSalesAdjustmentAccount));
        JobPostingGroup.Validate("Recognized Costs Account", CA.Convert(RecognizedCostsAccount));
        JobPostingGroup.Validate("Recognized Sales Account", CA.Convert(RecognizedSalesAccount));
        JobPostingGroup.Insert();
    end;
}

