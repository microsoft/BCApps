codeunit 139101 "Document Service Mgmt Test"
{
    // This Test Codeunit is included in SNAP so the utmost attention must be paid to stability. For example,
    // avoid calling product functions which result in calls to O365; instead, use the mock Document Service
    // assembly.

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [INT] [Document Service]
    end;

    var
        NoConfigErr: Label 'No online document configuration was found.';
        MultipleConfigsErr: Label 'More than one online document configuration was found.';
        SourceFileNotFoundErr: Label 'Cannot open the specified document from the following location: %1 due to the following error: %2.', Comment = '%1=Full path to the file on disk;%2=the detailed error describing why the document could not be accessed.';
        RequiredSourceErr: Label 'You must specify a source path for the document.';
        RequiredTargetErr: Label 'You must specify a name for the document.';
        EmptyURLErr: Label 'You must specify the URI that you want to open.';
        O365NotConfiguredErr: Label 'No online document configuration was found.';
        TestDocumentConfiguredErr: Label 'This test case is only intended for when the Document Service is NOT configured.';
        TestUnexpectedErr: Label 'Unexpected error: ''%1''.', Comment = '%1 is the actual error.';
        TestIsConfiguredTrue1Err: Label 'IsConfigured should return TRUE when there is a record having valid configuration.';
        TestIsConfiguredTrue2Err: Label 'IsConfigured should return TRUE, even when there is a record having invalid configuration.';
        TestIsConfiguredFalseErr: Label 'IsConfigured should return FALSE when there are no Configuration records.';
        TestDefaultServiceTypeErr: Label 'The default ServiceType was expected to be empty but was found to be ''%1''.', Comment = '%1 is the actual ServiceType found';
        TestUpdatedServiceTypeErr: Label 'Setting the ServiceType resulted in no change.', Comment = '%1 is the actual serviceType';
        MockServiceTypeTok: Label 'DOCUMENTSERVICEMOCK', Comment = 'Indicates the identifier for the mock assembly to load at runtime. This is matched against the parameter for the DocumentServiceMetadata attribute decorated on the class inheriting from IDocumentServiceHandler.';
        MockValidLocationTok: Label 'http://ValidLocation', Comment = 'Indicates to the mock ServiceType that a valid location is used which succeeds TestConnection';
        MockInvalidLocationTok: Label 'http://InvalidLocation', Comment = 'Indicates to the mock ServiceType that an invalid location is used which fails TestConnection';
        MockExistingTargetFileTok: Label 'ExistingTargetFile.txt', Comment = 'Indicates to the mock ServiceType that the target file already exists on SharePoint';
        MockNonExistingTargetFileTok: Label 'NonExistingTargetFile.txt', Comment = 'Indicates to the mock ServiceType that the target file does not exist on SharePoint';
        MockConnectErr: Label 'DocumentServiceMock says TestConnection failed due to an invalid Location.', Comment = 'Text is copied from Mock assembly.';
        MockConnectOnSaveErr: Label 'DocumentServiceMock says failed to save because a connection couldn''t be made due to an invalid Location.', Comment = 'Text is copied from Mock assembly.';
        MockTargetFileExistsErr: Label 'DocumentServiceMock says failed to save file because a file with that name already exists.', Comment = 'Text is copied from Mock assembly.';
        AlternateMockServiceTypeTok: Label 'EMPTYDOCUMENTSERVICEMOCK', Comment = 'Indicates the identifier for the mock assembly to load at runtime. This is matched against the parameter for the DocumentServiceMetadata attribute decorated on the class inheriting from IDocumentServiceHandler.';
        AlternateMockCannotConnectErr: Label 'EmptyDocumentServiceMock says TestConnection failed.', Comment = 'Text is copied from Mock assembly.';
        Assert: Codeunit Assert;

    [Test]
    [Scope('OnPrem')]
    procedure TestSuccessfulTestConnection()
    var
        DocumentServiceMgt: Codeunit "Document Service Management";
    begin
        CreateValidDocumentServiceConfig();
        DocumentServiceMgt.SetServiceType(MockServiceTypeTok);

        ClearLastError();
        DocumentServiceMgt.TestConnection();
        if GetLastErrorText <> '' then
            Error(TestUnexpectedErr, GetLastErrorText);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFailedTestConnection()
    begin
        CreateInvalidDocumentServiceConfig();
        CallTestConnectionAndExpectError(MockConnectErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestNoConfigTestConnection()
    var
        DocumentServiceConfiguration: Record "Document Service";
    begin
        DocumentServiceConfiguration.DeleteAll();
        CallTestConnectionAndExpectError(NoConfigErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestMultipleConfigsTestConnection()
    begin
        CreateValidDocumentServiceConfig();
        InsertDocumentServiceRec('SO2', 'Cassies Service', 'http://sharepoint', 'x@y.z', 'p', 'Shared Documents', 'myFolder');

        CallTestConnectionAndExpectError(MultipleConfigsErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestIsConfiguredTrue()
    var
        DocumentServiceMgt: Codeunit "Document Service Management";
    begin
        CreateValidDocumentServiceConfig();
        if not DocumentServiceMgt.IsConfigured() then
            Error(TestIsConfiguredTrue1Err);

        // IsConfigured should not care whether the configuration can successfully connect.
        CreateInvalidDocumentServiceConfig();
        if not DocumentServiceMgt.IsConfigured() then
            Error(TestIsConfiguredTrue2Err);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestIsConfiguredFalse()
    var
        DocumentServiceConfiguration: Record "Document Service";
        DocumentServiceMgt: Codeunit "Document Service Management";
    begin
        DocumentServiceConfiguration.DeleteAll();
        if DocumentServiceMgt.IsConfigured() then
            Error(TestIsConfiguredFalseErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestIsConfiguredMultipleConfigs()
    var
        DocumentServiceMgt: Codeunit "Document Service Management";
    begin
        CreateValidDocumentServiceConfig();
        InsertDocumentServiceRec('SO2', 'Cassies Service', 'http://sharepoint', 'a@b.c', 'p', 'Shared Documents', 'myFolder');

        asserterror DocumentServiceMgt.IsConfigured();
        Assert.ExpectedError(MultipleConfigsErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSaveEmptyInputs()
    begin
        CreateValidDocumentServiceConfig();

        // Expect these inputs to fail fast.

        CallSaveFileAndExpectError('', 'My.txt', Enum::"Doc. Sharing Conflict Behavior"::Rename, RequiredSourceErr);
        CallSaveFileAndExpectError('C:\x\y.z', '', Enum::"Doc. Sharing Conflict Behavior"::Replace, RequiredTargetErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSaveCannotFindSourceDoc()
    var
        FileName: Text;
        ExpectedError: Text[1024];
    begin
        CreateValidDocumentServiceConfig();

        FileName := CreateSampleFile();
        if Exists(FileName) then
            Erase(FileName);

        // Trim text for comparison since it uses substitution and ends with a period.
        ExpectedError := StrSubstNo(SourceFileNotFoundErr, FileName, '');
        ExpectedError := DelStr(ExpectedError, StrLen(ExpectedError) - 1);

        // Assume SaveFile fails fast before expensive connection operations are done.
        CallSaveFileAndExpectError(FileName, 'My.txt', Enum::"Doc. Sharing Conflict Behavior"::Rename, ExpectedError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSaveNoConfig()
    var
        DocumentServiceConfiguration: Record "Document Service";
        SampleFile: Text;
    begin
        DocumentServiceConfiguration.DeleteAll();
        SampleFile := CreateSampleFile();

        CallSaveFileAndExpectError(SampleFile, 'My.txt', Enum::"Doc. Sharing Conflict Behavior"::Rename, NoConfigErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSaveMultipleConfigs()
    var
        SampleFile: Text;
    begin
        CreateValidDocumentServiceConfig();
        InsertDocumentServiceRec('SO2', 'Cassies Service', 'http://sharepoint', 'a@b.c', 'p', 'Shared Documents', 'MyFolder');
        SampleFile := CreateSampleFile();

        CallSaveFileAndExpectError(SampleFile, 'My.txt', Enum::"Doc. Sharing Conflict Behavior"::Rename, MultipleConfigsErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSaveConnectionError()
    var
        SampleFile: Text;
    begin
        CreateInvalidDocumentServiceConfig();
        SampleFile := CreateSampleFile();

        CallSaveFileAndExpectError(SampleFile, MockNonExistingTargetFileTok, Enum::"Doc. Sharing Conflict Behavior"::Rename, MockConnectOnSaveErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSaveSuccess()
    var
        DocumentServiceMgt: Codeunit "Document Service Management";
        SampleFile: Text;
    begin
        CreateValidDocumentServiceConfig();
        SampleFile := CreateSampleFile();
        DocumentServiceMgt.SetServiceType(MockServiceTypeTok);

        ClearLastError();
        DocumentServiceMgt.SaveFile(SampleFile, MockNonExistingTargetFileTok, Enum::"Doc. Sharing Conflict Behavior"::Rename);

        Erase(SampleFile);
        if GetLastErrorText <> '' then
            Error(TestUnexpectedErr, GetLastErrorText);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSaveSuccessfulOverwrite()
    var
        DocumentServiceMgt: Codeunit "Document Service Management";
        SampleFile: Text;
    begin
        CreateValidDocumentServiceConfig();
        SampleFile := CreateSampleFile();
        DocumentServiceMgt.SetServiceType(MockServiceTypeTok);

        ClearLastError();
        DocumentServiceMgt.SaveFile(SampleFile, MockExistingTargetFileTok, Enum::"Doc. Sharing Conflict Behavior"::Replace);

        Erase(SampleFile);
        if GetLastErrorText <> '' then
            Error(TestUnexpectedErr, GetLastErrorText);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSaveExistingFile()
    var
        SampleFile: Text;
    begin
        CreateValidDocumentServiceConfig();
        SampleFile := CreateSampleFile();

        CallSaveFileAndExpectError(SampleFile, MockExistingTargetFileTok, Enum::"Doc. Sharing Conflict Behavior"::Rename, MockTargetFileExistsErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetSetServiceType()
    var
        DocumentServiceMgt: Codeunit "Document Service Management";
        ActualServiceType: Text;
    begin
        ActualServiceType := DocumentServiceMgt.GetServiceType();
        if ActualServiceType <> '' then
            Error(TestDefaultServiceTypeErr, ActualServiceType);

        DocumentServiceMgt.SetServiceType('Hello World!');
        ActualServiceType := DocumentServiceMgt.GetServiceType();
        if ActualServiceType <> 'Hello World!' then
            Error(TestUpdatedServiceTypeErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestChangingServiceType()
    var
        DocumentServiceMgt: Codeunit "Document Service Management";
    begin
        CreateInvalidDocumentServiceConfig();

        DocumentServiceMgt.SetServiceType(MockServiceTypeTok);

        asserterror DocumentServiceMgt.TestConnection();
        Assert.ExpectedError(MockConnectErr);

        DocumentServiceMgt.SetServiceType(AlternateMockServiceTypeTok);

        ClearLastError();
        asserterror DocumentServiceMgt.TestConnection();
        Assert.ExpectedError(AlternateMockCannotConnectErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestMultipleOperationsWithSameServiceType()
    var
        DocumentServiceMgt: Codeunit "Document Service Management";
    begin
        CreateInvalidDocumentServiceConfig();

        DocumentServiceMgt.SetServiceType(MockServiceTypeTok);

        ClearLastError();
        asserterror DocumentServiceMgt.TestConnection();
        Assert.ExpectedError(MockConnectErr);

        ClearLastError();
        asserterror DocumentServiceMgt.TestConnection();
        Assert.ExpectedError(MockConnectErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOpenExisting_EmptyURLError()
    var
        DocumentServiceManagement: Codeunit "Document Service Management";
    begin
        asserterror DocumentServiceManagement.OpenDocument('');

        Assert.ExpectedError(EmptyURLErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOpenNewlyGenerated_O365NotConfiguredError()
    var
        DocumentService: Record "Document Service";
        DocumentServiceManagement: Codeunit "Document Service Management";
    begin
        // Clean configuration table to ensure SharePoint is NOT configured.
        DocumentService.DeleteAll();
        if DocumentServiceManagement.IsConfigured() then
            Error(TestDocumentConfiguredErr);

        asserterror DocumentServiceManagement.OpenDocument('abc');
        Assert.ExpectedError(O365NotConfiguredErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPermissionExistsInDemoData()
    var
        Permission: Record Permission;
    begin
        // Cannot check which Permission Set the Permission actually belongs to
        // because the Role ID is a code which gets translated in demo data
        // for local builds, and we have no way of translating it here.
        // Permission.SETFILTER("Role ID",'=%1','BASIC');
        Permission.SetFilter("Object Type", '=%1', Permission."Object Type"::"Table Data");
        Permission.SetFilter("Object ID", '=%1', 2000000114);
        Permission.SetFilter("Read Permission", '=%1', Permission."Read Permission"::Yes);
        Permission.SetFilter("Insert Permission", '=%1', Permission."Insert Permission"::" ");
        Permission.SetFilter("Modify Permission", '=%1', Permission."Modify Permission"::" ");
        Permission.SetFilter("Delete Permission", '=%1', Permission."Delete Permission"::" ");
        Permission.SetFilter("Execute Permission", '=%1', Permission."Execute Permission"::" ");
        Permission.FindFirst();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestIsServiceUriReturnsFalseWhenDocumentServiceIsNotConfigured()
    var
        DocumentService: Record "Document Service";
        DocumentServiceManagement: Codeunit "Document Service Management";
    begin
        DocumentService.DeleteAll();
        if DocumentServiceManagement.IsConfigured() then
            Error(TestDocumentConfiguredErr);
        DocumentServiceManagement.SetServiceType(MockServiceTypeTok);
        Assert.IsFalse(DocumentServiceManagement.IsServiceUri(MockValidLocationTok),
          'Expected call to IsValidUri to return false when document service is not configured');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestIsServiceUriReturnsFalseWhenDocumentAddressIsEmpty()
    var
        DocumentService: Record "Document Service";
        DocumentServiceManagement: Codeunit "Document Service Management";
    begin
        DocumentService.DeleteAll();
        if DocumentServiceManagement.IsConfigured() then
            Error(TestDocumentConfiguredErr);
        DocumentServiceManagement.SetServiceType(MockServiceTypeTok);
        Assert.IsFalse(DocumentServiceManagement.IsServiceUri(''),
          'Expected call to IsValidUri to return false when document path is blank');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestIsServiceUriReturnsTrueWithValidDocumentAddress()
    var
        DocumentServiceManagement: Codeunit "Document Service Management";
    begin
        CreateValidDocumentServiceConfig();
        DocumentServiceManagement.SetServiceType(MockServiceTypeTok);
        Assert.IsTrue(DocumentServiceManagement.IsServiceUri(MockValidLocationTok + '/path/document.ext'),
          'Expected call to IsValidUri to return true when document path a valid location');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestIsServiceUriReturnsFalseWithInvalidDocumentAddress()
    var
        DocumentServiceManagement: Codeunit "Document Service Management";
    begin
        CreateValidDocumentServiceConfig();
        if not DocumentServiceManagement.IsConfigured() then
            Error(TestIsConfiguredTrue1Err);
        DocumentServiceManagement.SetServiceType(MockServiceTypeTok);
        Assert.IsFalse(DocumentServiceManagement.IsServiceUri('C:\TEMP\File.ext'),
          'Expected call to IsValidUri to return false when document path is local');
    end;

    local procedure CallTestConnectionAndExpectError(ExpectedError: Text[1024])
    var
        DocumentServiceMgt: Codeunit "Document Service Management";
    begin
        DocumentServiceMgt.SetServiceType(MockServiceTypeTok);
        asserterror DocumentServiceMgt.TestConnection();
        Assert.ExpectedError(ExpectedError);
    end;

    local procedure CallSaveFileAndExpectError(Source: Text; Target: Text; ConflictBehavior: Enum "Doc. Sharing Conflict Behavior"; ExpectedError: Text[1024])
    var
        DocumentServiceMgt: Codeunit "Document Service Management";
    begin
        DocumentServiceMgt.SetServiceType(MockServiceTypeTok);
        asserterror DocumentServiceMgt.SaveFile(Source, Target, ConflictBehavior);
        if Exists(Source) then
            Erase(Source);
        Assert.ExpectedError(ExpectedError);
    end;

    local procedure InsertDocumentServiceRec(ServiceID: Code[30]; ServiceDescription: Text[80]; Loc: Text[250]; Usr: Text[128]; Pwd: Text[128]; DocRepository: Text[250]; DocFolder: Text[250])
    var
        DocumentServiceConfiguration: Record "Document Service";
    begin
        DocumentServiceConfiguration.Init();
        DocumentServiceConfiguration."Service ID" := ServiceID;
        DocumentServiceConfiguration.Description := ServiceDescription;
        DocumentServiceConfiguration.Location := Loc;
        DocumentServiceConfiguration."User Name" := Usr;
        DocumentServiceConfiguration.Password := Pwd;
        DocumentServiceConfiguration."Document Repository" := DocRepository;
        DocumentServiceConfiguration.Folder := DocFolder;
        DocumentServiceConfiguration.Insert(true);
        Commit();
    end;

    local procedure SetDocumentServiceConfig(ServiceID: Code[30]; ServiceDescription: Text[80]; Location: Text[250]; Usr: Text[128]; Pwd: Text[128]; DocRepository: Text[250]; Folder: Text[250])
    var
        DocumentServiceConfiguration: Record "Document Service";
    begin
        DocumentServiceConfiguration.DeleteAll();
        InsertDocumentServiceRec(ServiceID, ServiceDescription, Location, Usr, Pwd, DocRepository, Folder);
    end;

    local procedure CreateValidDocumentServiceConfig()
    begin
        // Not guaranteed to create a valid configuration which will connect to O365.
        SetDocumentServiceConfig('SO1', 'My Valid Særvice', MockValidLocationTok, 'æ@b.c', 'validPwd!', 'Documents', 'TempFolder');
    end;

    local procedure CreateInvalidDocumentServiceConfig()
    begin
        SetDocumentServiceConfig('SO1', 'My Invalid Særvice', MockInvalidLocationTok, 'nøn@existant.com', 'invalidPwd!', 'Documents', 'abc');
    end;

    local procedure CreateSampleFile(): Text
    var
        TempFile: File;
        FileName: Text;
    begin
        // Leverages CREATETEMPFILE to create a permanent file
        // with a generated, unique name and in a known location.
        TempFile.CreateTempFile();
        FileName := TempFile.Name;
        TempFile.Close();
        TempFile.Create(FileName);
        TempFile.Write('Hello World!');
        TempFile.Close();
        exit(FileName);
    end;
}

