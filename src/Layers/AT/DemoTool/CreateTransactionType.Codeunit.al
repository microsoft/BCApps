codeunit 101258 "Create Transaction Type"
{

    trigger OnRun()
    begin
        InsertData('11', TransactionType11Txt);
        InsertData('12', TransactionType12Txt);
        InsertData('21', TransactionType21Txt);
        InsertData('22', TransactionType22Txt);
        InsertData('23', TransactionType23Txt);
        InsertData('31', TransactionType31Txt);
        InsertData('32', TransactionType32Txt);
        InsertData('33', TransactionType33Txt);
        InsertData('34', TransactionType34Txt);
        InsertData('41', TransactionType41Txt);
        InsertData('42', TransactionType42Txt);
        InsertData('51', TransactionType51Txt);
        InsertData('52', TransactionType52Txt);
        InsertData('71', TransactionType71Txt);
        InsertData('72', TransactionType72Txt);
        InsertData('80', TransactionType80Txt);
        InsertData('91', TransactionType91Txt);
        InsertData('99', TransactionType99Txt);
    end;

    var
        "Transaction Type": Record "Transaction Type";
        TransactionType11Txt: Label 'Outright sale/purchase except direct trade with/by private consumers', MaxLength = 80;
        TransactionType12Txt: Label 'Direct trade with/by private consumers (incl. distance sale)', MaxLength = 80;
        TransactionType21Txt: Label 'Return of goods', Comment = 'For translation: max text length is 80', MaxLength = 80;
        TransactionType22Txt: Label 'Replacement for returned goods', Comment = 'For translation: max text length is 80', MaxLength = 80;
        TransactionType23Txt: Label 'Replacement (e.g. under warranty) for goods not being returned', MaxLength = 80;
        TransactionType31Txt: Label 'Movements to/from a warehouse (excluding calloff and consignment stock)', MaxLength = 80;
        TransactionType32Txt: Label 'Supply for sale on approval or after trial (incl. call-off and consign. stock)', MaxLength = 80;
        TransactionType33Txt: Label 'Financial leasing', Comment = 'For translation: max text length is 80', MaxLength = 80;
        TransactionType34Txt: Label 'Transactions with transfer of ownership without financial compensation', MaxLength = 80;
        TransactionType41Txt: Label 'Goods expected to return to the initial Member State/country of export', MaxLength = 80;
        TransactionType42Txt: Label 'Goods not expected to return to the initial Member State/country of export', MaxLength = 80;
        TransactionType51Txt: Label 'Goods returning to the initial Member State/country of export', MaxLength = 80;
        TransactionType52Txt: Label 'Goods not returning to the initial Member State/country of export', MaxLength = 80;
        TransactionType71Txt: Label 'Release of goods for free circulation in a Member State with subsequent export', MaxLength = 80;
        TransactionType72Txt: Label 'Goods from one Member State to another - goods under the export procedure', MaxLength = 80;
        TransactionType80Txt: Label 'Transactions involving supply of building materials and technical equipment', MaxLength = 80;
        TransactionType91Txt: Label 'Hire, loan, and operational leasing longer than 24 months', MaxLength = 80;
        TransactionType99Txt: Label 'Other', MaxLength = 80;

    procedure InsertData("Code": Code[10]; NewDescription: Text)
    begin
        "Transaction Type".Init();
        "Transaction Type".Validate(Code, Code);
        "Transaction Type".Validate(Description, CopyStr(NewDescription, 1, MaxStrLen("Transaction Type".Description)));
        "Transaction Type".Insert();
    end;
}

