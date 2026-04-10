codeunit 119070 "Modify Manufacturing Setup"
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        ManufacturingSetup.Get();
        CreateNoSeries.InitFinalSeries(ManufacturingSetup."Planned Order Nos.", XMFG + '-05-02', XProductionOrderPlanned, 9);
        ManufacturingSetup."Planned Order Nos." := XMFG + '-05-02';
        CreateNoSeries.InitFinalSeries(ManufacturingSetup."Firm Planned Order Nos.", XMFG + '-05-03', XProductionOrderFirmPlanned, 10);
        ManufacturingSetup."Firm Planned Order Nos." := XMFG + '-05-03';
        CreateNoSeries.InitFinalSeries(ManufacturingSetup."Released Order Nos.", XMFG + '-05-04', XProductionOrderReleased, 11);
        ManufacturingSetup."Released Order Nos." := XMFG + '-05-04';
        ManufacturingSetup."Show Capacity In" := XMINUTES;
        ManufacturingSetup.Modify();
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        ManufacturingSetup: Record "Manufacturing Setup";
        CreateNoSeries: Codeunit "Create No. Series";
        XProductionOrderPlanned: Label 'Production Order(Planned)';
        XProductionOrderFirmPlanned: Label 'Production Order(Firm Planned)';
        XProductionOrderReleased: Label 'Production Order(Released)';
        XMINUTES: Label 'MINUTES', Comment = 'Minutes is a unit to show capacity in Manufacturing Setup.';
        XMFG: Label 'MFG';

    procedure Finalize()
    begin
        ManufacturingSetup.Get();
        ManufacturingSetup."Planned Order Nos." := XMFG + '-04-02';
        ManufacturingSetup."Firm Planned Order Nos." := XMFG + '-04-03';
        ManufacturingSetup."Released Order Nos." := XMFG + '-04-04';
        ManufacturingSetup.Modify();
    end;
}

