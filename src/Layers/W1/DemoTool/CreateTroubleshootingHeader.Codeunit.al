codeunit 117044 "Create Troubleshooting Header"
{

    trigger OnRun()
    begin
        InsertData(XTR00001, XServerfailure, '');
        InsertData(XTR00002, XNetworkfailure, '');
        InsertData(XTR00003, XRAMFailure, XSMdashTROUBLE);
        InsertData(XTR00004, XHarddiskfailure, '');
        InsertData(XTR00005, XGeneralTroubleshooting, '');
    end;

    var
        XTR00001: Label 'TR00001';
        XTR00002: Label 'TR00002';
        XTR00003: Label 'TR00003';
        XTR00004: Label 'TR00004';
        XTR00005: Label 'TR00005';
        XServerfailure: Label 'Server failure';
        XNetworkfailure: Label 'Network failure';
        XRAMFailure: Label 'RAM Failure';
        XSMdashTROUBLE: Label 'SM-TROUBLE';
        XHarddiskfailure: Label 'Harddisk failure';
        XGeneralTroubleshooting: Label 'General Troubleshooting';

    procedure InsertData("No.": Text[250]; Description: Text[250]; "No. Series": Text[250])
    var
        TroubleshootingHeader: Record "Troubleshooting Header";
    begin
        TroubleshootingHeader.Init();
        TroubleshootingHeader.Validate("No.", "No.");
        TroubleshootingHeader.Validate(Description, Description);
        TroubleshootingHeader.Validate("No. Series", "No. Series");
        TroubleshootingHeader.Insert(true);
    end;
}

