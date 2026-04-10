codeunit 119020 "Create Manufacturing Setup"
{

    trigger OnRun()
    begin
        if not MfgSetup.Get() then
            MfgSetup.Insert();
        MfgSetup.Validate("Normal Starting Time", 080000T);
        MfgSetup.Validate("Normal Ending Time", 230000T);
        MfgSetup.Validate("Doc. No. Is Prod. Order No.", true);

        MfgSetup.Validate("Cost Incl. Setup", true);
        MfgSetup.Validate("Planning Warning", true);
        MfgSetup.Validate("Dynamic Low-Level Code", true);
        "Create No. Series".InitBaseSeries(MfgSetup."Work Center Nos.", XMFG + '-01', XWorkCenters, XW10, XW99990, '', '', 10, Enum::"No. Series Implementation"::Sequence);
        "Create No. Series".InitBaseSeries(MfgSetup."Machine Center Nos.", XMFG + '-02', XMachineCenters, XM10, XM99990, '', '', 10, Enum::"No. Series Implementation"::Sequence);
        "Create No. Series".InitBaseSeries(MfgSetup."Production BOM Nos.", XMFG + '-03', XProductionBOMs, XP10, XP99990, '', '', 10, Enum::"No. Series Implementation"::Sequence);
        "Create No. Series".InitBaseSeries(MfgSetup."Routing Nos.", XMFG + '-04', XRoutingslc, XR10, XR99990, '', '', 10, Enum::"No. Series Implementation"::Sequence);
        "Create No. Series".InitTempSeries(MfgSetup."Simulated Order Nos.", XMFG + '-04-01', XSalesQuote);
        "Create No. Series".InitFinalSeries(MfgSetup."Planned Order Nos.", XMFG + '-04-02', XPlannedorders, 1);
        "Create No. Series".InitFinalSeries(MfgSetup."Firm Planned Order Nos.", XMFG + '-04-03', XFirmPlannedorders, 1);
        "Create No. Series".InitFinalSeries(MfgSetup."Released Order Nos.", XMFG + '-04-04', XReleasedorders, 1);
        MfgSetup."Simulated Order Nos." := XMFG + '-04-01';
        MfgSetup."Planned Order Nos." := XMFG + '-04-02';
        MfgSetup."Firm Planned Order Nos." := XMFG + '-04-03';
        MfgSetup."Released Order Nos." := XMFG + '-04-04';

        MfgSetup.Modify();
    end;

    var
        MfgSetup: Record "Manufacturing Setup";
        "Create No. Series": Codeunit "Create No. Series";
        XWorkCenters: Label 'Work Centers';
        XW10: Label 'W10';
        XW99990: Label 'W99990';
        XMachineCenters: Label 'Machine Centers';
        XM10: Label 'M10';
        XM99990: Label 'M99990';
        XProductionBOMs: Label 'Production BOMs';
        XP10: Label 'P10';
        XP99990: Label 'P99990';
        XRoutingslc: Label 'Routings';
        XR10: Label 'R10';
        XR99990: Label 'R99990';
        XSalesQuote: Label 'Sales Quote';
        XPlannedorders: Label 'Planned orders';
        XFirmPlannedorders: Label 'Firm Planned orders';
        XReleasedorders: Label 'Released orders';
        XMFG: Label 'MFG';
}

