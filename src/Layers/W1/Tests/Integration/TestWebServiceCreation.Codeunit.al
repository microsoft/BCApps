codeunit 134848 "Test Web Service Creation"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Web Service]
    end;

    var
        Assert: Codeunit Assert;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateWebServices()
    var
        WebService: Record "Web Service";
        AllObj: Record AllObj;
        ObjectName: Text;
    begin
        // [SCENARIO] The web service is expected to named 'SalesOrder' (no space) by other tests
        AllObj.Get(WebService."Object Type"::Page, PAGE::"Sales Order");
        ObjectName := DelChr(AllObj."Object Name", '=', ' ');
        WebService.Get(AllObj."Object Type", ObjectName);
        Assert.AreEqual(WebService."Object Type", WebService."Object Type"::Page, 'Invalid Object Type for the web service');
        Assert.AreEqual(WebService."Service Name", ObjectName, 'Invalid name for the web service');
        Assert.AreEqual(WebService."Object ID", PAGE::"Sales Order", 'Invalid Object ID for the web service');
        Assert.AreEqual(WebService.Published, true, 'Web service should have been published');
    end;
}

