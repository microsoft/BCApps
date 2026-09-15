codeunit 139928 "APIV2 - Purch. Ret. Shpts. E2E"
{
    // version Test,ERM,W1,All

    Subtype = Test;
    TestType = Uncategorized;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Graph] [Purchase] [Return Shipment]
    end;

    var
        Assert: Codeunit "Assert";
        LibraryGraphMgt: Codeunit "Library - Graph Mgt";
        LibraryPurchase: Codeunit "Library - Purchase";
        ServiceNameTxt: Label 'purchaseReturnShipments', Locked = true;

    [Test]
    procedure TestGetPurchaseReturnShipments()
    var
        ReturnShipmentHeader: Record "Return Shipment Header";
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [SCENARIO] Post a purchase return order and use GET to retrieve the resulting return shipment
        // [GIVEN] A posted purchase return shipment
        EnsurePurchaseReturnShipment(ReturnShipmentHeader);

        // [WHEN] we GET all purchase return shipments from the web service
        TargetURL := LibraryGraphMgt.CreateTargetURL('', Page::"APIV2 - Purch. Ret. Shpts.", ServiceNameTxt);
        LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);

        // [THEN] the response contains the purchase return shipment
        Assert.AreNotEqual('', ResponseText, 'Response JSON should not be blank');
    end;

    [Test]
    procedure TestExpandAttachments()
    var
        ReturnShipmentHeader: Record "Return Shipment Header";
        ResponseText: Text;
        TargetURL: Text;
        AttachmentsValue: Text;
    begin
        // [SCENARIO] GET a purchase return shipment with $expand=attachments
        // [GIVEN] A posted purchase return shipment
        EnsurePurchaseReturnShipment(ReturnShipmentHeader);

        // [WHEN] we GET the shipment with expanded attachments
        TargetURL := LibraryGraphMgt.CreateTargetURL(ReturnShipmentHeader.SystemId, Page::"APIV2 - Purch. Ret. Shpts.", ServiceNameTxt);
        TargetURL := AppendExpandToURL(TargetURL, 'attachments');
        LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);

        // [THEN] the response contains attachments
        Assert.AreNotEqual('', ResponseText, 'Response JSON should not be blank');
        LibraryGraphMgt.GetPropertyValueFromJSON(ResponseText, 'attachments', AttachmentsValue);
    end;

    [Test]
    procedure TestExpandDocumentAttachments()
    var
        ReturnShipmentHeader: Record "Return Shipment Header";
        ResponseText: Text;
        TargetURL: Text;
        DocumentAttachmentsValue: Text;
    begin
        // [SCENARIO] GET a purchase return shipment with $expand=documentAttachments
        // [GIVEN] A posted purchase return shipment
        EnsurePurchaseReturnShipment(ReturnShipmentHeader);

        // [WHEN] we GET the shipment with expanded documentAttachments
        TargetURL := LibraryGraphMgt.CreateTargetURL(ReturnShipmentHeader.SystemId, Page::"APIV2 - Purch. Ret. Shpts.", ServiceNameTxt);
        TargetURL := AppendExpandToURL(TargetURL, 'documentAttachments');
        LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);

        // [THEN] the response contains documentAttachments
        Assert.AreNotEqual('', ResponseText, 'Response JSON should not be blank');
        LibraryGraphMgt.GetPropertyValueFromJSON(ResponseText, 'documentAttachments', DocumentAttachmentsValue);
    end;

    [Test]
    procedure TestExpandPdfDocument()
    var
        ReturnShipmentHeader: Record "Return Shipment Header";
        ResponseText: Text;
        TargetURL: Text;
        PdfDocumentValue: Text;
    begin
        // [SCENARIO] GET a purchase return shipment with $expand=pdfDocument
        // [GIVEN] A posted purchase return shipment
        EnsurePurchaseReturnShipment(ReturnShipmentHeader);

        // [WHEN] we GET the shipment with expanded pdfDocument
        TargetURL := LibraryGraphMgt.CreateTargetURL(ReturnShipmentHeader.SystemId, Page::"APIV2 - Purch. Ret. Shpts.", ServiceNameTxt);
        TargetURL := AppendExpandToURL(TargetURL, 'pdfDocument');
        LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);

        // [THEN] the response contains pdfDocument
        Assert.AreNotEqual('', ResponseText, 'Response JSON should not be blank');
        LibraryGraphMgt.GetPropertyValueFromJSON(ResponseText, 'pdfDocument', PdfDocumentValue);
    end;

    local procedure EnsurePurchaseReturnShipment(var ReturnShipmentHeader: Record "Return Shipment Header")
    var
        PurchaseHeader: Record "Purchase Header";
        ShipmentNo: Code[20];
    begin
        if ReturnShipmentHeader.FindFirst() then
            exit;
        LibraryPurchase.CreatePurchaseReturnOrder(PurchaseHeader);
        ShipmentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        Commit();
        ReturnShipmentHeader.Get(ShipmentNo);
    end;

    local procedure AppendExpandToURL(TargetURL: Text; ExpandValue: Text): Text
    begin
        if StrPos(TargetURL, '?') <> 0 then
            exit(TargetURL + '&$expand=' + ExpandValue);
        exit(TargetURL + '?$expand=' + ExpandValue);
    end;
}
