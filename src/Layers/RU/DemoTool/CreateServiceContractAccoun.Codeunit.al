codeunit 117074 "Create Service Contract Accoun"
{

    trigger OnRun()
    begin
        InsertData(XHARDWARE, XHardwarelc, '90-1210', '90-1210');
        InsertData(XSOFTWARE, XSoftwarelc, '90-1210', '90-1210');
    end;

    var
        XHARDWARE: Label 'HARDWARE';
        XHardwarelc: Label 'Hardware';
        XSOFTWARE: Label 'SOFTWARE';
        XSoftwarelc: Label 'Software';
        CA: Codeunit "Make Adjustments";

    procedure InsertData("Code": Text[250]; Description: Text[250]; "Non-Prepaid Contract Acc.": Text[250]; "Prepaid Contract Acc.": Text[250])
    var
        ServiceContractAccountGroup: Record "Service Contract Account Group";
    begin
        ServiceContractAccountGroup.Init();
        ServiceContractAccountGroup.Validate(Code, Code);
        ServiceContractAccountGroup.Validate(Description, Description);
        ServiceContractAccountGroup.Validate("Non-Prepaid Contract Acc.", CA.Convert("Non-Prepaid Contract Acc."));
        ServiceContractAccountGroup.Validate("Prepaid Contract Acc.", CA.Convert("Prepaid Contract Acc."));
        ServiceContractAccountGroup.Insert(true);
    end;
}

