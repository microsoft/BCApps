codeunit 139103 "API Overview Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [API Overview]
    end;

    var
        Assert: Codeunit Assert;

    [Test]
    [Scope('OnPrem')]
    procedure TestAPIOverviewListsAPIPages()
    var
        APIOverview: TestPage "API Overview";
        FoundPage: Boolean;
    begin
        // [SCENARIO] The API Overview page lists API pages from the environment
        // [GIVEN] The API Overview page is opened
        APIOverview.OpenView();

        // [WHEN] Iterating the rows
        // [THEN] At least one row with Type = Page is present
        if APIOverview.First() then
            repeat
                if APIOverview."Object Type".Value() = 'Page' then begin
                    FoundPage := true;
                    break;
                end;
            until not APIOverview.Next();

        APIOverview.Close();
        Assert.IsTrue(FoundPage, 'Expected at least one API page in the API Overview');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAPIOverviewListsAPIQueries()
    var
        APIOverview: TestPage "API Overview";
        FoundQuery: Boolean;
    begin
        // [SCENARIO] The API Overview page lists API queries from the environment
        // [GIVEN] The API Overview page is opened
        APIOverview.OpenView();

        // [WHEN] Iterating the rows
        // [THEN] At least one row with Type = Query is present
        if APIOverview.First() then
            repeat
                if APIOverview."Object Type".Value() = 'Query' then begin
                    FoundQuery := true;
                    break;
                end;
            until not APIOverview.Next();

        APIOverview.Close();
        Assert.IsTrue(FoundQuery, 'Expected at least one API query in the API Overview');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAPIOverviewIncludesKnownAPIPage()
    var
        APIOverview: TestPage "API Overview";
        Found: Boolean;
    begin
        // [SCENARIO] A well-known base-app API page is shown with the right publisher, group, version, entity name and URL
        // [GIVEN] The API Overview page is opened
        APIOverview.OpenView();

        // [WHEN] Locating the Posted Sales Invoice API row
        if APIOverview.First() then
            repeat
                if (APIOverview."Object Type".Value() = 'Page') and (APIOverview.Description.Value() = 'Posted Sales Invoice API') then begin
                    Found := true;
                    break;
                end;
            until not APIOverview.Next();

        // [THEN] The row exposes the page's publisher, group, version, entity name and API URL
        Assert.IsTrue(Found, 'Expected Posted Sales Invoice API in the API Overview');
        Assert.AreEqual('microsoft', APIOverview."API Publisher".Value(), 'Unexpected API publisher for Posted Sales Invoice API');
        Assert.AreEqual('automate', APIOverview."API Group".Value(), 'Unexpected API group for Posted Sales Invoice API');
        Assert.AreEqual('v1.0', APIOverview."API Version".Value(), 'Unexpected API version for Posted Sales Invoice API');
        Assert.AreEqual('postedSalesInvoice', APIOverview."Entity Name".Value(), 'Unexpected entity name for Posted Sales Invoice API');
        Assert.IsTrue(APIOverview."API URL".Value().Contains('/api/microsoft/automate/v1.0/'), 'Unexpected API URL for Posted Sales Invoice API');
        APIOverview.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAPIOverviewBuildsStandardApiUrl()
    var
        APIOverview: TestPage "API Overview";
        Found: Boolean;
    begin
        // [SCENARIO] A standard v2.0 API page shows a URL that follows the /api/v2.0/ route
        // [GIVEN] The API Overview page is opened
        APIOverview.OpenView();

        // [WHEN] Locating a standard v2.0 API page (blank publisher and group, version v2.0)
        if APIOverview.First() then
            repeat
                if (APIOverview."Object Type".Value() = 'Page') and (APIOverview."API Publisher".Value() = '') and (APIOverview."API Group".Value() = '') and (APIOverview."API Version".Value() = 'v2.0') then begin
                    Found := true;
                    break;
                end;
            until not APIOverview.Next();

        // [THEN] The URL follows the standard /api/v2.0/ route (no publisher or group segments)
        Assert.IsTrue(Found, 'Expected at least one standard v2.0 API page');
        Assert.IsTrue(APIOverview."API URL".Value().Contains('/api/v2.0/'), 'Standard API URL should contain the /api/v2.0/ route');
        APIOverview.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAPIOverviewListsEveryAPIPage()
    var
        APIOverview: TestPage "API Overview";
        PageMetadata: Record "Page Metadata";
        APIPageCount: Integer;
        DetailPageCount: Integer;
    begin
        // [SCENARIO] Every API page in metadata appears as a row in the flat list (no APIs are lost)
        // [GIVEN] The API Overview page is opened
        APIOverview.OpenView();

        // [WHEN] Counting Page-type rows by walking the UI
        if APIOverview.First() then
            repeat
                if APIOverview."Object Type".Value() = 'Page' then
                    DetailPageCount += 1;
            until not APIOverview.Next();

        APIOverview.Close();

        // [THEN] Count matches the underlying Page Metadata where PageType = API
        PageMetadata.SetRange(PageType, PageMetadata.PageType::API);
        APIPageCount := PageMetadata.Count();
        Assert.AreEqual(APIPageCount, DetailPageCount, 'API Overview did not list every API page from Page Metadata');
    end;
}
