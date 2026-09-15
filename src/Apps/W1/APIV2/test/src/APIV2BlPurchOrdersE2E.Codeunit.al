codeunit 139908 "APIV2 - Bl. Purch. Orders E2E"
{
    // version Test,ERM,W1,All

    Subtype = Test;
    TestType = Uncategorized;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Graph] [Purchase] [Blanket Order]
    end;

    var
        Assert: Codeunit "Assert";
        LibraryGraphMgt: Codeunit "Library - Graph Mgt";
        LibraryPurchase: Codeunit "Library - Purchase";
        ServiceNameTxt: Label 'blanketPurchaseOrders', Locked = true;

    [Test]
    procedure TestGetBlanketPurchaseOrders()
    var
        PurchaseHeader: Record "Purchase Header";
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [SCENARIO] Create a blanket purchase order and use GET to retrieve it
        // [GIVEN] A blanket purchase order
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Blanket Order", '');
        Commit();

        // [WHEN] we GET all blanket purchase orders from the web service
        TargetURL := LibraryGraphMgt.CreateTargetURL('', Page::"APIV2 - Bl. Purch. Orders", ServiceNameTxt);
        LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);

        // [THEN] the response contains the blanket purchase order
        Assert.AreNotEqual('', ResponseText, 'Response JSON should not be blank');
    end;

    [Test]
    procedure TestGetBlanketPurchaseOrderById()
    var
        PurchaseHeader: Record "Purchase Header";
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [SCENARIO] Create a blanket purchase order and GET it by SystemId
        // [GIVEN] A blanket purchase order
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Blanket Order", '');
        Commit();

        // [WHEN] we GET the blanket purchase order by SystemId
        TargetURL := LibraryGraphMgt.CreateTargetURL(PurchaseHeader.SystemId, Page::"APIV2 - Bl. Purch. Orders", ServiceNameTxt);
        LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);

        // [THEN] the response contains the blanket purchase order with correct number
        Assert.AreNotEqual('', ResponseText, 'Response JSON should not be blank');
        LibraryGraphMgt.VerifyIDInJson(ResponseText);
    end;

    [Test]
    procedure TestExpandDimensionSetLines()
    var
        PurchaseHeader: Record "Purchase Header";
        ResponseText: Text;
        TargetURL: Text;
        DimensionSetValue: Text;
    begin
        // [SCENARIO] GET a blanket purchase order with $expand=dimensionSetLines
        // [GIVEN] A blanket purchase order
        PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::"Blanket Order");
        if not PurchaseHeader.FindFirst() then begin
            LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Blanket Order", '');
            Commit();
        end;

        // [WHEN] we GET with expanded dimension set lines
        TargetURL := LibraryGraphMgt.CreateTargetURL(PurchaseHeader.SystemId, Page::"APIV2 - Bl. Purch. Orders", ServiceNameTxt);
        TargetURL := AppendExpandToURL(TargetURL, 'dimensionSetLines');
        LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);

        // [THEN] the response contains dimensionSetLines
        Assert.AreNotEqual('', ResponseText, 'Response JSON should not be blank');
        LibraryGraphMgt.GetPropertyValueFromJSON(ResponseText, 'dimensionSetLines', DimensionSetValue);
    end;

    [Test]
    procedure TestExpandAttachments()
    var
        PurchaseHeader: Record "Purchase Header";
        ResponseText: Text;
        TargetURL: Text;
        AttachmentsValue: Text;
    begin
        // [SCENARIO] GET a blanket purchase order with $expand=attachments
        // [GIVEN] A blanket purchase order
        PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::"Blanket Order");
        if not PurchaseHeader.FindFirst() then begin
            LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Blanket Order", '');
            Commit();
        end;

        // [WHEN] we GET with expanded attachments
        TargetURL := LibraryGraphMgt.CreateTargetURL(PurchaseHeader.SystemId, Page::"APIV2 - Bl. Purch. Orders", ServiceNameTxt);
        TargetURL := AppendExpandToURL(TargetURL, 'attachments');
        LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);

        // [THEN] the response contains attachments
        Assert.AreNotEqual('', ResponseText, 'Response JSON should not be blank');
        LibraryGraphMgt.GetPropertyValueFromJSON(ResponseText, 'attachments', AttachmentsValue);
    end;

    [Test]
    procedure TestExpandDocumentAttachments()
    var
        PurchaseHeader: Record "Purchase Header";
        ResponseText: Text;
        TargetURL: Text;
        DocumentAttachmentsValue: Text;
    begin
        // [SCENARIO] GET a blanket purchase order with $expand=documentAttachments
        // [GIVEN] A blanket purchase order
        PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::"Blanket Order");
        if not PurchaseHeader.FindFirst() then begin
            LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Blanket Order", '');
            Commit();
        end;

        // [WHEN] we GET with expanded documentAttachments
        TargetURL := LibraryGraphMgt.CreateTargetURL(PurchaseHeader.SystemId, Page::"APIV2 - Bl. Purch. Orders", ServiceNameTxt);
        TargetURL := AppendExpandToURL(TargetURL, 'documentAttachments');
        LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);

        // [THEN] the response contains documentAttachments
        Assert.AreNotEqual('', ResponseText, 'Response JSON should not be blank');
        LibraryGraphMgt.GetPropertyValueFromJSON(ResponseText, 'documentAttachments', DocumentAttachmentsValue);
    end;

    [Test]
    procedure TestExpandPdfDocument()
    var
        PurchaseHeader: Record "Purchase Header";
        ResponseText: Text;
        TargetURL: Text;
        PdfDocumentValue: Text;
    begin
        // [SCENARIO] GET a blanket purchase order with $expand=pdfDocument
        // [GIVEN] A blanket purchase order
        PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::"Blanket Order");
        if not PurchaseHeader.FindFirst() then begin
            LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Blanket Order", '');
            Commit();
        end;

        // [WHEN] we GET with expanded pdfDocument
        TargetURL := LibraryGraphMgt.CreateTargetURL(PurchaseHeader.SystemId, Page::"APIV2 - Bl. Purch. Orders", ServiceNameTxt);
        TargetURL := AppendExpandToURL(TargetURL, 'pdfDocument');
        LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);

        // [THEN] the response contains pdfDocument
        Assert.AreNotEqual('', ResponseText, 'Response JSON should not be blank');
        LibraryGraphMgt.GetPropertyValueFromJSON(ResponseText, 'pdfDocument', PdfDocumentValue);
    end;

    [Test]
    procedure TestExpandLines()
    var
        PurchaseHeader: Record "Purchase Header";
        ResponseText: Text;
        TargetURL: Text;
        LinesValue: Text;
    begin
        // [SCENARIO] GET a blanket purchase order with $expand=blanketPurchaseOrderLines
        // [GIVEN] A blanket purchase order
        PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::"Blanket Order");
        if not PurchaseHeader.FindFirst() then begin
            LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Blanket Order", '');
            Commit();
        end;

        // [WHEN] we GET with expanded blanketPurchaseOrderLines
        TargetURL := LibraryGraphMgt.CreateTargetURL(PurchaseHeader.SystemId, Page::"APIV2 - Bl. Purch. Orders", ServiceNameTxt);
        TargetURL := AppendExpandToURL(TargetURL, 'blanketPurchaseOrderLines');
        LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);

        // [THEN] the response contains blanketPurchaseOrderLines
        Assert.AreNotEqual('', ResponseText, 'Response JSON should not be blank');
        LibraryGraphMgt.GetPropertyValueFromJSON(ResponseText, 'blanketPurchaseOrderLines', LinesValue);
    end;

    local procedure AppendExpandToURL(TargetURL: Text; ExpandValue: Text): Text
    begin
        if StrPos(TargetURL, '?') <> 0 then
            exit(TargetURL + '&$expand=' + ExpandValue);
        exit(TargetURL + '?$expand=' + ExpandValue);
    end;
}
