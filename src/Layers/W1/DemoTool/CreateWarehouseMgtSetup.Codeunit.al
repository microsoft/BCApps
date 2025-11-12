codeunit 118810 "Create Warehouse Mgt. Setup"
{

    trigger OnRun()
    begin
        WarehouseSetup.Get();
        "Create No. Series".InitBaseSeries(
          WarehouseSetup."Whse. Receipt Nos.", XWMSRCPT, XWhseReceipt, XRE000001, XRE999999, '', '', 1);
        "Create No. Series".InitBaseSeries(
          WarehouseSetup."Posted Whse. Receipt Nos.", XWMSRCPTplus, XPostedWhseReceipt, XR_000001, XR_999999, '', '', 1);
        "Create No. Series".InitBaseSeries(
          WarehouseSetup."Whse. Put-away Nos.", XWMSPUT, XWhsePutaway, XPU000001, XPU999999, '', '', 1);
        "Create No. Series".InitBaseSeries(
          WarehouseSetup."Whse. Internal Put-away Nos.", XWMSPAO, XWhseInternalPutaway, XWA000001, XWA999999, '', '', 1);
        "Create No. Series".InitBaseSeries(
          WarehouseSetup."Whse. Internal Pick Nos.", XWMSPIO, XWhseInternalPick, XWI000001, XWI999999, '', '', 1);
        "Create No. Series".InitBaseSeries(
          WarehouseSetup."Registered Whse. Put-away Nos.", XWMSPUTplus, XRegisteredWhsePutaway, XPU_000001, XPU_999999, '', '', 1);
        "Create No. Series".InitBaseSeries(
          WarehouseSetup."Whse. Pick Nos.", XWMSPICK, XWhsePick, XPI000001, XPI999999, '', '', 1);
        "Create No. Series".InitBaseSeries(
          WarehouseSetup."Registered Whse. Pick Nos.", XWMSPICKplus, XRegisteredWhsePick, XP_000001, XP_999999, '', '', 1);
        "Create No. Series".InitBaseSeries(
          WarehouseSetup."Whse. Ship Nos.", XWMSSHIP, XWhseShip, XSH000001, XSH999999, '', '', 1);
        "Create No. Series".InitBaseSeries(
          WarehouseSetup."Posted Whse. Shipment Nos.", XWMSSHIPplus, XPostedWhseShpt, XS_000001, XS_999999, '', '', 1);
        "Create No. Series".InitBaseSeries(
          WarehouseSetup."Whse. Movement Nos.", XWMSMov, XWhseMovement, XWM000001, XWM999999, '', '', 1);
        "Create No. Series".InitBaseSeries(
          WarehouseSetup."Registered Whse. Movement Nos.", XWMSMovplus, XRegisteredWhseMovement, XWM_000001, XWM_999999, '', '', 1);

        WarehouseSetup.Modify();
    end;

    var
        WarehouseSetup: Record "Warehouse Setup";
        "Create No. Series": Codeunit "Create No. Series";
        XWMSRCPT: Label 'WMS-RCPT';
        XWhseReceipt: Label 'Whse. Receipt';
        XRE000001: Label 'RE000001';
        XRE999999: Label 'RE999999';
        XWMSRCPTplus: Label 'WMS-RCPT+';
        XPostedWhseReceipt: Label 'Posted Whse. Receipt';
        XR_000001: Label 'R_000001';
        XR_999999: Label 'R_999999';
        XWMSPUT: Label 'WMS-PUT';
        XWhsePutaway: Label 'Whse. Put-away';
        XPU000001: Label 'PU000001';
        XPU999999: Label 'PU999999';
        XWMSPAO: Label 'WMS-PAO';
        XWhseInternalPutaway: Label 'Whse. Internal Put-away';
        XWA000001: Label 'WA000001';
        XWA999999: Label 'WA999999';
        XWMSPIO: Label 'WMS-PIO';
        XWhseInternalPick: Label 'Whse. Internal Pick';
        XWI000001: Label 'WI000001';
        XWI999999: Label 'WI999999';
        XWMSPUTplus: Label 'WMS-PUT+';
        XRegisteredWhsePutaway: Label 'Registered Whse. Put-away';
        XPU_000001: Label 'PU_000001';
        XPU_999999: Label 'PU_999999';
        XWMSPICK: Label 'WMS-PICK';
        XWhsePick: Label 'Whse. Pick';
        XPI000001: Label 'PI000001';
        XPI999999: Label 'PI999999';
        XWMSPICKplus: Label 'WMS-PICK+';
        XRegisteredWhsePick: Label 'Registered Whse. Pick';
        XP_000001: Label 'P_000001';
        XP_999999: Label 'P_999999';
        XWMSSHIP: Label 'WMS-SHIP';
        XWhseShip: Label 'Whse. Ship';
        XSH000001: Label 'SH000001';
        XSH999999: Label 'SH999999';
        XWMSSHIPplus: Label 'WMS-SHIP+';
        XPostedWhseShpt: Label 'Posted Whse. Shpt.';
        XS_000001: Label 'S_000001';
        XS_999999: Label 'S_999999';
        XWMSMov: Label 'WMS-Mov';
        XWhseMovement: Label 'Whse. Movement';
        XWM000001: Label 'WM000001';
        XWM999999: Label 'WM999999';
        XWMSMovplus: Label 'WMS-Mov+';
        XRegisteredWhseMovement: Label 'Registered Whse. Movement';
        XWM_000001: Label 'WM_000001';
        XWM_999999: Label 'WM_999999';
}

