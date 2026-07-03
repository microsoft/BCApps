codeunit 139927 "APIV2 - Sales Ord. Arch. E2E"
{
    // version Test,ERM,W1,All

    Subtype = Test;
    TestType = Uncategorized;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Graph] [Sales] [Order] [Archive]
    end;

    var
        Assert: Codeunit "Assert";
        LibraryGraphMgt: Codeunit "Library - Graph Mgt";
        LibrarySales: Codeunit "Library - Sales";
        ArchiveManagement: Codeunit ArchiveManagement;
        ServiceNameTxt: Label 'salesOrderArchives', Locked = true;

    [Test]
    procedure TestGetSalesOrderArchives()
    var
        SalesHeaderArchive: Record "Sales Header Archive";
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [SCENARIO] Archive a sales order and use GET to retrieve the archive
        // [GIVEN] An archived sales order
        EnsureSalesOrderArchive(SalesHeaderArchive);

        // [WHEN] we GET all sales order archives from the web service
        TargetURL := LibraryGraphMgt.CreateTargetURL('', Page::"APIV2 - Sales Ord. Archives", ServiceNameTxt);
        LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);

        // [THEN] the response contains the sales order archive
        Assert.AreNotEqual('', ResponseText, 'Response JSON should not be blank');
    end;

    [Test]
    procedure TestExpandDimensionSetLines()
    var
        SalesHeaderArchive: Record "Sales Header Archive";
        ResponseText: Text;
        TargetURL: Text;
        DimensionSetValue: Text;
    begin
        // [SCENARIO] GET a sales order archive with $expand=dimensionSetLines
        // [GIVEN] An archived sales order
        EnsureSalesOrderArchive(SalesHeaderArchive);

        // [WHEN] we GET the archive with expanded dimensionSetLines
        TargetURL := LibraryGraphMgt.CreateTargetURL(SalesHeaderArchive.SystemId, Page::"APIV2 - Sales Ord. Archives", ServiceNameTxt);
        TargetURL := AppendExpandToURL(TargetURL, 'dimensionSetLines');
        LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);

        // [THEN] the response contains dimensionSetLines
        Assert.AreNotEqual('', ResponseText, 'Response JSON should not be blank');
        LibraryGraphMgt.GetPropertyValueFromJSON(ResponseText, 'dimensionSetLines', DimensionSetValue);
    end;

    [Test]
    procedure TestExpandAttachments()
    var
        SalesHeaderArchive: Record "Sales Header Archive";
        ResponseText: Text;
        TargetURL: Text;
        AttachmentsValue: Text;
    begin
        // [SCENARIO] GET a sales order archive with $expand=attachments
        // [GIVEN] An archived sales order
        EnsureSalesOrderArchive(SalesHeaderArchive);

        // [WHEN] we GET the archive with expanded attachments
        TargetURL := LibraryGraphMgt.CreateTargetURL(SalesHeaderArchive.SystemId, Page::"APIV2 - Sales Ord. Archives", ServiceNameTxt);
        TargetURL := AppendExpandToURL(TargetURL, 'attachments');
        LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);

        // [THEN] the response contains attachments
        Assert.AreNotEqual('', ResponseText, 'Response JSON should not be blank');
        LibraryGraphMgt.GetPropertyValueFromJSON(ResponseText, 'attachments', AttachmentsValue);
    end;

    [Test]
    procedure TestExpandDocumentAttachments()
    var
        SalesHeaderArchive: Record "Sales Header Archive";
        ResponseText: Text;
        TargetURL: Text;
        DocumentAttachmentsValue: Text;
    begin
        // [SCENARIO] GET a sales order archive with $expand=documentAttachments
        // [GIVEN] An archived sales order
        EnsureSalesOrderArchive(SalesHeaderArchive);

        // [WHEN] we GET the archive with expanded documentAttachments
        TargetURL := LibraryGraphMgt.CreateTargetURL(SalesHeaderArchive.SystemId, Page::"APIV2 - Sales Ord. Archives", ServiceNameTxt);
        TargetURL := AppendExpandToURL(TargetURL, 'documentAttachments');
        LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);

        // [THEN] the response contains documentAttachments
        Assert.AreNotEqual('', ResponseText, 'Response JSON should not be blank');
        LibraryGraphMgt.GetPropertyValueFromJSON(ResponseText, 'documentAttachments', DocumentAttachmentsValue);
    end;

    local procedure EnsureSalesOrderArchive(var SalesHeaderArchive: Record "Sales Header Archive")
    var
        SalesHeader: Record "Sales Header";
    begin
        if SalesHeaderArchive.FindFirst() then
            exit;
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        ArchiveManagement.ArchSalesDocumentNoConfirm(SalesHeader);
        Commit();
        SalesHeaderArchive.FindFirst();
    end;

    local procedure AppendExpandToURL(TargetURL: Text; ExpandValue: Text): Text
    begin
        if StrPos(TargetURL, '?') <> 0 then
            exit(TargetURL + '&$expand=' + ExpandValue);
        exit(TargetURL + '?$expand=' + ExpandValue);
    end;
}
