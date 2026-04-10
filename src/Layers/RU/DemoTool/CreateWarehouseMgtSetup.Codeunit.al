codeunit 118810 "Create Warehouse Mgt. Setup"
{

    trigger OnRun()
    begin
        WarehouseSetup.Get();
        "Create No. Series".InitBaseSeries(
          WarehouseSetup."Whse. Receipt Nos.", XINV + '-40', XWhseReceipt, XRE000001, XRE999999, '', '', 1);
        "Create No. Series".InitBaseSeries(
          WarehouseSetup."Posted Whse. Receipt Nos.", XINV + '-41', XPostedWhseReceipt, XR_000001, XR_999999, '', '', 1);
        "Create No. Series".InitBaseSeries(
          WarehouseSetup."Whse. Put-away Nos.", XINV + '-48', XWhsePutaway, XPU000001, XPU999999, '', '', 1);
        "Create No. Series".InitBaseSeries(
          WarehouseSetup."Whse. Internal Put-away Nos.", XINV + '-51', XWhseInternalPutaway, XWA000001, XWA999999, '', '', 1);
        "Create No. Series".InitBaseSeries(
          WarehouseSetup."Whse. Internal Pick Nos.", XINV + '-50', XWhseInternalPick, XWI000001, XWI999999, '', '', 1);
        "Create No. Series".InitBaseSeries(
          WarehouseSetup."Registered Whse. Put-away Nos.", XINV + '-49', XRegisteredWhsePutaway, XPU_000001, XPU_999999, '', '', 1);
        "Create No. Series".InitBaseSeries(
          WarehouseSetup."Whse. Pick Nos.", XINV + '-46', XWhsePick, XPI000001, XPI999999, '', '', 1);
        "Create No. Series".InitBaseSeries(
          WarehouseSetup."Registered Whse. Pick Nos.", XINV + '-47', XRegisteredWhsePick, XP_000001, XP_999999, '', '', 1);
        "Create No. Series".InitBaseSeries(
          WarehouseSetup."Whse. Ship Nos.", XINV + '-42', XWhseShip, XSH000001, XSH999999, '', '', 1);
        "Create No. Series".InitBaseSeries(
          WarehouseSetup."Posted Whse. Shipment Nos.", XINV + '-43', XPostedWhseShpt, XS_000001, XS_999999, '', '', 1);
        "Create No. Series".InitBaseSeries(
          WarehouseSetup."Whse. Movement Nos.", XINV + '-44', XWhseMovement, XWM000001, XWM999999, '', '', 1);
        "Create No. Series".InitBaseSeries(
          WarehouseSetup."Registered Whse. Movement Nos.", XINV + '-45', XRegisteredWhseMovement, XWM_000001, XWM_999999, '', '', 1);

        WarehouseSetup.Modify();
    end;

    var
        WarehouseSetup: Record "Warehouse Setup";
        "Create No. Series": Codeunit "Create No. Series";
        XWhseReceipt: Label 'Whse. Receipt';
        XRE000001: Label 'RE000001';
        XRE999999: Label 'RE999999';
        XPostedWhseReceipt: Label 'Posted Whse. Receipt';
        XR_000001: Label 'R_000001';
        XR_999999: Label 'R_999999';
        XWhsePutaway: Label 'Whse. Put-away';
        XPU000001: Label 'PU000001';
        XPU999999: Label 'PU999999';
        XWhseInternalPutaway: Label 'Whse. Internal Put-away';
        XWA000001: Label 'WA000001';
        XWA999999: Label 'WA999999';
        XWhseInternalPick: Label 'Whse. Internal Pick';
        XWI000001: Label 'WI000001';
        XWI999999: Label 'WI999999';
        XRegisteredWhsePutaway: Label 'Registered Whse. Put-away';
        XPU_000001: Label 'PU_000001';
        XPU_999999: Label 'PU_999999';
        XWhsePick: Label 'Whse. Pick';
        XPI000001: Label 'PI000001';
        XPI999999: Label 'PI999999';
        XRegisteredWhsePick: Label 'Registered Whse. Pick';
        XP_000001: Label 'P_000001';
        XP_999999: Label 'P_999999';
        XWhseShip: Label 'Whse. Ship';
        XSH000001: Label 'SH000001';
        XSH999999: Label 'SH999999';
        XPostedWhseShpt: Label 'Posted Whse. Shpt.';
        XS_000001: Label 'S_000001';
        XS_999999: Label 'S_999999';
        XWhseMovement: Label 'Whse. Movement';
        XWM000001: Label 'WM000001';
        XWM999999: Label 'WM999999';
        XRegisteredWhseMovement: Label 'Registered Whse. Movement';
        XWM_000001: Label 'WM_000001';
        XWM_999999: Label 'WM_999999';
        XINV: Label 'INV';
}

