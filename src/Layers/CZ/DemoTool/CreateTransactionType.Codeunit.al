codeunit 101258 "Create Transaction Type"
{

    trigger OnRun()
    begin
        InsertData('11', XOrdinarypurchasesale);
        InsertData('12', XPurchsaleafterinspectiontrial);
        InsertData('13', XBarterExchanges);
        InsertData('14', XFinancialleasing);
        InsertData('19', XDirectSalePurchaseNonVat);
        InsertData('21', XReturnofprevrecdshippedgoods);
        InsertData('22', XExchangeofreturnedgoods);
        InsertData('23', XExchangeofnonreturnedgoods);
        InsertData('29', XReturnOfGoods91);
        InsertData('30', XTransferOwnership);
        InsertData('41', XSendRecevingGoods);
        InsertData('42', XTempAcceptGoods);
        InsertData('49', XRetGoodsForProcess);
        InsertData('51', XReSentReceiptGoods);
        InsertData('52', XReturnReprocGoods);
        InsertData('59', XReturnGoodsBack);
        InsertData('70', XDeliveriesJointDefense);
        InsertData('80', XSuppliesBuildMatTechEquipWhole);
        InsertData('82', XReturnGoods80);
        InsertData('83', XReceiptDeliverySubst80);
        InsertData('91', XImportExportGoodsWithConnection);
        InsertData('92', XRElocOwnPropertyByVatPers);
        InsertData('94', XDelivGoodsWithoutChengeOwner);
        InsertData('96', XTemporaryDelivery2Years);
        InsertData('97', XTemporaryFreeDelivery2Years);
        InsertData('99', XOtherTransactions);
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
        XReturnOfGoods91: Label 'Return of goods originally declared with code 91';
        XTransferOwnership: Label 'Transfer of ownership of goods without financial or other consideration';
        XDirectSalePurchaseNonVat: Label 'Direct sale or purchase for non VAT payers';
        XSendRecevingGoods: Label 'Send/receiving goods for processing according to contract, returns to CZ or EU';
        XTempAcceptGoods: Label 'Temp. accept. of goods for processing if not returned to the EU after processing';
        XRetGoodsForProcess: Label 'Ret. goods receiv. for proc. under contract that has not undergone any operation';
        XReSentReceiptGoods: Label 'Re-sent or receipt of goods after processing under contract, to the EU';
        XReturnReprocGoods: Label 'Returning reproc. goods back to the EU, where they were not accepted for process';
        XReturnGoodsBack: Label 'Returning the goods back to the recipient or sender processed under the contract';
        XDeliveriesJointDefense: Label 'Deliveries under joint defense projects or other joint intergov. prod. programs';
        XSuppliesBuildMatTechEquipWhole: Label 'Supplies of build. mat. and tech. eq., within delivery contract, for the whole';
        XReturnGoods80: Label 'Return of Goods Originally Reported with Transaction Code "80"';
        XReceiptDeliverySubst80: Label 'Receipt or delivery of goods deliv. by subs. originally reported with Code "80"';
        XImportExportGoodsWithConnection: Label 'Im/export of goods outside EU, with customs conn. outside CZ in another EU state';
        XRElocOwnPropertyByVatPers: Label 'Reloc. of own prop. to another member state EU, by person VAT reg. both U and O';
        XDelivGoodsWithoutChengeOwner: Label 'Deliv. of goods w/out change of owner to be used for sub. prod. or sale of goods';
        XTemporaryDelivery2Years: Label 'Temp. deliveries for more than 2 years w/out change of owner but for replacement';
        XTemporaryFreeDelivery2Years: Label 'Temporary free delivery for more than 2 years without change of owner';
        XOtherTransactions: Label 'Other transactions that cannot be marked with another code';

    procedure InsertData("Code": Code[10]; Description: Text[80])
    begin
        "Transaction Type".Init();
        "Transaction Type".Validate(Code, Code);
        "Transaction Type".Validate(Description, Description);
        "Transaction Type".Insert();
    end;
}

