namespace System.Test.Tooling;

using System.Threading;
using System.Tooling;

codeunit 149131 "BCPT Sleep X seconds JQ" implements "BCPT Test Param. Provider"
{
    var
        GlobalBCPTTestContext: Codeunit "BCPT Test Context";
        ParamValidationErr: Label 'Parameter is not defined in the correct format. The expected format is "%1"', Comment = '%1 = a string';
        NoOfSecondsLbl: label 'NoOfSeconds';
        NoOfSeconds: Integer;
        CategoryLbl: label 'CategoryCode';
        Category: Code[10];

    trigger OnRun();
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        if Evaluate(NoOfSeconds, GlobalBCPTTestContext.GetParameter(NoOfSecondsLbl)) then;
        if Evaluate(Category, GlobalBCPTTestContext.GetParameter(CategoryLbl)) then;

        JobQueueEntry.Init();
        JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Codeunit;
        JobQueueEntry.Validate("Object ID to Run", Codeunit::"BCPT Sleep X seconds");
        JobQueueEntry."Job Queue Category Code" := Category;
        JobQueueEntry."Parameter String" := format(NoOfSeconds);
        JobQueueEntry."Priority Within Category" := JobQueueEntry."Priority Within Category"::High;
        Codeunit.run(Codeunit::"Job Queue - Enqueue", JobQueueEntry);
    end;

    procedure GetDefaultParameters(): Text[1000]
    begin
        exit(copystr(NoOfSecondsLbl + '=' + Format(10) + ',' + CategoryLbl + '=', 1, 1000));
    end;

    procedure ValidateParameters(Parameters: Text[1000])
    begin
        if not (Evaluate(NoOfSeconds, GlobalBCPTTestContext.GetParameter(NoOfSecondsLbl)) and Evaluate(Category, GlobalBCPTTestContext.GetParameter(CategoryLbl))) then
            Error(ParamValidationErr, GetDefaultParameters());
    end;
}