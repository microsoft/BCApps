codeunit 161376 "Create ABI/CAB Codes"
{

    trigger OnRun()
    begin
        InsertData('36558', '22508');
        InsertData('56200', '45007');
        InsertData('52714', '10180');
        InsertData('33577', '05423');
        InsertData('58600', '12004');
        InsertData('56220', '24452');
        InsertData('45100', '22550');
        InsertData('25100', '32100');
        InsertData('85400', '45600');
        InsertData('12350', '45680');
        InsertData('33350', '44450');
        InsertData('56000', '85456');
        InsertData('52001', '56300');
        InsertData('05428', '11101');
        InsertData('56220', '11101');
        InsertData('12345', '22224');
        InsertData('56220', '22224');
    end;

    procedure InsertData(ABI: Code[5]; CAB: Code[5])
    var
        ABICABCodes: Record "ABI/CAB Codes";
    begin
        ABICABCodes.Init();
        ABICABCodes.Validate(ABI, ABI);
        ABICABCodes.Validate(CAB, CAB);
        ABICABCodes.Insert();
    end;
}

