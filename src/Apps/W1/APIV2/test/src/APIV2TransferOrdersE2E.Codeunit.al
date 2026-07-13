codeunit 139926 "APIV2 - Transfer Orders E2E"
{
    // version Test,ERM,W1,All

    Subtype = Test;
    TestType = Uncategorized;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Graph] [Inventory] [Transfer]
    end;

    var
        Assert: Codeunit "Assert";
        LibraryGraphMgt: Codeunit "Library - Graph Mgt";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        ServiceNameTxt: Label 'transferOrders', Locked = true;

    [Test]
    procedure TestGetTransferOrders()
    var
        TransferHeader: Record "Transfer Header";
        FromLocation: Record Location;
        ToLocation: Record Location;
        InTransitLocation: Record Location;
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [SCENARIO] Create a transfer order and use GET to retrieve it
        // [GIVEN] A transfer order
        LibraryWarehouse.CreateTransferLocations(FromLocation, ToLocation, InTransitLocation);
        LibraryWarehouse.CreateTransferHeader(TransferHeader, FromLocation.Code, ToLocation.Code, InTransitLocation.Code);
        Commit();

        // [WHEN] we GET all transfer orders from the web service
        TargetURL := LibraryGraphMgt.CreateTargetURL('', Page::"APIV2 - Transfer Orders", ServiceNameTxt);
        LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);

        // [THEN] the response contains the transfer order
        Assert.AreNotEqual('', ResponseText, 'Response JSON should not be blank');
    end;

    [Test]
    procedure TestGetTransferOrderById()
    var
        TransferHeader: Record "Transfer Header";
        FromLocation: Record Location;
        ToLocation: Record Location;
        InTransitLocation: Record Location;
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [SCENARIO] Create a transfer order and GET it by SystemId
        // [GIVEN] A transfer order
        LibraryWarehouse.CreateTransferLocations(FromLocation, ToLocation, InTransitLocation);
        LibraryWarehouse.CreateTransferHeader(TransferHeader, FromLocation.Code, ToLocation.Code, InTransitLocation.Code);
        Commit();

        // [WHEN] we GET the transfer order by SystemId
        TargetURL := LibraryGraphMgt.CreateTargetURL(TransferHeader.SystemId, Page::"APIV2 - Transfer Orders", ServiceNameTxt);
        LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);

        // [THEN] the response contains the transfer order with correct number
        Assert.AreNotEqual('', ResponseText, 'Response JSON should not be blank');
        LibraryGraphMgt.VerifyIDInJson(ResponseText);
    end;

    [Test]
    procedure TestExpandDimensionSetLines()
    var
        TransferHeader: Record "Transfer Header";
        FromLocation: Record Location;
        ToLocation: Record Location;
        InTransitLocation: Record Location;
        ResponseText: Text;
        TargetURL: Text;
        DimensionSetValue: Text;
    begin
        // [SCENARIO] GET a transfer order with $expand=dimensionSetLines
        // [GIVEN] A transfer order
        if not TransferHeader.FindFirst() then begin
            LibraryWarehouse.CreateTransferLocations(FromLocation, ToLocation, InTransitLocation);
            LibraryWarehouse.CreateTransferHeader(TransferHeader, FromLocation.Code, ToLocation.Code, InTransitLocation.Code);
            Commit();
        end;

        // [WHEN] we GET with expanded dimension set lines
        TargetURL := LibraryGraphMgt.CreateTargetURL(TransferHeader.SystemId, Page::"APIV2 - Transfer Orders", ServiceNameTxt);
        TargetURL := AppendExpandToURL(TargetURL, 'dimensionSetLines');
        LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);

        // [THEN] the response contains dimensionSetLines
        Assert.AreNotEqual('', ResponseText, 'Response JSON should not be blank');
        LibraryGraphMgt.GetPropertyValueFromJSON(ResponseText, 'dimensionSetLines', DimensionSetValue);
    end;

    [Test]
    procedure TestExpandAttachments()
    var
        TransferHeader: Record "Transfer Header";
        FromLocation: Record Location;
        ToLocation: Record Location;
        InTransitLocation: Record Location;
        ResponseText: Text;
        TargetURL: Text;
        AttachmentsValue: Text;
    begin
        // [SCENARIO] GET a transfer order with $expand=attachments
        // [GIVEN] A transfer order
        if not TransferHeader.FindFirst() then begin
            LibraryWarehouse.CreateTransferLocations(FromLocation, ToLocation, InTransitLocation);
            LibraryWarehouse.CreateTransferHeader(TransferHeader, FromLocation.Code, ToLocation.Code, InTransitLocation.Code);
            Commit();
        end;

        // [WHEN] we GET with expanded attachments
        TargetURL := LibraryGraphMgt.CreateTargetURL(TransferHeader.SystemId, Page::"APIV2 - Transfer Orders", ServiceNameTxt);
        TargetURL := AppendExpandToURL(TargetURL, 'attachments');
        LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);

        // [THEN] the response contains attachments
        Assert.AreNotEqual('', ResponseText, 'Response JSON should not be blank');
        LibraryGraphMgt.GetPropertyValueFromJSON(ResponseText, 'attachments', AttachmentsValue);
    end;

    [Test]
    procedure TestExpandDocumentAttachments()
    var
        TransferHeader: Record "Transfer Header";
        FromLocation: Record Location;
        ToLocation: Record Location;
        InTransitLocation: Record Location;
        ResponseText: Text;
        TargetURL: Text;
        DocumentAttachmentsValue: Text;
    begin
        // [SCENARIO] GET a transfer order with $expand=documentAttachments
        // [GIVEN] A transfer order
        if not TransferHeader.FindFirst() then begin
            LibraryWarehouse.CreateTransferLocations(FromLocation, ToLocation, InTransitLocation);
            LibraryWarehouse.CreateTransferHeader(TransferHeader, FromLocation.Code, ToLocation.Code, InTransitLocation.Code);
            Commit();
        end;

        // [WHEN] we GET with expanded documentAttachments
        TargetURL := LibraryGraphMgt.CreateTargetURL(TransferHeader.SystemId, Page::"APIV2 - Transfer Orders", ServiceNameTxt);
        TargetURL := AppendExpandToURL(TargetURL, 'documentAttachments');
        LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);

        // [THEN] the response contains documentAttachments
        Assert.AreNotEqual('', ResponseText, 'Response JSON should not be blank');
        LibraryGraphMgt.GetPropertyValueFromJSON(ResponseText, 'documentAttachments', DocumentAttachmentsValue);
    end;

    [Test]
    procedure TestExpandPdfDocument()
    var
        TransferHeader: Record "Transfer Header";
        FromLocation: Record Location;
        ToLocation: Record Location;
        InTransitLocation: Record Location;
        ResponseText: Text;
        TargetURL: Text;
        PdfDocumentValue: Text;
    begin
        // [SCENARIO] GET a transfer order with $expand=pdfDocument
        // [GIVEN] A transfer order
        if not TransferHeader.FindFirst() then begin
            LibraryWarehouse.CreateTransferLocations(FromLocation, ToLocation, InTransitLocation);
            LibraryWarehouse.CreateTransferHeader(TransferHeader, FromLocation.Code, ToLocation.Code, InTransitLocation.Code);
            Commit();
        end;

        // [WHEN] we GET with expanded pdfDocument
        TargetURL := LibraryGraphMgt.CreateTargetURL(TransferHeader.SystemId, Page::"APIV2 - Transfer Orders", ServiceNameTxt);
        TargetURL := AppendExpandToURL(TargetURL, 'pdfDocument');
        LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);

        // [THEN] the response contains pdfDocument
        Assert.AreNotEqual('', ResponseText, 'Response JSON should not be blank');
        LibraryGraphMgt.GetPropertyValueFromJSON(ResponseText, 'pdfDocument', PdfDocumentValue);
    end;

    [Test]
    procedure TestExpandLines()
    var
        TransferHeader: Record "Transfer Header";
        FromLocation: Record Location;
        ToLocation: Record Location;
        InTransitLocation: Record Location;
        ResponseText: Text;
        TargetURL: Text;
        LinesValue: Text;
    begin
        // [SCENARIO] GET a transfer order with $expand=transferOrderLines
        // [GIVEN] A transfer order
        if not TransferHeader.FindFirst() then begin
            LibraryWarehouse.CreateTransferLocations(FromLocation, ToLocation, InTransitLocation);
            LibraryWarehouse.CreateTransferHeader(TransferHeader, FromLocation.Code, ToLocation.Code, InTransitLocation.Code);
            Commit();
        end;

        // [WHEN] we GET with expanded transferOrderLines
        TargetURL := LibraryGraphMgt.CreateTargetURL(TransferHeader.SystemId, Page::"APIV2 - Transfer Orders", ServiceNameTxt);
        TargetURL := AppendExpandToURL(TargetURL, 'transferOrderLines');
        LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);

        // [THEN] the response contains transferOrderLines
        Assert.AreNotEqual('', ResponseText, 'Response JSON should not be blank');
        LibraryGraphMgt.GetPropertyValueFromJSON(ResponseText, 'transferOrderLines', LinesValue);
    end;

    local procedure AppendExpandToURL(TargetURL: Text; ExpandValue: Text): Text
    begin
        if StrPos(TargetURL, '?') <> 0 then
            exit(TargetURL + '&$expand=' + ExpandValue);
        exit(TargetURL + '?$expand=' + ExpandValue);
    end;
}
