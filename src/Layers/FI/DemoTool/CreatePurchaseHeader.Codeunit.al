codeunit 101038 "Create Purchase Header"
{

    trigger OnRun()
    begin
        //+JK MSFI NAVISION 4.0 FI
        InsertData(1, '20000', 19030102D, '5755', '', 0, '577558');
        InsertData(1, '10000', 19030104D, '23047', '', 0, '230472');
        InsertData(1, '10000', 19030107D, '23587', '', 0, '235875');
        InsertData(1, '38458653', 19030110D, '45885', '', 0, '458856');
        InsertData(1, '30000', 19030115D, '563', '', 0, '5636');
        InsertData(1, '10000', 19030118D, '24521', '', 0, '245218');
        InsertData(1, '20000', 19030123D, '5966', '', 0, '59669');
        InsertData(1, '30000', 19030126D, '599', '', 0, '5995');
        InsertData(1, '10000', 19030128D, '26874', '', 0, '268745');
        InsertData(1, '47586622', 19030129D, XBTZ009, '', 2, 'XBTZ009');
        InsertData(1, '38654478', 19030129D, '43/3-66', '', 2, '43/3-66');
        InsertData(1, '01863656', 19030116D, XAWE1, '', 2, 'XAWE1');
        InsertData(1, '01863656', 19030121D, XAWE2, '', 2, 'XAWE2');
        InsertData(1, '43698547', 19030128D, '2265423', '', 0, '22654234');
        InsertData(1, '44127914', 19020101D, '18051', XGIRO, 0, '180519');
        InsertData(1, '44127914', 19020501D, '21152', XGIRO, 0, '211527');
        InsertData(1, '44127914', 19020601D, '24057', XGIRO, 0, '240572');
        InsertData(1, '44127904', 19020101D, '24365', XGIRO, 0, '243650');
        InsertData(1, '44127904', 19020201D, '27116', XGIRO, 0, '271169');
        InsertData(1, '44127904', 19020301D, '35211', XGIRO, 0, '352114');
        InsertData(1, '44127904', 19020401D, '36668', XGIRO, 0, '36689');
        InsertData(1, '44127904', 19020201D, '27117', XGIRO, 0, '271172');
        InsertData(1, '46558855', 19030126D, '712001', '', 0, '7120019');
        InsertData(1, '20000', 19030102D, '5756', '', 0, '577559');
        // Add new orders here

        InsertData(2, '44127904', 19020130D, '25760', XGIRO, 0, '257604');
        InsertData(2, '44127904', 19020228D, '35111', XGIRO, 0, '351115');
        InsertData(2, '44127904', 19020430D, '37552', XGIRO, 0, '375528');
        InsertData(2, '44127904', 19020531D, '38661', XGIRO, 0, '386614');
        InsertData(2, '44127904', 19020228D, '35112', XGIRO, 0, '351128');
        InsertData(2, '44127914', 19020228D, '20053', XGIRO, 0, '200538');
        InsertData(2, '44127914', 19020531D, '24054', XGIRO, 0, '240543');
        InsertData(2, '44127914', 19020630D, '36455', XGIRO, 0, '36455');
        InsertDataSetVAT(2, '33299199', 19030122D, '123401', XBANKTxt, true);
        InsertDataSetVAT(2, '33299199', 19030122D, '123402', XBANKTxt, true);
        InsertDataSetVAT(2, '33299199', 19030122D, '123403', XBANKTxt, true);
        InsertDataSetVAT(2, '31580305', 19030122D, 'INV4444', XBANKTxt, true);
        InsertDataSetVAT(2, '32554455', 19030122D, 'REF9999', XBANKTxt, true);
        InsertDataSetVAT(2, '33012999', 19030126D, '88888', XBANKTxt, true);
        InsertDataSetVAT(2, '49454647', 19030126D, '0000004444', XBANKTxt, true);
        InsertDataSetVAT(2, '43589632', 19030126D, 'BBB-555', XBANKTxt, true);
        // Add new invoices here

        InsertData(3, '30000', 19030112D, XKR950201, '', 0, '');
        InsertData(3, '01863656', 19030125D, 'AWE-C3', '', 0, '');
        // Add new credit memos here
    end;

    var
        "Purchase Header": Record "Purchase Header";
        CA: Codeunit "Make Adjustments";
        XBTZ009: Label 'BTZ-009';
        XAWE1: Label 'AWE1';
        XAWE2: Label 'AWE2';
        XGIRO: Label 'GIRO';
        XKR950201: Label 'KR95-02-01';
        XBANKTxt: Label 'BANK', Comment = 'Has to be translated exactly the same as global constant 1005 (XBANK) from COD101289 (Create Payment Method)';

    procedure InsertData("Document Type": Integer; "Buy-from Vendor No.": Code[20]; "Posting Date": Date; "Vendor Invoice No.": Code[20]; "Payment Method": Code[10]; "Message Type": Option; "Invoice Message": Text[250])
    begin
        Clear("Purchase Header");
        "Purchase Header".Validate("Document Type", "Document Type");
        "Purchase Header".Validate("No.", '');
        "Purchase Header"."Posting Date" := CA.AdjustDate("Posting Date");
        "Purchase Header".Insert(true);
        "Purchase Header".Validate("Buy-from Vendor No.", "Buy-from Vendor No.");
        "Purchase Header".Validate("Posting Date");
        "Purchase Header".Validate("Order Date", CA.AdjustDate("Posting Date"));
        "Purchase Header".Validate("Expected Receipt Date", CA.AdjustDate("Posting Date"));
        "Purchase Header".Validate("Document Date", CA.AdjustDate("Posting Date"));
        //+JK MSFI NAVISION 4.0 FI
        "Purchase Header"."Message Type" := "Message Type";
        "Purchase Header"."Invoice Message" := "Invoice Message";
        //-JK MSFI NAVISION 4.0 FI
        case "Document Type" of
            1:
                begin
                    "Purchase Header".Validate("Vendor Invoice No.", "Vendor Invoice No.");
                    "Purchase Header".Validate("Promised Receipt Date", "Purchase Header"."Expected Receipt Date");
                end;
            2:
                "Purchase Header".Validate("Vendor Invoice No.", "Vendor Invoice No.");
            3:
                "Purchase Header".Validate("Vendor Cr. Memo No.", "Vendor Invoice No.");
        end;

        if "Payment Method" <> '' then
            "Purchase Header".Validate("Payment Method Code", "Payment Method");

        "Purchase Header".Modify();
    end;

    local procedure InsertDataSetVAT(DocumentType: Integer; BuyFromVendorNo: Code[20]; PostingDate: Date; VendorInvoiceNo: Code[20]; PaymentMethod: Code[10]; InclVAT: Boolean)
    begin
        InsertData(DocumentType, BuyFromVendorNo, PostingDate, VendorInvoiceNo, PaymentMethod, 0, '36455');
        "Purchase Header".Validate("Prices Including VAT", InclVAT);
        "Purchase Header".Modify(true);
    end;
}

