codeunit 101038 "Create Purchase Header"
{

    trigger OnRun()
    begin
        InsertData(1, '20000', 19030102D, '5755', '', XxITVNPUR, '', 2284.63);//IT
        InsertData(1, '10000', 19030104D, '23047', '', XxITVNPUR, '', 12093.12);//IT
        InsertData(1, '10000', 19030107D, '23587', '', XxITVNPUR, '', 12197.32);//IT
        InsertData(1, '38458653', 19030110D, '45885', '', XxEXTVNPUR, '', 1760.0);//IT
        InsertData(1, '30000', 19030115D, '563', '', XxITVNPUR, '', 29011.2);//IT
        InsertData(1, '10000', 19030118D, '24521', '', XxITVNPUR, '', 23563.12);//IT
        InsertData(1, '20000', 19030123D, '5966', '', XxITVNPUR, '', 2034.4);//IT
        InsertData(1, '30000', 19030126D, '599', '', XxITVNPUR, '', 5410.08);//IT
        InsertData(1, '10000', 19030128D, '26874', '', XxITVNPUR, '', 1679.04);//IT
        InsertData(1, '47586622', 19030129D, XBTZ009, '', XxEXTVNPUR, '', 100789.3);//IT
        InsertData(1, '38654478', 19030129D, '43/3-66', '', XxEXTVNPUR, '', 14890.0);//IT
        InsertData(1, '01863656', 19030116D, XAWE1, '', XxEXTVNPUR, '', 123047); // IT
        InsertData(1, '01863656', 19030121D, XAWE2, '', XxEXTVNPUR, '', 1022.5); // IT
        InsertData(1, '43698547', 19030128D, '2265423', '', XxEUVNPUR, XxEUVNSLS, 12360);//IT
        InsertData(1, '44127914', 19020101D, '18051', XxWWBUSD, XxEUVNPUR, XxEUVNSLS, 30000);//IT
        InsertData(1, '44127914', 19020501D, '21152', XxWWBUSD, XxEUVNPUR, XxEUVNSLS, 42000);//IT
        InsertData(1, '44127914', 19020601D, '24057', XxWWBUSD, XxEUVNPUR, XxEUVNSLS, 15000);//IT
        InsertData(1, '44127904', 19020101D, '24365', XxWWBUSD, XxEUVNPUR, XxEUVNSLS, 6600);//IT
        InsertData(1, '44127904', 19020201D, '27116', XxWWBUSD, XxEUVNPUR, XxEUVNSLS, 4512);//IT
        InsertData(1, '44127904', 19020301D, '35211', XxWWBUSD, XxEUVNPUR, XxEUVNSLS, 3024);//IT
        InsertData(1, '44127904', 19020401D, '36668', XxWWBUSD, XxEUVNPUR, XxEUVNSLS, 3840);//IT
        InsertData(1, '44127904', 19020201D, '27117', XxWWBUSD, XxEUVNPUR, XxEUVNSLS, 7140);//IT
        InsertData(1, '46558855', 19030126D, '712001', '', XxEUVNPUR, XxEUVNSLS, 5887.38); // IT
        InsertData(1, '20000', 19030102D, '5756', '', XxITVNPUR, '', 6778.94);//IT
        // Add new orders here

        InsertData(2, '44127904', 19020130D, '25760', XxWWBUSD, XxEUVNPUR, XxEUVNSLS, 20000);//IT - These need to be date-ordered
        InsertData(2, '44127904', 19020228D, '35111', XxWWBUSD, XxEUVNPUR, XxEUVNSLS, 600);//IT
        InsertData(2, '44127904', 19020228D, '35112', XxWWBUSD, XxEUVNPUR, XxEUVNSLS, 400);//IT
        InsertData(2, '44127914', 19020228D, '20053', XxWWBUSD, XxEUVNPUR, XxEUVNSLS, 1200);//IT
        InsertData(2, '44127904', 19020430D, '37552', XxWWBUSD, XxEUVNPUR, XxEUVNSLS, 2000);//IT
        InsertData(2, '44127904', 19020531D, '38661', XxWWBUSD, XxEUVNPUR, XxEUVNSLS, 20000);//IT
        InsertData(2, '44127914', 19020531D, '24054', XxWWBUSD, XxEUVNPUR, XxEUVNSLS, 600);//IT
        InsertData(2, '44127914', 19020630D, '36455', XxWWBUSD, XxEUVNPUR, XxEUVNSLS, 400);//IT
        InsertDataSetVAT(2, '33299199', 19030122D, '123401', XBANKTxt, true, 1879.83);
        InsertDataSetVAT(2, '33299199', 19030122D, '123402', XBANKTxt, true, 563.95);
        InsertDataSetVAT(2, '33299199', 19030122D, '123403', XBANKTxt, true, 375.96);
        InsertDataSetVAT(2, '31580305', 19030122D, 'INV4444', XBANKTxt, true, 1127.89);
        InsertDataSetVAT(2, '32554455', 19030122D, 'REF9999', XBANKTxt, true, 939.91);
        InsertDataSetVAT(2, '33012999', 19030126D, '88888', XBANKTxt, true, 2255.78);
        InsertDataSetVAT(2, '49454647', 19030126D, '0000004444', XBANKTxt, true, 5639.46);
        InsertDataSetVAT(2, '43589632', 19030126D, 'BBB-555', XBANKTxt, true, 4699.55);
        // Add new invoices here

        InsertData(3, '30000', 19030112D, XKR950201, '', XxITVNPUR, '', 52680);//IT
        InsertData(3, '01863656', 19030125D, XxAWEC3, '', XxEXTVNPUR, '', 4637.2); // IT

        // Add new credit memos here
    end;

    var
        XxITVNPUR: Label 'IT-VN-PUR';
        XxEXTVNPUR: Label 'EXT-VN-PUR';
        XxEUVNPUR: Label 'EU-VN-PUR';
        XxEUVNSLS: Label 'EU-VN-SLS';
        XxWWBUSD: Label 'WWB-USD';
        XxAWEC3: Label 'AWE-C3';
        "Purchase Header": Record "Purchase Header";
        CA: Codeunit "Make Adjustments";
        XBTZ009: Label 'BTZ-009';
        XAWE1: Label 'AWE1';
        XAWE2: Label 'AWE2';
        XKR950201: Label 'KR95-02-01';
        XBANKTxt: Label 'BANK', Comment = 'Has to be translated exactly the same as global constant 1005 (XBANK) from COD101289 (Create Payment Method)';

    procedure InsertData("Document Type": Integer; "Buy-from Vendor No.": Code[20]; "Posting Date": Date; "Vendor Invoice No.": Code[20]; "Payment Method": Code[10]; "Operation Type": Code[20]; "Reverse Sales VAT No. Series": Code[10]; "Check Total": Decimal)
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

        //IT
        "Purchase Header".Validate("Operation Type", "Operation Type");
        "Purchase Header"."Operation Occurred Date" := CA.AdjustDate("Posting Date");
        "Purchase Header".Validate("Reverse Sales VAT No. Series", "Reverse Sales VAT No. Series");
        "Purchase Header"."Check Total" := "Check Total";
        //END IT

        "Purchase Header".Modify();
    end;

    local procedure InsertDataSetVAT(DocumentType: Integer; BuyFromVendorNo: Code[20]; PostingDate: Date; VendorInvoiceNo: Code[20]; PaymentMethod: Code[10]; InclVAT: Boolean; Total: Decimal)
    begin
        InsertData(DocumentType, BuyFromVendorNo, PostingDate, VendorInvoiceNo, PaymentMethod, XxEUVNPUR, '', Total);
        "Purchase Header".Validate("Prices Including VAT", InclVAT);
        "Purchase Header".Modify(true);
    end;
}

