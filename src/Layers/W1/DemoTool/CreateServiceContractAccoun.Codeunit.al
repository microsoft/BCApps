codeunit 117074 "Create Service Contract Accoun"
{

    trigger OnRun()
    begin
        InsertData(XHARDWARE, XHardwarelc, '6955', '5796');
        InsertData(XSOFTWARE, XSoftwarelc, '6955', '5797');
    end;

    var
        XHARDWARE: Label 'HARDWARE';
        XHardwarelc: Label 'Hardware';
        XSOFTWARE: Label 'SOFTWARE';
        XSoftwarelc: Label 'Software';

    procedure InsertData("Code": Text[250]; Description: Text[250]; "Non-Prepaid Contract Acc.": Text[250]; "Prepaid Contract Acc.": Text[250])
    var
        ServiceContractAccountGroup: Record "Service Contract Account Group";
    begin
        ServiceContractAccountGroup.Init();
        ServiceContractAccountGroup.Validate(Code, Code);
        ServiceContractAccountGroup.Validate(Description, Description);
        ServiceContractAccountGroup.Validate("Non-Prepaid Contract Acc.", "Non-Prepaid Contract Acc.");
        ServiceContractAccountGroup.Validate("Prepaid Contract Acc.", "Prepaid Contract Acc.");
        ServiceContractAccountGroup.Insert(true);
    end;
}

