// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Test.ExternalFileStorage;

using System.ExternalFileStorage;
using System.Test.Integration.Sharepoint;
using System.TestLibraries.Integration.Sharepoint;
using System.TestLibraries.Utilities;

/// <summary>
/// Verifies that "Ext. SharePoint Connector Impl" dispatches to the right helper (REST or Graph)
/// based on the account's "Use legacy REST API" flag. All calls go through the connector — not the
/// helpers directly — so the dispatching logic itself is what gets tested. The [HttpClientHandler]
/// records which API family every outbound request hits: Graph calls go to graph.microsoft.com,
/// REST calls go to /_api/.
/// </summary>
codeunit 144587 "Ext. SharePoint Dispatch Test"
{
    Subtype = Test;
    TestHttpRequestPolicy = BlockOutboundRequests;
    TestPermissions = Disabled;

    var
        ConnectorImpl: Codeunit "Ext. SharePoint Connector Impl";
        GraphAuthMock: Codeunit "SharePoint Graph Auth Mock";
        DummySharePointAuthorization: Codeunit "Dummy SharePoint Authorization";
        Assert: Codeunit "Library Assert";
        HitGraphApi: Boolean;
        HitRestApi: Boolean;
        SharePointUrlLbl: Label 'https://contoso.sharepoint.com/sites/test', Locked = true;

    #region Tests

    [Test]
    [HandlerFunctions('DispatchHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TestConnectorDispatchesListFilesToGraphWhenLegacyRestIsFalse()
    var
        Account: Record "Ext. SharePoint Account";
        TempContent: Record "File Account Content" temporary;
        Pagination: Codeunit "File Pagination Data";
    begin
        // [GIVEN] An account with Use legacy REST API = false
        Initialize(Account, false);

        // [WHEN] Listing files through the connector
        ConnectorImpl.ListFiles(Account.Id, '', Pagination, TempContent);

        // [THEN] Traffic went to Graph only
        Assert.IsTrue(HitGraphApi, 'The connector should dispatch to the Graph helper');
        Assert.IsFalse(HitRestApi, 'The connector should not call the REST API');
    end;

    [Test]
    [HandlerFunctions('DispatchHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TestConnectorDispatchesListFilesToRestWhenLegacyRestIsTrue()
    var
        Account: Record "Ext. SharePoint Account";
        TempContent: Record "File Account Content" temporary;
        Pagination: Codeunit "File Pagination Data";
    begin
        // [GIVEN] An account with Use legacy REST API = true
        Initialize(Account, true);

        // [WHEN] Listing files through the connector
        ConnectorImpl.ListFiles(Account.Id, '', Pagination, TempContent);

        // [THEN] Traffic went to the REST API only
        Assert.IsTrue(HitRestApi, 'The connector should dispatch to the REST helper');
        Assert.IsFalse(HitGraphApi, 'The connector should not call the Graph API');
    end;

    [Test]
    [HandlerFunctions('DispatchHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TestConnectorDispatchesListDirectoriesToGraphWhenLegacyRestIsFalse()
    var
        Account: Record "Ext. SharePoint Account";
        TempContent: Record "File Account Content" temporary;
        Pagination: Codeunit "File Pagination Data";
    begin
        // [GIVEN] An account with Use legacy REST API = false
        Initialize(Account, false);

        // [WHEN] Listing directories through the connector
        ConnectorImpl.ListDirectories(Account.Id, '', Pagination, TempContent);

        // [THEN] Traffic went to Graph only
        Assert.IsTrue(HitGraphApi, 'The connector should dispatch directory listing to the Graph helper');
        Assert.IsFalse(HitRestApi, 'The connector should not call the REST API');
    end;

    [Test]
    [HandlerFunctions('DispatchHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TestConnectorDispatchesListDirectoriesToRestWhenLegacyRestIsTrue()
    var
        Account: Record "Ext. SharePoint Account";
        TempContent: Record "File Account Content" temporary;
        Pagination: Codeunit "File Pagination Data";
    begin
        // [GIVEN] An account with Use legacy REST API = true
        Initialize(Account, true);

        // [WHEN] Listing directories through the connector
        ConnectorImpl.ListDirectories(Account.Id, '', Pagination, TempContent);

        // [THEN] Traffic went to the REST API only
        Assert.IsTrue(HitRestApi, 'The connector should dispatch directory listing to the REST helper');
        Assert.IsFalse(HitGraphApi, 'The connector should not call the Graph API');
    end;

    [Test]
    [HandlerFunctions('DispatchHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TestConnectorDispatchesFileExistsToGraphWhenLegacyRestIsFalse()
    var
        Account: Record "Ext. SharePoint Account";
    begin
        // [GIVEN] An account with Use legacy REST API = false
        Initialize(Account, false);

        // [WHEN] Checking file existence through the connector
        ConnectorImpl.FileExists(Account.Id, 'file.txt');

        // [THEN] Traffic went to Graph only
        Assert.IsTrue(HitGraphApi, 'The connector should dispatch FileExists to the Graph helper');
        Assert.IsFalse(HitRestApi, 'The connector should not call the REST API');
    end;

    [Test]
    [HandlerFunctions('DispatchHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TestConnectorDispatchesFileExistsToRestWhenLegacyRestIsTrue()
    var
        Account: Record "Ext. SharePoint Account";
    begin
        // [GIVEN] An account with Use legacy REST API = true
        Initialize(Account, true);

        // [WHEN] Checking file existence through the connector
        ConnectorImpl.FileExists(Account.Id, 'file.txt');

        // [THEN] Traffic went to the REST API only
        Assert.IsTrue(HitRestApi, 'The connector should dispatch FileExists to the REST helper');
        Assert.IsFalse(HitGraphApi, 'The connector should not call the Graph API');
    end;

    #endregion

    #region HTTP Handler

    [HttpClientHandler]
    procedure DispatchHandler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    begin
        case true of
            Request.Path.Contains('graph.microsoft.com'):
                begin
                    HitGraphApi := true;
                    RespondAsGraph(Request, Response);
                end;
            Request.Path.Contains('/_api/'):
                begin
                    HitRestApi := true;
                    RespondAsRest(Request, Response);
                end;
            else
                Response.Content.WriteFrom('{}');
        end;
    end;

    local procedure RespondAsGraph(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage)
    begin
        case true of
            // Site discovery: /sites/hostname:/path: (no /drive, no /root)
            Request.Path.Contains('/sites/') and
                not Request.Path.Contains('/drive') and
                not Request.Path.Contains('/root'):
                Response.Content.WriteFrom('{"id":"test-site-id"}');
            // Drive discovery: /sites/{siteId}/drive
            Request.Path.Contains('/drive') and
                not Request.Path.Contains('/drives/') and
                not Request.Path.Contains('/root'):
                Response.Content.WriteFrom('{"id":"test-drive-id"}');
            else
                // Listing / item request
                Response.Content.WriteFrom('{"value":[{"id":"1","name":"file.txt","file":{},"size":10}],"id":"1","name":"file.txt","file":{},"size":10}');
        end;
    end;

    local procedure RespondAsRest(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage)
    begin
        case true of
            Request.Path.Contains('contextinfo') and (Request.RequestType = HttpRequestType::POST):
                Response.Content.WriteFrom('{"d":{"GetContextWebInformation":{"FormDigestValue":"fake-digest","FormDigestTimeoutSeconds":1800,"LibraryVersion":"16.0.0.0","SiteFullUrl":"https://contoso.sharepoint.com/sites/test","WebFullUrl":"https://contoso.sharepoint.com/sites/test"}}}');
            Request.Path.Contains('/Files') and (Request.RequestType = HttpRequestType::GET):
                Response.Content.WriteFrom('{"odata.metadata":"","value":[{"odata.type":"SP.File","UniqueId":"11111111-1111-1111-1111-111111111111","Name":"file.txt","ServerRelativeUrl":"/sites/test/file.txt","Length":"100"}]}');
            Request.Path.Contains('/Folders') and (Request.RequestType = HttpRequestType::GET):
                Response.Content.WriteFrom('{"odata.metadata":"","value":[{"odata.type":"SP.Folder","UniqueId":"22222222-2222-2222-2222-222222222222","Name":"SubFolder","ServerRelativeUrl":"/sites/test/SubFolder","ItemCount":0}]}');
            else
                Response.Content.WriteFrom('{}');
        end;
    end;

    #endregion

    #region Setup

    local procedure Initialize(var Account: Record "Ext. SharePoint Account"; UseLegacyRestAPI: Boolean)
    begin
        Clear(ConnectorImpl);
        ConnectorImpl.SetAuthorizationsForTest(GraphAuthMock, DummySharePointAuthorization);

        HitGraphApi := false;
        HitRestApi := false;

        Account.Init();
        Account.Id := CreateGuid();
        Account."SharePoint Url" := SharePointUrlLbl;
        Account."Tenant Id" := CreateGuid();
        Account."Client Id" := CreateGuid();
        Account."Authentication Type" := Enum::"Ext. SharePoint Auth Type"::"Client Secret";
        Account."Use legacy REST API" := UseLegacyRestAPI;
        Account.Insert();
    end;

    #endregion
}
