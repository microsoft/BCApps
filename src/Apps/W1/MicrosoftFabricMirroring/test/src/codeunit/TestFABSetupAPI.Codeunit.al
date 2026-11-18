namespace Microsoft.FabricExport;

using System.Fabric;

codeunit 140013 "Test FAB Setup API 4PS"
{
    Subtype = Test;
    TestType = IntegrationTest;
    TestPermissions = Disabled;
    RequiredTestIsolation = Disabled;
    TestHttpRequestPolicy = AllowAllOutboundRequests;

    var
        Assert: Codeunit "Assert";
        LibraryGraphMgt: Codeunit "Library - Graph Mgt";
        FabricSetupsTok: Label 'fabricSetups', Locked = true;
        WorkspaceIdTok: Label 'fabricWorkspaceId', Locked = true;
        LakehouseIdTok: Label 'fabricLakehouseId', Locked = true;
        MinutesBetweenExportsTok: Label 'minutesBetweenExports', Locked = true;
        DestinationChangeBlockedErr: Label 'You cannot change the Fabric workspace or Open Mirroring database while setup is complete or export is enabled.';
        BadPatchResponseErr: Label 'PATCH request failed. Response code is 400 (BadRequest).', Locked = true;
        PatchSucceededTok: Label 'Fabric setup PATCH completed successfully.', Locked = true;

    [Test]
    procedure RejectAPIWorkspaceChangeAfterSetupCompleted()
    var
        Setup: Record "Tenant Fabric Setup";
        Request: JsonObject;
        PatchError: Text;
    begin
        //[SCENARIO] Change the workspace through the setup API after setup completes
        //[GIVEN] A request with a new workspace ID
        Request.Add(WorkspaceIdTok, Format(CreateGuid(), 0, 9));
        //[GIVEN] Completed setup with export disabled
        CreateSetup(Setup, true);

        //[WHEN] The workspace change is sent to the setup API
        PatchError := PatchSetup(Setup.SystemId, Request, 400);

        //[THEN] The request is rejected and the saved setup is unchanged
        VerifyRejectedPatch(Setup, PatchError);
    end;

    [Test]
    procedure RejectAPIDatabaseChangeAfterSetupCompleted()
    var
        Setup: Record "Tenant Fabric Setup";
        Request: JsonObject;
        PatchError: Text;
    begin
        //[SCENARIO] Change the mirrored database through the setup API after setup completes
        //[GIVEN] A request with a new mirrored database ID
        Request.Add(LakehouseIdTok, Format(CreateGuid(), 0, 9));
        //[GIVEN] Completed setup with export disabled
        CreateSetup(Setup, true);

        //[WHEN] The mirrored database change is sent to the setup API
        PatchError := PatchSetup(Setup.SystemId, Request, 400);

        //[THEN] The request is rejected and the saved setup is unchanged
        VerifyRejectedPatch(Setup, PatchError);
    end;

    [Test]
    procedure AllowAPIUnchangedDestinationAfterSetupCompleted()
    var
        Setup: Record "Tenant Fabric Setup";
        Request: JsonObject;
        PatchError: Text;
    begin
        //[SCENARIO] Resubmit the existing destination through the setup API
        //[GIVEN] Completed setup with export disabled
        CreateSetup(Setup, true);
        //[GIVEN] A request with the existing destination IDs
        AddDestination(Request, Setup."Fabric Workspace ID", Setup."Fabric Lakehouse ID");

        //[WHEN] The existing destination is sent to the setup API
        PatchError := PatchSetup(Setup.SystemId, Request, 200);

        //[THEN] The request succeeds and the saved setup is unchanged
        VerifyAcceptedPatch(Setup, PatchError);
    end;

    [Test]
    procedure AllowAPIIntervalChangeAfterSetupCompleted()
    var
        Setup: Record "Tenant Fabric Setup";
        Request: JsonObject;
        PatchError: Text;
    begin
        //[SCENARIO] Change the export interval through the setup API after setup completes
        //[GIVEN] A request for a ten-minute export interval
        Request.Add(MinutesBetweenExportsTok, 10);
        //[GIVEN] Completed setup with a five-minute export interval
        CreateSetup(Setup, true);

        //[WHEN] The interval change is sent to the setup API
        PatchError := PatchSetup(Setup.SystemId, Request, 200);

        //[THEN] The new interval is saved without changing the destination or lifecycle state
        VerifyIntervalChange(Setup, PatchError, 10);
    end;

    [Test]
    procedure AllowAPIDestinationChangeBeforeSetup()
    var
        Setup: Record "Tenant Fabric Setup";
        Request: JsonObject;
        NewWorkspaceId: Guid;
        NewLakehouseId: Guid;
        PatchError: Text;
    begin
        //[SCENARIO] Change both destination IDs through the setup API before connecting
        //[GIVEN] A request with new destination IDs
        CreateDestinationRequest(Request, NewWorkspaceId, NewLakehouseId);
        //[GIVEN] Incomplete setup with export disabled
        CreateSetup(Setup, false);

        //[WHEN] The destination change is sent to the setup API
        PatchError := PatchSetup(Setup.SystemId, Request, 200);

        //[THEN] Both new IDs are saved without changing the lifecycle state
        VerifyDestinationChange(Setup, PatchError, NewWorkspaceId, NewLakehouseId);
    end;

    local procedure CreateSetup(var Setup: Record "Tenant Fabric Setup"; SetupComplete: Boolean)
    begin
        Setup.Init();
        Setup."Setup ID" := CopyStr('T' + DelChr(Format(CreateGuid(), 0, 9), '=', '{}-'), 1, MaxStrLen(Setup."Setup ID"));
        Setup."Fabric Workspace ID" := CreateGuid();
        Setup."Fabric Workspace Name" := 'Original workspace';
        Setup."Fabric Lakehouse ID" := CreateGuid();
        Setup."Fabric Data Namespace" := 'BusinessCentral';
        Setup."Fabric Logging Namespace" := 'BusinessCentral_log';
        Setup."Minutes Between Exports" := 5;
        Setup."Max Consecutive Failed Runs" := 2;
        Setup."Setup Complete" := SetupComplete;
        // The API addresses this fixture by SystemId, leaving the environment's setup untouched.
        Setup.Insert(false);
        Commit();
    end;

    local procedure CreateDestinationRequest(var Request: JsonObject; var WorkspaceId: Guid; var LakehouseId: Guid)
    begin
        WorkspaceId := CreateGuid();
        LakehouseId := CreateGuid();
        AddDestination(Request, WorkspaceId, LakehouseId);
    end;

    local procedure AddDestination(var Request: JsonObject; WorkspaceId: Guid; LakehouseId: Guid)
    begin
        Request.Add(WorkspaceIdTok, Format(WorkspaceId, 0, 9));
        Request.Add(LakehouseIdTok, Format(LakehouseId, 0, 9));
    end;

    local procedure PatchSetup(SetupId: Guid; Request: JsonObject; ExpectedStatusCode: Integer): Text
    var
        PatchCompleted: Boolean;
    begin
        // The API test library may write the web service key, so TryFunction cannot wrap this call.
        // Capture the result before cleanup; the HTTP PATCH commits in a separate session.
        asserterror SendPatchAndSignalSuccess(SetupId, Request, ExpectedStatusCode, PatchCompleted);
        if PatchCompleted then
            exit('');
        exit(GetLastErrorText());
    end;

    local procedure SendPatchAndSignalSuccess(SetupId: Guid; Request: JsonObject; ExpectedStatusCode: Integer; var PatchCompleted: Boolean)
    var
        TargetUrl: Text;
        RequestBody: Text;
        ResponseBody: Text;
    begin
        TargetUrl := LibraryGraphMgt.CreateTargetURL(Format(SetupId, 0, 9), Page::"Fabric API Setup", FabricSetupsTok);
        Request.WriteTo(RequestBody);
        LibraryGraphMgt.PatchToWebServiceAndCheckResponseCode(TargetUrl, RequestBody, ResponseBody, ExpectedStatusCode);
        PatchCompleted := true;
        Assert.Fail(PatchSucceededTok);
    end;

    local procedure VerifyRejectedPatch(ExpectedSetup: Record "Tenant Fabric Setup"; PatchError: Text)
    var
        ActualSetup: Record "Tenant Fabric Setup";
    begin
        ReadAndRemoveFixture(ExpectedSetup.SystemId, ActualSetup);
        Assert.IsTrue(StrPos(PatchError, BadPatchResponseErr) > 0, PatchError);
        Assert.IsTrue(StrPos(PatchError, DestinationChangeBlockedErr) > 0, PatchError);
        VerifySavedSetup(ExpectedSetup, ActualSetup);
    end;

    local procedure VerifyAcceptedPatch(ExpectedSetup: Record "Tenant Fabric Setup"; PatchError: Text)
    var
        ActualSetup: Record "Tenant Fabric Setup";
    begin
        ReadAndRemoveFixture(ExpectedSetup.SystemId, ActualSetup);
        Assert.AreEqual('', PatchError, 'Expected the PATCH request to succeed.');
        VerifySavedSetup(ExpectedSetup, ActualSetup);
    end;

    local procedure VerifyIntervalChange(ExpectedSetup: Record "Tenant Fabric Setup"; PatchError: Text; NewInterval: Integer)
    begin
        ExpectedSetup."Minutes Between Exports" := NewInterval;
        VerifyAcceptedPatch(ExpectedSetup, PatchError);
    end;

    local procedure VerifyDestinationChange(ExpectedSetup: Record "Tenant Fabric Setup"; PatchError: Text; NewWorkspaceId: Guid; NewLakehouseId: Guid)
    begin
        ExpectedSetup."Fabric Workspace ID" := NewWorkspaceId;
        ExpectedSetup."Fabric Lakehouse ID" := NewLakehouseId;
        VerifyAcceptedPatch(ExpectedSetup, PatchError);
    end;

    local procedure ReadAndRemoveFixture(SetupId: Guid; var ActualSetup: Record "Tenant Fabric Setup")
    begin
        SelectLatestVersion();
        if not ActualSetup.GetBySystemId(SetupId) then
            exit;

        // Persist cleanup before assertions can fail; the HTTP session commits independently.
        ActualSetup.Delete(false);
        Commit();
    end;

    local procedure VerifySavedSetup(ExpectedSetup: Record "Tenant Fabric Setup"; ActualSetup: Record "Tenant Fabric Setup")
    begin
        Assert.AreEqual(ExpectedSetup.SystemId, ActualSetup.SystemId, 'Expected the same setup record to remain.');
        Assert.AreEqual(ExpectedSetup."Fabric Workspace ID", ActualSetup."Fabric Workspace ID", 'Unexpected workspace ID.');
        Assert.AreEqual(ExpectedSetup."Fabric Workspace Name", ActualSetup."Fabric Workspace Name", 'Unexpected workspace name.');
        Assert.AreEqual(ExpectedSetup."Fabric Lakehouse ID", ActualSetup."Fabric Lakehouse ID", 'Unexpected mirrored database ID.');
        Assert.AreEqual(ExpectedSetup."Setup Complete", ActualSetup."Setup Complete", 'Unexpected setup completion state.');
        Assert.AreEqual(ExpectedSetup."Export Enabled", ActualSetup."Export Enabled", 'Unexpected export enablement state.');
        Assert.AreEqual(ExpectedSetup."Minutes Between Exports", ActualSetup."Minutes Between Exports", 'Unexpected export interval.');
    end;
}
