codeunit 101036 "Create Sales Header"
{

    trigger OnRun()
    begin
        InsertData(1, '10000', 19030105D);
        InsertData(1, '01445544', 19030121D);
        InsertData(1, '32656565', 19030109D);
        InsertData(1, '20000', 19030111D);
        InsertData(1, '30000', 19030112D);
        InsertData(1, '49633663', 19030114D);
        InsertData(1, '20000', 19030116D);
        InsertData(1, '35451236', 19030118D);
        InsertData(1, '38128456', 19030120D);
        InsertData(1, '42147258', 19030113D);
        InsertData(1, '43687129', 19030113D);
        InsertData(1, '20000', 19030115D);
        InsertData(1, '46897889', 19030119D);
        InsertData(1, '47563218', 19030120D);
        InsertData(1, '49633663', 19030122D);
        InsertData(1, '10000', 19030126D);
        InsertData(1, '20000', 19030127D);
        InsertData(1, '01454545', 19030127D);
        InsertData(1, '31987987', 19030123D);
        InsertData(1, '32789456', 19030127D);
        InsertData(1, '35963852', 19030123D);
        InsertData(1, '38128456', 19030205D);
        InsertData(1, '30000', 19030222D);
        // Add new orders here

        InsertData(2, '10000', 19030123D);
        InsertData(2, '20000', 19030123D);
        InsertData(2, '30000', 19030123D);
        InsertData(2, '50000', 19030124D);
        InsertData(2, '49525252', 19030105D);
        InsertData(2, '49525252', 19030105D);
        InsertData(2, '49858585', 19030105D);
        InsertData(2, '49858585', 19030105D);
        InsertData(2, '49858585', 19030105D);
        InsertData(2, '49633663', 19030105D);
        InsertData(2, '43687129', 19030105D);
        InsertData(2, '43687129', 19030105D);
        InsertData(2, '43687129', 19030105D);
        InsertData(2, '49858585', 19030105D);
        // Add new invoices here

        InsertData(3, '10000', 19030115D);
        InsertData(3, '20000', 19030117D);
        InsertData(3, '20000', 19030120D);
        InsertData(3, '47563218', 19030127D);
        InsertData(3, '49633663', 19030120D);

        // Add new credit memos here
    end;

    var
        CurrencyExchRate: Record "Currency Exchange Rate";
        "Sales Header": Record "Sales Header";
        CA: Codeunit "Make Adjustments";
        i: Integer;
        "Date Displacement": Text[1];
        XEquip: Label 'Equip';
        XEquipment: Label 'Equipment';
        XVENDRET: Label 'VEND RET';
        XReturnstoVendors: Label 'Returns to Vendors';
        ReasonCode: Record "Reason Code";
        XCUSTRET: Label 'CUST RET';
        XReturnsfromCustomers: Label 'Returns from Customers';
        XVPMTDISC: Label 'V PMT DISC';
        XPaymentDiscounts: Label 'Payment Discounts';

    procedure InsertData("Document Type": Integer; "Sell-to Customer No.": Code[20]; "Posting Date": Date)
    begin
        Clear("Sales Header");
        "Sales Header".Validate("Document Type", "Document Type");
        "Sales Header".Validate("No.", '');
        "Sales Header"."Posting Date" := CA.AdjustDate("Posting Date");
        "Sales Header".Insert(true);
        "Sales Header".Validate("Sell-to Customer No.", "Sell-to Customer No.");
        "Sales Header".Validate("Posting Date");
        "Sales Header".Validate("Order Date", CA.AdjustDate("Posting Date"));
        "Sales Header".Validate("Shipment Date", CA.AdjustDate("Posting Date"));
        "Sales Header".Validate("Document Date", CA.AdjustDate("Posting Date"));
        "Sales Header"."Currency Factor" :=
          CurrencyExchRate.ExchangeRate(WorkDate(), "Sales Header"."Currency Code");

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

        if "Document Type" = 3 then begin
            ReasonCode.Init();
            ReasonCode.Code := XEquip;
            ReasonCode.Description := XEquipment;
            if not ReasonCode.Insert() then;
            ReasonCode.Init();
            ReasonCode.Code := XVENDRET;
            ReasonCode.Description := XReturnstoVendors;
            if not ReasonCode.Insert() then;
            ReasonCode.Init();
            ReasonCode.Code := XCUSTRET;
            ReasonCode.Description := XReturnsfromCustomers;
            if not ReasonCode.Insert() then;
            ReasonCode.Init();
            ReasonCode.Code := XVPMTDISC;
            ReasonCode.Description := XPaymentDiscounts;
            if not ReasonCode.Insert() then;

            "Sales Header".Validate("Reason Code", ReasonCode.Code);
            case "Sell-to Customer No." of
                '10000':
                    "Sales Header"."Adjustment Applies-to" := '00-1';
                '20000':
                    "Sales Header"."Adjustment Applies-to" := '00-2';
                '30000':
                    "Sales Header"."Adjustment Applies-to" := '00-4';
                '47563218':
                    "Sales Header"."Adjustment Applies-to" := '103014';
                '49633663':
                    "Sales Header"."Adjustment Applies-to" := '103011';
            end;
        end;

        "Sales Header".Modify();
    end;

    procedure SetPackage("Shipping Agent Code": Code[10]; "Package Tracking No.": Text[50])
    begin
        "Sales Header"."Shipping Agent Code" := "Shipping Agent Code";
        "Sales Header"."Package Tracking No." := "Package Tracking No.";
    end;
}
