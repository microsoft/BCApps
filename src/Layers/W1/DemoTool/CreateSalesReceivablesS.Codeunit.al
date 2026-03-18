codeunit 101311 "Create Sales & Receivables S."
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        "Sales & Receivables Setup".Get();
        "Sales & Receivables Setup".Validate("Shipment on Invoice", true);
        "Sales & Receivables Setup".Validate("Return Receipt on Credit Memo", true);
        "Sales & Receivables Setup".Validate("Discount Posting", "Sales & Receivables Setup"."Discount Posting"::"All Discounts");
        "Sales & Receivables Setup".Validate("Invoice Rounding", true);
        "Sales & Receivables Setup".Validate("Customer Group Dimension Code", XCUSTOMERGROUP);
        "Sales & Receivables Setup".Validate("Salesperson Dimension Code", XSALESPERSON);
        "Sales & Receivables Setup"."Copy Customer Name to Entries" := true;
        "Create No. Series".InitBaseSeries("Sales & Receivables Setup"."Customer Nos.", XCUST, XCustomer, XC10, XC99990, '', '', 10, Enum::"No. Series Implementation"::Sequence);
        "Create No. Series".InitTempSeries("Sales & Receivables Setup"."Quote Nos.", XSQUO, XSalesQuote);
        "Create No. Series".InitTempSeries("Sales & Receivables Setup"."Blanket Order Nos.", XSBLK, XBlanketSalesOrder);
        "Create No. Series".InitFinalSeries("Sales & Receivables Setup"."Order Nos.", XSORD, XSalesOrderexpired, 1);
        "Create No. Series".InitTempSeries("Sales & Receivables Setup"."Order Nos.", XSORD1, XSalesOrder, 1);
        "Create No. Series".InitTempSeries("Sales & Receivables Setup"."Order Nos.", XSORD2, XSalesOrder, 2);
        "Create No. Series".InsertRelation(XSORD1, XSORD2);
        "Create No. Series".InitTempSeries("Sales & Receivables Setup"."Return Order Nos.", XSRETORD, XSalesReturnOrder);
        "Create No. Series".InitFinalSeries("Sales & Receivables Setup"."Posted Shipment Nos.", XSSHPT, XSalesShipment, 2);
        "Create No. Series".InitTempSeries("Sales & Receivables Setup"."Invoice Nos.", XSINV, XSalesInvoice);
        "Create No. Series".InitFinalSeries("Sales & Receivables Setup"."Posted Invoice Nos.", XSINVplus, XPostedSalesInvoice, 3);
        "Create No. Series".InitFinalSeries("Sales & Receivables Setup"."Posted Prepmt. Inv. Nos.", XSPREINVplus, XPostedPrepaymentSalesCreditMemo, 3);
        "Create No. Series".InitTempSeries("Sales & Receivables Setup"."Credit Memo Nos.", XSCR, XSalesCreditMemo);
        "Create No. Series".InitFinalSeries("Sales & Receivables Setup"."Posted Return Receipt Nos.", XSRCPT, XPostedSalesReceipt, 7);
        "Create No. Series".InitFinalSeries("Sales & Receivables Setup"."Posted Credit Memo Nos.", XSCRPLUS, XPostedSalesCreditMemo, 4);
        "Create No. Series".InitFinalSeries("Sales & Receivables Setup"."Posted Prepmt. Cr. Memo Nos.", XSPRECRPLUS, XPostedSalesCreditMemo, 4);
        "Create No. Series".InitBaseSeries("Sales & Receivables Setup"."Price List Nos.", XSPL, XSalesPriceList, XS00001, XS99999, '', '', 1, Enum::"No. Series Implementation"::Sequence);
        "Create No. Series".InitTempSeries("Sales & Receivables Setup"."Reminder Nos.", XSREM, XReminder);
        "Create No. Series".InitFinalSeries("Sales & Receivables Setup"."Issued Reminder Nos.", XSREMPLUS, XIssuedReminder, 5);
        "Create No. Series".InitFinalSeries("Sales & Receivables Setup"."Canceled Issued Reminder Nos.", XSREMCPLUS, XCanceledIssuedReminder, 6);
        "Create No. Series".InitTempSeries("Sales & Receivables Setup"."Fin. Chrg. Memo Nos.", XSFIN, XFinanceChargeMemo);
        "Create No. Series".InitFinalSeries("Sales & Receivables Setup"."Issued Fin. Chrg. M. Nos.", XSFINPLUS, XIssuedFinanceChargeMemo, 6);
        "Create No. Series".InitFinalSeries("Sales & Receivables Setup"."Canc. Iss. Fin. Ch. Mem. Nos.", XSFINCPLUS, XCanceledIssuedFinanceChargeMemo, 7);
        "Create No. Series".InitTempSeries("Sales & Receivables Setup"."Direct Debit Mandate Nos.", XDDMTxt, XDirectDebitMandateTxt);
        "Sales & Receivables Setup"."Order Nos." := XSORD;
        "Sales & Receivables Setup"."Invoice Nos." := "Sales & Receivables Setup"."Posted Invoice Nos.";
        "Sales & Receivables Setup"."Credit Memo Nos." := "Sales & Receivables Setup"."Posted Credit Memo Nos.";
        "Sales & Receivables Setup"."Appln. between Currencies" := "Sales & Receivables Setup"."Appln. between Currencies"::All;
        "Sales & Receivables Setup"."Document Default Line Type" := "Sales & Receivables Setup"."Document Default Line Type"::Item;
        "Sales & Receivables Setup".Modify();
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        "Sales & Receivables Setup": Record "Sales & Receivables Setup";
        "Create No. Series": Codeunit "Create No. Series";
        XCUST: Label 'CUST';
        XCustomer: Label 'Customer';
        XC10: Label 'C10';
        XC99990: Label 'C99990';
        XDDMTxt: Label 'DDM', Comment = 'Direct Debit Mandate';
        XDirectDebitMandateTxt: Label 'Direct Debit Mandate';
        XSQUO: Label 'S-QUO';
        XSalesQuote: Label 'Sales Quote';
        XSBLK: Label 'S-BLK';
        XBlanketSalesOrder: Label 'Blanket Sales Order';
        XSORD: Label 'S-ORD';
        XSalesOrderexpired: Label 'Sales Order (expired)';
        XSORD1: Label 'S-ORD-1';
        XSalesOrder: Label 'Sales Order';
        XSORD2: Label 'S-ORD-2';
        XSRETORD: Label 'S-RETORD';
        XSalesReturnOrder: Label 'Sales Return Order';
        XSSHPT: Label 'S-SHPT';
        XSalesShipment: Label 'Sales Shipment';
        XSINV: Label 'S-INV';
        XSalesInvoice: Label 'Sales Invoice';
        XSINVplus: Label 'S-INV+';
        XPostedSalesInvoice: Label 'Posted Sales Invoice';
        XSPREINVplus: Label 'S-INV-P+';
        XSCR: Label 'S-CR';
        XSalesCreditMemo: Label 'Sales Credit Memo';
        XSRCPT: Label 'S-RCPT';
        XPostedSalesReceipt: Label 'Posted Sales Receipt';
        XSCRPLUS: Label 'S-CR+';
        XPostedSalesCreditMemo: Label 'Posted Sales Credit Memo';
        XSPRECRPLUS: Label 'S-CR-P+';
        XPostedPrepaymentSalesCreditMemo: Label 'Posted Prepayment Sales Credit Memo';
        XSPL: Label 'S-PL';
        XSalesPriceList: Label 'Sales Price List';
        XS00001: Label 'S00001';
        XS99999: Label 'S99999';
        XSREM: Label 'S-REM';
        XReminder: Label 'Reminder';
        XSREMPLUS: Label 'S-REM+';
        XIssuedReminder: Label 'Issued Reminder';
        XSREMCPLUS: Label 'S-REM-C+';
        XCanceledIssuedReminder: Label 'Canceled Issued Reminder';
        XSFIN: Label 'S-FIN';
        XFinanceChargeMemo: Label 'Finance Charge Memo';
        XSFINPLUS: Label 'S-FIN+';
        XIssuedFinanceChargeMemo: Label 'Issued Finance Charge Memo';
        XSFINCPLUS: Label 'S-FIN-C+';
        XCanceledIssuedFinanceChargeMemo: Label 'Canceled Issued Finance Charge Memo';
        XCUSTOMERGROUP: Label 'CUSTOMERGROUP';
        XSALESPERSON: Label 'SALESPERSON';

    procedure InsertMiniAppData()
    var
        CreateVATBusPostingGr: Codeunit "Create VAT Bus. Posting Gr.";
    begin
        DemoDataSetup.Get();
        "Sales & Receivables Setup".Get();
        "Sales & Receivables Setup".Validate("Discount Posting", "Sales & Receivables Setup"."Discount Posting"::"All Discounts");
        "Sales & Receivables Setup".Validate("Invoice Rounding", true);
        "Sales & Receivables Setup".Validate("Shipment on Invoice", true);
        "Sales & Receivables Setup"."Copy Customer Name to Entries" := true;
        "Create No. Series".InitBaseSeries("Sales & Receivables Setup"."Customer Nos.", XCUST, XCustomer, XC10, XC99990, '', '', 10, Enum::"No. Series Implementation"::Sequence);
        "Create No. Series".InitTempSeries("Sales & Receivables Setup"."Quote Nos.", XSQUO, XSalesQuote);
        "Create No. Series".InitFinalSeries("Sales & Receivables Setup"."Order Nos.", XSORD, XSalesOrder, 1);
        "Create No. Series".InitTempSeries("Sales & Receivables Setup"."Return Order Nos.", XSRETORD, XSalesReturnOrder);
        "Create No. Series".InitFinalSeries("Sales & Receivables Setup"."Posted Shipment Nos.", XSSHPT, XSalesShipment, 2);
        "Create No. Series".InitFinalSeries("Sales & Receivables Setup"."Posted Return Receipt Nos.", XSRCPT, XPostedSalesReceipt, 7);
        "Create No. Series".InitFinalSeries("Sales & Receivables Setup"."Invoice Nos.", XSINV, XSalesInvoice, 2);
        "Create No. Series".InitFinalSeries("Sales & Receivables Setup"."Posted Invoice Nos.", XSINVplus, XPostedSalesInvoice, 3);
        "Create No. Series".InitTempSeries("Sales & Receivables Setup"."Credit Memo Nos.", XSCR, XSalesCreditMemo);
        "Create No. Series".InitFinalSeries("Sales & Receivables Setup"."Posted Credit Memo Nos.", XSCRPLUS, XPostedSalesCreditMemo, 4);
        "Create No. Series".InitBaseSeries("Sales & Receivables Setup"."Price List Nos.", XSPL, XSalesPriceList, XS00001, XS99999, '', '', 1, Enum::"No. Series Implementation"::Sequence);
        "Create No. Series".InitTempSeries("Sales & Receivables Setup"."Reminder Nos.", XSREM, XReminder);
        "Create No. Series".InitFinalSeries("Sales & Receivables Setup"."Issued Reminder Nos.", XSREMPLUS, XIssuedReminder, 5);
        "Create No. Series".InitTempSeries("Sales & Receivables Setup"."Fin. Chrg. Memo Nos.", XSFIN, XFinanceChargeMemo);
        "Create No. Series".InitFinalSeries("Sales & Receivables Setup"."Issued Fin. Chrg. M. Nos.", XSFINPLUS, XIssuedFinanceChargeMemo, 6);
        "Create No. Series".InitTempSeries("Sales & Receivables Setup"."Blanket Order Nos.", XSBLK, XBlanketSalesOrder);
        "Sales & Receivables Setup"."Appln. between Currencies" := "Sales & Receivables Setup"."Appln. between Currencies"::All;
        "Sales & Receivables Setup"."Discount Posting" := "Sales & Receivables Setup"."Discount Posting"::"All Discounts";
        "Sales & Receivables Setup"."Stockout Warning" := true;
        "Sales & Receivables Setup"."VAT Bus. Posting Gr. (Price)" := CreateVATBusPostingGr.GetDomesticVATGroup();
        "Sales & Receivables Setup"."Document Default Line Type" := "Sales & Receivables Setup"."Document Default Line Type"::Item;
        "Sales & Receivables Setup".Modify();
    end;

    procedure Finalize()
    begin
        DemoDataSetup.Get();
        "Sales & Receivables Setup".Get();
        "Sales & Receivables Setup"."Invoice Nos." := XSINV;
        "Sales & Receivables Setup"."Credit Memo Nos." := XSCR;
        "Sales & Receivables Setup"."Order Nos." := XSORD1;
        "Sales & Receivables Setup"."Posted Prepmt. Inv. Nos." := XSINVplus;
        "Sales & Receivables Setup"."Posted Prepmt. Cr. Memo Nos." := XSCRPLUS;
        "Sales & Receivables Setup".Modify();
    end;
}

