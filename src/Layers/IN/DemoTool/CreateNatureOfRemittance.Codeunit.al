codeunit 101121 "Create Nature Of Remittance"
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();

        InsertData('16', XDIVIDEND);
        InsertData('21', copystr(XFEESFORTECHNICALSERVICESFEESFORINCLUDEDSERVICES, 1, 50));
        InsertData('27', XINTERESTPAYMENT);
        InsertData('28', XINVESTMENTINCOME);
        InsertData('31', XLONGTERMCAPITALGAINS);
        InsertData('49', XROYALTY);
        InsertData('52', XSHORTTERMCAPITALGAINS);
        InsertData('99', copystr(XOTHERINCOMEOTHERNOTINTHENATUREOFINCOME, 1, 50));
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        XDIVIDEND: Label 'DIVIDEND';
        XFEESFORTECHNICALSERVICESFEESFORINCLUDEDSERVICES: Label 'FEES FOR TECHNICAL SERVICES/ FEES FOR INCLUDED SERVICES';
        XINTERESTPAYMENT: Label 'INTEREST PAYMENT';
        XINVESTMENTINCOME: Label 'INVESTMENT INCOME ';
        XLONGTERMCAPITALGAINS: Label 'LONG TERM CAPITAL GAINS ';
        XROYALTY: Label 'ROYALTY';
        XSHORTTERMCAPITALGAINS: Label 'SHORT TERM CAPITAL GAINS ';
        XOTHERINCOMEOTHERNOTINTHENATUREOFINCOME: Label 'OTHER INCOME / OTHER (NOT IN THE NATURE OF INCOME)';

    procedure InsertMiniAppData()
    begin
        AddNatureOfremittanceForMini();
    end;

    local procedure AddNatureOfremittanceForMini()
    begin
        DemoDataSetup.Get();
        InsertData('16', XDIVIDEND);
        InsertData('21', XFEESFORTECHNICALSERVICESFEESFORINCLUDEDSERVICES);
        InsertData('27', XINTERESTPAYMENT);
        InsertData('28', XINVESTMENTINCOME);
        InsertData('31', XLONGTERMCAPITALGAINS);
        InsertData('49', XROYALTY);
        InsertData('52', XSHORTTERMCAPITALGAINS);
        InsertData('99', XOTHERINCOMEOTHERNOTINTHENATUREOFINCOME);
    end;

    procedure InsertData(Code: Code[20]; Description: Text[50])
    var
        TDSNatureOfRemittance: Record "TDS Nature Of Remittance";
    begin
        TDSNatureOfRemittance.Init();
        TDSNatureOfRemittance.Validate(Code, Code);
        TDSNatureOfRemittance.Validate(Description, Description);
        TDSNatureOfRemittance.Insert();
    end;
}