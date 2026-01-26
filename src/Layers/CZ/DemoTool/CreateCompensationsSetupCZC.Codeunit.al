codeunit 163525 "Create Compensations Setup CZC"
{

    trigger OnRun()
    begin
        if not CompensationsSetupCZC.Get() then begin
            CompensationsSetupCZC.Init();
            CompensationsSetupCZC.Insert();
        end;

        CompensationsSetupCZC."Compensation Bal. Account No." := '395100';
        CreateNoSeries.InitBaseSeries2(CompensationsSetupCZC."Compensation Nos.", XCOMPENSATION, XCompensations, 'ZAP0001', 'ZAP9999', '', '', 1);
        CompensationsSetupCZC.Modify();
    end;

    var
        CompensationsSetupCZC: Record "Compensations Setup CZC";
        CreateNoSeries: Codeunit "Create No. Series";
        XCOMPENSATION: Label 'COMPENSATION';
        XCompensations: Label 'Compensations';
}

