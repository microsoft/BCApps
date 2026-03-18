codeunit 117046 "Create Troubleshooting Setup"
{

    trigger OnRun()
    begin
        InsertData(TroubleshootingSetup.Type::"Service Item Group", XDESKTOP, XTR00005);
        InsertData(TroubleshootingSetup.Type::"Service Item Group", XSERVER, XTR00005);
        InsertData(TroubleshootingSetup.Type::"Service Item", '7', XTR00001);
        InsertData(TroubleshootingSetup.Type::"Service Item", '7', XTR00002);
        InsertData(TroubleshootingSetup.Type::"Service Item", '7', XTR00003);
        InsertData(TroubleshootingSetup.Type::"Service Item", '7', XTR00004);
        InsertData(TroubleshootingSetup.Type::"Service Item", '7', XTR00005);
        InsertData(TroubleshootingSetup.Type::"Service Item", '16', XTR00001);
        InsertData(TroubleshootingSetup.Type::"Service Item", '16', XTR00002);
        InsertData(TroubleshootingSetup.Type::"Service Item", '16', XTR00003);
        InsertData(TroubleshootingSetup.Type::"Service Item", '16', XTR00004);
        InsertData(TroubleshootingSetup.Type::"Service Item", '16', XTR00005);
        InsertData(TroubleshootingSetup.Type::"Service Item", '17', XTR00001);
        InsertData(TroubleshootingSetup.Type::"Service Item", '17', XTR00002);
        InsertData(TroubleshootingSetup.Type::"Service Item", '17', XTR00003);
        InsertData(TroubleshootingSetup.Type::"Service Item", '17', XTR00004);
        InsertData(TroubleshootingSetup.Type::"Service Item", '17', XTR00005);
    end;

    var
        TroubleshootingSetup: Record "Troubleshooting Setup";
        XDESKTOP: Label 'DESKTOP';
        XSERVER: Label 'SERVER';
        XTR00005: Label 'TR00005';
        XTR00001: Label 'TR00001';
        XTR00002: Label 'TR00002';
        XTR00003: Label 'TR00003';
        XTR00004: Label 'TR00004';

    procedure InsertData(Type: Enum "Troubleshooting Item Type"; "No.": Text[250]; "Troubleshooting No.": Text[250])
    var
        TroubleshootingSetup: Record "Troubleshooting Setup";
    begin
        TroubleshootingSetup.Init();
        TroubleshootingSetup.Validate(Type, Type);
        TroubleshootingSetup.Validate("No.", "No.");
        TroubleshootingSetup.Validate("Troubleshooting No.", "Troubleshooting No.");
        TroubleshootingSetup.Insert(true);
    end;
}

