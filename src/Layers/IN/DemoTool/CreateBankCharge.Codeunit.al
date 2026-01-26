codeunit 120544 "Create Bank Charge"
{
    trigger OnRun()
    begin
        DemoDataSetup.Get();
        InsertData(XBankCodeBKCHG_01, XDescriptionBank, '8249', false, '2089', XGSTCredit::Availment, XHSNSAC, false);
        InsertData(XBankCodeBKCHG_02, X2Description, '8249', false, '2089', XGSTCredit::"Non-Availment", XHSNSAC, false);
        InsertData(XBankCodeBKCHG_03, X3Description, '8249', false, '2089', XGSTCredit::Availment, XHSNSAC, true);
        InsertData(XBankCodeBKCHG_04, XDescriptionBank, '8249', true, '2089', XGSTCredit::Availment, XHSNSAC, false);
        InsertData(XBankCodeBKCHG_05, XDescriptionBank, '8249', true, '2089', XGSTCredit::"Non-Availment", XHSNSAC, false);
        InsertData(XBankCodeBKCHG_06, XDescriptionBank, '8249', true, '2089', XGSTCredit::Availment, XHSNSAC, true);
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        BankCharge: Record "Bank Charge";
        BankChargeDeemedValueSetup: Record "Bank Charge Deemed Value Setup";
        XGSTCredit: Enum "GST Credit";
        XBankCodeBKCHG_01: Label 'BKCHG_01';
        XBankCodeBKCHG_02: Label 'BKCHG_02';
        XBankCodeBKCHG_03: Label 'BKCHG_03';
        XBankCodeBKCHG_04: Label 'BKCHG_04';
        XBankCodeBKCHG_05: Label 'BKCHG_05';
        XBankCodeBKCHG_06: Label 'BKCHG_06';
        X2Description: Label 'Commission';
        XDescriptionBank: Label 'Bank Charge';
        X3Description: Label 'Exempted';
        XHSNSAC: Label '2089001';

    procedure InsertData(
        BankChargeNo: Code[10];
        Descrip: Text[50];
        BankCHargeAcc: Code[20];
        ForeignExc: Boolean;
        GSTGrpCode: Code[10];
        GSTCredit: Enum "GST Credit";
        HSNSAC: Code[10];
        Exemp: Boolean)
    begin
        BankCharge.Init();
        BankCharge.Validate(Code, BankChargeNo);
        BankCharge.Validate(BankCharge.Description, Descrip);
        BankCharge.Account := BankCHargeAcc;
        BankCharge."Foreign Exchange" := ForeignExc;
        BankCharge."GST Group Code" := GSTGrpCode;
        BankCharge."GST Credit" := GSTCredit;
        BankCharge."HSN/SAC Code" := HSNSAC;
        BankCharge.Exempted := Exemp;
        BankCharge.Insert();
    end;

    procedure InsertBankChargeDeemedValueSetup(
        BankChargeNo: Code[10];
        LLimit: Decimal;
        ULimit: Decimal;
        Formula: Enum "Deemed Value Calculation";
        MinDeemedVal: Decimal;
        MaxDeemedVal: Decimal;
        DeemedPer: Decimal;
        FixedAmt: Decimal)
    begin
        BankChargeDeemedValueSetup.Init();
        BankChargeDeemedValueSetup."Bank Charge Code" := BankChargeNo;
        BankChargeDeemedValueSetup."Lower Limit" := LLimit;
        BankChargeDeemedValueSetup."Upper Limit" := ULimit;
        BankChargeDeemedValueSetup.Formula := Formula;
        BankChargeDeemedValueSetup."Min. Deemed Value" := MinDeemedVal;
        BankChargeDeemedValueSetup."Max. Deemed Value" := MaxDeemedVal;
        BankChargeDeemedValueSetup."Deemed %" := DeemedPer;
        BankChargeDeemedValueSetup."Fixed Amount" := FixedAmt;
        BankChargeDeemedValueSetup.Insert();
    end;
}
