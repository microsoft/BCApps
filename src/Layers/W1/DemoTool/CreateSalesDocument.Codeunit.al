codeunit 122002 "Create Sales Document"
{

    trigger OnRun()
    begin
    end;

    var
        CurrentSalesHeader: Record "Sales Header";
        CurrentSalesLine: Record "Sales Line";
        ThankYouForOrderingTxt: Label 'Thank you for ordering';

    procedure AddInvoiceHeader(CustomerNo: Code[20]; PostingDate: Date)
    begin
        CreateSalesHeader(
          CurrentSalesHeader, CurrentSalesHeader."Document Type"::Invoice, CustomerNo, PostingDate);
    end;

    procedure AddLine(ItemNo: Code[20]; Quantity: Decimal)
    begin
        CreateSalesLine(
          CurrentSalesLine, CurrentSalesHeader, CurrentSalesLine.Type::Item, ItemNo, Quantity);
    end;

    procedure AddGLAccountLine(GLAccountNo: Code[20]; Quantity: Decimal; UnitPrice: Decimal)
    begin
        CreateSalesLine(
          CurrentSalesLine, CurrentSalesHeader, CurrentSalesLine.Type::"G/L Account", GLAccountNo, Quantity);
        CurrentSalesLine.Validate("Unit Price", UnitPrice);
        CurrentSalesLine.Modify(true);
    end;

    procedure AddCommentLine(Comment: Text[50])
    begin
        CreateSalesLine(
          CurrentSalesLine, CurrentSalesHeader, CurrentSalesLine.Type::" ", '', 0);
        CurrentSalesLine.Validate(Description, Comment);
        CurrentSalesLine.Modify(true);
    end;

    procedure AddOrderHeader(CustomerNo: Code[20]; PostingDate: Date)
    begin
        CreateSalesHeader(
          CurrentSalesHeader, CurrentSalesHeader."Document Type"::Order, CustomerNo, PostingDate);
    end;

    procedure AddQuoteHeader(CustomerNo: Code[20]; PostingDate: Date)
    begin
        CreateSalesHeader(
          CurrentSalesHeader, CurrentSalesHeader."Document Type"::Quote, CustomerNo, PostingDate);
    end;

    procedure AddPaymentCodes(PaymentTermsCode: Code[10]; PaymentMethodCode: Code[10])
    begin
        CurrentSalesHeader.Validate("Payment Terms Code", PaymentTermsCode);
        CurrentSalesHeader.Validate("Payment Method Code", PaymentMethodCode);
        CurrentSalesHeader.Modify(true);
    end;

    local procedure CreateSalesHeader(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; CustomerNo: Code[20]; PostingDate: Date)
    var
        CurrencyExchRate: Record "Currency Exchange Rate";
        YourReference: Text[35];
    begin
        YourReference := SalesHeader."Your Reference"; // Passing a marker for processing filter
        SalesHeader.Init();
        SalesHeader.Validate("Document Type", DocumentType);
        SalesHeader."No." := '';
        SalesHeader."Posting Date" := PostingDate;
        SalesHeader."Your Reference" := YourReference;
        SalesHeader.Insert(true);
        SalesHeader.Validate("Sell-to Customer No.", CustomerNo);
        SalesHeader.Validate("Posting Date");
        SalesHeader.Validate("Document Date", PostingDate);
        SalesHeader.Validate("Shipment Date", CalcDate('<2D>', SalesHeader."Posting Date"));
        if SalesHeader."Document Type" = SalesHeader."Document Type"::Order then begin
            SalesHeader.Validate("Order Date", SalesHeader."Posting Date");
            SalesHeader.Validate("Requested Delivery Date", CalcDate('<1D>', SalesHeader."Posting Date"));
        end;
        SalesHeader."Currency Factor" := CurrencyExchRate.ExchangeRate(WorkDate(), SalesHeader."Currency Code");
        SalesHeader.Modify();
    end;

    local procedure CreateSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; Type: Enum "Sales Line Type"; No: Code[20]; Quantity: Decimal)
    var
        PrevDocNo: Code[20];
        LineNo: Integer;
    begin
        PrevDocNo := SalesLine."Document No.";
        LineNo := SalesLine."Line No.";
        SalesLine.Init();
        SalesLine.Validate("Document Type", SalesHeader."Document Type");
        SalesLine.Validate("Document No.", SalesHeader."No.");
        if PrevDocNo = SalesLine."Document No." then
            LineNo += 10000
        else
            LineNo := 10000;
        SalesLine.Validate("Line No.", LineNo);
        SalesLine.Validate(Type, Type);
        SalesLine.Validate("No.", No);
        if Quantity <> 0 then
            SalesLine.Validate(Quantity, Quantity);
        SalesLine.Insert();
        PrevDocNo := SalesLine."Document No.";
    end;

    procedure CreateOpenSalesDocuments(FromDate: Date; OpenDocMarker: Text[35])
    var
        CreateShippingAgentService: Codeunit "Create Shipping Agent Service";
    begin
        CurrentSalesHeader."Your Reference" := OpenDocMarker;
        AddInvoiceHeader('10000', CalcDate('<+3D>', FromDate));
        AddLine('1968-S', 5);
        AddLine('1996-S', 7);
        AddCommentLine(ThankYouForOrderingTxt);

        AddInvoiceHeader('10000', CalcDate('<+1M>', FromDate));
        AddLine('2000-S', 2);
        AddLine('1996-S', 5);

        AddInvoiceHeader('20000', CalcDate('<+2D>', FromDate));
        AddLine('1896-S', 1);

        AddInvoiceHeader('30000', CalcDate('<+4D>', FromDate));
        AddLine('1920-S', 4);

        AddInvoiceHeader('30000', CalcDate('<+6W>', FromDate));
        AddLine('1920-S', 10);

        AddInvoiceHeader('40000', CalcDate('<+1M>', FromDate));
        CreateShippingAgentService.AddFedExNextDayShippingAgentInfo(CurrentSalesHeader);
        AddLine('1928-S', 5);

        AddInvoiceHeader('50000', CalcDate('<+1D>', FromDate));
        CreateShippingAgentService.AddDHLOvernightShippingAgentInfo(CurrentSalesHeader);
        AddLine('1920-S', 4);
        AddLine('1936-S', 23);

        AddOrderHeader('10000', CalcDate('<+1D>', FromDate));
        CreateShippingAgentService.AddFedExNextDayShippingAgentInfo(CurrentSalesHeader);
        AddLine('1996-S', 12);

        AddOrderHeader('10000', CalcDate('<+1M>', FromDate));
        CreateShippingAgentService.AddFedExNextDayShippingAgentInfo(CurrentSalesHeader);
        AddLine('1968-S', 10);
        AddLine('1928-S', 7);

        AddOrderHeader('30000', CalcDate('<+3W>', FromDate));
        CreateShippingAgentService.AddDHLOvernightShippingAgentInfo(CurrentSalesHeader);
        AddLine('1920-S', 8);

        AddOrderHeader('40000', CalcDate('<+6W>', FromDate));
        CreateShippingAgentService.AddDHLOvernightShippingAgentInfo(CurrentSalesHeader);
        AddLine('2000-S', 3);

        AddQuoteHeader('20000', CalcDate('<+1D>', FromDate));
        AddLine('1936-S', 10);

        AddQuoteHeader('40000', CalcDate('<+2D>', FromDate));
        AddLine('2000-S', 5);
    end;

    procedure CreatePaidLateSalesDocuments(FromDate: Date; LateDocMarker: Text[35])
    begin
        CreateInvoice('10000', FromDate, 3, '1969-W', 5, 15, LateDocMarker);
        CreateInvoice('10000', FromDate, 4, '1965-W', 6, 5, LateDocMarker);
        CreateInvoice('10000', FromDate, 5, '1965-W', 11, 6, LateDocMarker);
        CreateInvoice('10000', FromDate, 10, '1953-W', 2, 4, LateDocMarker);
        CreateInvoice('10000', FromDate, 20, '1953-W', 23, 3, LateDocMarker);
        CreateInvoice('10000', FromDate, 30, '1965-W', 1, 2, LateDocMarker);

        CreateInvoice('20000', FromDate, 6, '1969-W', 2, 64, LateDocMarker);
        CreateInvoice('20000', FromDate, 11, '1965-W', 20, 1, LateDocMarker);
        CreateInvoice('20000', FromDate, 11, '1965-W', 4, 5, LateDocMarker);
        CreateInvoice('20000', FromDate, 20, '1953-W', 10, 2, LateDocMarker);
        CreateInvoice('20000', FromDate, 25, '1953-W', 14, 5, LateDocMarker);
        CreateInvoice('20000', FromDate, 30, '1965-W', 2, 17, LateDocMarker);

        CreateInvoice('30000', FromDate, 2, '1965-W', 4, 3, LateDocMarker);
        CreateInvoice('30000', FromDate, 5, '1965-W', 11, 8, LateDocMarker);

        CreateInvoice('40000', FromDate, 6, '1965-W', 20, 12, LateDocMarker);
        CreateInvoice('40000', FromDate, 11, '1965-W', 2, 6, LateDocMarker);
    end;

    local procedure CreateInvoice(CustomerNo: Code[20]; FromDate: Date; DueDateDays: Integer; ItemCode: Code[20]; ItemQuantity: Integer; DueDateDaysLate: Integer; LateDocMarker: Text[35])
    begin
        CurrentSalesHeader."Your Reference" := LateDocMarker;
        AddInvoiceHeader(CustomerNo, CalcDate('<+' + Format(DueDateDays) + 'D>', FromDate));
        AddLine(ItemCode, ItemQuantity);
        CreateInvoiceAndGenJnlLine(DueDateDaysLate);
    end;

    local procedure CreateInvoiceAndGenJnlLine(DaysLate: Integer)
    var
        CreateGenJournalLine: Codeunit "Create Gen. Journal Line";
    begin
        AddCommentLine(ThankYouForOrderingTxt);
        CreateGenJournalLine.CreateGenJnlLine(
          CurrentSalesHeader."No.", CalcDate('<+' + Format(DaysLate) + 'D>', CurrentSalesHeader."Due Date"),
          CurrentSalesHeader."Bill-to Customer No.");
    end;
}

