codeunit 117181 "Create Service Price Group"
{

    trigger OnRun()
    begin
        InsertData(XDESKTOP, XPCDesktops);
        InsertData(XMONITOR, XMonitors);
        InsertData(XSERVER, XServers);
    end;

    var
        XDESKTOP: Label 'DESKTOP';
        XPCDesktops: Label 'PC Desktops';
        XMONITOR: Label 'MONITOR';
        XMonitors: Label 'Monitors';
        XSERVER: Label 'SERVER';
        XServers: Label 'Servers';

    procedure InsertData("Code": Text[250]; Description: Text[250])
    var
        ServicePriceGroup: Record "Service Price Group";
    begin
        ServicePriceGroup.Init();
        ServicePriceGroup.Validate(Code, Code);
        ServicePriceGroup.Validate(Description, Description);
        ServicePriceGroup.Insert(true);
    end;
}

