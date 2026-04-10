codeunit 135519 "IRS 1099 Code Entity E2E Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Graph] [IRS 1099 Form-Box]
    end;

    var
        Assert: Codeunit Assert;
        LibraryGraphMgt: Codeunit "Library - Graph Mgt";
        IsInitialized: Boolean;
        ServiceNameTxt: Label 'irs1099Codes';

    [Test]
    [Scope('OnPrem')]
    procedure TestGetIRS1099FormBox()
    var
        TargetURL: Text;
        Responsetext: Text;
    begin
        // [SCENARIO] User cannot retrieve IRS1099FormBox records from the IRS1099FormBox API in W1.
        Initialize();

        // [GIVEN] IRS1099FormBox endpoint
        // [WHEN] The user makes a GET request to the endpoint for the IRS1099FormBox.
        TargetURL := StrSubstNo('%1/%2', GetUrl(CLIENTTYPE::Api, CompanyName), ServiceNameTxt);
        asserterror LibraryGraphMgt.GetFromWebService(Responsetext, TargetURL);

        // [THEN] The response is empty.
        Assert.AreEqual('', Responsetext, 'GET response in W1 must be empty.');
    end;

    local procedure Initialize()
    begin
        if IsInitialized then
            exit;

        IsInitialized := true;
    end;
}

