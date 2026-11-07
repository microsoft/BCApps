codeunit 101750 "Create Data Sensitivity"
{

    trigger OnRun()
    var
        DataClassificationEvalData: Codeunit "Data Classification Eval. Data";
    begin
        DataClassificationEvalData.CreateEvaluationData();
    end;
}

