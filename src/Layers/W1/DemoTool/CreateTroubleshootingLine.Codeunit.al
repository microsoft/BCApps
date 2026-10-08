codeunit 117045 "Create Troubleshooting Line"
{

    trigger OnRun()
    begin
        InsertData(XTR00001, 10000, XIsthepowerswitchdonQmark);
        InsertData(XTR00001, 20000, XIsservercnnctdtontworkQmark);
        InsertData(XTR00001, 30000, Xrqurdprphrlcompscnnctdtosrv);
        InsertData(XTR00001, 40000, Xrqurdswinstalledontheserver);
        InsertData(XTR00001, 50000, Xpossbltologontomachineslnetw);
        InsertData(XTR00001, 60000, XWhterrormsgsifanyaredisplayd);
        InsertData(XTR00001, 70000, XWhtltsterrormsgsalrtsevntlog);
        InsertData(XTR00002, 10000, XIsthenetworkcableconnected);
        InsertData(XTR00002, 20000, Xlghtsinntwcrdndcatngnetwtrffc);
        InsertData(XTR00002, 30000, Xutltprogfornetwcrdndcthwerror);
        InsertData(XTR00003, 10000, XWhtltsterralrtsineventlog);
        InsertData(XTR00004, 10000, XWhtltsterralrtsineventlog);
        InsertData(XTR00005, 10000, XPowerfailureQmark);
    end;

    var
        XTR00001: Label 'TR00001';
        XTR00002: Label 'TR00002';
        XTR00003: Label 'TR00003';
        XTR00004: Label 'TR00004';
        XTR00005: Label 'TR00005';
        XIsthepowerswitchdonQmark: Label 'Is the power switched on?';
        XIsservercnnctdtontworkQmark: Label 'Is the server connected to the network?';
        Xrqurdprphrlcompscnnctdtosrv: Label 'Are all the required peripheral components connected to the server?';
        Xrqurdswinstalledontheserver: Label 'Is all the required software installed on the server?';
        Xpossbltologontomachineslnetw: Label 'Is it possible to log on to the machine / network?';
        XWhterrormsgsifanyaredisplayd: Label 'What error messages, if any, are displayed?';
        XWhtltsterrormsgsalrtsevntlog: Label 'What are the latest error messages or alerts in the event log?';
        XIsthenetworkcableconnected: Label 'Is the network cable connected?';
        Xlghtsinntwcrdndcatngnetwtrffc: Label 'Are there any lights in the network card indicating network traffic?';
        Xutltprogfornetwcrdndcthwerror: Label 'Does the utility program for the network card indicate hardware error?';
        XWhtltsterralrtsineventlog: Label 'What are the latest error or alerts in the event log?';
        XPowerfailureQmark: Label 'Has there been a power failure?';

    procedure InsertData("No.": Text[250]; "Line No.": Integer; Comment: Text[250])
    var
        TroubleshootingLine: Record "Troubleshooting Line";
    begin
        TroubleshootingLine.Init();
        TroubleshootingLine.Validate("No.", "No.");
        TroubleshootingLine.Validate("Line No.", "Line No.");
        TroubleshootingLine.Validate(Comment, Comment);
        TroubleshootingLine.Insert(true);
    end;
}

