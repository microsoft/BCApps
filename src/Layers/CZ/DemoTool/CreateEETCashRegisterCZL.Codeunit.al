codeunit 163541 "Create EET Cash Register CZL"
{

    trigger OnRun()
    begin
        InsertData(XEETBP, XEETCR, "EET Cash Register Type CZL"::"Cash Desk", 'POK01', XCashRegister1);
    end;

    var
        EETCashRegisterCZL: Record "EET Cash Register CZL";
        CreateNoSeries: Codeunit "Create No. Series";
        XEETBP: Label 'EETBP';
        XEETCR: Label 'EETCR';
        XEETRCPT: Label 'EETRCPT';
        XSerialNumberOfReceipt: Label 'Serial number of receipt';
        XEET1600001: Label 'EET1600001', Locked = true;
        XCashRegister1: Label 'Cash register 1';

    procedure InsertData(BusinessPremisesCode: Code[10]; "Code": Code[10]; CashRegisterType: Enum "EET Cash Register Type CZL"; CashRegisterNo: Code[20]; CashRegisterName: Text[50])
    begin
        EETCashRegisterCZL.Init();
        EETCashRegisterCZL."Business Premises Code" := BusinessPremisesCode;
        EETCashRegisterCZL.Code := Code;
        EETCashRegisterCZL."Cash Register Type" := CashRegisterType;
        EETCashRegisterCZL."Cash Register No." := CashRegisterNo;
        EETCashRegisterCZL."Cash Register Name" := CashRegisterName;

        CreateNoSeries.InitBaseSeries2(
          EETCashRegisterCZL."Receipt Serial Nos.", XEETRCPT, XSerialNumberOfReceipt, XEET1600001, '', '', '', 1);
        EETCashRegisterCZL.Insert();
    end;
}

