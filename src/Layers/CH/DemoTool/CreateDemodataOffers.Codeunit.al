codeunit 161556 "Create Demodata Offers"
{

    trigger OnRun()
    begin
        CreateSalesQuotes();
    end;

    var
        Text11509: Label 'Office Equipment';
        Text11514: Label 'Variant:';
        Text11517: Label 'Meeting Room';
        Text11520: Label 'Add. Furniture, Meeting Room';
        Text11522: Label 'Equipment';
        Text11523: Label 'New Equipment for 4 Offices and Meeting Rooms';
        Text11524: Label 'Project: Mr. Schnider';
        Text11525: Label 'Office Equipment';
        Text11528: Label 'Thank you for your inquiry.';
        Text11530: Label 'Sales Department';
        Text11534: Label 'Purchasing Department';
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        QuoteMgt: Codeunit QuoteMgt;
        ArchiveManagement: Codeunit ArchiveManagement;
        SalesQuoteToOrder: Codeunit "Sales-Quote to Order";
        Counter: Integer;
        NextLineNo: Integer;

    procedure CreateSalesQuotes()
    begin
        CreateSalesHeader('10000', 20010104D, 50, '<+14D>', 0D, 0D);
        CreateSalesLine(SalesLine.Type::Title, '', Text11509, 0, 0, 0, false);
        CreateSalesLine(SalesLine.Type::Item, '1896-S', '', 2, 0, 5, false);
        CreateSalesLine(SalesLine.Type::Item, '1906-S', '', 2, 0, 0, false);
        CreateSalesLine(SalesLine.Type::Item, '1908-S', '', 1, 0, 5, false);
        CreateSalesLine(SalesLine.Type::Item, '1936-S', '', 1, 0, 5, false);
        CreateSalesLine(SalesLine.Type::" ", '', '', 0, 0, 0, false);
        CreateSalesLine(SalesLine.Type::Title, '', Text11514, 0, 0, 0, false);
        CreateSalesLine(SalesLine.Type::Item, '2000-S', '', 2, 0, 0, true);
        QuoteMgt.ReCalc(SalesHeader, false);

        CreateSalesHeader('40000', 20010110D, 65, '<+1M>', 20010120D, 0D);
        CreateSalesLine(SalesLine.Type::"Begin-Total", '', Text11517, 0, 0, 0, false);
        CreateSalesLine(SalesLine.Type::Item, '766BC-A', '', 1, 0, 0, false);
        CreateSalesLine(SalesLine.Type::Item, '766BC-C', '', 2, 0, 0, false);
        CreateSalesLine(SalesLine.Type::"End-Total", '', '', 0, 0, 0, false);
        CreateSalesLine(SalesLine.Type::" ", '', '', 0, 0, 0, false);
        CreateSalesLine(SalesLine.Type::"Begin-Total", '', Text11520, 0, 0, 0, false);
        CreateSalesLine(SalesLine.Type::Item, '70041', '', 2, 0, 0, false);
        CreateSalesLine(SalesLine.Type::Item, '1928-W', '', 4, 0, 0, false);
        CreateSalesLine(SalesLine.Type::"End-Total", '', '', 0, 0, 0, false);
        QuoteMgt.ReCalc(SalesHeader, false);
        ArchiveManagement.StoreSalesDocument(SalesHeader, false);

        CreateSalesHeader('40000', 20010110D, 35, '<+1M>', 20010120D, 0D);
        CreateSalesLine(SalesLine.Type::"Begin-Total", '', Text11517, 0, 0, 0, false);
        CreateSalesLine(SalesLine.Type::Item, '766BC-A', '', 1, 0, 0, false);
        CreateSalesLine(SalesLine.Type::Item, '766BC-C', '', 2, 0, 0, false);
        CreateSalesLine(SalesLine.Type::"End-Total", '', '', 0, 0, 0, false);
        CreateSalesLine(SalesLine.Type::" ", '', '', 0, 0, 0, false);
        CreateSalesLine(SalesLine.Type::"Begin-Total", '', Text11520, 0, 0, 0, false);
        CreateSalesLine(SalesLine.Type::Item, '70041', '', 2, 0, 0, true);
        CreateSalesLine(SalesLine.Type::Item, '1928-W', '', 4, 0, 0, true);
        CreateSalesLine(SalesLine.Type::"End-Total", '', '', 0, 0, 0, false);
        QuoteMgt.ReCalc(SalesHeader, false);

        CreateSalesHeader('20000', 20010120D, 95, '<+1M>', 20010120D, 0D);
        CreateSalesLine(SalesLine.Type::Title, '', Text11522, 0, 0, 0, false);
        CreateSalesLine(SalesLine.Type::" ", '', Text11523, 0, 0, 0, false);
        CreateSalesLine(SalesLine.Type::" ", '', Text11524, 0, 0, 0, false);
        CreateSalesLine(SalesLine.Type::" ", '', '', 0, 0, 0, false);
        CreateSalesLine(SalesLine.Type::"Begin-Total", '', Text11525, 0, 0, 0, false);
        CreateSalesLine(SalesLine.Type::Item, '766BC-B', '', 4, 0, 0, false);
        CreateSalesLine(SalesLine.Type::Title, '', Text11514, 0, 0, 0, false);
        CreateSalesLine(SalesLine.Type::Item, '2000-S', '', 4, 0, 0, true);
        CreateSalesLine(SalesLine.Type::Item, '1968-W', '', 2, 0, 0, false);
        CreateSalesLine(SalesLine.Type::Item, '1936-S', '', 4, 0, 0, false);
        CreateSalesLine(SalesLine.Type::"End-Total", '', '', 0, 0, 0, false);
        CreateSalesLine(SalesLine.Type::" ", '', '', 0, 0, 0, false);
        CreateSalesLine(SalesLine.Type::"Begin-Total", '', Text11517, 0, 0, 0, false);
        CreateSalesLine(SalesLine.Type::Item, '766BC-A', '', 1, 0, 0, false);
        CreateSalesLine(SalesLine.Type::Item, '766BC-C', '', 2, 0, 0, false);
        CreateSalesLine(SalesLine.Type::"End-Total", '', '', 0, 0, 0, false);
        CreateSalesLine(SalesLine.Type::" ", '', '', 0, 0, 0, false);
        CreateSalesLine(SalesLine.Type::" ", '', Text11528, 0, 0, 0, false);
        QuoteMgt.ReCalc(SalesHeader, false);

        CreateSalesHeader('30000', 20010104D, 85, '<+14D>', 0D, 0D);
        CreateSalesLine(SalesLine.Type::Title, '', Text11509, 0, 0, 0, false);
        CreateSalesLine(SalesLine.Type::" ", '', '', 0, 0, 0, false);
        CreateSalesLine(SalesLine.Type::"Begin-Total", '', Text11530, 0, 0, 0, false);
        CreateSalesLine(SalesLine.Type::Item, '1896-S', '', 6, 0, 10, false);
        CreateSalesLine(SalesLine.Type::Item, '1906-S', '', 6, 0, 10, false);
        CreateSalesLine(SalesLine.Type::Item, '1928-S', '', 6, 0, 10, false);
        CreateSalesLine(SalesLine.Type::Item, '2000-S', '', 6, 0, 10, false);
        CreateSalesLine(SalesLine.Type::Item, '1924-W', '', 4, 0, 5, false);
        CreateSalesLine(SalesLine.Type::Item, '1992-W', '', 2, 0, 5, false);
        CreateSalesLine(SalesLine.Type::"End-Total", '', '', 0, 0, 0, false);
        CreateSalesLine(SalesLine.Type::" ", '', '', 0, 0, 0, false);
        CreateSalesLine(SalesLine.Type::"Begin-Total", '', Text11534, 0, 0, 0, false);
        CreateSalesLine(SalesLine.Type::Item, '1896-S', '', 2, 0, 10, false);
        CreateSalesLine(SalesLine.Type::Item, '1964-S', '', 6, 0, 10, false);
        CreateSalesLine(SalesLine.Type::Item, '1928-S', '', 2, 0, 10, false);
        CreateSalesLine(SalesLine.Type::Item, '1908-S', '', 2, 0, 10, false);
        CreateSalesLine(SalesLine.Type::Item, '1924-W', '', 4, 0, 5, false);
        CreateSalesLine(SalesLine.Type::Item, '1984-W', '', 2, 0, 5, false);
        CreateSalesLine(SalesLine.Type::"End-Total", '', '', 0, 0, 0, false);
        QuoteMgt.ReCalc(SalesHeader, false);
        SalesQuoteToOrder.Run(SalesHeader);
    end;

    procedure CreateSalesHeader(CustomerNo: Code[20]; DocumentDate: Date; Probability: Integer; ExpectedOrderInflow: Code[20]; FollowupDate: Date; DecisionDate: Date)
    begin
        Clear(SalesHeader);
        SalesHeader.Init();
        SalesHeader.Insert(true);
        SalesHeader.Validate("Sell-to Customer No.", CustomerNo);
        SalesHeader.Validate("Document Date", DocumentDate);
        SalesHeader.Validate("Probability %", Probability);
        Evaluate(SalesHeader."Expected Order Inflow", ExpectedOrderInflow);
        SalesHeader.Validate("Expected Order Inflow");
        SalesHeader.Validate("Followup Date", FollowupDate);
        SalesHeader.Validate("Decision Date", DecisionDate);
        SalesHeader.Modify();

        NextLineNo := 0;

        Counter := Counter + 1;
    end;

    procedure CreateSalesLine(Type2: Enum "Sales Line Type"; No2: Code[20]; Description2: Text[50]; Quantity2: Integer; UnitPrice2: Decimal; Discount2: Decimal; QuoteVariant: Boolean)
    begin
        Clear(SalesLine);
        SalesLine.Init();
        SalesLine."Document Type" := SalesHeader."Document Type";
        SalesLine."Document No." := SalesHeader."No.";
        NextLineNo := NextLineNo + 10000;
        SalesLine."Line No." := NextLineNo;
        SalesLine.Validate(Type, Type2);
        if SalesLine.Type in [SalesLine.Type::"G/L Account", SalesLine.Type::Item, SalesLine.Type::Resource] then begin
            SalesLine.Validate("No.", No2);
            SalesLine.Validate(Quantity, Quantity2);
            if UnitPrice2 <> 0 then
                SalesLine.Validate("Unit Price", UnitPrice2);
            if Discount2 <> 0 then
                SalesLine.Validate("Line Discount %", Discount2);
            if QuoteVariant then
                SalesLine.Validate("Quote Variant", SalesLine."Quote Variant"::Variant);
        end else
            SalesLine.Description := Description2;
        SalesLine.Insert();
    end;
}

