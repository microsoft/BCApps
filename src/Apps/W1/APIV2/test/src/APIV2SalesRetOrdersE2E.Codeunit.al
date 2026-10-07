codeunit 139924 "APIV2 - Sales Ret. Orders E2E"
{
    // version Test,ERM,W1,All

    Subtype = Test;
    TestType = Uncategorized;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Graph] [Sales] [Return Order]
    end;

    var
        Assert: Codeunit "Assert";
        LibraryGraphMgt: Codeunit "Library - Graph Mgt";
        LibrarySales: Codeunit "Library - Sales";
        ServiceNameTxt: Label 'salesReturnOrders', Locked = true;

    [Test]
    procedure TestGetSalesReturnOrders()
    var
        SalesHeader: Record "Sales Header";
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [SCENARIO] Create a sales return order and use GET to retrieve it
        // [GIVEN] A sales return order
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", '');
        Commit();

        // [WHEN] we GET all sales return orders from the web service
        TargetURL := LibraryGraphMgt.CreateTargetURL('', Page::"APIV2 - Sales Ret. Orders", ServiceNameTxt);
        LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);

        // [THEN] the response contains the sales return order
        Assert.AreNotEqual('', ResponseText, 'Response JSON should not be blank');
    end;

    [Test]
    procedure TestGetSalesReturnOrderById()
    var
        SalesHeader: Record "Sales Header";
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [SCENARIO] Create a sales return order and GET it by SystemId
        // [GIVEN] A sales return order
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", '');
        Commit();

        // [WHEN] we GET the sales return order by SystemId
        TargetURL := LibraryGraphMgt.CreateTargetURL(SalesHeader.SystemId, Page::"APIV2 - Sales Ret. Orders", ServiceNameTxt);
        LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);

        // [THEN] the response contains the sales return order with correct number
        Assert.AreNotEqual('', ResponseText, 'Response JSON should not be blank');
        LibraryGraphMgt.VerifyIDInJson(ResponseText);
    end;

    [Test]
    procedure TestExpandDimensionSetLines()
    var
        SalesHeader: Record "Sales Header";
        ResponseText: Text;
        TargetURL: Text;
        DimensionSetValue: Text;
    begin
        // [SCENARIO] GET a sales return order with $expand=dimensionSetLines
        // [GIVEN] A sales return order
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::"Return Order");
        if not SalesHeader.FindFirst() then begin
            LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", '');
            Commit();
        end;

        // [WHEN] we GET with expanded dimension set lines
        TargetURL := LibraryGraphMgt.CreateTargetURL(SalesHeader.SystemId, Page::"APIV2 - Sales Ret. Orders", ServiceNameTxt);
        TargetURL := AppendExpandToURL(TargetURL, 'dimensionSetLines');
        LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);

        // [THEN] the response contains dimensionSetLines
        Assert.AreNotEqual('', ResponseText, 'Response JSON should not be blank');
        LibraryGraphMgt.GetPropertyValueFromJSON(ResponseText, 'dimensionSetLines', DimensionSetValue);
    end;

    [Test]
    procedure TestExpandAttachments()
    var
        SalesHeader: Record "Sales Header";
        ResponseText: Text;
        TargetURL: Text;
        AttachmentsValue: Text;
    begin
        // [SCENARIO] GET a sales return order with $expand=attachments
        // [GIVEN] A sales return order
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::"Return Order");
        if not SalesHeader.FindFirst() then begin
            LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", '');
            Commit();
        end;

        // [WHEN] we GET with expanded attachments
        TargetURL := LibraryGraphMgt.CreateTargetURL(SalesHeader.SystemId, Page::"APIV2 - Sales Ret. Orders", ServiceNameTxt);
        TargetURL := AppendExpandToURL(TargetURL, 'attachments');
        LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);

        // [THEN] the response contains attachments
        Assert.AreNotEqual('', ResponseText, 'Response JSON should not be blank');
        LibraryGraphMgt.GetPropertyValueFromJSON(ResponseText, 'attachments', AttachmentsValue);
    end;

    [Test]
    procedure TestExpandDocumentAttachments()
    var
        SalesHeader: Record "Sales Header";
        ResponseText: Text;
        TargetURL: Text;
        DocumentAttachmentsValue: Text;
    begin
        // [SCENARIO] GET a sales return order with $expand=documentAttachments
        // [GIVEN] A sales return order
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::"Return Order");
        if not SalesHeader.FindFirst() then begin
            LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", '');
            Commit();
        end;

        // [WHEN] we GET with expanded documentAttachments
        TargetURL := LibraryGraphMgt.CreateTargetURL(SalesHeader.SystemId, Page::"APIV2 - Sales Ret. Orders", ServiceNameTxt);
        TargetURL := AppendExpandToURL(TargetURL, 'documentAttachments');
        LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);

        // [THEN] the response contains documentAttachments
        Assert.AreNotEqual('', ResponseText, 'Response JSON should not be blank');
        LibraryGraphMgt.GetPropertyValueFromJSON(ResponseText, 'documentAttachments', DocumentAttachmentsValue);
    end;

    [Test]
    procedure TestExpandPdfDocument()
    var
        SalesHeader: Record "Sales Header";
        ResponseText: Text;
        TargetURL: Text;
        PdfDocumentValue: Text;
    begin
        // [SCENARIO] GET a sales return order with $expand=pdfDocument
        // [GIVEN] A sales return order
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::"Return Order");
        if not SalesHeader.FindFirst() then begin
            LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", '');
            Commit();
        end;

        // [WHEN] we GET with expanded pdfDocument
        TargetURL := LibraryGraphMgt.CreateTargetURL(SalesHeader.SystemId, Page::"APIV2 - Sales Ret. Orders", ServiceNameTxt);
        TargetURL := AppendExpandToURL(TargetURL, 'pdfDocument');
        LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);

        // [THEN] the response contains pdfDocument
        Assert.AreNotEqual('', ResponseText, 'Response JSON should not be blank');
        LibraryGraphMgt.GetPropertyValueFromJSON(ResponseText, 'pdfDocument', PdfDocumentValue);
    end;

    [Test]
    procedure TestExpandLines()
    var
        SalesHeader: Record "Sales Header";
        ResponseText: Text;
        TargetURL: Text;
        LinesValue: Text;
    begin
        // [SCENARIO] GET a sales return order with $expand=salesReturnOrderLines
        // [GIVEN] A sales return order
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::"Return Order");
        if not SalesHeader.FindFirst() then begin
            LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", '');
            Commit();
        end;

        // [WHEN] we GET with expanded salesReturnOrderLines
        TargetURL := LibraryGraphMgt.CreateTargetURL(SalesHeader.SystemId, Page::"APIV2 - Sales Ret. Orders", ServiceNameTxt);
        TargetURL := AppendExpandToURL(TargetURL, 'salesReturnOrderLines');
        LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);

        // [THEN] the response contains salesReturnOrderLines
        Assert.AreNotEqual('', ResponseText, 'Response JSON should not be blank');
        LibraryGraphMgt.GetPropertyValueFromJSON(ResponseText, 'salesReturnOrderLines', LinesValue);
    end;

    local procedure AppendExpandToURL(TargetURL: Text; ExpandValue: Text): Text
    begin
        if StrPos(TargetURL, '?') <> 0 then
            exit(TargetURL + '&$expand=' + ExpandValue);
        exit(TargetURL + '?$expand=' + ExpandValue);
    end;
}
