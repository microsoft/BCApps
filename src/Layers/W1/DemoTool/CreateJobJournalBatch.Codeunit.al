codeunit 101237 "Create Job Journal Batch"
{

    trigger OnRun()
    begin
        InsertData();
    end;

    var
        XJOB: Label 'JOB';
        XDEFAULT: Label 'DEFAULT';
        XJJNLGEN: Label 'JJNL-GEN', Comment = 'Number series for job journal batch.';
        JnlDescription: Label 'Default Journal';

    procedure InsertData()
    var
        "Job Journal Batch": Record "Job Journal Batch";
        DemoDataSetup: Record "Demo Data Setup";
    begin
        DemoDataSetup.Get();
        "Job Journal Batch".Init();
        "Job Journal Batch".Validate("Journal Template Name", XJOB);
        "Job Journal Batch".SetupNewBatch();
        "Job Journal Batch".Validate(Name, XDEFAULT);
        "Job Journal Batch".Validate(Description, JnlDescription);

        if DemoDataSetup."Data Type" = DemoDataSetup."Data Type"::Evaluation then
            "Job Journal Batch".Validate("No. Series", XJJNLGEN);

        "Job Journal Batch".Insert(true);
    end;
}

