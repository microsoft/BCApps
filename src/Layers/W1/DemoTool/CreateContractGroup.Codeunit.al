codeunit 117067 "Create Contract Group"
{

    trigger OnRun()
    begin
        InsertData(XHARDWARE, XHardwareContract, true);
        InsertData(XMAINT, XMaintenanceContract, true);
        InsertData(XSOFTWARE, XSoftwareContract, false);
        InsertData(XSPECIAL, XSpecialContract, false);
        InsertData(XSUPPORT, XSupportContract, false);
    end;

    var
        XHARDWARE: Label 'HARDWARE';
        XHardwareContract: Label 'Hardware Contract';
        XMAINT: Label 'MAINT';
        XSOFTWARE: Label 'SOFTWARE';
        XSPECIAL: Label 'SPECIAL';
        XSUPPORT: Label 'SUPPORT';
        XMaintenanceContract: Label 'Maintenance Contract';
        XSoftwareContract: Label 'Software Contract';
        XSpecialContract: Label 'Special Contract';
        XSupportContract: Label 'Support Contract';

    procedure InsertData("Code": Text[250]; Description: Text[250]; "Disc. on Contr. Orders Only": Boolean)
    var
        ContractGroup: Record "Contract Group";
    begin
        ContractGroup.Init();
        ContractGroup.Validate(Code, Code);
        ContractGroup.Validate(Description, Description);
        ContractGroup.Validate("Disc. on Contr. Orders Only", "Disc. on Contr. Orders Only");
        ContractGroup.Insert(true);
    end;
}

