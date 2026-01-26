codeunit 163549 "Create Commodity Setup CZL"
{
    trigger OnRun()
    begin
        InsertData('0', DMY2Date(1, 1, 2013), 0);
        InsertData('12', DMY2Date(1, 4, 2015), 100000);
        InsertData('13', DMY2Date(1, 4, 2015), 100000);
        InsertData('14', DMY2Date(1, 4, 2015), 100000);
        InsertData('15', DMY2Date(1, 4, 2015), 100000);
        InsertData('16', DMY2Date(1, 4, 2015), 100000);
        InsertData('17', DMY2Date(1, 4, 2015), 100000);
    end;

    procedure InsertData(CommodityCode: Code[10]; ValidFrom: Date; CommodityLimitAmount: Decimal)
    var
        CommoditySetupCZL: Record "Commodity Setup CZL";
    begin
        CommoditySetupCZL.Init();
        CommoditySetupCZL."Commodity Code" := CommodityCode;
        CommoditySetupCZL."Valid From" := ValidFrom;
        CommoditySetupCZL."Commodity Limit Amount LCY" := CommodityLimitAmount;
        CommoditySetupCZL.Insert();
    end;
}