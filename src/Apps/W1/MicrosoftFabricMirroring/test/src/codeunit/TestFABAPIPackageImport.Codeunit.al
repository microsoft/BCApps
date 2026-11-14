namespace Microsoft.FabricExport;

using System.Fabric;

codeunit 140013 "Test FAB API Package Import"
{
    Subtype = Test;
    TestType = IntegrationTest;
    TestHttpRequestPolicy = AllowAllOutboundRequests;
    // The API is called over HTTP in a separate session, so test data must be committed.
    RequiredTestIsolation = Disabled;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Assert";
        LibraryGraphMgt: Codeunit "Library - Graph Mgt";
        SetupServiceNameTok: Label 'fabricSetups', Locked = true;
        ImportPackageActionTok: Label 'Microsoft.NAV.importPackage', Locked = true;
        PackageCodeTok: Label 'API-IMPORT', Locked = true;
        PackageJsonTok: Label '{"code":"API-IMPORT","description":"Imported through API","version":"1.0","tables":[18,27]}', Locked = true;
        InvalidPackageFileTxt: Label 'The file could not be read as a valid package definition.';

    [Test]
    procedure ImportThroughSetupApiWhenNoPackageExists()
    var
        FabricConfigPackage: Record "Fabric Config Package";
        FabricConfigPackageLine: Record "Fabric Config Package Line";
        SetupId: Text;
        ResponseText: Text;
    begin
        // [SCENARIO] A package can be imported over HTTP when the package collection is empty
        // [GIVEN] No configuration packages exist
        Initialize();

        // [GIVEN] The package API returns an empty collection, so no package entity can bind an action
        Assert.AreEqual(0, GetPackageCollectionCount(), 'Expected the package collection to be empty.');

        // [GIVEN] The setup singleton is discovered through the setup API
        SetupId := GetSetupId();

        // [WHEN] The import action is invoked on the setup entity
        LibraryGraphMgt.PostToWebServiceAndCheckResponseCode(GetImportUrl(SetupId), CreateImportRequestBody(PackageJsonTok), ResponseText, 201);

        // [THEN] The package header and lines are persisted
        Assert.IsTrue(FabricConfigPackage.Get(PackageCodeTok), 'Expected the imported package to exist.');
        FabricConfigPackage.TestField(Description, 'Imported through API');
        FabricConfigPackage.TestField(Version, '1.0');
        FabricConfigPackage.TestField(Active, false);
        FabricConfigPackageLine.SetRange("Package Code", PackageCodeTok);
        Assert.AreEqual(2, FabricConfigPackageLine.Count(), 'Expected two imported package lines.');

        // [THEN] The imported package is exposed through the package API
        Assert.AreEqual(1, GetPackageCollectionCount(), 'Expected the imported package in the package collection.');

        Cleanup();
    end;

    [Test]
    procedure ImportThroughSetupApiRejectsInvalidJson()
    var
        FabricConfigPackage: Record "Fabric Config Package";
        ResponseText: Text;
        SetupId: Text;
    begin
        // [SCENARIO] An invalid package definition is rejected over HTTP without creating a package
        // [GIVEN] No configuration packages exist and the setup singleton is discovered
        Initialize();
        SetupId := GetSetupId();

        // [WHEN] The import action is invoked with an invalid JSON definition
        asserterror LibraryGraphMgt.PostToWebServiceAndCheckResponseCode(GetImportUrl(SetupId), CreateImportRequestBody('not json'), ResponseText, 201);

        // [THEN] The request fails with the package validation error and no package is created
        Assert.ExpectedError(InvalidPackageFileTxt);
        Assert.IsTrue(FabricConfigPackage.IsEmpty(), 'Expected no package to be created.');

        Cleanup();
    end;

    local procedure Initialize()
    begin
        Cleanup();
    end;

    local procedure Cleanup()
    var
        TenantFabricTables: Record "Tenant Fabric Tables";
        FabricConfigPackage: Record "Fabric Config Package";
        FabricConfigPackageLine: Record "Fabric Config Package Line";
        FabricTableClaim: Record "Fabric Table Claim";
    begin
        TenantFabricTables.SetFilter("Table ID", '<>%1&<>%2', Database::"Tenant Fabric Export Details", Database::"Tenant Fabric Export Summary");
        TenantFabricTables.DeleteAll(false);
        FabricConfigPackageLine.DeleteAll(false);
        FabricConfigPackage.DeleteAll(false);
        FabricTableClaim.DeleteAll(false);
        Commit();
    end;

    local procedure GetPackageCollectionCount(): Integer
    begin
        exit(GetCollection(Page::"Fabric API Config Packages").Count());
    end;

    local procedure GetSetupId(): Text
    var
        Setups: JsonArray;
        SetupToken: JsonToken;
        IdToken: JsonToken;
    begin
        Setups := GetCollection(Page::"Fabric API Setup");
        Assert.AreEqual(1, Setups.Count(), 'Expected the setup API to expose the setup singleton.');
        Setups.Get(0, SetupToken);
        SetupToken.AsObject().Get('id', IdToken);
        exit(IdToken.AsValue().AsText());
    end;

    local procedure GetCollection(PageId: Integer): JsonArray
    var
        Response: JsonObject;
        ValueToken: JsonToken;
        ResponseText: Text;
    begin
        LibraryGraphMgt.GetFromWebService(ResponseText, LibraryGraphMgt.CreateTargetURL('', PageId, ''));
        Response.ReadFrom(ResponseText);
        Response.Get('value', ValueToken);
        exit(ValueToken.AsArray());
    end;

    local procedure GetImportUrl(SetupId: Text): Text
    begin
        exit(LibraryGraphMgt.CreateTargetURLWithSubpage(SetupId, Page::"Fabric API Setup", SetupServiceNameTok, ImportPackageActionTok));
    end;

    local procedure CreateImportRequestBody(PackageJson: Text) RequestBodyText: Text
    var
        RequestBody: JsonObject;
    begin
        RequestBody.Add('packageJson', PackageJson);
        RequestBody.WriteTo(RequestBodyText);
    end;
}
