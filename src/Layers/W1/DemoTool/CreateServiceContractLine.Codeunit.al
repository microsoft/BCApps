codeunit 117065 "Create Service Contract Line"
{

    trigger OnRun()
    begin
        InsertData(ServiceContractLine."Contract Type"::Quote, XSC00004, 10000, ServiceContractLine."Contract Status"::" ", '9');
        InsertData(ServiceContractLine."Contract Type"::Quote, XSC00004, 20000, ServiceContractLine."Contract Status"::" ", '10');
        InsertData(ServiceContractLine."Contract Type"::Quote, XSC00004, 30000, ServiceContractLine."Contract Status"::" ", X2000S2);
        InsertData(ServiceContractLine."Contract Type"::Contract, XSC00001, 10000, ServiceContractLine."Contract Status"::" ", '7');
        InsertData(ServiceContractLine."Contract Type"::Contract, XSC00001, 20000, ServiceContractLine."Contract Status"::" ", '6');
        InsertData(ServiceContractLine."Contract Type"::Contract, XSC00002, 10000, ServiceContractLine."Contract Status"::" ", '1');
        InsertData(ServiceContractLine."Contract Type"::Contract, XSC00002, 20000, ServiceContractLine."Contract Status"::" ", '2');
        InsertData(ServiceContractLine."Contract Type"::Contract, XSC00002, 30000, ServiceContractLine."Contract Status"::" ", '3');
        InsertData(ServiceContractLine."Contract Type"::Contract, XSC00002, 40000, ServiceContractLine."Contract Status"::" ", '4');
        InsertData(ServiceContractLine."Contract Type"::Contract, XSC00002, 50000, ServiceContractLine."Contract Status"::" ", '5');
        InsertData(ServiceContractLine."Contract Type"::Contract, XSC00002, 60000, ServiceContractLine."Contract Status"::" ", '27');
        InsertData(ServiceContractLine."Contract Type"::Contract, XSC00002, 70000, ServiceContractLine."Contract Status"::" ", '26');
        InsertData(ServiceContractLine."Contract Type"::Contract, XSC00002, 80000, ServiceContractLine."Contract Status"::" ", '25');
        InsertData(ServiceContractLine."Contract Type"::Contract, XSC00002, 90000, ServiceContractLine."Contract Status"::" ", '23');
        InsertData(ServiceContractLine."Contract Type"::Contract, XSC00002, 100000, ServiceContractLine."Contract Status"::" ", '24');
        InsertData(ServiceContractLine."Contract Type"::Contract, XSC00003, 10000, ServiceContractLine."Contract Status"::" ", '8');
        InsertData(ServiceContractLine."Contract Type"::Contract, XSC00005, 10000, ServiceContractLine."Contract Status"::" ", '16');
        InsertData(ServiceContractLine."Contract Type"::Contract, XSC00005, 20000, ServiceContractLine."Contract Status"::" ", '11');
        InsertData(ServiceContractLine."Contract Type"::Contract, XSC00005, 30000, ServiceContractLine."Contract Status"::" ", '12');
        InsertData(ServiceContractLine."Contract Type"::Contract, XSC00005, 40000, ServiceContractLine."Contract Status"::" ", '13');
        InsertData(ServiceContractLine."Contract Type"::Contract, XSC00005, 50000, ServiceContractLine."Contract Status"::" ", '14');
        InsertData(ServiceContractLine."Contract Type"::Contract, XSC00005, 60000, ServiceContractLine."Contract Status"::" ", '15');
        InsertData(ServiceContractLine."Contract Type"::Contract, XSC00005, 70000, ServiceContractLine."Contract Status"::" ", '21');
        InsertData(ServiceContractLine."Contract Type"::Contract, XSC00006, 10000, ServiceContractLine."Contract Status"::" ", '17');
        InsertData(ServiceContractLine."Contract Type"::Contract, XSC00006, 20000, ServiceContractLine."Contract Status"::" ", '18');
        InsertData(ServiceContractLine."Contract Type"::Contract, XSC00006, 30000, ServiceContractLine."Contract Status"::" ", '19');
        InsertData(ServiceContractLine."Contract Type"::Contract, XSC00006, 40000, ServiceContractLine."Contract Status"::" ", '20');
        InsertData(ServiceContractLine."Contract Type"::Contract, XSC00007, 10000, ServiceContractLine."Contract Status"::" ", '28');
        InsertData(ServiceContractLine."Contract Type"::Contract, XSC00007, 20000, ServiceContractLine."Contract Status"::" ", '29');
    end;

    var
        ServiceContractLine: Record "Service Contract Line";
        XSC00004: Label 'SC00004';
        XSC00001: Label 'SC00001';
        XSC00002: Label 'SC00002';
        XSC00003: Label 'SC00003';
        XSC00005: Label 'SC00005';
        XSC00006: Label 'SC00006';
        XSC00007: Label 'SC00007';
        X2000S2: Label '2000-S-2';

    procedure InsertData("Contract Type": Enum "Service Contract Type"; "Contract No.": Text[250]; "Line No.": Integer; "Contract Status": Enum "Service Contract Status"; "Service Item No.": Text[250])
    var
        ServiceContractLine: Record "Service Contract Line";
    begin
        ServiceContractLine.Init();

        ServiceContractLine.HideDialogBox := true;

        ServiceContractLine.Validate("Contract Type", "Contract Type");
        ServiceContractLine.Validate("Contract No.", "Contract No.");
        ServiceContractLine.Validate("Line No.", "Line No.");
        ServiceContractLine.SetupNewLine();
        ServiceContractLine.Validate("Contract Status", "Contract Status");
        ServiceContractLine.Validate("Service Item No.", "Service Item No.");
        ServiceContractLine.Insert(true);
    end;
}

