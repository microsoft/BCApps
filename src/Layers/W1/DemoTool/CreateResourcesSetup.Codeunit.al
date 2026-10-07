codeunit 101314 "Create Resources Setup"
{

    trigger OnRun()
    begin
        ResourcesSetup.Get();
        if ResourcesSetup."Resource Nos." = '' then
            if not NoSeries.Get(XRES) then
                CreateNoSeries.InitBaseSeries(ResourcesSetup."Resource Nos.", XRES, XResource, XR10, XR9990, '', '', 10, Enum::"No. Series Implementation"::Sequence)
            else
                ResourcesSetup."Resource Nos." := XRES;
        if ResourcesSetup."Time Sheet Nos." = '' then
            if not NoSeries.Get(XTS) then
                CreateNoSeries.InitBaseSeries(ResourcesSetup."Time Sheet Nos.", XTS, XTimeSheet, XTS00001, XTS99999, '', '', 1, Enum::"No. Series Implementation"::Sequence)
            else
                ResourcesSetup."Time Sheet Nos." := XTS;
        ResourcesSetup.Modify();
    end;

    var
        ResourcesSetup: Record "Resources Setup";
        NoSeries: Record "No. Series";
        CreateNoSeries: Codeunit "Create No. Series";
        XRES: Label 'RES';
        XResource: Label 'Resource';
        XR10: Label 'R10';
        XR9990: Label 'R9990';
        XTS: Label 'TS';
        XTimeSheet: Label 'Time Sheet';
        XTS00001: Label 'TS00001', Comment = 'TS stands for Time Sheet.';
        XTS99999: Label 'TS99999', Comment = 'TS stands for Time Sheet.';
}

