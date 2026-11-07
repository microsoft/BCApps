codeunit 117014 "Create Loaner"
{

    trigger OnRun()
    begin
        InsertData(XL00001, XMonitor, '', XPCS, '', false, XSMdashLOANER, 'A3452');
        InsertData(XL00002, XMonitor, '', XPCS, '', false, XSMdashLOANER, '12365');
        InsertData(XL00003, XServerdashTeamwearPackage, '', XPCS, '8920-W', false, XSMdashLOANER, 'AB-123');
        InsertData(XL00004, XServerdashTeamwearPackage, '', XPCS, '8920-W', false, XSMdashLOANER, 'AC-256');
        InsertData(XL00005, XATHENSspaceDesk, '', XPCS, '1896-S', false, XSMdashLOANER, 'CG-123');
    end;

    var
        XL00001: Label 'L00001';
        XL00002: Label 'L00002';
        XL00003: Label 'L00003';
        XL00004: Label 'L00004';
        XL00005: Label 'L00005';
        XMonitor: Label 'Monitor';
        XServerdashTeamwearPackage: Label 'Server - Teamwear Package';
        XATHENSspaceDesk: Label 'ATHENS Desk';
        XPCS: Label 'PCS';
        XSMdashLOANER: Label 'SM-LOANER';

    procedure InsertData("No.": Text[250]; Description: Text[250]; "Description 2": Text[250]; "Unit of Measure Code": Text[250]; "Item No.": Text[250]; Blocked: Boolean; "No. Series": Text[250]; "Serial No.": Text[250])
    var
        Loaner: Record Loaner;
    begin
        Loaner.Init();
        Loaner.Validate("No.", "No.");
        Loaner.Validate(Description, Description);
        Loaner.Validate("Description 2", "Description 2");
        Loaner.Validate("Unit of Measure Code", "Unit of Measure Code");
        if "Item No." <> '' then
            Loaner.Validate("Item No.", "Item No.");
        Loaner.Validate(Blocked, Blocked);
        Loaner.Validate("No. Series", "No. Series");
        Loaner.Validate("Serial No.", "Serial No.");
        Loaner.Insert(true);
    end;
}

