codeunit 163557 "Create S. AdvLetter Appl. CZZ"
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        InsertData("Sales Document Type"::Invoice, '10000', CalcDate('<+1D>', WorkDate()), 'PZ01220003', 1210.00);
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        MakeAdjustments: Codeunit "Make Adjustments";

    procedure InsertData(DocumentType: Enum "Sales Document Type"; SellToCustomerNo: Code[20]; PostingDate: Date; AdvanceLetterNo: Code[20]; LinkAmount: Decimal)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        AdvanceLetterApplicationCZZ: Record "Advance Letter Application CZZ";
    begin
        SalesHeader.Init();
        SalesHeader."Document Type" := DocumentType;
        SalesHeader."No." := '';
        SalesHeader.Insert(true);
        SalesHeader.Validate("Sell-to Customer No.", SellToCustomerNo);
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Validate("Prices Including VAT", true);
        SalesHeader.Modify();

        SalesLine.Init();
        SalesLine.Validate("Document Type", SalesHeader."Document Type");
        SalesLine.Validate("Document No.", SalesHeader."No.");
        SalesLine.Validate("Line No.", 10000);
        SalesLine."Sell-to Customer No." := SellToCustomerNo;
        SalesLine.Validate(Type, SalesLine.Type::"G/L Account");
        SalesLine.Validate("No.", MakeAdjustments.Convert('996440'));
        SalesLine.Validate("VAT Prod. Posting Group", DemoDataSetup.BaseVATItemCode());
        SalesLine.Validate(Quantity, 1);
        SalesLine.Validate("Unit Price", LinkAmount);
        SalesLine.Insert();

        AdvanceLetterApplicationCZZ.Init();
        AdvanceLetterApplicationCZZ."Advance Letter Type" := "Advance Letter Type CZZ"::Sales;
        AdvanceLetterApplicationCZZ."Advance Letter No." := AdvanceLetterNo;
        AdvanceLetterApplicationCZZ."Posting Date" := PostingDate;
        AdvanceLetterApplicationCZZ."Document Type" := "Adv. Letter Usage Doc.Type CZZ"::"Sales Invoice";
        AdvanceLetterApplicationCZZ."Document No." := SalesHeader."No.";
        AdvanceLetterApplicationCZZ.Amount := SalesLine."Amount Including VAT";
        AdvanceLetterApplicationCZZ.Insert();
    end;
}
