codeunit 138401 "RS Pack Evaluation Api Setup"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [DEMO] [Evaluation] [Rapid Start] [Api Setup]
    end;

    var
        Assert: Codeunit Assert;

    [Test]
    [Scope('OnPrem')]
    procedure EntityTablesAreNotEmpty()
    begin
        VerifySalesQuoteEntityTable();
        VerifySalesInvoiceEntityTable();
        VerifySalesOrderEntityTable();
        VerifyPurchaseInvoiceEntityTable();
    end;

    local procedure VerifySalesQuoteEntityTable()
    var
        SalesQuoteEntityBuffer: Record "Sales Quote Entity Buffer";
        SalesHeader: Record "Sales Header";
    begin
        SalesQuoteEntityBuffer.SetRange("Document Type", SalesQuoteEntityBuffer."Document Type"::Quote);
        SalesQuoteEntityBuffer.FindSet();
        repeat
            SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Quote);
            SalesHeader.SetRange("No.", SalesQuoteEntityBuffer."No.");
            SalesHeader.SetRange(SystemId, SalesQuoteEntityBuffer.Id);
            Assert.RecordIsNotEmpty(SalesHeader);
        until SalesQuoteEntityBuffer.Next() = 0;
    end;

    local procedure VerifySalesInvoiceEntityTable()
    var
        SalesInvoiceEntityAggregate: Record "Sales Invoice Entity Aggregate";
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Invoice);
        SalesHeader.FindSet();
        repeat
            SalesInvoiceEntityAggregate.SetRange("Document Type", SalesInvoiceEntityAggregate."Document Type"::Invoice);
            SalesInvoiceEntityAggregate.SetRange("No.", SalesHeader."No.");
            SalesInvoiceEntityAggregate.SetRange(Id, SalesHeader.SystemId);
            Assert.RecordIsNotEmpty(SalesInvoiceEntityAggregate);
        until SalesHeader.Next() = 0;
    end;

    local procedure VerifySalesOrderEntityTable()
    var
        SalesOrderEntityBuffer: Record "Sales Order Entity Buffer";
        SalesHeader: Record "Sales Header";
    begin
        SalesOrderEntityBuffer.FindSet();
        repeat
            SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);
            SalesHeader.SetRange("No.", SalesOrderEntityBuffer."No.");
            SalesHeader.SetRange(SystemId, SalesOrderEntityBuffer.Id);
            Assert.RecordIsNotEmpty(SalesHeader);
        until SalesOrderEntityBuffer.Next() = 0;
    end;

    local procedure VerifyPurchaseInvoiceEntityTable()
    var
        PurchInvEntityAggregate: Record "Purch. Inv. Entity Aggregate";
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::Invoice);
        PurchaseHeader.FindSet();
        repeat
            PurchInvEntityAggregate.SetRange("Document Type", PurchInvEntityAggregate."Document Type"::Invoice);
            PurchInvEntityAggregate.SetRange("No.", PurchaseHeader."No.");
            PurchInvEntityAggregate.SetRange(Id, PurchaseHeader.SystemId);
            Assert.RecordIsNotEmpty(PurchInvEntityAggregate);
        until PurchaseHeader.Next() = 0;
    end;
}

