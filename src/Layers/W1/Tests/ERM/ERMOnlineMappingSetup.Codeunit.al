codeunit 134915 "ERM Online Mapping Setup"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Online Map]
        isInitialized := false;
    end;

    var
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        isInitialized: Boolean;
        Bing: Label 'BING';
        BingMaps: Label 'Bing Maps';
        BingMapsURL: Label 'https://bing.com/maps/default.aspx?where1={1}+{2}+{6}&v=2&mkt={7}', Locked = true;
        BingDirectionsURL: Label 'https://bing.com/maps/default.aspx?rtp=adr.{1}+{2}+{6}~adr.{1}+{2}+{6}&v=2&mkt={7}&rtop={9}~0~0', Locked = true;
        BingComment: Label 'http://go.microsoft.com/fwlink/?LinkId=519372', Locked = true;
        RollBackMessage: Label 'Revert back the tables to their original state.';

    [Normal]
    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Online Mapping Setup");
        // Lazy setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Online Mapping Setup");

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Online Mapping Setup");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnlineMappingDefaultSetup()
    var
        OnlineMapSetup: Record "Online Map Setup";
        OnlineMapParameterSetup: Record "Online Map Parameter Setup";
        OnlineMapManagement: Codeunit "Online Map Management";
        Assert: Codeunit Assert;
    begin
        // Covers Document TFS_TC_ID 143437, 143438.
        // Validate that default setup could be used.

        // Setup: Existing demo data is sufficient.
        Initialize();

        // Exercise: Execute the default setup function of the Online Map Management code unit.
        OnlineMapManagement.SetupDefault();

        // Verify: Check that the default entries exist.
        OnlineMapSetup.SetFilter("Map Parameter Setup Code", '%1', Bing);
        Assert.IsTrue(OnlineMapSetup.FindFirst(), 'Cannot find a Bing Maps entry in the Online Map Setup table.');

        OnlineMapParameterSetup.SetFilter(Code, '%1', OnlineMapSetup."Map Parameter Setup Code");
        Assert.IsTrue(OnlineMapParameterSetup.FindFirst(), 'Cannot find a Bing Maps entry in the Online Map Parameter Setup table.');

        OnlineMapParameterSetup.TestField(Name, BingMaps);
        OnlineMapParameterSetup.TestField("Map Service", BingMapsURL);
        OnlineMapParameterSetup.TestField("Directions Service", BingDirectionsURL);
        OnlineMapParameterSetup.TestField("URL Encode Non-ASCII Chars", false);
        OnlineMapParameterSetup.TestField(Comment, BingComment);

        // Tear Down: Roll back the introduced changes.
        asserterror Error(RollBackMessage);
    end;
}

