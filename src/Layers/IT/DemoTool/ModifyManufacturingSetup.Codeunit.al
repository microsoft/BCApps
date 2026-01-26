codeunit 119070 "Modify Manufacturing Setup"
{

    trigger OnRun()
    var
        "No. Series": Record "No. Series";
    begin
        DemoDataSetup.Get();
        ManufacturingSetup.Get();
        CreateNoSeries.InitFinalSeries(
          ManufacturingSetup."Planned Order Nos.", XMPLANM, XProductionOrderPlanned, 9,
          "No. Series"."No. Series Type"::Normal, '', 0, '', false);
        ManufacturingSetup."Planned Order Nos." := XMPLANM;
        CreateNoSeries.InitFinalSeries(
          ManufacturingSetup."Firm Planned Order Nos.", XMFIRMPM, XProductionOrderFirmPlanned, 10,
          "No. Series"."No. Series Type"::Normal, '', 0, '', false);
        ManufacturingSetup."Firm Planned Order Nos." := XMFIRMPM;
        CreateNoSeries.InitFinalSeries(
          ManufacturingSetup."Released Order Nos.", XMRELM, XProductionOrderReleased, 11,
          "No. Series"."No. Series Type"::Normal, '', 0, '', false);
        ManufacturingSetup."Released Order Nos." := XMRELM;
        ManufacturingSetup."Show Capacity In" := XMINUTES;
        ManufacturingSetup.Modify();
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        ManufacturingSetup: Record "Manufacturing Setup";
        CreateNoSeries: Codeunit "Create No. Series";
        XMPLANM: Label 'M-PLAN-M';
        XMRELM: Label 'M-REL-M';
        XProductionOrderPlanned: Label 'Production Order(Planned)';
        XProductionOrderFirmPlanned: Label 'Production Order(Firm Planned)';
        XProductionOrderReleased: Label 'Production Order(Released)';
        XMFIRMPM: Label 'M-FIRMP-M';
        XMPLAN: Label 'M-PLAN';
        XMFIRMP: Label 'M-FIRMP';
        XMREL: Label 'M-REL';
        XMINUTES: Label 'MINUTES', Comment = 'Minutes is a unit to show capacity in Manufacturing Setup.';

    procedure Finalize()
    begin
        ManufacturingSetup.Get();
        ManufacturingSetup."Planned Order Nos." := XMPLAN;
        ManufacturingSetup."Firm Planned Order Nos." := XMFIRMP;
        ManufacturingSetup."Released Order Nos." := XMREL;
        ManufacturingSetup.Modify();
    end;
}

