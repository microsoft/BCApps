codeunit 163530 "Create Reason Code"
{

    trigger OnRun()
    begin
        InsertData(XLIQUID, XLiquidation);
        InsertData(XSale, XSale);
        InsertData('PRSKONTO', 'Daňový doklad - skonto včetně DPH');
    end;

    var
        ReasonCode: Record "Reason Code";
        XLIQUID: Label 'LIQUID';
        XLiquidation: Label 'Liquidation';
        XSale: Label 'Sale';

    procedure InsertData("Code": Code[10]; Description: Text[50])
    begin
        ReasonCode.Init();
        ReasonCode.Code := Code;
        ReasonCode.Description := Description;
        ReasonCode.Insert();
    end;

    procedure GetReasonCode(ReasonCode: Text): Code[10]
    begin
        case UpperCase(ReasonCode) of
            'XLIQUID':
                exit(XLIQUID);
            'XSALE':
                exit(XSale);
            else
                Error('Unknown Reason Code %1.', ReasonCode);
        end;
    end;
}
