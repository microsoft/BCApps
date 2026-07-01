codeunit 101258 "Create Transaction Type"
{

    trigger OnRun()
    begin
        InsertData('11', XOrdinarypurchasesale);
        InsertData('12', XDirectTradePrivateCustomer);
        InsertData('21', XReturnofprevrecdshippedgoods);
        InsertData('22', XReturnedGoodsReplacement);
        InsertData('23', XExchangeofnonreturnedgoods);
        InsertData('31', XMovementsToFromWhse);
        InsertData('32', XSupplyForSaleOnApproval);
        InsertData('33', XFinancialleasing);
        InsertData('34', XOwnershipWOFinCompensation);
        InsertData('41', XGoodsToReturnToCountryOfExport);
        InsertData('42', XGoodsToNotReturnToCountryOfExport);
        InsertData('51', XGoodsReturningToCountryOfExport);
        InsertData('52', XGoodsNotReturningToCountryOfExport);
        InsertData('71', XReleaseOfGoodsForFreeCirc);
        InsertData('72', XTransfrerFromAnotherMemberState);
        InsertData('80', XTransferInvSupply);
        InsertData('91', XHireLoanAndLeasingMore24Months);
        InsertData('99', XOther);
    end;

    var
        "Transaction Type": Record "Transaction Type";
        XOrdinarypurchasesale: Label 'Outright sale/purchase except direct trade with/by private consumers', MaxLength = 80;
        XDirectTradePrivateCustomer: Label 'Direct trade with/by private consumers (incl. distance sale)', MaxLength = 80;
        XFinancialleasing: Label 'Financial leasing', MaxLength = 80;
        XReturnofprevrecdshippedgoods: Label 'Return of goods', MaxLength = 80;
        XReturnedGoodsReplacement: Label 'Replacement for returned goods', MaxLength = 80;
        XExchangeofnonreturnedgoods: Label 'Replacement (e.g. under warranty) for goods not being returned', MaxLength = 80;
        XMovementsToFromWhse: Label 'Movements to/from a warehouse (excluding calloff and consignment stock)', MaxLength = 80;
        XSupplyForSaleOnApproval: Label 'Supply for sale on approval or after trial (including call-off and cons. stock)', MaxLength = 80;
        XOwnershipWOFinCompensation: Label 'Transactions involving transfer of ownership without financial compensation', MaxLength = 80;
        XGoodsToReturnToCountryOfExport: Label 'Goods expected to return to the initial Member State/country of export', MaxLength = 80;
        XGoodsToNotReturnToCountryOfExport: Label 'Goods not expected to return to the initial Member State/country of export', MaxLength = 80;
        XGoodsReturningToCountryOfExport: Label 'Goods returning to the initial Member State/ country of export', MaxLength = 80;
        XGoodsNotReturningToCountryOfExport: Label 'Goods not returning to the initial Member State/ country of export', MaxLength = 80;
        XOther: Label 'Other', MaxLength = 80;
        XReleaseOfGoodsForFreeCirc: Label 'Release of goods for free circ.in a Memb.State with a subs.ex.to another M.State', MaxLength = 80;
        XTransfrerFromAnotherMemberState: Label 'Trans.of goods from one to anoth.Memb.State to place the goods und.the exp.proc.', MaxLength = 80;
        XTransferInvSupply: Label 'Transac. inv.supply of build.mat.and tec.eq.under a gen.cons.or civ.eng.contract', MaxLength = 80;
        XHireLoanAndLeasingMore24Months: Label 'Hire, loan, and operational leasing longer than 24 months', MaxLength = 80;

    procedure InsertData("Code": Code[10]; Description: Text[80])
    begin
        "Transaction Type".Init();
        "Transaction Type".Validate(Code, Code);
        "Transaction Type".Validate(Description, Description);
        "Transaction Type".Insert();
    end;
}

