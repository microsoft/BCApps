codeunit 119060 "Create Sales Header Manf"
{

    trigger OnRun()
    begin
        CreateSalesHeader.InsertData(1, '49633663', 19030912D, XxEUVNSLS);
        CreateSalesHeader.InsertData(1, '43687129', 19030916D, XxEUVNSLS);
        CreateSalesHeader.InsertData(1, '38128456', 19030925D, XxEXTVNSLS);
        CreateSalesHeader.InsertData(1, '43687129', 19030922D, XxEUVNSLS);
        CreateSalesHeader.InsertData(1, '38128456', 19030927D, XxEXTVNSLS);
    end;

    var
        XxEUVNSLS: Label 'EU-VN-SLS';
        XxEXTVNSLS: Label 'EXT-VN-SLS';
        CreateSalesHeader: Codeunit "Create Sales Header";
}

