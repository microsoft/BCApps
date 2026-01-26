codeunit 101258 "Create Transaction Type"
{

    trigger OnRun()
    begin
        InsertData('11', XOrdinarypurchasesale);
        InsertData('12', XPurchsaleafterinspectiontrial);
        InsertData('13', XBarterExchanges);
        InsertData('15', XFinancialleasing);
        InsertData('21', XReturnofprevrecdshippedgoods);
        InsertData('22', XExchangeofreturnedgoods);
        InsertData('23', XExchangeofnonreturnedgoods);
        // InsertData('31',XGoodsusedinEUaidprograms);
        InsertData('31', XGoodsusedinOtheraidprograms);
        InsertData('32', XOtherpublicsupport);
        InsertData('33', XOtherprivatesupport);
        InsertData('41', XProcessingundercontract);
        InsertData('42', XForrepairmaintenancewithfee);
        InsertData('43', XForrepmaintwithoutcharge);
        InsertData('51', XAftercontractwork);
        InsertData('52', XAfterrepairmaintenancewithfee);
        InsertData('53', XAfterrepmaintwithoutcharge);
        InsertData('61', XOperationalleasing);
        InsertData('70', XJointdefenseprojects);
        InsertData('80', XConstructionmatcovbycontract);
        // InsertData('91',XEUgoodssameownsenttoprivstor);
        // InsertData('92',XEUgoodsrecdforprivatestorage);
        InsertData('91', XMISCgoodssameownsentprivstor);
        InsertData('92', XMISCgoodsrecdprivatestorage);
        InsertData('99', XOther);
    end;

    var
        "Transaction Type": Record "Transaction Type";
        XOrdinarypurchasesale: Label 'Ordinary purchase/sale';
        XPurchsaleafterinspectiontrial: Label 'Purchase/sale after inspection/trial';
        XBarterExchanges: Label 'Barter/Exchanges';
        XFinancialleasing: Label 'Financial leasing';
        XReturnofprevrecdshippedgoods: Label 'Return of previously recd./shipped goods';
        XExchangeofreturnedgoods: Label 'Exchange of returned goods';
        XExchangeofnonreturnedgoods: Label 'Exchange of non-returned goods';
        XOtherpublicsupport: Label 'Other public support';
        XOtherprivatesupport: Label 'Other (private) support';
        XProcessingundercontract: Label 'Processing under contract';
        XForrepairmaintenancewithfee: Label 'For repair/maintenance with fee';
        XForrepmaintwithoutcharge: Label 'For repair/maintenance without charge';
        XAftercontractwork: Label 'After contract work';
        XAfterrepairmaintenancewithfee: Label 'After repair/maintenance with fee';
        XAfterrepmaintwithoutcharge: Label 'After repair/maintenance without charge';
        XOperationalleasing: Label 'Operational leasing';
        XJointdefenseprojects: Label 'Joint defense projects';
        XConstructionmatcovbycontract: Label 'Construction materials covered by contract';
        XOther: Label 'Other';
        XGoodsusedinOtheraidprograms: Label 'Goods used in other aid programs';
        XMISCgoodssameownsentprivstor: Label 'MISC goods (same owner) sent to private storage';
        XMISCgoodsrecdprivatestorage: Label 'MISC goods received for private storage';

    procedure InsertData("Code": Code[10]; Description: Text[80])
    begin
        "Transaction Type".Init();
        "Transaction Type".Validate(Code, Code);
        "Transaction Type".Validate(Description, Description);
        "Transaction Type".Insert();
    end;
}

