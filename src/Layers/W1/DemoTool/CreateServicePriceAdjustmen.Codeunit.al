codeunit 117183 "Create Service Price Adjustmen"
{

    trigger OnRun()
    begin
        InsertData(XMONITOR, XMonitors);
        InsertData(XOSP, XOnlyspareparts);
    end;

    var
        XMONITOR: Label 'MONITOR';
        XMonitors: Label 'Monitors';
        XOSP: Label 'OSP';
        XOnlyspareparts: Label 'Only spare parts';

    procedure InsertData("Code": Text[250]; Description: Text[250])
    var
        ServicePriceAdjustmentGroup: Record "Service Price Adjustment Group";
    begin
        ServicePriceAdjustmentGroup.Init();
        ServicePriceAdjustmentGroup.Validate(Code, Code);
        ServicePriceAdjustmentGroup.Validate(Description, Description);
        ServicePriceAdjustmentGroup.Insert(true);
    end;
}

