#if not CLEAN28
codeunit 134414 "Service Connection Test"
{
    Subtype = Test;
    TestPermissions = Disabled;
    ObsoleteReason = 'AMC Banking 365 Fundamental extension is discontinued';
    ObsoleteState = Pending;
    ObsoleteTag = '28.0';
    trigger OnRun()
    begin
        // [FEATURE] [Document Exchange Service] [Service Connections] [UI]
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";

    [Test]
    [Scope('OnPrem')]
    procedure VerifyDocExchServiceConnection()
    var
        DocExchServiceSetup: Record "Doc. Exch. Service Setup";
    begin
        // Setup
        Initialize();
        if not DocExchServiceSetup.Get() then begin
            DocExchServiceSetup.Init();
            DocExchServiceSetup.Insert();
        end;
        // Exercise & Verify
        Assert.IsTrue(
          ServiceExist(DocExchServiceSetup.TableCaption()),
          'DocExchService Setup Connection are not recognized');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyNoDocExchServiceConnectionExist()
    var
        DocExchServiceSetup: Record "Doc. Exch. Service Setup";
    begin
        // Setup
        Initialize();
        if DocExchServiceSetup.Get() then
            DocExchServiceSetup.Delete();
        // Exercise & Verify
        Assert.IsTrue(
          ServiceExist(DocExchServiceSetup.TableCaption()),
          'DocExchService Setup Connection should be created automatically');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyBankDataConvServiceSetupConnection()
    var
        AMCBankingSetup: Record "AMC Banking Setup";
    begin
        // Setup
        Initialize();
        // Exercise & Verify
        Assert.IsTrue(
          ServiceExist(AMCBankingSetup.TableCaption()),
          'AMC Banking Setup Connection are not recognized')
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyBankDataConvServiceSetupDisableConnection()
    var
        AMCBankingSetup: Record "AMC Banking Setup";
        TempServiceConnection: Record "Service Connection";
    begin
        // Setup
        Initialize();
        AMCBankingSetup.Get();
        AMCBankingSetup."Service URL" := '';
        AMCBankingSetup.Modify();
        TempServiceConnection.Status := TempServiceConnection.Status::Disabled;

        // Exercise & Verify
        Assert.IsTrue(
          ServiceExist(AMCBankingSetup.TableCaption()),
          'AMC Banking Setup Connection are not recognized');
        Assert.IsTrue(
          ServiceExistWithStatusAsExpected(AMCBankingSetup.TableCaption(), TempServiceConnection),
          'AMC Banking Setup Connection have wrong status');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure HasResponseErrorsHandlesMissingInvalidSyslogAndEmptyResponse()
    var
        AMCBankRESTRequestMgt: Codeunit "AMC Bank REST Request Mgt.";
    begin
        Initialize();

        VerifyResponseWithoutValidSyslog(AMCBankRESTRequestMgt, '');
        VerifyResponseWithoutValidSyslog(AMCBankRESTRequestMgt, '{}');
        VerifyResponseWithoutValidSyslog(AMCBankRESTRequestMgt, '{"syslog":null}');
        VerifyResponseWithoutValidSyslog(AMCBankRESTRequestMgt, '{"syslog":"not json"}');
        VerifyResponseWithoutValidSyslog(AMCBankRESTRequestMgt, 'not json');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LogHttpActivityDoesNotLogInvalidJsonContent()
    var
        ActivityLog: Record "Activity Log";
        AMCBankRESTRequestMgt: Codeunit "AMC Bank REST Request Mgt.";
        HttpContent: HttpContent;
        DetailedInfoInStream: InStream;
        ActualContent: Text;
        InvalidContent: Text;
        ActivityId: Integer;
    begin
        Initialize();
        InvalidContent := 'not json';
        HttpContent.WriteFrom(InvalidContent);

        ActivityId := AMCBankRESTRequestMgt.LogHttpActivity('REST', 'TEST', 'error', '', '', HttpContent, 'error');

        ActivityLog.Get(ActivityId);
        ActivityLog.CalcFields("Detailed Info");
        ActivityLog."Detailed Info".CreateInStream(DetailedInfoInStream);
        DetailedInfoInStream.ReadText(ActualContent);
        Assert.AreEqual('', ActualContent, 'Invalid JSON log content must not be logged.');
        ActivityLog.Delete();
        Commit();
    end;

    local procedure Initialize()
    var
        AMCBankingSetup: Record "AMC Banking Setup";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Service Connection Test");
        if not AMCBankingSetup.Get() then begin
            AMCBankingSetup.Init();
            AMCBankingSetup.Insert();
        end;
        AMCBankingSetup."AMC Enabled" := true;
        AMCBankingSetup.Modify();
    end;

    local procedure VerifyResponseWithoutValidSyslog(var AMCBankRESTRequestMgt: Codeunit "AMC Bank REST Request Mgt."; ResponseText: Text)
    var
        ActivityLog: Record "Activity Log";
        ResponseTempBlob: Codeunit "Temp Blob";
        ResponseOutStream: OutStream;
        ResponseResult: Text;
        ActivityId: Integer;
    begin
        if ResponseText <> '' then begin
            ResponseTempBlob.CreateOutStream(ResponseOutStream);
            ResponseOutStream.WriteText(ResponseText);
        end;

        Assert.IsFalse(
            AMCBankRESTRequestMgt.HasResponseErrors(ResponseTempBlob, 'REST', 'syslog', ResponseResult, 'TEST'),
            'A response without a valid syslog must retain the legacy non-error classification.');
        Assert.AreEqual('', ResponseResult, 'A response without a valid syslog must have an empty result.');

        ActivityId := AMCBankRESTRequestMgt.GetGlobalToActivityId();
        Assert.IsTrue(ActivityLog.Get(ActivityId), 'A response without a valid syslog must still be logged.');
        Assert.AreEqual(Format(ActivityLog.Status::Failed), Format(ActivityLog.Status), 'The response must retain the legacy failed log status.');
        Assert.AreEqual(Format(AMCBankWebLogStatus::Failed), Format(ActivityLog."AMC Bank WebLog Status"), 'The response must retain the legacy failed web log status.');
        ActivityLog.Delete();
        Commit();
    end;

    local procedure ServiceExist(Desc: Text): Boolean
    var
        ServiceConnectionsOverview: TestPage "Service Connections";
    begin
        ServiceConnectionsOverview.OpenView();
        ServiceConnectionsOverview.FILTER.SetFilter(Name, Desc);
        ServiceConnectionsOverview.First();
        exit(Format(ServiceConnectionsOverview.Name) = Desc);
    end;

    local procedure ServiceExistWithStatusAsExpected(Desc: Text; ServiceConnection: Record "Service Connection"): Boolean
    var
        ServiceConnectionsOverviewTestPage: TestPage "Service Connections";
    begin
        ServiceConnectionsOverviewTestPage.OpenView();
        ServiceConnectionsOverviewTestPage.FILTER.SetFilter(Name, Desc);
        ServiceConnectionsOverviewTestPage.First();
        exit(Format(ServiceConnectionsOverviewTestPage.Status) = Format(ServiceConnection.Status));
    end;
}
#endif
