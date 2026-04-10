codeunit 101851 "Create Item Charges"
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        InsertData(XJBFREIGHT, XFreightChargeJBSpedition, XGOODS20, XSERV20, false);
        InsertData(XPFREIGHT, XMiscFreightChargePurch, XGOODS20, XSERV20, false);
        InsertData(XPALLOWANCE, XPurchaseAllowance, XGOODS20, XSERV20, false);
        InsertData(XPRESTOCK, XPurchaseRestockCharge, XGOODS20, XSERV20, false);
        InsertData(XSFREIGHT, XMiscFreightChargesSales, XGOODS20, XSERV20, false);
        InsertData(XSALLOWANCE, XSalesAllowance, XGOODS20, XSERV20, false);
        InsertData(XSRESTOCK, XSalesRestockCharge, XGOODS20, XSERV20, false);

        InsertData(XCUSTDUTY, XCustomsDuties, XGOODS, XCUSTOMS, false);
        InsertData(XCUSTCHARGE, XCustomsDues, XGOODS, XCUSTOMS, false);
        InsertData(XTRANCHARGE, XTransportationExpenses, XMATMFG, XMAT20, false);
        InsertData(XEXCLTACOST, 'Exclude cost for TA', '', '', true);
        InsertData(XINCLTACOST, 'Include cost for TA', '', '', false);
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        XJBFREIGHT: Label 'JB-FREIGHT';
        XFreightChargeJBSpedition: Label 'Freight Charge (JB-Spedition)';
        XPFREIGHT: Label 'P-FREIGHT';
        XMiscFreightChargePurch: Label 'Misc. Freight Charge (Purch.)';
        XPALLOWANCE: Label 'P-ALLOWANCE';
        XPurchaseAllowance: Label 'Purchase Allowance';
        XPRESTOCK: Label 'P-RESTOCK';
        XPurchaseRestockCharge: Label 'Purchase Restock Charge';
        XSFREIGHT: Label 'S-FREIGHT';
        XMiscFreightChargesSales: Label 'Misc. Freight Charges (Sales)';
        XSALLOWANCE: Label 'S-ALLOWANCE';
        XSalesAllowance: Label 'Sales Allowance';
        XSRESTOCK: Label 'S-RESTOCK';
        XSalesRestockCharge: Label 'Sales Restock Charge';
        XCUSTDUTY: Label 'CUSTDUTY';
        XCUSTCHARGE: Label 'CUSTCHARGE';
        XTRANCHARGE: Label 'TRANCHARGE';
        XGOODS20: Label 'GOODS20', Comment = 'GOODS20';
        XSERV20: Label 'SERV20', Comment = 'SERV20';
        XGOODS: Label 'GOODS';
        XCUSTOMS: Label 'CUSTOMS';
        XMATMFG: Label 'MATMFG';
        XMAT20: Label 'MAT20', Comment = 'MAT20';
        XEXCLTACOST: Label 'EXCLTACOST';
        XINCLTACOST: Label 'INCLTACOST';
        XCustomsDuties: Label 'Customs duties';
        XCustomsDues: Label 'Customs dues';
        XTransportationExpenses: Label 'Transp. expenses';

    procedure InsertData(ItemChargeNo: Code[20]; Description: Text[50]; GenProdPostingGroup: Code[20]; TaxGroup: Code[10]; ExcludeCostForTA: Boolean)
    var
        ItemCharge: Record "Item Charge";
    begin
        ItemCharge.Init();
        ItemCharge."No." := ItemChargeNo;
        ItemCharge.Validate(Description, Description);
        ItemCharge.Validate("Gen. Prod. Posting Group", GenProdPostingGroup);
        if DemoDataSetup."Company Type" = DemoDataSetup."Company Type"::VAT then
            ItemCharge.Validate("VAT Prod. Posting Group", TaxGroup)
        else
            ItemCharge.Validate("Tax Group Code", TaxGroup);
        ItemCharge.Validate("Exclude Cost for TA", ExcludeCostForTA);
        ItemCharge.Insert();
    end;
}

