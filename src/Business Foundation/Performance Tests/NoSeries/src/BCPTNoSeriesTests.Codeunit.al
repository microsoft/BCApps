namespace Microsoft.Test.Foundation.NoSeries;

using Microsoft.Foundation.NoSeries;
using System.TestLibraries.Utilities;
using System.Tooling;

codeunit 134533 "BCPT - No. Series Tests" implements "BCPT Test Param. Provider"
{
    var
        Any: Codeunit Any;
        BCPTTestContext: Codeunit "BCPT Test Context";
        NoOfIterationsLbl: Label 'Iterations', Locked = true;
        ImplementationLbl: Label 'Implementation', Locked = true;
        UseBatchImplLbl: Label 'Batch', Locked = true;
        SimulationLbl: Label 'Simulation', Locked = true;
        ParamValidationErr: Label 'Parameter is not defined in the correct format. The expected format is "%1"', Comment = '%1 = a string';
        ParamCombinationErr: Label 'The chosen combination of parameters is not valid. RunLegacy or Simulation must be false.';
#if not CLEAN24
        RunLegacyLbl: Label 'RunLegacy', Locked = true;
        ParameterStringLbl: Label '%1=%2,%3=%4,%5=%6,%7=%8,%9=%10', Locked = true;
        RunLegacy: Boolean;
#else
        ParameterStringLbl: Label '%1=%2,%3=%4,%5=%6,%7=%8', Locked = true;
#endif
        NoOfIterations: Integer;
        NoSeriesImplementation: enum "No. Series Implementation";
        UseBatch: Boolean;
        Simulation: Boolean;

    trigger OnRun()
    begin
        TestGetNextNo()
    end;

    #region interface implementation
    procedure GetDefaultParameters() ParameterString: Text[1000];
    begin
        NoOfIterations := 1000;
        NoSeriesImplementation := enum::"No. Series Implementation"::"Normal";
        UseBatch := false;
        Simulation := false;
#if not CLEAN24
        RunLegacy := false;
        exit(CopyStr(StrSubstNo(ParameterStringLbl, NoOfIterationsLbl, NoOfIterations, ImplementationLbl, NoSeriesImplementation, UseBatchImplLbl, UseBatch, SimulationLbl, Simulation, RunLegacyLbl, RunLegacy), 1, MaxStrlen(ParameterString)))
#else
        exit(CopyStr(StrSubstNo(ParameterStringLbl, NoOfIterationsLbl, NoOfIterations, ImplementationLbl, NoSeriesImplementation,UseBatchImplLbl,UseBatch,SimulationLbl, Simulation), 1, MaxStrlen(ParameterString)))
#endif
    end;

    procedure ValidateParameters(Parameters: Text[1000]);
    var
        ParameterList: List of [Text];
        ParameterName: Text;
        ParameterValue: Text;
        i: Integer;
    begin
        if Parameters = '' then
            exit;
        ParameterList := Parameters.Split(',');
        for i := 1 to ParameterList.Count() do begin
            ParameterList.Get(i, ParameterName);
            ParameterValue := CopyStr(ParameterName, StrPos(ParameterName, '=') + 1);
            ParameterName := CopyStr(ParameterName, 1, StrPos(ParameterName, '=') - 1);
            case ParameterName of
                NoOfIterationsLbl:
                    if not Evaluate(NoOfIterations, ParameterValue) then
                        Error(ParamValidationErr, GetDefaultParameters());
                ImplementationLbl:
                    if not Evaluate(NoSeriesImplementation, ParameterValue) then
                        Error(ParamValidationErr, GetDefaultParameters());
                UseBatchImplLbl:
                    if not Evaluate(UseBatch, ParameterValue) then
                        Error(ParamValidationErr, GetDefaultParameters());
                SimulationLbl:
                    if not Evaluate(Simulation, ParameterValue) then
                        Error(ParamValidationErr, GetDefaultParameters());
#if not CLEAN24
                RunLegacyLbl:
                    if not Evaluate(RunLegacy, ParameterValue) then
                        Error(ParamValidationErr, GetDefaultParameters());
#endif
                else
                    Error(ParamValidationErr, GetDefaultParameters());
            end;
        end;
        if RunLegacy and Simulation then
            Error(ParamCombinationErr);
    end;
    #endregion;

    local procedure TestGetNextNo()
    var
        NoSeries: Codeunit "No. Series";
        NoSeriesBatch: Codeunit "No. Series - Batch";
#if not CLEAN24
#pragma warning disable AL0432
        NoSeriesManagement: Codeunit NoSeriesManagement;
        NoSeriesManagement2: Codeunit NoSeriesManagement;
#pragma warning restore AL0432
#endif
        NoSeriesCode1, NoSeriesCode2 : Code[20];
        NextNo1, NextNo2 : Code[20];
        i: integer;
    begin
        Any.SetDefaultSeed();
        ValidateParameters(CopyStr(BCPTTestContext.GetParameters(), 1, 1000));
        NoSeriesCode1 := CreateNoSeriesWithLine();
        NoSeriesCode2 := CreateNoSeriesWithLine();

        BCPTTestContext.StartScenario('Test GetNextNo');
        for i := 1 to (NoOfIterations / 2) do
            case true of
#if not CLEAN24
#pragma warning disable AL0432
                RunLegacy and not UseBatch:
                    begin
                        NextNo1 := NoSeriesManagement.GetNextNo(NoSeriesCode1, WorkDate(), true);
                        NextNo2 := NoSeriesManagement.GetNextNo(NoSeriesCode2, WorkDate(), true);
                    end;
                RunLegacy and UseBatch:
                    begin
                        NextNo1 := NoSeriesManagement.GetNextNo(NoSeriesCode1, WorkDate(), false);
                        NextNo2 := NoSeriesManagement2.GetNextNo(NoSeriesCode2, WorkDate(), false);
                    end;
#pragma warning restore AL0432
#endif
                not UseBatch:
                    begin
                        NextNo1 := NoSeries.GetNextNo(NoSeriesCode1);
                        NextNo2 := NoSeries.GetNextNo(NoSeriesCode2);
                    end;
                UseBatch and Simulation:
                    begin
                        NextNo1 := NoSeriesBatch.SimulateGetNextNo(NoSeriesCode1, WorkDate(), NextNo1);
                        NextNo2 := NoSeriesBatch.SimulateGetNextNo(NoSeriesCode2, WorkDate(), NextNo2);
                    end;
                UseBatch and not Simulation:
                    begin
                        NextNo1 := NoSeriesBatch.GetNextNo(NoSeriesCode1);
                        NextNo2 := NoSeriesBatch.GetNextNo(NoSeriesCode2);
                    end;
            end;
        if UseBatch and not Simulation then
            NoSeriesBatch.SaveState();
#if not CLEAN24
#pragma warning disable AL0432
        if RunLegacy and UseBatch then begin
            NoSeriesManagement.SaveNoSeries();
            NoSeriesManagement2.SaveNoSeries();
        end;
#pragma warning restore AL0432
#endif
        BCPTTestContext.EndScenario('Test GetNextNo');
    end;

    local procedure CreateNoSeriesWithLine() NoSeriesCode: Code[20];
    begin
        NoSeriesCode := CreateNoSeries();
        CreateNoSeriesLine(NoSeriesCode);
    end;

    local procedure CreateNoSeries(): Code[20];
    var
        NoSeries: Record "No. Series";
    begin
        NoSeries.Code := CopyStr(Any.AlphanumericText(MaxStrLen(NoSeries.Code)), 1, MaxStrLen(NoSeries.Code));
        NoSeries.Description := 'Test No. Series';
        NoSeries."Date Order" := true;
        NoSeries."Default Nos." := true;
        NoSeries."Manual Nos." := false;
        NoSeries.Insert(true);
        exit(NoSeries.Code)
    end;

    local procedure CreateNoSeriesLine(NoSeriesCode: Code[20]);
    var
        NoSeriesLine: Record "No. Series Line";
    begin
        NoSeriesLine."Series Code" := NoSeriesCode;
        NoSeriesLine."Line No." := 10000;
        NoSeriesLine.Validate("Starting No.", CopyStr(Any.AlphanumericText(3), 1, 3) + '-0000000001');
        NoSeriesLine."Increment-by No." := 1;
        NoSeriesLine.Validate(Implementation, NoSeriesImplementation);
        NoSeriesLine.Insert(true);
    end;
}