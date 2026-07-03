codeunit 122003 "Create Purchase Document"
{

    trigger OnRun()
    begin
    end;

    var
        CurrentPurchaseHeader: Record "Purchase Header";
        CurrentPurchaseLine: Record "Purchase Line";

    procedure AddInvoiceHeader(VendorNo: Code[20]; PostingDate: Date)
    begin
        CreatePurchaseHeader(
          CurrentPurchaseHeader, CurrentPurchaseHeader."Document Type"::Invoice, VendorNo, PostingDate);
    end;

    procedure AddLine(ItemNo: Code[20]; Quantity: Decimal)
    begin
        CreatePurchaseLine(
          CurrentPurchaseLine, CurrentPurchaseHeader, CurrentPurchaseLine.Type::Item,
          ItemNo, Quantity);
    end;

    procedure AddPaymentCodes(PaymentTermsCode: Code[10]; PaymentMethodCode: Code[10])
    begin
        CurrentPurchaseHeader.Validate("Payment Terms Code", PaymentTermsCode);
        CurrentPurchaseHeader.Validate("Payment Method Code", PaymentMethodCode);
        CurrentPurchaseHeader.Modify(true);
    end;

    procedure AddLocation(LocationCode: Code[10])
    begin
        CurrentPurchaseHeader.Validate("Location Code", LocationCode);
        CurrentPurchaseHeader.Modify(true);
    end;

    local procedure CreatePurchaseHeader(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; VendorNo: Code[20]; PostingDate: Date)
    var
        VendorInvoiceNo: Code[35];
        YourReference: Text[35];
    begin
        YourReference := PurchaseHeader."Your Reference";
        VendorInvoiceNo := PurchaseHeader."Vendor Invoice No.";
        PurchaseHeader.Init();
        PurchaseHeader.Validate("Document Type", DocumentType);
        PurchaseHeader."No." := '';
        PurchaseHeader."Posting Date" := PostingDate;
        PurchaseHeader."Your Reference" := YourReference;
        PurchaseHeader.Insert(true);
        PurchaseHeader.Validate("Buy-from Vendor No.", VendorNo);
        PurchaseHeader.Validate("Posting Date");
        PurchaseHeader.Validate("Document Date", PostingDate);
        if PurchaseHeader."Document Type" = PurchaseHeader."Document Type"::Order then begin
            PurchaseHeader.Validate("Order Date", PurchaseHeader."Posting Date");
            PurchaseHeader.Validate("Expected Receipt Date", PurchaseHeader."Posting Date" + 1);
        end;
        if DocumentType = PurchaseHeader."Document Type"::Order then
            PurchaseHeader.Validate("Vendor Invoice No.", VendorInvoiceNo)
        else
            PurchaseHeader.Validate("Vendor Invoice No.", PurchaseHeader."No.");
        PurchaseHeader.Modify();
    end;

    local procedure CreatePurchaseLine(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; Type: Enum "Purchase Line Type"; No: Code[20]; Quantity: Decimal)
    var
        PrevDocNo: Code[20];
        LineNo: Integer;
    begin
        PrevDocNo := PurchaseLine."Document No.";
        LineNo := PurchaseLine."Line No.";
        PurchaseLine.Init();
        PurchaseLine.Validate("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.Validate("Document No.", PurchaseHeader."No.");
        if PrevDocNo = PurchaseLine."Document No." then
            LineNo += 10000
        else
            LineNo := 10000;
        PurchaseLine.Validate("Line No.", LineNo);
        PurchaseLine.Validate(Type, Type);
        PurchaseLine.Validate("No.", No);
        PurchaseLine.Validate(Quantity, Quantity);
        PurchaseLine.Validate("Location Code", PurchaseHeader."Location Code");
        PurchaseLine.Insert();
        PrevDocNo := PurchaseLine."Document No.";
    end;

    procedure CreateOpenPurchDocuments(FromDate: Date; OpenDocMarker: Text[35])
    begin
        CurrentPurchaseHeader."Your Reference" := OpenDocMarker;
        AddInvoiceHeader('10000', CalcDate('<+1W>', FromDate));
        AddLine('1928-S', 5);

        AddInvoiceHeader('20000', CalcDate('<+9D>', FromDate));
        AddLine('1900-S', 5);
        AddLine('1964-S', 7);

        AddInvoiceHeader('30000', CalcDate('<+1M>', FromDate));
        AddLine('1968-S', 5);
        AddLine('1972-S', 9);
        AddLine('1996-S', 2);
    end;

    procedure CreatePurchaseOrders(FromDate: Date; OpenDocMarker: Text[35])
    begin
        CurrentPurchaseHeader."Your Reference" := OpenDocMarker;
        AddOrderHeader('10000', CalcDate('<+1W>', FromDate), '5755');
        AddLine('1896-S', 7);

        AddOrderHeader('20000', CalcDate('<+8D>', FromDate), '23047');
        AddLine('1964-S', 14);

        AddOrderHeader('40000', CalcDate('<+12D>', FromDate), 'D-304');
        AddLine('1900-S', 8);
        AddLine('1908-S', 20);
        AddLine('1906-S', 20);

        AddOrderHeader('30000', CalcDate('<+1M>', FromDate), '563');
        AddLine('1980-S', 10);
        AddLine('1996-S', 2);

        AddResourceOrder(FromDate);
    end;

    local procedure AddOrderHeader(VendorNo: Code[20]; PostingDate: Date; VendorInvoiceNo: Code[35])
    begin
        CurrentPurchaseHeader."Vendor Invoice No." := VendorInvoiceNo;
        CreatePurchaseHeader(
          CurrentPurchaseHeader, CurrentPurchaseHeader."Document Type"::Order, VendorNo, PostingDate);
    end;

    local procedure AddResourceLine(ResourceNo: Code[20]; Quantity: Decimal)
    begin
        CreatePurchaseLine(CurrentPurchaseLine, CurrentPurchaseHeader, CurrentPurchaseLine.Type::Resource, ResourceNo, Quantity);
    end;

    local procedure AddResourceOrder(FromDate: Date)
    var
        CreateJobResources: Codeunit "Create Job Resources";
    begin
        AddOrderHeader('50000', CalcDate('<+10D>', FromDate), 'V5-010');
        AddResourceLine(CreateJobResources.KatherineCode(), 4);
        AddResourceLine(CreateJobResources.MartyCode(), 8);
    end;
}

