namespace System.Test.Tooling;

using System.Threading;
using System.Tooling;

codeunit 149132 "BCPT Schedule Job Queue" implements "BCPT Test Param. Provider"
{
    SingleInstance = true;

    var
        GlobalBCPTTestContext: Codeunit "BCPT Test Context";
        CodeUnitNo: Integer;
        CodeUnitNoLbl: Label 'CodeUnit_No';
        CategoryCode: code[10];
        CategoryLbl: label 'Category';

    trigger OnRun()
    var
        JobQueueEntry: Record "Job Queue Entry";
        i: Integer;
    begin
        ValidateParameters(CopyStr(GlobalBCPTTestContext.GetParameters(), 1, 1000));
   
        JobQueueEntry.Init();
        JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Codeunit;
        JobQueueEntry."Object ID to Run" := CodeUnitNo;
        JobQueueEntry."Job Queue Category Code" := CategoryCode;
        for i := 1 to 5 do begin
            Clear(JobQueueEntry.ID);
            JobQueueEntry."Entry No." := 0;
            Codeunit.Run(Codeunit::"Job Queue - Enqueue", JobQueueEntry);
            JobQueueEntry.Description := Format(JobQueueEntry."Entry No.") + ' - ' + Format(i);
            JobQueueEntry.Modify();
        end;
    end;

    procedure GetDefaultParameters(): Text[1000]
    begin
        exit(copystr(
            CodeunitNoLbl + '=' + Format(Codeunit::"BCPT Sleep 1s") + ', ' +
            CategoryLbl + '=' + 'DOCPOST'
            , 1, 1000));
    end;

    procedure ValidateParameters(Parameters: Text[1000])
    var
        JobQueueCategory: Record "Job Queue Category";
        dict: Dictionary of [Text, Text];
        parm: Text;
        UnkownParameterErr: label 'Unknown parameter: %1', Comment = '%1 is any unknown user input.';
    begin
        if Parameters = '' then
            exit;
        ParameterStringToDictionary(Parameters, dict);
        foreach parm in dict.Keys do
            if not (UpperCase(parm) in [UpperCase(CodeunitNoLbl), UpperCase(CategoryLbl)]) then
                error(UnkownParameterErr, parm);

        if dict.ContainsKey(CodeunitNoLbl) then begin
            parm := dict.Get(CodeunitNoLbl);
            Evaluate(CodeUnitNo, parm);
        end;

        if dict.ContainsKey(CategoryLbl) then begin
            CategoryCode := CopyStr(dict.Get(CategoryLbl), 1, 10);
            JobQueueCategory.Get(CategoryCode);
        end;
    end;

    local procedure ParameterStringToDictionary(Params: Text; var dict: Dictionary of [Text, Text])
    var
        i: Integer;
        p: Integer;
        KeyVal: Text;
        NoOfParams: Integer;
    begin
        clear(dict);
        if Params = '' then
            exit;

        NoOfParams := StrLen(Params) - strlen(DelChr(Params, '=', ',')) + 1;

        for i := 1 to NoOfParams do begin
            if NoOfParams = 1 then
                KeyVal := Params
            else
                KeyVal := SelectStr(i, Params);
            p := StrPos(KeyVal, '=');
            if p > 0 then
                dict.Add(DelChr(CopyStr(KeyVal, 1, p - 1), '<>', ' '), DelChr(CopyStr(KeyVal, p + 1), '<>', ' '))
            else
                dict.Add(DelChr(KeyVal, '<>', ' '), '');
        end;
    end;
}