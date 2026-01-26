codeunit 101036 "Create Sales Header"
{

    trigger OnRun()
    begin
        InsertData(1, '10000', 19030105D, '', false, '');
        InsertData(1, '01445544', 19030121D, '', false, '');
        InsertData(1, '32656565', 19030109D, '', false, '');
        InsertData(1, '20000', 19030111D, '', false, '');
        InsertData(1, '30000', 19030112D, '', false, '');
        InsertData(1, '49633663', 19030114D, '', false, '');
        InsertData(1, '20000', 19030116D, '', false, '');
        InsertData(1, '35451236', 19030118D, '', false, '');
        InsertData(1, '38128456', 19030120D, '', false, '');
        InsertData(1, '42147258', 19030113D, '', false, '');
        InsertData(1, '43687129', 19030113D, '', false, '');
        InsertData(1, '20000', 19030115D, '', false, '');
        InsertData(1, '46897889', 19030119D, '', false, '');
        InsertData(1, '47563218', 19030120D, '', false, '');
        InsertData(1, '49633663', 19030122D, '', false, '');
        InsertData(1, '10000', 19030126D, '', false, '');
        InsertData(1, '20000', 19030127D, '', false, '');
        InsertData(1, '01454545', 19030127D, '', false, '');
        InsertData(1, '31987987', 19030123D, '', false, '');
        InsertData(1, '32789456', 19030127D, '', false, '');
        InsertData(1, '35963852', 19030123D, '', false, '');
        InsertData(1, '38128456', 19030205D, '', false, '');
        InsertData(1, '30000', 19030222D, '', false, '');


        CreateINSalesOrders();
        // Add new orders here

        InsertData(2, '10000', 19030123D, '', false, '');
        InsertData(2, '20000', 19030123D, '', false, '');
        InsertData(2, '30000', 19030123D, '', false, '');
        InsertData(2, '50000', 19030124D, '', false, '');
        InsertData(2, '49525252', 19030105D, '', false, '');
        InsertData(2, '49525252', 19030105D, '', false, '');
        InsertData(2, '49858585', 19030105D, '', false, '');
        InsertData(2, '49858585', 19030105D, '', false, '');
        InsertData(2, '49858585', 19030105D, '', false, '');
        InsertData(2, '49633663', 19030105D, '', false, '');
        InsertData(2, '43687129', 19030105D, '', false, '');
        InsertData(2, '43687129', 19030105D, '', false, '');
        InsertData(2, '43687129', 19030105D, '', false, '');
        InsertData(2, '49858585', 19030105D, '', false, '');

        CreateINSalesInvoice();
        // Add new invoices here

        InsertData(3, '10000', 19030115D, '', false, '');
        InsertData(3, '20000', 19030117D, '', false, '');
        InsertData(3, '20000', 19030120D, '', false, '');
        InsertData(3, '47563218', 19030127D, '', false, '');
        InsertData(3, '49633663', 19030120D, '', false, '');
        CreateINSalesCrMemo();
        // Add new credit memos here
    end;

    var
        CurrencyExchRate: Record "Currency Exchange Rate";
        "Sales Header": Record "Sales Header";
        CA: Codeunit "Make Adjustments";
        i: Integer;
        "Date Displacement": Text[1];
        XINSALES: Label 'IN-SALES';

    procedure InsertData("Document Type": Integer; "Sell-to Customer No.": Code[20]; "Posting Date": Date; DocumentNo: Code[20]; TDSCert: Boolean; PostingNoSeries: Code[20])
    begin
        Clear("Sales Header");
        "Sales Header".Validate("Document Type", "Document Type");
        if DocumentNo = '' then
            "Sales Header".Validate("No.", '')
        else
            "Sales Header"."No." := DocumentNo;
        "Sales Header"."Posting Date" := CA.AdjustDate("Posting Date");
        "Sales Header".Insert(true);
        "Sales Header".Validate("Sell-to Customer No.", "Sell-to Customer No.");
        "Sales Header".Validate("Posting Date");
        "Sales Header".Validate("Order Date", CA.AdjustDate("Posting Date"));
        "Sales Header".Validate("Shipment Date", CA.AdjustDate("Posting Date"));
        "Sales Header".Validate("Document Date", CA.AdjustDate("Posting Date"));

        if "Sales Header"."No." = 'SI-0002' then
            "Sales Header"."Currency Code" := 'USD';

        "Sales Header"."Currency Factor" :=
          CurrencyExchRate.ExchangeRate(WorkDate(), "Sales Header"."Currency Code");

        if "Sales Header"."No." in ['SO-0001', 'SO-0002', 'SO-0003', 'SO-0004', 'SI-0001', 'SI-0002', 'SCM-1001', 'SCM-1002', 'SRO-1001', 'SRO-1002'] then
            if "Sales Header"."Currency Code" = '' then
                "Sales Header"."Currency Factor" := 0;

        if "Sales Header"."Shipping Agent Code" = '' then begin
            "Date Displacement" := CopyStr("Sales Header"."No.", StrLen("Sales Header"."No."), 1);
            if not ("Date Displacement" in ['1', '3', '5', '7', '9'])
            then begin // Not Partial Shipment (Set defined in CodeUnit 101901)
                i := i + 1;
                case i of
                    1:
                        SetPackage('DHL', '4561900081');
                    2:
                        SetPackage('UPS', '35505881957');
                    3:
                        SetPackage('DHL', '4515543524');
                    4:
                        SetPackage('UPS', '35531791111');
                    5:
                        SetPackage('DHL', '4561986030');
                    6:
                        SetPackage('UPS', '35531791102');
                    7:
                        SetPackage('DHL', '4363648774');
                    8:
                        SetPackage('DHL', '4457864736');
                    9:
                        SetPackage('DHL', '6040558366');
                    10:
                        SetPackage('DHL', '4430706862');
                    11:
                        SetPackage('DHL', '4327584111');
                    12:
                        SetPackage('DHL', '8321238321');
                    13:
                        SetPackage('DHL', '4490790441');
                end;
            end;
        end;

        if PostingNoSeries <> '' then
            "Sales Header"."Posting No. Series" := PostingNoSeries;

        "Sales Header"."TDS Certificate Receivable" := TDSCert;
        "Sales Header".Modify();
    end;

    procedure SetPackage("Shipping Agent Code": Code[10]; "Package Tracking No.": Text[50])
    begin
        "Sales Header"."Shipping Agent Code" := "Shipping Agent Code";
        "Sales Header"."Package Tracking No." := "Package Tracking No.";
    end;

    procedure CreateINSalesOrders()
    begin
        InsertData(1, '10000', 19030205D, 'SO-0001', false, XINSALES);
        InsertData(1, '30000', 19030205D, 'SO-0002', false, XINSALES);
        InsertData(1, '50000', 19030205D, 'SO-0003', false, XINSALES);
        InsertData(1, '50000', 19030205D, 'SO-0004', false, XINSALES);
    end;

    procedure CreateINSalesInvoice()
    begin
        InsertData(2, '20000', 19030205D, 'SI-0001', false, XINSALES);
        InsertData(2, '50000', 19030205D, 'SI-0002', false, XINSALES);
    end;

    procedure CreateINSalesCrMemo()
    begin
        InsertData(3, '10000', 19030120D, 'SCM-1001', false, '');
        InsertData(3, '10000', 19030127D, 'SCM-1002', false, '');
    end;
}
