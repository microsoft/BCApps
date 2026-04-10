codeunit 101208 "Create Job Posting Group"
{

    trigger OnRun()
    begin
        InsertData(XJOB0,
          '46-1000', '46-1000', '90-2230', '90-1230', '', '', '', '', '', '90-2230', '90-1230');
        InsertData(XJOB20,
          '46-1000', '46-1000', '90-2210', '90-1210', '', '', '', '', '', '90-2210', '90-1210');
    end;

    var
        JobPostingGroup: Record "Job Posting Group";
        CA: Codeunit "Make Adjustments";
        XJOB0: Label 'JOB0';
        XJOB20: Label 'JOB20', Comment = 'JOB20';

    procedure InsertData("Code": Code[10]; "WIP Costs Account": Code[20]; "WIP Accrued Costs Account": Code[20]; "Job Costs Applied Account": Code[20]; "Job Costs Adjustment Account": Code[20]; "G/L Expense Acc. (Contract)": Code[20]; "WIP Accrued Sales Account": Code[20]; "WIP Invoiced Sales Account": Code[20]; "Job Sales Applied Account": Code[20]; "Job Sales Adjustment Account": Code[20]; "Recognized Costs Account": Code[20]; "Recognized Sales Account": Code[20])
    begin
        JobPostingGroup.Init();
        JobPostingGroup.Validate(Code, Code);
        JobPostingGroup.Validate("WIP Costs Account", CA.Convert("WIP Costs Account"));
        JobPostingGroup.Validate("WIP Accrued Costs Account", CA.Convert("WIP Accrued Costs Account"));
        JobPostingGroup.Validate("Job Costs Applied Account", CA.Convert("Job Costs Applied Account"));
        JobPostingGroup.Validate("Job Costs Adjustment Account", CA.Convert("Job Costs Adjustment Account"));
        JobPostingGroup.Validate("G/L Expense Acc. (Contract)", CA.Convert("G/L Expense Acc. (Contract)"));
        JobPostingGroup.Validate("WIP Accrued Sales Account", CA.Convert("WIP Accrued Sales Account"));
        JobPostingGroup.Validate("WIP Invoiced Sales Account", CA.Convert("WIP Invoiced Sales Account"));
        JobPostingGroup.Validate("Job Sales Applied Account", CA.Convert("Job Sales Applied Account"));
        JobPostingGroup.Validate("Job Sales Adjustment Account", CA.Convert("Job Sales Adjustment Account"));
        JobPostingGroup.Validate("Recognized Costs Account", CA.Convert("Recognized Costs Account"));
        JobPostingGroup.Validate("Recognized Sales Account", CA.Convert("Recognized Sales Account"));
        JobPostingGroup.Insert();
    end;
}

