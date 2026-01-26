codeunit 163554 "Create P. AdvLetter Appl. CZZ"
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        InsertData("Purchase Document Type"::Invoice, '10000', CalcDate('<+1D>', WorkDate()), 'NZ01220003', 1210.00, 'NF22/03');
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        MakeAdjustments: Codeunit "Make Adjustments";

    procedure InsertData(DocumentType: Enum "Purchase Document Type"; BuyFromVendorNo: Code[20]; PostingDate: Date; AdvanceLetterNo: Code[20]; LinkAmount: Decimal; VendorInvoiceNo: Code[35])
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        AdvanceLetterApplicationCZZ: Record "Advance Letter Application CZZ";
    begin
        PurchaseHeader.Init();
        PurchaseHeader."Document Type" := DocumentType;
        PurchaseHeader."No." := '';
        PurchaseHeader.Insert(true);
        PurchaseHeader.Validate("Buy-from Vendor No.", BuyFromVendorNo);
        PurchaseHeader.Validate("Posting Date", PostingDate);
        PurchaseHeader.Validate("Prices Including VAT", true);
        PurchaseHeader."Vendor Invoice No." := VendorInvoiceNo;
        PurchaseHeader.Modify();

        PurchaseLine.Init();
        PurchaseLine.Validate("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.Validate("Document No.", PurchaseHeader."No.");
        PurchaseLine.Validate("Line No.", 10000);
        PurchaseLine."Buy-from Vendor No." := BuyFromVendorNo;
        PurchaseLine.Validate(Type, PurchaseLine.Type::"G/L Account");
        PurchaseLine.Validate("No.", MakeAdjustments.Convert('998110'));
        PurchaseLine.Validate("VAT Prod. Posting Group", DemoDataSetup.BaseVATItemCode());
        PurchaseLine.Validate(Quantity, 1);
        PurchaseLine.Validate("Direct Unit Cost", LinkAmount);
        PurchaseLine.Insert();

        AdvanceLetterApplicationCZZ.Init();
        AdvanceLetterApplicationCZZ."Advance Letter Type" := "Advance Letter Type CZZ"::Purchase;
        AdvanceLetterApplicationCZZ."Advance Letter No." := AdvanceLetterNo;
        AdvanceLetterApplicationCZZ."Posting Date" := PostingDate;
        AdvanceLetterApplicationCZZ."Document Type" := "Adv. Letter Usage Doc.Type CZZ"::"Purchase Invoice";
        AdvanceLetterApplicationCZZ."Document No." := PurchaseHeader."No.";
        AdvanceLetterApplicationCZZ.Amount := PurchaseLine."Amount Including VAT";
        AdvanceLetterApplicationCZZ.Insert();
    end;
}
