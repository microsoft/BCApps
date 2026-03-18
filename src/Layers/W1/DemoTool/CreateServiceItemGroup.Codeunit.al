codeunit 117005 "Create Service Item Group"
{

    trigger OnRun()
    begin
        InsertData(XCDROM, XCDROM, false, 0, '', 24);
        InsertData(XCONTROLLER, XControllerCard, false, 0, '', 12);
        InsertData(XDESKTOP, XDesktopspacePC, true, 0, '', 12);
        InsertData(XGRAPHICS, XGraphicsspaceCard, false, 0, '', 12);
        InsertData(XHARDDRIVE, XHardspaceDrive, false, 0, '', 12);
        InsertData(XKEYBOARD, XKeyboardlc, false, 0, '', 24);
        InsertData(XMEMORY, XMemoryspaceCard, false, 0, '', 12);
        InsertData(XMISCACCESS, XMiscspaceAccessoriesTxt, false, 0, '', 24);
        InsertData(XMONITOR, XMonitorlc, false, 0, '', 24);
        InsertData(XMOUSE, XMouselc, false, 0, '', 24);
        InsertData(XNETWCARD, XNetworkspaceCard, false, 0, '', 12);
        InsertData(XOFFICEEQ, XOfficespaceEquipment, true, 0, '', 24);
        InsertData(XSERVER, XServerlc, true, 0, '', 8);
        InsertData(XZIPDRIVE, XZipspaceDrive, false, 0, '', 24);
    end;

    var
        XCDROM: Label 'CD ROM';
        XCONTROLLER: Label 'CONTROLLER';
        XControllerCard: Label 'Controller Card';
        XDESKTOP: Label 'DESKTOP';
        XGRAPHICS: Label 'GRAPHICS';
        XHARDDRIVE: Label 'HARDDRIVE';
        XKEYBOARD: Label 'KEYBOARD';
        XMEMORY: Label 'MEMORY';
        XMISCACCESS: Label 'MISCACCESS';
        XMONITOR: Label 'MONITOR';
        XMOUSE: Label 'MOUSE';
        XNETWCARD: Label 'NETWCARD';
        XOFFICEEQ: Label 'OFFICE EQ';
        XSERVER: Label 'SERVER';
        XZIPDRIVE: Label 'ZIPDRIVE';
        XDesktopspacePC: Label 'Desktop PC';
        XGraphicsspaceCard: Label 'Graphics Card';
        XHardspaceDrive: Label 'Hard Drive';
        XKeyboardlc: Label 'Keyboard';
        XMemoryspaceCard: Label 'Memory Card';
        XMiscspaceAccessoriesTxt: Label 'Misc. Accessories';
        XMonitorlc: Label 'Monitor';
        XMouselc: Label 'Mouse';
        XNetworkspaceCard: Label 'Network Card';
        XOfficespaceEquipment: Label 'Office Equipment';
        XServerlc: Label 'Server';
        XZipspaceDrive: Label 'Zip Drive';

    procedure InsertData("Code": Text[250]; Description: Text[250]; "Create Service Item": Boolean; "Default Contract Discount %": Decimal; "Default Serv. Price Group Code": Text[250]; "Default Response Time (Hours)": Decimal)
    var
        ServiceItemGroup: Record "Service Item Group";
    begin
        ServiceItemGroup.Init();
        ServiceItemGroup.Validate(Code, Code);
        ServiceItemGroup.Validate(Description, Description);
        ServiceItemGroup.Validate("Create Service Item", "Create Service Item");
        ServiceItemGroup.Validate("Default Contract Discount %", "Default Contract Discount %");
        ServiceItemGroup.Validate("Default Serv. Price Group Code", "Default Serv. Price Group Code");
        ServiceItemGroup.Validate("Default Response Time (Hours)", "Default Response Time (Hours)");
        ServiceItemGroup.Insert(true);
    end;
}

