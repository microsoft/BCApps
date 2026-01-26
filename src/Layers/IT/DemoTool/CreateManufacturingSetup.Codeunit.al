codeunit 119020 "Create Manufacturing Setup"
{

    trigger OnRun()
    var
        "No. Series": Record "No. Series";
    begin
        if not MfgSetup.Get() then
            MfgSetup.Insert();
        MfgSetup.Validate("Normal Starting Time", 080000T);
        MfgSetup.Validate("Normal Ending Time", 230000T);
        MfgSetup.Validate("Doc. No. Is Prod. Order No.", true);

        MfgSetup.Validate("Cost Incl. Setup", true);
        MfgSetup.Validate("Planning Warning", true);
        MfgSetup.Validate("Dynamic Low-Level Code", true);

        "Create No. Series".InitBaseSeries(MfgSetup."Work Center Nos.", XWORKCTR, XWorkCenters, XW10, XW99990, '', '', 10,
          "No. Series"."No. Series Type"::Normal, '', 0, '', false, Enum::"No. Series Implementation"::Sequence);
        "Create No. Series".InitBaseSeries(MfgSetup."Machine Center Nos.", XMACHCTR, XMachineCenters, XM10, XM99990, '', '', 10,
          "No. Series"."No. Series Type"::Normal, '', 0, '', false, Enum::"No. Series Implementation"::Sequence);
        "Create No. Series".InitBaseSeries(MfgSetup."Production BOM Nos.", XPRODBOM, XProductionBOMs, XP10, XP99990, '', '', 10,
          "No. Series"."No. Series Type"::Normal, '', 0, '', false, Enum::"No. Series Implementation"::Sequence);
        "Create No. Series".InitBaseSeries(MfgSetup."Routing Nos.", XROUTING, XRoutingslc, XR10, XR99990, '', '', 10,
          "No. Series"."No. Series Type"::Normal, '', 0, '', false, Enum::"No. Series Implementation"::Sequence);
        "Create No. Series".InitTempSeries(MfgSetup."Simulated Order Nos.", XMQUO, XSalesQuote,
          "No. Series"."No. Series Type"::Normal, '', 0, '', false);
        "Create No. Series".InitFinalSeries(MfgSetup."Planned Order Nos.", XMPLAN, XPlannedorders, 1,
          "No. Series"."No. Series Type"::Normal, '', 0, '', false);
        "Create No. Series".InitFinalSeries(MfgSetup."Firm Planned Order Nos.", XMFIRMP, XFirmPlannedorders, 1,
          "No. Series"."No. Series Type"::Normal, '', 0, '', false);
        "Create No. Series".InitFinalSeries(MfgSetup."Released Order Nos.", XMREL, XReleasedorders, 1,
          "No. Series"."No. Series Type"::Normal, '', 0, '', false);
        MfgSetup."Simulated Order Nos." := XMQUO;
        MfgSetup."Planned Order Nos." := XMPLAN;
        MfgSetup."Firm Planned Order Nos." := XMFIRMP;
        MfgSetup."Released Order Nos." := XMREL;

        MfgSetup.Modify();
    end;

    var
        MfgSetup: Record "Manufacturing Setup";
        "Create No. Series": Codeunit "Create No. Series";
        XWORKCTR: Label 'WORKCTR';
        XWorkCenters: Label 'Work Centers';
        XW10: Label 'W10';
        XW99990: Label 'W99990';
        XMACHCTR: Label 'MACHCTR';
        XMachineCenters: Label 'Machine Centers';
        XM10: Label 'M10';
        XM99990: Label 'M99990';
        XPRODBOM: Label 'PRODBOM';
        XProductionBOMs: Label 'Production BOMs';
        XP10: Label 'P10';
        XP99990: Label 'P99990';
        XROUTING: Label 'ROUTING';
        XRoutingslc: Label 'Routings';
        XR10: Label 'R10';
        XR99990: Label 'R99990';
        XMQUO: Label 'M-QUO';
        XSalesQuote: Label 'Sales Quote';
        XMPLAN: Label 'M-PLAN';
        XPlannedorders: Label 'Planned orders';
        XMFIRMP: Label 'M-FIRMP';
        XFirmPlannedorders: Label 'Firm Planned orders';
        XMREL: Label 'M-REL';
        XReleasedorders: Label 'Released orders';
}

