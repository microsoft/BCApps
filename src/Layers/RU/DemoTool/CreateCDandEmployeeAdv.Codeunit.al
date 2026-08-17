codeunit 163403 "Create CD and Employee Adv."
{

    trigger OnRun()
    begin
        DemoSetup.Get();

        InsertCDHeader('10124090/140307/0001416', 19021030D, 'US', 2, XVLE + '013');
        InsertCDLine(10000, XITE + '-022', 59400);
        InsertCDLine(20000, XITE + '-023', 44900);
        InsertCDLine(30000, XITE + '-024', 10000);
        InsertCDLine(40000, XITE + '-025', 3000);

        InsertCDHeader('10124090/160107/0000157', 19021027D, 'US', 2, XVLE + '013');
        InsertCDLine(10000, XITE + '-022', 53600);
        InsertCDLine(20000, XITE + '-023', 36400);
        InsertCDLine(30000, XITE + '-024', 10900);
        InsertCDLine(40000, XITE + '-025', 3000);
        InsertCDLine(50000, XITE + '-026', 13676.9);

        InsertCDHeader('30000-01', 19030101D, 'BE', 2, '30000');
        InsertCDLine(10000, '70000', 0);
        InsertCDLine(20000, '70001', 0);
        InsertCDLine(30000, '70002', 0);
        InsertCDLine(40000, '70003', 0);

        InsertCDHeader('30000-02', 19030101D, 'CA', 2, '30000');
        InsertCDLine(10000, '70100', 0);
        InsertCDLine(20000, '70101', 0);
        InsertCDLine(30000, '70102', 0);
        InsertCDLine(40000, '70103', 0);

        // PurchaseHeader.Init();
        // PurchaseHeader."Document Type" := PurchaseHeader."Document Type"::Invoice;
        // PurchaseHeader."Empl. Purchase" := TRUE;
        // PurchaseHeader.VALIDATE("Buy-from Vendor No.",XMD);
        // PurchaseHeader.VALIDATE("Posting Date",DemoSetup."Working Date");
        // PurchaseHeader."Document Date" := DemoSetup."Working Date";
        // IF PurchaseHeader.INSERT(TRUE) THEN;
        // PurchaseHeader."Vendor Invoice No." := PurchaseHeader."No.";
        // PurchaseHeader.Modify();

        // PurchaseLine.Init();
        // PurchaseLine."Document Type" := PurchaseHeader."Document Type";
        // PurchaseLine."Document No." := PurchaseHeader."No.";
        // PurchaseLine."Line No." := 10000;
        // PurchaseLine.VALIDATE("Buy-from Vendor No.",PurchaseHeader."Buy-from Vendor No.");
        // PurchaseLine.Type := PurchaseLine.Type :: "Empl. Purchase";
        // PurchaseLine.VALIDATE("Empl. Purchase Vendor No.",'30000');

        // VendorLedgerEntry.Reset();
        // VendorLedgerEntry.SETRANGE("Vendor No.",PurchaseLine."Empl. Purchase Vendor No.");
        // VendorLedgerEntry.SETRANGE("Document Type",VendorLedgerEntry."Document Type"::Invoice);
        // VendorLedgerEntry.SETFILTER("Remaining Amount",'<%1',0);
        // IF VendorLedgerEntry.FindLast() then BEGIN
        //   PurchaseLine.VALIDATE("Empl. Purchase Entry No.",VendorLedgerEntry."Entry No.");
        //   IF VendorLedgerEntry."Posting Date" > PurchaseHeader."Posting Date" THEN
        //     PurchaseHeader.VALIDATE("Posting Date",VendorLedgerEntry."Posting Date");
        // END;
        // PurchaseLine.Insert();
        // PurchPost.RUN(PurchaseHeader);

        // PurchaseHeader.Init();
        // PurchaseHeader."Document Type" := PurchaseHeader."Document Type"::Invoice;
        // PurchaseHeader."Empl. Purchase" := TRUE;
        // PurchaseHeader.VALIDATE("Buy-from Vendor No.",XAH);
        // PurchaseHeader.VALIDATE("Posting Date", DemoSetup."Working Date");
        // PurchaseHeader."Document Date" := DemoSetup."Working Date";
        // IF PurchaseHeader.INSERT(TRUE) THEN;
        // PurchaseHeader."Vendor Invoice No." := PurchaseHeader."No.";
        // PurchaseHeader.Modify();

        // PurchaseLine.Init();
        // PurchaseLine."Document Type" := PurchaseHeader."Document Type";
        // PurchaseLine."Document No." := PurchaseHeader."No.";
        // PurchaseLine."Line No." := 10000;
        // PurchaseLine.VALIDATE("Buy-from Vendor No.",PurchaseHeader."Buy-from Vendor No.");
        // PurchaseLine.Type := PurchaseLine.Type :: "Empl. Purchase";
        // PurchaseLine.VALIDATE("Empl. Purchase Vendor No.",'10000');

        // VendorLedgerEntry.Reset();
        // VendorLedgerEntry.SETRANGE("Vendor No.",PurchaseLine."Empl. Purchase Vendor No.");
        // VendorLedgerEntry.SETRANGE("Document Type",VendorLedgerEntry."Document Type"::Invoice);
        // VendorLedgerEntry.SETFILTER("Remaining Amount",'<%1',0);
        // IF VendorLedgerEntry.FindLast() then BEGIN
        //   PurchaseLine.VALIDATE("Empl. Purchase Entry No.",VendorLedgerEntry."Entry No.");
        //   IF VendorLedgerEntry."Posting Date" > PurchaseHeader."Posting Date" THEN
        //     PurchaseHeader.VALIDATE("Posting Date",VendorLedgerEntry."Posting Date");
        // END;
        // PurchaseLine.Insert();
        // PurchPost.RUN(PurchaseHeader);

        // PurchaseHeader.Init();
        // PurchaseHeader."Document Type" := PurchaseHeader."Document Type" :: Invoice;
        // PurchaseHeader."Empl. Purchase" := TRUE;
        // PurchaseHeader.VALIDATE("Buy-from Vendor No.",XAH);
        // PurchaseHeader.VALIDATE("Posting Date", DemoSetup."Working Date");
        // PurchaseHeader."Document Date" := DemoSetup."Working Date";
        // IF PurchaseHeader.INSERT(TRUE) THEN;
        // PurchaseHeader."Vendor Invoice No." := PurchaseHeader."No.";
        // PurchaseHeader.Modify();

        // PurchaseLine.Init();
        // PurchaseLine."Document Type" := PurchaseHeader."Document Type";
        // PurchaseLine."Document No." := PurchaseHeader."No.";
        // PurchaseLine."Line No." := 10000;
        // PurchaseLine.VALIDATE("Buy-from Vendor No.",PurchaseHeader."Buy-from Vendor No.");
        // PurchaseLine.Type := PurchaseLine.Type :: "Empl. Purchase";
        // PurchaseLine.VALIDATE("Empl. Purchase Vendor No.",'10000');

        // VendorLedgerEntry.Reset();
        // VendorLedgerEntry.SETRANGE("Vendor No.",PurchaseLine."Empl. Purchase Vendor No.");
        // VendorLedgerEntry.SETRANGE("Document Type",VendorLedgerEntry."Document Type" :: Invoice);
        // VendorLedgerEntry.SETFILTER("Remaining Amount",'<%1',0);
        // IF VendorLedgerEntry.FindLast() then BEGIN
        //   PurchaseLine.VALIDATE("Empl. Purchase Entry No.",VendorLedgerEntry."Entry No.");
        //   IF VendorLedgerEntry."Posting Date" > PurchaseHeader."Posting Date" THEN
        //     PurchaseHeader.VALIDATE("Posting Date",VendorLedgerEntry."Posting Date");
        // END;
        // PurchaseLine.Insert();
    end;

    var
        DemoSetup: Record "Demo Data Setup";
        XVLE: Label 'VLE';
        XITE: Label 'ITE';

    procedure InsertCDHeader("Package No.": Code[30]; "CD Date": Date; "Country/Region of Origin Code": Code[10]; "Source Type": Integer; "Source No.": Code[20])
    begin
        /*
        BOEHeader.Init();
        BOEHeader."Custom Declaration No." := "Package No.";
        BOEHeader."Declaration Date" := CA.AdjustDate("CD Date");
        BOEHeader."Country/Region of Origin Code" := "Country/Region of Origin Code";
        BOEHeader."Source Type" := "Source Type";
        BOEHeader."Source No." := "Source No.";
        BOEHeader.Insert();
        */

    end;

    procedure InsertCDLine("Line No.": Integer; "Item No.": Code[20]; Quantity: Decimal)
    begin
        /*
        BOELine.Init();
        BOELine."Package No." := BOEHeader."Custom Declaration No.";
        BOELine."CD Line No." := "Line No.";
        BOELine.VALIDATE("Item No.","Item No.");
        BOELine.Quantity := Quantity;
        BOELine."Country/Region of Origin Code" := BOEHeader."Country/Region of Origin Code";
        BOELine.Insert();
        */

    end;
}

