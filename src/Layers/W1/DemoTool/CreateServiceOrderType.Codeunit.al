codeunit 117004 "Create Service Order Type"
{

    trigger OnRun()
    begin
        InsertData(XHARDWARE, XHardwareService);
        InsertData(XPREVMAINT, XPreventativeMaintenance);
        InsertData(XSERVICE, XGeneralService);
        InsertData(XSOFTWARE, XSoftwareService);
    end;

    var
        XHARDWARE: Label 'HARDWARE';
        XPREVMAINT: Label 'PREVMAINT';
        XSERVICE: Label 'SERVICE';
        XSOFTWARE: Label 'SOFTWARE';
        XHardwareService: Label 'Hardware Service';
        XPreventativeMaintenance: Label 'Preventative Maintenance';
        XGeneralService: Label 'General Service';
        XSoftwareService: Label 'Software Service';

    procedure InsertData("Code": Text[250]; Description: Text[250])
    var
        ServiceOrderType: Record "Service Order Type";
    begin
        ServiceOrderType.Init();
        ServiceOrderType.Validate(Code, Code);
        ServiceOrderType.Validate(Description, Description);
        ServiceOrderType.Insert(true);
    end;
}

