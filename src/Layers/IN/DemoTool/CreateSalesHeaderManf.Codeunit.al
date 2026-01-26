codeunit 119060 "Create Sales Header Manf"
{

    trigger OnRun()
    begin
        CreateSalesHeader.InsertData(1, '49633663', 19030912D, '', false, '');
        CreateSalesHeader.InsertData(1, '43687129', 19030916D, '', false, '');
        CreateSalesHeader.InsertData(1, '38128456', 19030925D, '', false, '');
        CreateSalesHeader.InsertData(1, '43687129', 19030922D, '', false, '');
        CreateSalesHeader.InsertData(1, '38128456', 19030927D, '', false, '');
    end;

    var
        CreateSalesHeader: Codeunit "Create Sales Header";
}

