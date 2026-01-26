codeunit 101258 "Create Transaction Type"
{

    trigger OnRun()
    begin
        InsertData('1', XOrdinarypurchasesale);
        InsertData('2', XReturnofprevrecdshippedgoods);
        InsertData('3', XGoodsusedinEUaidprograms);
        InsertData('4', XProcessingundercontract);
        InsertData('5', XAftercontractwork);
        InsertData('7', XJointdefenseprojects);
        InsertData('8', XConstructionmatcovbycontract);
        InsertData('9', XOther);
    end;

    var
        "Transaction Type": Record "Transaction Type";
        XOrdinarypurchasesale: Label 'Ordinary purchase/sale';
        XReturnofprevrecdshippedgoods: Label 'Return of previously recd./shipped goods';
        XGoodsusedinEUaidprograms: Label 'Goods used in EU aid programs';
        XProcessingundercontract: Label 'Processing under contract';
        XAftercontractwork: Label 'After contract work';
        XJointdefenseprojects: Label 'Joint defense projects';
        XConstructionmatcovbycontract: Label 'Construction materials covered by contract';
        XOther: Label 'Other';

    procedure InsertData("Code": Code[10]; Description: Text[80])
    begin
        "Transaction Type".Init();
        "Transaction Type".Validate(Code, Code);
        "Transaction Type".Validate(Description, Description);
        "Transaction Type".Insert();
    end;
}

