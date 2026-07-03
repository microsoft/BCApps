codeunit 101713 "Create Analysis Type"
{

    trigger OnRun()
    begin
        AnalyseType.ResetDefaultAnalysisTypes(false);
    end;

    var
        AnalyseType: Record "Analysis Type";
}

