codeunit 101594 "Create Close Opportunity Code"
{

    trigger OnRun()
    begin
        InsertData(XBUSINESSW, XKnowledgeofcustbusiness, 0);
        InsertData(XCONSULTW, XCompetentconsultant, 0);
        InsertData(XRELATIONW, XGoodcustomerrelations, 0);
        InsertData(XPRICEW, XBestprice, 0);
        InsertData(XPRODUCTW, XBestproduct, 0);
        InsertData(XPRESW, XStrongpresalework, 0);
        InsertData(XSALESREPW, XCompetentsalesperson, 0);
        InsertData(XBUSINESSL, XInadequateknowledgeofcust, 1);
        InsertData(XCONSULTL, XIneffectiveconsultant, 1);
        InsertData(XRELATIONL, XPoorcustomerrelations, 1);
        InsertData(XPRICEL, XOurproductwastooexpensive, 1);
        InsertData(XPRODUCTL, XCustomerchoseanotherproduct, 1);
        InsertData(XPRESL, XIneffectivepresalework, 1);
        InsertData(XSALESREPL, XAttitudeofsalesperson, 1);
        InsertData(XTIMEWSTL, XCustnotcommittedtodeal, 1);
        InsertData(XPOSTPNDL, XDealpostponedindefinitely, 1);
        InsertData(XWALKEDL, XWewalked, 1);
        InsertData(XCP, XClosedfromCommercePortal, 0);
    end;

    var
        "Close Opportunity Code": Record "Close Opportunity Code";
        XBUSINESSW: Label 'BUSINESS_W';
        XKnowledgeofcustbusiness: Label 'Knowledge of cust. business';
        XCONSULTW: Label 'CONSULT_W';
        XCompetentconsultant: Label 'Competent consultant';
        XRELATIONW: Label 'RELATION_W';
        XGoodcustomerrelations: Label 'Good customer relations';
        XPRICEW: Label 'PRICE_W';
        XBestprice: Label 'Best price';
        XPRODUCTW: Label 'PRODUCT_W';
        XBestproduct: Label 'Best product';
        XPRESW: Label 'PRES_W';
        XStrongpresalework: Label 'Strong presale work';
        XSALESREPW: Label 'SALESREP_W';
        XCompetentsalesperson: Label 'Competent salesperson';
        XBUSINESSL: Label 'BUSINESS_L';
        XInadequateknowledgeofcust: Label 'Inadequate knowledge of cust';
        XCONSULTL: Label 'CONSULT_L';
        XIneffectiveconsultant: Label 'Ineffective consultant';
        XRELATIONL: Label 'RELATION_L';
        XPoorcustomerrelations: Label 'Poor customer relations';
        XPRICEL: Label 'PRICE_L';
        XOurproductwastooexpensive: Label 'Our product was too expensive';
        XPRODUCTL: Label 'PRODUCT_L';
        XCustomerchoseanotherproduct: Label 'Customer chose another product';
        XPRESL: Label 'PRES_L';
        XIneffectivepresalework: Label 'Ineffective presale work';
        XSALESREPL: Label 'SALESREP_L';
        XAttitudeofsalesperson: Label 'Attitude of salesperson';
        XTIMEWSTL: Label 'TIMEWST_L';
        XCustnotcommittedtodeal: Label 'Cust. not committed to deal';
        XPOSTPNDL: Label 'POSTPND_L';
        XDealpostponedindefinitely: Label 'Deal postponed indefinitely';
        XWALKEDL: Label 'WALKED_L';
        XWewalked: Label 'We walked';
        XCP: Label 'CP';
        XClosedfromCommercePortal: Label 'Closed from Commerce Portal';

    procedure InsertData("Code": Code[10]; Description: Text[30]; Type: Option)
    begin
        "Close Opportunity Code".Init();
        "Close Opportunity Code".Validate(Code, Code);
        "Close Opportunity Code".Validate(Description, Description);
        "Close Opportunity Code".Validate(Type, Type);
        "Close Opportunity Code".Insert();
    end;
}

