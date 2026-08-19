codeunit 139922 "APIV2 - Purch. Quotes E2E"
{
    // version Test,ERM,W1,All

    Subtype = Test;
    TestType = Uncategorized;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Graph] [Purchase] [Quote]
    end;

    var
        Assert: Codeunit "Assert";
        LibraryGraphMgt: Codeunit "Library - Graph Mgt";
        LibraryPurchase: Codeunit "Library - Purchase";
        ServiceNameTxt: Label 'purchaseQuotes', Locked = true;

    [Test]
    procedure TestGetPurchaseQuotes()
    var
        PurchaseHeader: Record "Purchase Header";
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [SCENARIO] Create a purchase quote and use GET to retrieve it
        // [GIVEN] A purchase quote
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Quote, '');
        Commit();

        // [WHEN] we GET all purchase quotes from the web service
        TargetURL := LibraryGraphMgt.CreateTargetURL('', Page::"APIV2 - Purch. Quotes", ServiceNameTxt);
        LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);

        // [THEN] the response contains the purchase quote
        Assert.AreNotEqual('', ResponseText, 'Response JSON should not be blank');
    end;

    [Test]
    procedure TestGetPurchaseQuoteById()
    var
        PurchaseHeader: Record "Purchase Header";
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [SCENARIO] Create a purchase quote and GET it by SystemId
        // [GIVEN] A purchase quote
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Quote, '');
        Commit();

        // [WHEN] we GET the purchase quote by SystemId
        TargetURL := LibraryGraphMgt.CreateTargetURL(PurchaseHeader.SystemId, Page::"APIV2 - Purch. Quotes", ServiceNameTxt);
        LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);

        // [THEN] the response contains the purchase quote with correct number
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
        // [SCENARIO] GET a purchase quote with $expand=dimensionSetLines
        // [GIVEN] A purchase quote
        PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::Quote);
        if not PurchaseHeader.FindFirst() then begin
            LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Quote, '');
            Commit();
        end;

        // [WHEN] we GET with expanded dimension set lines
        TargetURL := LibraryGraphMgt.CreateTargetURL(PurchaseHeader.SystemId, Page::"APIV2 - Purch. Quotes", ServiceNameTxt);
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
        // [SCENARIO] GET a purchase quote with $expand=attachments
        // [GIVEN] A purchase quote
        PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::Quote);
        if not PurchaseHeader.FindFirst() then begin
            LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Quote, '');
            Commit();
        end;

        // [WHEN] we GET with expanded attachments
        TargetURL := LibraryGraphMgt.CreateTargetURL(PurchaseHeader.SystemId, Page::"APIV2 - Purch. Quotes", ServiceNameTxt);
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
        // [SCENARIO] GET a purchase quote with $expand=documentAttachments
        // [GIVEN] A purchase quote
        PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::Quote);
        if not PurchaseHeader.FindFirst() then begin
            LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Quote, '');
            Commit();
        end;

        // [WHEN] we GET with expanded documentAttachments
        TargetURL := LibraryGraphMgt.CreateTargetURL(PurchaseHeader.SystemId, Page::"APIV2 - Purch. Quotes", ServiceNameTxt);
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
        // [SCENARIO] GET a purchase quote with $expand=pdfDocument
        // [GIVEN] A purchase quote
        PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::Quote);
        if not PurchaseHeader.FindFirst() then begin
            LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Quote, '');
            Commit();
        end;

        // [WHEN] we GET with expanded pdfDocument
        TargetURL := LibraryGraphMgt.CreateTargetURL(PurchaseHeader.SystemId, Page::"APIV2 - Purch. Quotes", ServiceNameTxt);
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
        // [SCENARIO] GET a purchase quote with $expand=purchaseQuoteLines
        // [GIVEN] A purchase quote
        PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::Quote);
        if not PurchaseHeader.FindFirst() then begin
            LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Quote, '');
            Commit();
        end;

        // [WHEN] we GET with expanded purchaseQuoteLines
        TargetURL := LibraryGraphMgt.CreateTargetURL(PurchaseHeader.SystemId, Page::"APIV2 - Purch. Quotes", ServiceNameTxt);
        TargetURL := AppendExpandToURL(TargetURL, 'purchaseQuoteLines');
        LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);

        // [THEN] the response contains purchaseQuoteLines
        Assert.AreNotEqual('', ResponseText, 'Response JSON should not be blank');
        LibraryGraphMgt.GetPropertyValueFromJSON(ResponseText, 'purchaseQuoteLines', LinesValue);
    end;

    local procedure AppendExpandToURL(TargetURL: Text; ExpandValue: Text): Text
    begin
        if StrPos(TargetURL, '?') <> 0 then
            exit(TargetURL + '&$expand=' + ExpandValue);
        exit(TargetURL + '?$expand=' + ExpandValue);
    end;
}
