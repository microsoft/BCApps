codeunit 139925 "APIV2 - Assembly Orders E2E"
{
    // version Test,ERM,W1,All

    Subtype = Test;
    TestType = Uncategorized;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Graph] [Assembly] [Order]
    end;

    var
        Assert: Codeunit "Assert";
        LibraryGraphMgt: Codeunit "Library - Graph Mgt";
        LibraryAssembly: Codeunit "Library - Assembly";
        LibraryInventory: Codeunit "Library - Inventory";
        ServiceNameTxt: Label 'assemblyOrders', Locked = true;

    [Test]
    procedure TestGetAssemblyOrders()
    var
        AssemblyHeader: Record "Assembly Header";
        Item: Record Item;
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [SCENARIO] Create an assembly order and use GET to retrieve it
        // [GIVEN] An assembly order
        LibraryInventory.CreateItem(Item);
        LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, WorkDate(), Item."No.", '', 1, '');
        Commit();

        // [WHEN] we GET all assembly orders from the web service
        TargetURL := LibraryGraphMgt.CreateTargetURL('', Page::"APIV2 - Assembly Orders", ServiceNameTxt);
        LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);

        // [THEN] the response contains the assembly order
        Assert.AreNotEqual('', ResponseText, 'Response JSON should not be blank');
    end;

    [Test]
    procedure TestGetAssemblyOrderById()
    var
        AssemblyHeader: Record "Assembly Header";
        Item: Record Item;
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [SCENARIO] Create an assembly order and GET it by SystemId
        // [GIVEN] An assembly order
        LibraryInventory.CreateItem(Item);
        LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, WorkDate(), Item."No.", '', 1, '');
        Commit();

        // [WHEN] we GET the assembly order by SystemId
        TargetURL := LibraryGraphMgt.CreateTargetURL(AssemblyHeader.SystemId, Page::"APIV2 - Assembly Orders", ServiceNameTxt);
        LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);

        // [THEN] the response contains the assembly order with correct number
        Assert.AreNotEqual('', ResponseText, 'Response JSON should not be blank');
        LibraryGraphMgt.VerifyIDInJson(ResponseText);
    end;

    [Test]
    procedure TestExpandDimensionSetLines()
    var
        AssemblyHeader: Record "Assembly Header";
        Item: Record Item;
        ResponseText: Text;
        TargetURL: Text;
        DimensionSetValue: Text;
    begin
        // [SCENARIO] GET an assembly order with $expand=dimensionSetLines
        // [GIVEN] An assembly order
        if not AssemblyHeader.FindFirst() then begin
            LibraryInventory.CreateItem(Item);
            LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, WorkDate(), Item."No.", '', 1, '');
            Commit();
        end;

        // [WHEN] we GET with expanded dimension set lines
        TargetURL := LibraryGraphMgt.CreateTargetURL(AssemblyHeader.SystemId, Page::"APIV2 - Assembly Orders", ServiceNameTxt);
        TargetURL := AppendExpandToURL(TargetURL, 'dimensionSetLines');
        LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);

        // [THEN] the response contains dimensionSetLines
        Assert.AreNotEqual('', ResponseText, 'Response JSON should not be blank');
        LibraryGraphMgt.GetPropertyValueFromJSON(ResponseText, 'dimensionSetLines', DimensionSetValue);
    end;

    [Test]
    procedure TestExpandAttachments()
    var
        AssemblyHeader: Record "Assembly Header";
        Item: Record Item;
        ResponseText: Text;
        TargetURL: Text;
        AttachmentsValue: Text;
    begin
        // [SCENARIO] GET an assembly order with $expand=attachments
        // [GIVEN] An assembly order
        if not AssemblyHeader.FindFirst() then begin
            LibraryInventory.CreateItem(Item);
            LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, WorkDate(), Item."No.", '', 1, '');
            Commit();
        end;

        // [WHEN] we GET with expanded attachments
        TargetURL := LibraryGraphMgt.CreateTargetURL(AssemblyHeader.SystemId, Page::"APIV2 - Assembly Orders", ServiceNameTxt);
        TargetURL := AppendExpandToURL(TargetURL, 'attachments');
        LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);

        // [THEN] the response contains attachments
        Assert.AreNotEqual('', ResponseText, 'Response JSON should not be blank');
        LibraryGraphMgt.GetPropertyValueFromJSON(ResponseText, 'attachments', AttachmentsValue);
    end;

    [Test]
    procedure TestExpandDocumentAttachments()
    var
        AssemblyHeader: Record "Assembly Header";
        Item: Record Item;
        ResponseText: Text;
        TargetURL: Text;
        DocumentAttachmentsValue: Text;
    begin
        // [SCENARIO] GET an assembly order with $expand=documentAttachments
        // [GIVEN] An assembly order
        if not AssemblyHeader.FindFirst() then begin
            LibraryInventory.CreateItem(Item);
            LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, WorkDate(), Item."No.", '', 1, '');
            Commit();
        end;

        // [WHEN] we GET with expanded documentAttachments
        TargetURL := LibraryGraphMgt.CreateTargetURL(AssemblyHeader.SystemId, Page::"APIV2 - Assembly Orders", ServiceNameTxt);
        TargetURL := AppendExpandToURL(TargetURL, 'documentAttachments');
        LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);

        // [THEN] the response contains documentAttachments
        Assert.AreNotEqual('', ResponseText, 'Response JSON should not be blank');
        LibraryGraphMgt.GetPropertyValueFromJSON(ResponseText, 'documentAttachments', DocumentAttachmentsValue);
    end;

    [Test]
    procedure TestExpandPdfDocument()
    var
        AssemblyHeader: Record "Assembly Header";
        Item: Record Item;
        ResponseText: Text;
        TargetURL: Text;
        PdfDocumentValue: Text;
    begin
        // [SCENARIO] GET an assembly order with $expand=pdfDocument
        // [GIVEN] An assembly order
        if not AssemblyHeader.FindFirst() then begin
            LibraryInventory.CreateItem(Item);
            LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, WorkDate(), Item."No.", '', 1, '');
            Commit();
        end;

        // [WHEN] we GET with expanded pdfDocument
        TargetURL := LibraryGraphMgt.CreateTargetURL(AssemblyHeader.SystemId, Page::"APIV2 - Assembly Orders", ServiceNameTxt);
        TargetURL := AppendExpandToURL(TargetURL, 'pdfDocument');
        LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);

        // [THEN] the response contains pdfDocument
        Assert.AreNotEqual('', ResponseText, 'Response JSON should not be blank');
        LibraryGraphMgt.GetPropertyValueFromJSON(ResponseText, 'pdfDocument', PdfDocumentValue);
    end;

    [Test]
    procedure TestExpandLines()
    var
        AssemblyHeader: Record "Assembly Header";
        Item: Record Item;
        ResponseText: Text;
        TargetURL: Text;
        LinesValue: Text;
    begin
        // [SCENARIO] GET an assembly order with $expand=assemblyOrderLines
        // [GIVEN] An assembly order
        if not AssemblyHeader.FindFirst() then begin
            LibraryInventory.CreateItem(Item);
            LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, WorkDate(), Item."No.", '', 1, '');
            Commit();
        end;

        // [WHEN] we GET with expanded assemblyOrderLines
        TargetURL := LibraryGraphMgt.CreateTargetURL(AssemblyHeader.SystemId, Page::"APIV2 - Assembly Orders", ServiceNameTxt);
        TargetURL := AppendExpandToURL(TargetURL, 'assemblyOrderLines');
        LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);

        // [THEN] the response contains assemblyOrderLines
        Assert.AreNotEqual('', ResponseText, 'Response JSON should not be blank');
        LibraryGraphMgt.GetPropertyValueFromJSON(ResponseText, 'assemblyOrderLines', LinesValue);
    end;

    local procedure AppendExpandToURL(TargetURL: Text; ExpandValue: Text): Text
    begin
        if StrPos(TargetURL, '?') <> 0 then
            exit(TargetURL + '&$expand=' + ExpandValue);
        exit(TargetURL + '?$expand=' + ExpandValue);
    end;
}
