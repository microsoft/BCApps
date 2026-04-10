codeunit 139049 "SMB Office Addin Mgmt Test"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Outlook Add-in] [SMB]
    end;

    var
        Assert: Codeunit Assert;
        AddinManifestManagement: Codeunit "Add-in Manifest Management";
        XMLDomManagement: Codeunit "XML DOM Management";
        HyperlinkManifest: Codeunit "Hyperlink Manifest";
        NoRuleFoundErr: Label 'Rule missing for %1, expected %2 in regex %3.', Locked = true;
        RuleFoundErr: Label 'Rule missing for %1, expected %2 to be missing from regex %3.';
        FileManagement: Codeunit "File Management";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryNoSeries: Codeunit "Library - No. Series";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        PrivacyNotice: Codeunit "Privacy Notice";
        PrivacyNoticeRegistrations: Codeunit "Privacy Notice Registrations";
        AdminEmail: Text[80];
        AdminPassword: Text[50];
        CloseReopenHandlerAction: Option CloseImmediately,EnterCredentials;

    [Test]
    [Scope('OnPrem')]
    procedure CreateDefaultAddinsWhenPageRuns()
    var
        OfficeAddin: Record "Office Add-in";
        OfficeAddinManagement: TestPage "Office Add-in Management";
    begin
        // [SCENARIO 173442] Add-ins should always be available - if they don't exist, create them when the management page opens.

        // [GIVEN] None of the default add-ins exist
        OfficeAddin.DeleteAll();

        // [WHEN] Office add-in management page is run.
        OfficeAddinManagement.Trap();
        PAGE.Run(PAGE::"Office Add-in Management");

        // [THEN] The default add-ins are created and available to deploy.
        Assert.AreEqual(2, OfficeAddin.Count, 'Default add-ins did not get created.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ManifestGeneration()
    var
        OfficeAddin: Record "Office Add-in";
        FileName: Text;
    begin
        // Validate that a manifest can be generated

        // Setup
        Initialize();
        InitializeHyperLinkNoSeries5Prefix();
        AddinManifestManagement.GetAddin(OfficeAddin, CODEUNIT::"Hyperlink Manifest");

        // Exercise
        AddinManifestManagement.SetTestMode(true);
        FileName := AddinManifestManagement.SaveManifestToServer(OfficeAddin);

        // Validate
        VerifyCommonManifestItems(FileName);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure IntelligentInfoManifestGeneration()
    var
        OfficeAddin: Record "Office Add-in";
        FileName: Text;
    begin
        // Validate that the intelligent information manifest can be generated and that the URLs are updated

        // Setup
        Initialize();
        AddinManifestManagement.GetAddin(OfficeAddin, CODEUNIT::"Intelligent Info Manifest");

        // Exercise
        AddinManifestManagement.SetTestMode(true);
        FileName := AddinManifestManagement.SaveManifestToServer(OfficeAddin);

        // Validate
        VerifyCommonManifestItems(FileName);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure HyperlinkManifestNoSeriesRegex()
    var
        OfficeAddin: Record "Office Add-in";
        FileName: Text;
    begin
        // Validate that a manifest is generated with multiple regular expressions

        // Setup
        Initialize();
        InitializeHyperLinkNoSeries5Prefix();
        AddinManifestManagement.GetAddin(OfficeAddin, CODEUNIT::"Hyperlink Manifest");

        // Exercise
        AddinManifestManagement.SetTestMode(true);
        FileName := AddinManifestManagement.SaveManifestToServer(OfficeAddin);

        // Validate
        VerifyNoSeriesRegex5Prefix(FileName);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure HyperlinkManifestNoSeriesRegex1Prefix()
    var
        OfficeAddin: Record "Office Add-in";
        FileName: Text;
    begin
        // Validate that a manifest is generated with multiple regular expressions

        // Setup
        Initialize();
        InitializeHyperLinkNoSeries1Prefix();
        OfficeAddin."Manifest Codeunit" := CODEUNIT::"Hyperlink Manifest";
        OfficeAddin.FindFirst();

        // Exercise
        AddinManifestManagement.SetTestMode(true);
        FileName := AddinManifestManagement.SaveManifestToServer(OfficeAddin);

        // Validate
        VerifyNoSeriesRegex1Prefix(FileName);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SaveManifest()
    var
        OfficeAddin: Record "Office Add-in";
        TempFileName: Text;
    begin
        // Validate that a generated manifest saves as expected to a given filename

        // Setup
        Initialize();
        InitializeHyperLinkNoSeries5Prefix();
        OfficeAddin."Manifest Codeunit" := CODEUNIT::"Hyperlink Manifest";
        OfficeAddin.FindFirst();

        // Exercise
        AddinManifestManagement.SetTestMode(true);
        TempFileName := AddinManifestManagement.SaveManifestToServer(OfficeAddin);

        // Validate
        Assert.IsTrue(Exists(TempFileName), StrSubstNo('Manifest did not download correctly, %1 does not exist', TempFileName));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ManifestGenerationHyperLink()
    var
        OfficeAddin: Record "Office Add-in";
        FilePath: Text;
    begin
        // Validate that the Hyperlink add in manifest generates properly
        Initialize();
        InitializeHyperLinkNoSeries5Prefix();
        AddinManifestManagement.GetAddin(OfficeAddin, CODEUNIT::"Hyperlink Manifest");

        AddinManifestManagement.SetTestMode(true);
        FilePath := AddinManifestManagement.SaveManifestToServer(OfficeAddin);

        VerifyHyperlinkManifest(FilePath);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdateServerInformation()
    var
        OfficeAddin: Record "Office Add-in";
        XMLDomManagement: Codeunit "XML DOM Management";
        OldManifestXML: DotNet XmlNode;
        NewManifestXML: DotNet XmlNode;
    begin
        // When generating a manifest, the default manifest template is unchanged.

        // Setup
        Initialize();
        InitializeHyperLinkNoSeries5Prefix();
        AddinManifestManagement.GetAddin(OfficeAddin, CODEUNIT::"Hyperlink Manifest");
        XMLDomManagement.LoadXMLNodeFromText(OfficeAddin.GetDefaultManifestText(), OldManifestXML);

        // Exercise
        AddinManifestManagement.SetTestMode(true);
        AddinManifestManagement.SaveManifestToServer(OfficeAddin);

        // Validate
        XMLDomManagement.LoadXMLNodeFromText(OfficeAddin.GetDefaultManifestText(), NewManifestXML);
        VerifySameServerInformation(OldManifestXML, NewManifestXML);
    end;

    [Test]
    [HandlerFunctions('O365CredentialsHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure SetO365Credentials()
    var
        TempOfficeAdminCredentials: Record "Office Admin. Credentials" temporary;
    begin
        // Call the add in credentials page, enter credentials, and verify that they make it into the table

        // Setup
        Initialize();
        TempOfficeAdminCredentials.DeleteAll();
        Commit();

        // Exerise
        GetOfficeAdminCredentials(TempOfficeAdminCredentials);

        // Verify
        TempOfficeAdminCredentials.Find();
        Assert.AreEqual(AdminEmail, TempOfficeAdminCredentials.Email, 'Credential mismatch: Email');
        AssertSecret(AdminPassword, TempOfficeAdminCredentials.GetPasswordAsSecretText(), 'Credential mismatch: Password');
    end;

    [Test]
    [HandlerFunctions('ExchangeCredentialsHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ExchangeCredentialsDefaultEndpoint()
    var
        TempOfficeAdminCredentials: Record "Office Admin. Credentials" temporary;
    begin
        // Call the add in credentials page, enter credentials, and verify that they make it into the table

        // Setup
        Initialize();
        TempOfficeAdminCredentials.DeleteAll();
        Commit();

        // Exerise
        GetOfficeAdminCredentials(TempOfficeAdminCredentials);

        // Verify
        TempOfficeAdminCredentials.Find();
        Assert.AreEqual(AdminEmail, TempOfficeAdminCredentials.Email, 'Credential mismatch: Email');
        AssertSecret(AdminPassword, TempOfficeAdminCredentials.GetPasswordAsSecretText(), 'Credential mismatch: Password');
        Assert.AreEqual(TempOfficeAdminCredentials.DefaultEndpoint(), TempOfficeAdminCredentials.Endpoint, 'Default endpoint not set.');
    end;

    [Test]
    [HandlerFunctions('ExchangeCredentialsHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ExchangeCredentialsClearEndpoint()
    var
        TempOfficeAdminCredentials: Record "Office Admin. Credentials" temporary;
    begin
        // Call the add in credentials page, enter credentials, and verify that they make it into the table

        // Setup
        Initialize();
        TempOfficeAdminCredentials.DeleteAll();
        Commit();

        // Exerise
        GetOfficeAdminCredentials(TempOfficeAdminCredentials);

        TempOfficeAdminCredentials.Find();
        TempOfficeAdminCredentials.Endpoint := '';
        TempOfficeAdminCredentials.Modify(true);

        // Verify
        Assert.AreEqual(TempOfficeAdminCredentials.DefaultEndpoint(), TempOfficeAdminCredentials.Endpoint, 'Default endpoint not set.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EnvironmentInfoGetsDetailsFromManifest()
    var
        OfficeAddin: Record "Office Add-in";
        XMLDomManagement: Codeunit "XML DOM Management";
        XMLRootNode: DotNet XmlNode;
        XMLFoundNodes: DotNet XmlNodeList;
        XMLNamespaceMgr: DotNet XmlNamespaceManager;
        Description: Text[250];
        Id: Guid;
        Name: Text[50];
        ManifestText: Text;
    begin
        // Get details from the add in helper and validate those against the manifest XML to verify that they are gathered appropriately.

        // Setup
        Initialize();
        AddinManifestManagement.GetAddin(OfficeAddin, CODEUNIT::"Hyperlink Manifest");
        ManifestText := OfficeAddin.GetDefaultManifestText();

        XMLDomManagement.LoadXMLNodeFromText(ManifestText, XMLRootNode);
        XMLDomManagement.AddNamespaces(XMLNamespaceMgr, XMLRootNode.OwnerDocument);
        XMLNamespaceMgr.AddNamespace('x', XMLNamespaceMgr.DefaultNamespace);

        // Exercise
        XMLDomManagement.FindNodesWithNamespaceManager(XMLRootNode, 'x:DisplayName', XMLNamespaceMgr, XMLFoundNodes);
        Name := XMLFoundNodes.Item(0).Attributes.ItemOf('DefaultValue').Value();

        XMLDomManagement.FindNodesWithNamespaceManager(XMLRootNode, 'x:Description', XMLNamespaceMgr, XMLFoundNodes);
        Description := XMLFoundNodes.Item(0).Attributes.ItemOf('DefaultValue').Value();

        XMLDomManagement.FindNodesWithNamespaceManager(XMLRootNode, 'x:Id', XMLNamespaceMgr, XMLFoundNodes);
        Id := XMLFoundNodes.Item(0).InnerText;

        // Verify
        Assert.AreEqual(Name, AddinManifestManagement.GetAppName(ManifestText),
          'Name mismatch between test XML and Office AddIn Configuration');
        Assert.AreEqual(Description, AddinManifestManagement.GetAppDescription(ManifestText),
          'Description mismatch between test XML and Office AddIn Configuration');
        Assert.AreEqual(LowerCase(Id), StrSubstNo('{%1}', LowerCase(AddinManifestManagement.GetAppID(ManifestText))),
          'Id mismatch between test XML and Office AddIn Configuration');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifySavingGeneratedManifest()
    var
        OfficeAddin: Record "Office Add-in";
        OldManifest: Text;
        NewManifest: Text;
    begin
        // Validate that updating the triggers also updates the manifest in the configuration table

        // Setup
        Initialize();
        InitializeHyperLinkNoSeries5Prefix();
        AddinManifestManagement.GetAddin(OfficeAddin, CODEUNIT::"Hyperlink Manifest");
        OldManifest := OfficeAddin.GetDefaultManifestText();

        // Exercise
        AddinManifestManagement.SetTestMode(true);
        NewManifest := FileManagement.GetFileContents(AddinManifestManagement.SaveManifestToServer(OfficeAddin));

        // Validate
        Assert.AreNotEqual(OldManifest, NewManifest, 'Manifest did not change as a result of generating a new manifest');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ConstructURLGetsURLWithoutCompany()
    var
        ExpectedUrl: Text;
        Url: Text;
        HostType: Text;
        QstStrPos: Integer;
    begin
        // Validate that the ConstructURL function creates the URL correctly.

        // Setup
        Initialize();
        HostType := 'Outlook-Test2';

        // Exercise
        Url := LowerCase(AddinManifestManagement.ConstructURL(HostType, '', ''));
        ExpectedUrl := GetUrl(CLIENTTYPE::Web);

        QstStrPos := StrPos(ExpectedUrl, '?');
        if QstStrPos > 0 then
            ExpectedUrl := InsStr(ExpectedUrl, '/OfficeAddin.aspx', QstStrPos) + '&OfficeContext=' + HostType
        else
            ExpectedUrl := ExpectedUrl + '/OfficeAddin.aspx?OfficeContext=' + HostType;

        // Verify
        Assert.AreEqual(LowerCase(ExpectedUrl), Url, 'ConstructURL received incorrect URL.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ConstructURLGetsURLWithAddinCommand()
    var
        OutlookCommand: DotNet OutlookCommand;
        ExpectedUrl: Text;
        Url: Text;
        HostType: Text;
        Command: Text;
        QstStrPos: Integer;
    begin
        // Validate that the ConstructURL function creates the URL correctly if an add-in command is specified.

        // Setup
        Initialize();
        HostType := 'Outlook-Test3';
        Command := OutlookCommand.NewSalesCreditMemo;

        // Exercise
        Url := LowerCase(AddinManifestManagement.ConstructURL(HostType, Command, ''));
        ExpectedUrl := GetUrl(CLIENTTYPE::Web);

        QstStrPos := StrPos(ExpectedUrl, '?');
        if QstStrPos > 0 then
            ExpectedUrl := InsStr(ExpectedUrl, '/OfficeAddin.aspx', QstStrPos) + '&OfficeContext=' + HostType
        else
            ExpectedUrl := ExpectedUrl + '/OfficeAddin.aspx?OfficeContext=' + HostType;
        ExpectedUrl := ExpectedUrl + '&Command=' + Command;

        // Verify
        Assert.AreEqual(LowerCase(ExpectedUrl), Url, 'ConstructURL received incorrect URL.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DownloadContactInsightsManifestUI()
    var
        OfficeAddinManagement: TestPage "Office Add-in Management";
    begin
        // Setup
        Initialize();
        OfficeAddinManagement.OpenView();

        // Exercise
        OfficeAddinManagement.FindFirstField(OfficeAddinManagement."Manifest Codeunit", CODEUNIT::"Intelligent Info Manifest");

        // Verify that an error is thrown - generation will fail due to HTTPS restraints
        asserterror OfficeAddinManagement."Download Add-in Manifest".Invoke();
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('AcceptPrivacyNotice')]
    procedure DownloadDocInsightsManifestAndApprovePrivacyNotice()
    var
        OfficeAddin: Record "Office Add-in";
        AddinManifestManagement: Codeunit "Add-in Manifest Management";
        Filename: Text;
    begin
        // Setup
        Initialize();
        AddinManifestManagement.SetTestMode(true);
        Filename := FileManagement.ServerTempFileName('xml');
        AddinManifestManagement.GetAddin(OfficeAddin, CODEUNIT::"Hyperlink Manifest");
        PrivacyNotice.SetApprovalState(PrivacyNoticeRegistrations.GetExchangePrivacyNoticeId(), "Privacy Notice Approval State"::"Not set");

        // Exercise
        AddinManifestManagement.DownloadManifestToClient(OfficeAddin, Filename);

        // Verify
        Assert.IsTrue(Exists(Filename), 'File did not generate and download.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DownloadDocInsightsManifest()
    var
        OfficeAddin: Record "Office Add-in";
        AddinManifestManagement: Codeunit "Add-in Manifest Management";
        Filename: Text;
    begin
        // Setup
        Initialize();
        AddinManifestManagement.SetTestMode(true);
        Filename := FileManagement.ServerTempFileName('xml');
        AddinManifestManagement.GetAddin(OfficeAddin, CODEUNIT::"Hyperlink Manifest");

        // Exercise
        AddinManifestManagement.DownloadManifestToClient(OfficeAddin, Filename);

        // Verify
        Assert.IsTrue(Exists(Filename), 'File did not generate and download.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DownloadContactInsightsManifest()
    var
        OfficeAddin: Record "Office Add-in";
        AddinManifestManagement: Codeunit "Add-in Manifest Management";
        Filename: Text;
    begin
        // Setup
        Initialize();
        AddinManifestManagement.SetTestMode(true);
        Filename := FileManagement.ServerTempFileName('xml');
        AddinManifestManagement.GetAddin(OfficeAddin, CODEUNIT::"Intelligent Info Manifest");

        // Exercise
        AddinManifestManagement.DownloadManifestToClient(OfficeAddin, Filename);

        // Verify
        Assert.IsTrue(Exists(Filename), 'File did not generate and download.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DownloadAndUploadManifest()
    var
        OfficeAddin: Record "Office Add-in";
        OfficeAddin2: Record "Office Add-in";
        AddinManifestManagement: Codeunit "Add-in Manifest Management";
        Filename: Text;
        Filename2: Text;
        Manifest1Text: Text;
        Manifest2Text: Text;
    begin
        // Setup
        Initialize();
        AddinManifestManagement.SetTestMode(true);
        Filename := FileManagement.ServerTempFileName('xml');
        Filename2 := FileManagement.ServerTempFileName('xml');

        AddinManifestManagement.GetAddin(OfficeAddin, CODEUNIT::"Hyperlink Manifest");
        Manifest1Text := OfficeAddin.GetDefaultManifestText();

        // Exercise
        AddinManifestManagement.DownloadManifestToClient(OfficeAddin, Filename);

        OfficeAddin2.Init();
        OfficeAddin2."Manifest Codeunit" := CODEUNIT::"Hyperlink Manifest";
        AddinManifestManagement.UploadDefaultManifest(OfficeAddin2, Filename);
        OfficeAddin2.Modify(true);

        AddinManifestManagement.DownloadManifestToClient(OfficeAddin2, Filename2);
        Manifest2Text := OfficeAddin2.GetDefaultManifestText();

        // Verify
        Assert.IsTrue(Exists(Filename), 'Existing manifest did not generate and download.');
        Assert.IsTrue(Exists(Filename2), 'Newly created manifest did not generate and download.');
        Assert.AreEqual(
          AddinManifestManagement.GetAppDescription(Manifest1Text), AddinManifestManagement.GetAppDescription(Manifest2Text),
          'Description mismatch.');
        Assert.AreEqual(
          AddinManifestManagement.GetAppID(Manifest1Text), AddinManifestManagement.GetAppID(Manifest2Text), 'AppID mismatch.');
        Assert.AreEqual(
          AddinManifestManagement.GetAppName(Manifest1Text), AddinManifestManagement.GetAppName(Manifest2Text), 'App name mismatch.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DownloadModifyAndUploadManifest()
    var
        OfficeAddin: Record "Office Add-in";
        TempBlob: Codeunit "Temp Blob";
        AddinManifestManagement: Codeunit "Add-in Manifest Management";
        OutStream: OutStream;
        InStream: InStream;
        Filename: Text;
        ManifestText: Text;
        NewResource: Text;
        SearchString: Text;
        SearchPosition: Integer;
    begin
        // [SCENARIO] A power user can download an add-in manifest file, make changes to it, then upload it to the server. When the add-in is downloaded or deployed, the changes made will persist.
        Initialize();
        AddinManifestManagement.SetTestMode(true);
        Filename := FileManagement.ServerTempFileName('xml');
        SearchString := '<bt:Url id="taskPaneUrl"';
        NewResource := '<bt:Url id="viewItemsUrl" DefaultValue="https://server" />';

        // [GIVEN] The user has made a change to the manifest for a given add-in.
        AddinManifestManagement.GetAddin(OfficeAddin, CODEUNIT::"Intelligent Info Manifest");
        ManifestText := OfficeAddin.GetDefaultManifestText();
        SearchPosition := StrPos(ManifestText, SearchString) - 1;
        ManifestText := InsStr(ManifestText, NewResource, SearchPosition);
        TempBlob.CreateOutStream(OutStream, TEXTENCODING::UTF8);
        OutStream.WriteText(ManifestText);

        // [GIVEN] The change exists in an XML file.
        FileManagement.BLOBExportToServerFile(TempBlob, Filename);

        // [WHEN] User uploads the default manifest for a given add-in.
        OfficeAddin.Init();
        OfficeAddin."Manifest Codeunit" := CODEUNIT::"Intelligent Info Manifest";
        AddinManifestManagement.UploadDefaultManifest(OfficeAddin, Filename);
        OfficeAddin.Modify(true);

        // [WHEN] User downloads the add-in manifest for the same add-in.
        Filename := FileManagement.ServerTempFileName('xml');
        AddinManifestManagement.DownloadManifestToClient(OfficeAddin, Filename);

        // [THEN] The new, generated manifest contains the change that the user had previously made.
        FileManagement.BLOBImportFromServerFile(TempBlob, Filename);
        TempBlob.CreateInStream(InStream, TEXTENCODING::UTF8);
        InStream.Read(ManifestText);
        Assert.IsTrue(StrPos(ManifestText, NewResource) > 0, 'New resource could not be found in generated manifest.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetOfficeAddin()
    var
        OfficeAddin: Record "Office Add-in";
        ManifestCodeunit: Integer;
    begin
        // Verify that we can get the correct add-in when specifying the manifest codeunit ID.
        for ManifestCodeunit := CODEUNIT::"Intelligent Info Manifest" to CODEUNIT::"Hyperlink Manifest" do begin
            AddinManifestManagement.GetAddin(OfficeAddin, ManifestCodeunit);
            Assert.AreEqual(ManifestCodeunit, OfficeAddin."Manifest Codeunit", 'Incorrect add-in retrieved.');
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetOfficeAddinByHostType()
    var
        OfficeHostType: DotNet OfficeHostType;
    begin
        // Verify that we can get the correct add-in when specifying a host type
        VerifyAddinByHostType(OfficeHostType.OutlookItemRead, CODEUNIT::"Intelligent Info Manifest");
        VerifyAddinByHostType(OfficeHostType.OutlookItemEdit, CODEUNIT::"Intelligent Info Manifest");
        VerifyAddinByHostType(OfficeHostType.OutlookMobileApp, CODEUNIT::"Intelligent Info Manifest");
        VerifyAddinByHostType(OfficeHostType.OutlookPopOut, CODEUNIT::"Intelligent Info Manifest");
        VerifyAddinByHostType(OfficeHostType.OutlookTaskPane, CODEUNIT::"Intelligent Info Manifest");

        VerifyAddinByHostType(OfficeHostType.OutlookHyperlink, CODEUNIT::"Hyperlink Manifest");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetOfficeAddinID()
    var
        InsightsID: Text;
        HyperlinkID: Text;
        AppID: Text;
        ManifestCodeunit: Integer;
    begin
        // Verify that we can get the correct add-in ID. These IDs should never change.
        InsightsID := 'cfca30bd-9846-4819-a6fc-56c89c5aae96';
        HyperlinkID := 'cf6f2e6a-5f76-4a17-b966-2ed9d0b3e88a';

        ManifestCodeunit := CODEUNIT::"Intelligent Info Manifest";
        AddinManifestManagement.GetAddinID(AppID, ManifestCodeunit);
        Assert.AreEqual(InsightsID, AppID, 'Incorrect add-in ID retrieved.');

        ManifestCodeunit := CODEUNIT::"Hyperlink Manifest";
        AddinManifestManagement.GetAddinID(AppID, ManifestCodeunit);
        Assert.AreEqual(HyperlinkID, AppID, 'Incorrect add-in ID retrieved.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetOfficeAddinVersion()
    var
        InsightsVersion: Text;
        HyperlinkVersion: Text;
        AddinVersion: Text;
        ManifestCodeunit: Integer;
    begin
        // Verify that we can get the correct manifest version.
        InsightsVersion := '2.0.0.0';
        HyperlinkVersion := '2.1.0.0';

        ManifestCodeunit := CODEUNIT::"Intelligent Info Manifest";
        AddinManifestManagement.GetAddinVersion(AddinVersion, ManifestCodeunit);
        Assert.AreEqual(InsightsVersion, AddinVersion, 'Incorrect add-in ID retrieved.');

        ManifestCodeunit := CODEUNIT::"Hyperlink Manifest";
        AddinManifestManagement.GetAddinVersion(AddinVersion, ManifestCodeunit);
        Assert.AreEqual(HyperlinkVersion, AddinVersion, 'Incorrect add-in ID retrieved.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetOfficeAddinManifestCodeunit()
    var
        OfficeHostType: DotNet OfficeHostType;
    begin
        // Verify that we can retrieve the correct manifest codeunit.
        VerifyAddinManifestCodeunit(OfficeHostType.OutlookItemRead, CODEUNIT::"Intelligent Info Manifest");
        VerifyAddinManifestCodeunit(OfficeHostType.OutlookItemEdit, CODEUNIT::"Intelligent Info Manifest");
        VerifyAddinManifestCodeunit(OfficeHostType.OutlookMobileApp, CODEUNIT::"Intelligent Info Manifest");
        VerifyAddinManifestCodeunit(OfficeHostType.OutlookTaskPane, CODEUNIT::"Intelligent Info Manifest");
        VerifyAddinManifestCodeunit(OfficeHostType.OutlookPopOut, CODEUNIT::"Intelligent Info Manifest");

        VerifyAddinManifestCodeunit(OfficeHostType.OutlookHyperlink, CODEUNIT::"Hyperlink Manifest");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetOfficeAddinDefaultManifestText()
    var
        OfficeAddin: Record "Office Add-in";
        InStream: InStream;
        ManifestText: Text;
        RetrievedManifestText: Text;
    begin
        // Setup
        AddinManifestManagement.GetAddin(OfficeAddin, CODEUNIT::"Intelligent Info Manifest");
        ManifestText := CreateGuid();

        // Exercise
        OfficeAddin.SetDefaultManifestText(ManifestText);

        // Verify
        OfficeAddin."Default Manifest".CreateInStream(InStream, TEXTENCODING::UTF8);
        InStream.Read(RetrievedManifestText);
        Assert.AreEqual(ManifestText, RetrievedManifestText, 'Retrieved manifest is not the same as what was set.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetOfficeAddinDefaultManifestText()
    var
        OfficeAddin: Record "Office Add-in";
        OutStream: OutStream;
        ManifestText: Text;
        RetrievedManifestText: Text;
    begin
        // Setup - Office add-in has known value as default manifest
        AddinManifestManagement.GetAddin(OfficeAddin, CODEUNIT::"Intelligent Info Manifest");
        ManifestText := CreateGuid();
        OfficeAddin."Default Manifest".CreateOutStream(OutStream, TEXTENCODING::UTF8);
        OutStream.Write(ManifestText);
        OfficeAddin.Modify();

        // Exercise
        RetrievedManifestText := OfficeAddin.GetDefaultManifestText();

        // Verify
        Assert.AreEqual(ManifestText, RetrievedManifestText, 'Retrieved manifest is not the same as what was set.');
    end;

    [Normal]
    [Scope('OnPrem')]
    procedure CreateNoSeriesAndLine(var NoSeries: Record "No. Series"; var NoSeriesLine: Record "No. Series Line"; StartNo: Code[20]; EndNo: Code[20])
    var
        LibraryUtility: Codeunit "Library - Utility";
    begin
        LibraryUtility.CreateNoSeries(NoSeries, true, true, true);
        LibraryUtility.CreateNoSeriesLine(NoSeriesLine, NoSeries.Code, StartNo, EndNo);
        LibraryNoSeries.CreateNoSeriesRelationship(NoSeries.Code, NoSeriesLine."Series Code");
    end;

    local procedure Initialize()
    var
        OfficeAddin: Record "Office Add-in";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        AddinManifestManagement: Codeunit "Add-in Manifest Management";
    begin
        PrivacyNotice.SetApprovalState(PrivacyNoticeRegistrations.GetExchangePrivacyNoticeId(), "Privacy Notice Approval State"::Agreed);
        AddinManifestManagement.CreateDefaultAddins(OfficeAddin);
        LibraryApplicationArea.EnableFoundationSetup();
    end;

    [Normal]
    [Scope('OnPrem')]
    procedure InitializeHyperLinkNoSeries5Prefix()
    begin
        // Set up appropriate number series for the document types for hyperlink:

        InitializeHyperLinkNoSeries5PrefixSales();
        InitializeHyperLinkNoSeries5PrefixPurchases();
    end;

    [Normal]
    [Scope('OnPrem')]
    procedure InitializeHyperLinkNoSeries5PrefixSales()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        // Set up appropriate number series for the document types for hyperlink:
        SalesReceivablesSetup.Get();

        CreateSalesCrMemoNoSeries('CC0_0CC44', 'CC0_0CC444444', SalesReceivablesSetup);
        CreateSalesInvoiceNoSeries('D0D**0D0', 'D0D**D0D9', SalesReceivablesSetup);
        CreateSalesOrderNoSeries('CAE-3420', 'CAE-3423', SalesReceivablesSetup);
        CreateSalesQuoteNoSeries('10000', '99999', SalesReceivablesSetup);

        SalesReceivablesSetup.Modify();
    end;

    [Normal]
    [Scope('OnPrem')]
    procedure InitializeHyperLinkNoSeries5PrefixPurchases()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        // Set up appropriate number series for the document types for hyperlink:
        PurchasesPayablesSetup.Get();

        CreatePurchaseInvoiceNoSeries('10000', '99999', PurchasesPayablesSetup);
        CreatePurchaseOrderNoSeries('BBB/~~~#+00', 'BBB/~~~#+99', PurchasesPayablesSetup);
        CreatePurchaseQuoteNoSeries('12345A-1', '12345A-999', PurchasesPayablesSetup);
        CreatePurchaseCrMemoNoSeries('10000', '99999', PurchasesPayablesSetup);

        PurchasesPayablesSetup.Modify();
    end;

    [Normal]
    [Scope('OnPrem')]
    procedure InitializeHyperLinkNoSeries1Prefix()
    begin
        // Set up appropriate number series for the document types for hyperlink:

        InitializeHyperLinkNoSeries1PrefixPurchases();
        InitializeHyperLinkNoSeries1PrefixSales();
    end;

    [Normal]
    [Scope('OnPrem')]
    procedure InitializeHyperLinkNoSeries1PrefixSales()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        // Set up appropriate number series for the document types for hyperlink:
        SalesReceivablesSetup.Get();

        CreateSalesCrMemoNoSeries('10000', '99999', SalesReceivablesSetup);
        CreateSalesInvoiceNoSeries('10000', '99999', SalesReceivablesSetup);
        CreateSalesOrderNoSeries('10000', '99999', SalesReceivablesSetup);
        CreateSalesQuoteNoSeries('D0D0D0D0', 'D0D0D0D9', SalesReceivablesSetup);

        SalesReceivablesSetup.Modify();
    end;

    [Normal]
    [Scope('OnPrem')]
    procedure InitializeHyperLinkNoSeries1PrefixPurchases()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        // Set up appropriate number series for the document types for hyperlink:
        PurchasesPayablesSetup.Get();

        CreatePurchaseQuoteNoSeries('10000', '99999', PurchasesPayablesSetup);
        CreatePurchaseCrMemoNoSeries('10000', '99999', PurchasesPayablesSetup);
        CreatePurchaseInvoiceNoSeries('10000', '99999', PurchasesPayablesSetup);
        CreatePurchaseOrderNoSeries('10000', '99999', PurchasesPayablesSetup);

        PurchasesPayablesSetup.Modify();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ExchangeCredentialsHandler(var OfficeAdminCredentialsDlg: TestPage "Office Admin. Credentials")
    begin
        OfficeAdminCredentialsDlg.New();
        AdminEmail := CreateGuid();
        AdminPassword := CreateGuid();
        Assert.IsTrue(OfficeAdminCredentialsDlg.UseO365.Visible(), 'Could not find O365 selection field.');
        OfficeAdminCredentialsDlg.UseO365.SetValue(false);
        OfficeAdminCredentialsDlg.ActionNext.Invoke();

        // If there's an issue with the visibility of the below items, do not proceed.
        Assert.IsTrue(OfficeAdminCredentialsDlg.OnPremUsername.Visible(), 'Could not find Exchange username field.');
        Assert.IsTrue(OfficeAdminCredentialsDlg.OnPremPassword.Visible(), 'Could not find Exchange password field.');
        Assert.IsTrue(OfficeAdminCredentialsDlg.Endpoint.Visible(), 'Could not find Exchange PS endpoint field.');
        Assert.IsFalse(OfficeAdminCredentialsDlg.O365Email.Visible(), 'Could not find O365 email field.');
        Assert.IsFalse(OfficeAdminCredentialsDlg.O365Password.Visible(), 'Could not find O365 password field.');

        OfficeAdminCredentialsDlg.OnPremUsername.SetValue(AdminEmail);
        OfficeAdminCredentialsDlg.OnPremPassword.SetValue(AdminPassword);
        OfficeAdminCredentialsDlg.ActionFinish.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure O365CredentialsHandler(var OfficeAdminCredentialsDlg: TestPage "Office Admin. Credentials")
    begin
        OfficeAdminCredentialsDlg.New();
        AdminEmail := CreateGuid();
        AdminPassword := CreateGuid();
        Assert.IsTrue(OfficeAdminCredentialsDlg.UseO365.Visible(), 'Could not find O365 selection field.');
        OfficeAdminCredentialsDlg.UseO365.SetValue(true);
        OfficeAdminCredentialsDlg.ActionNext.Invoke();

        // If there's an issue with the visibility of the below items, do not proceed.
        Assert.IsFalse(OfficeAdminCredentialsDlg.OnPremUsername.Visible(), 'Expected Exchange username field to be hidden.');
        Assert.IsFalse(OfficeAdminCredentialsDlg.OnPremPassword.Visible(), 'Expected Exchange password field to be hidden.');
        Assert.IsFalse(OfficeAdminCredentialsDlg.Endpoint.Visible(), 'Expected Exchange PS endpoint field to be hidden.');
        Assert.IsTrue(OfficeAdminCredentialsDlg.O365Email.Visible(), 'Could not find O365 email field.');
        Assert.IsTrue(OfficeAdminCredentialsDlg.O365Password.Visible(), 'Could not find O365 password field.');

        OfficeAdminCredentialsDlg.O365Email.SetValue(AdminEmail);
        OfficeAdminCredentialsDlg.O365Password.SetValue(AdminPassword);
        OfficeAdminCredentialsDlg.ActionFinish.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CloseAndReopenCredentialsHandler(var OfficeAdminCredentialsDlg: TestPage "Office Admin. Credentials")
    begin
        OfficeAdminCredentialsDlg.UseO365.SetValue(false);
        OfficeAdminCredentialsDlg.ActionNext.Invoke();

        if CloseReopenHandlerAction = CloseReopenHandlerAction::EnterCredentials then begin
            OfficeAdminCredentialsDlg.OnPremUsername.SetValue(LibraryUtility.GenerateRandomAlphabeticText(10, 0));
            OfficeAdminCredentialsDlg.OnPremPassword.SetValue(LibraryUtility.GenerateRandomText(10));
            OfficeAdminCredentialsDlg.ActionFinish.Invoke();
        end;

        LibraryVariableStorage.Enqueue(true);
    end;

    [NonDebuggable]
    local procedure AssertSecret(Expected: Text; Actual: SecretText; Message: Text)
    begin
        Assert.AreEqual(Expected, Actual.Unwrap(), Message);
    end;

    [Normal]
    [Scope('OnPrem')]
    procedure ValidateUnchangedXML(OldXML: DotNet XmlNode; NewXML: DotNet XmlNode; NodeLocation: Text; XMLNamespaceMgr: DotNet XmlNamespaceManager)
    var
        OldXMLFoundNodes: DotNet XmlNodeList;
        NewXMLFoundNodes: DotNet XmlNodeList;
        OldValue: Text;
        NewValue: Text;
        i: Integer;
    begin
        XMLDomManagement.FindNodesWithNamespaceManager(
          OldXML, NodeLocation, XMLNamespaceMgr, OldXMLFoundNodes);
        XMLDomManagement.FindNodesWithNamespaceManager(
          NewXML, NodeLocation, XMLNamespaceMgr, NewXMLFoundNodes);
        Assert.AreEqual(OldXMLFoundNodes.Count, NewXMLFoundNodes.Count, 'Difference in number of found XML nodes for DesktopSettings');
        for i := 0 to OldXMLFoundNodes.Count - 1 do begin
            OldValue := XMLDomManagement.GetAttributeValue(OldXMLFoundNodes.Item(0), 'DefaultValue');
            NewValue := XMLDomManagement.GetAttributeValue(NewXMLFoundNodes.Item(0), 'DefaultValue');
            Assert.AreEqual(OldValue, NewValue, 'XML value did not change.');
        end;
    end;

    [Normal]
    [Scope('OnPrem')]
    procedure CreatePurchaseInvoiceNoSeries(StartNo: Code[20]; EndNo: Code[20]; var PurchasesPayablesSetup: Record "Purchases & Payables Setup")
    var
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
    begin
        CreateNoSeriesAndLine(NoSeries, NoSeriesLine, StartNo, EndNo);
        PurchasesPayablesSetup."Invoice Nos." := NoSeries.Code;
    end;

    [Normal]
    [Scope('OnPrem')]
    procedure CreatePurchaseOrderNoSeries(StartNo: Code[20]; EndNo: Code[20]; var PurchasesPayablesSetup: Record "Purchases & Payables Setup")
    var
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
    begin
        CreateNoSeriesAndLine(NoSeries, NoSeriesLine, StartNo, EndNo);
        PurchasesPayablesSetup."Order Nos." := NoSeries.Code;
    end;

    [Normal]
    [Scope('OnPrem')]
    procedure CreatePurchaseQuoteNoSeries(StartNo: Code[20]; EndNo: Code[20]; var PurchasesPayablesSetup: Record "Purchases & Payables Setup")
    var
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
    begin
        CreateNoSeriesAndLine(NoSeries, NoSeriesLine, StartNo, EndNo);
        PurchasesPayablesSetup."Quote Nos." := NoSeries.Code;
    end;

    [Normal]
    [Scope('OnPrem')]
    procedure CreatePurchaseCrMemoNoSeries(StartNo: Code[20]; EndNo: Code[20]; var PurchasesPayablesSetup: Record "Purchases & Payables Setup")
    var
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
    begin
        CreateNoSeriesAndLine(NoSeries, NoSeriesLine, StartNo, EndNo);
        PurchasesPayablesSetup."Credit Memo Nos." := NoSeries.Code;
    end;

    [Normal]
    [Scope('OnPrem')]
    procedure CreateSalesInvoiceNoSeries(StartNo: Code[20]; EndNo: Code[20]; var SalesReceivablesSetup: Record "Sales & Receivables Setup")
    var
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
    begin
        CreateNoSeriesAndLine(NoSeries, NoSeriesLine, StartNo, EndNo);
        SalesReceivablesSetup."Invoice Nos." := NoSeries.Code;
    end;

    [Normal]
    [Scope('OnPrem')]
    procedure CreateSalesOrderNoSeries(StartNo: Code[20]; EndNo: Code[20]; var SalesReceivablesSetup: Record "Sales & Receivables Setup")
    var
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
    begin
        CreateNoSeriesAndLine(NoSeries, NoSeriesLine, StartNo, EndNo);
        SalesReceivablesSetup."Order Nos." := NoSeries.Code;
    end;

    [Normal]
    [Scope('OnPrem')]
    procedure CreateSalesQuoteNoSeries(StartNo: Code[20]; EndNo: Code[20]; var SalesReceivablesSetup: Record "Sales & Receivables Setup")
    var
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
    begin
        CreateNoSeriesAndLine(NoSeries, NoSeriesLine, StartNo, EndNo);
        SalesReceivablesSetup."Quote Nos." := NoSeries.Code;
    end;

    [Normal]
    [Scope('OnPrem')]
    procedure CreateSalesCrMemoNoSeries(StartNo: Code[20]; EndNo: Code[20]; var SalesReceivablesSetup: Record "Sales & Receivables Setup")
    var
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
    begin
        CreateNoSeriesAndLine(NoSeries, NoSeriesLine, StartNo, EndNo);
        SalesReceivablesSetup."Credit Memo Nos." := NoSeries.Code;
    end;

    [Normal]
    local procedure ValidatePurchaseOrderSeriesPrefixInRegex(RegexText: Text; ShouldInclude: Boolean)
    var
        RegExPrefix: Text;
    begin
        RegExPrefix := HyperlinkManifest.GetNoSeriesPrefixes(HyperlinkManifest.GetNoSeriesForPurchaseOrder());
        if ShouldInclude then
            Assert.IsTrue(StrPos(RegexText, RegExPrefix) <> 0, StrSubstNo(NoRuleFoundErr, 'Purchase Order', RegExPrefix, RegexText))
        else
            Assert.IsTrue(StrPos(RegexText, RegExPrefix) = 0, StrSubstNo(RuleFoundErr, 'Purchase Order', RegExPrefix, RegexText));
    end;

    [Normal]
    local procedure ValidatePurchaseQuoteSeriesPrefixInRegex(RegexText: Text; ShouldInclude: Boolean)
    var
        RegExPrefix: Text;
    begin
        RegExPrefix := HyperlinkManifest.GetNoSeriesPrefixes(HyperlinkManifest.GetNoSeriesForPurchaseQuote());
        if ShouldInclude then
            Assert.IsTrue(StrPos(RegexText, RegExPrefix) <> 0, StrSubstNo(NoRuleFoundErr, 'Purchase Quote', RegExPrefix, RegexText))
        else
            Assert.IsTrue(StrPos(RegexText, RegExPrefix) = 0, StrSubstNo(RuleFoundErr, 'Purchase Quote', RegExPrefix, RegexText));
    end;

    [Normal]
    local procedure ValidatePurchaseInvoiceSeriesPrefixInRegex(RegexText: Text; ShouldInclude: Boolean)
    var
        RegExPrefix: Text;
    begin
        RegExPrefix := HyperlinkManifest.GetNoSeriesPrefixes(HyperlinkManifest.GetNoSeriesForPurchaseInvoice());
        if ShouldInclude then
            Assert.IsTrue(StrPos(RegexText, RegExPrefix) <> 0, StrSubstNo(NoRuleFoundErr, 'Purchase Invoice', RegExPrefix, RegexText))
        else
            Assert.IsTrue(StrPos(RegexText, RegExPrefix) = 0, StrSubstNo(RuleFoundErr, 'Purchase Invoice', RegExPrefix, RegexText));
    end;

    [Normal]
    local procedure ValidatePurchaseCrMemoSeriesPrefixInRegex(RegexText: Text; ShouldInclude: Boolean)
    var
        RegExPrefix: Text;
    begin
        RegExPrefix := HyperlinkManifest.GetNoSeriesPrefixes(HyperlinkManifest.GetNoSeriesForPurchaseCrMemo());
        if ShouldInclude then
            Assert.IsTrue(StrPos(RegexText, RegExPrefix) <> 0, StrSubstNo(NoRuleFoundErr, 'Purchase CrMemo', RegExPrefix, RegexText))
        else
            Assert.IsTrue(StrPos(RegexText, RegExPrefix) = 0, StrSubstNo(RuleFoundErr, 'Purchase CrMemo', RegExPrefix, RegexText));
    end;

    [Normal]
    local procedure ValidateSalesOrderSeriesPrefixInRegex(RegexText: Text; ShouldInclude: Boolean)
    var
        RegExPrefix: Text;
    begin
        RegExPrefix := HyperlinkManifest.GetNoSeriesPrefixes(HyperlinkManifest.GetNoSeriesForSalesOrder());
        if ShouldInclude then
            Assert.IsTrue(StrPos(RegexText, RegExPrefix) <> 0, StrSubstNo(NoRuleFoundErr, 'Sales Order', RegExPrefix, RegexText))
        else
            Assert.IsTrue(StrPos(RegexText, RegExPrefix) = 0, StrSubstNo(RuleFoundErr, 'Sales Order', RegExPrefix, RegexText));
    end;

    [Normal]
    local procedure ValidateSalesQuoteSeriesPrefixInRegex(RegexText: Text; ShouldInclude: Boolean)
    var
        RegExPrefix: Text;
    begin
        RegExPrefix := HyperlinkManifest.GetNoSeriesPrefixes(HyperlinkManifest.GetNoSeriesForSalesQuote());
        if ShouldInclude then
            Assert.IsTrue(StrPos(RegexText, RegExPrefix) <> 0, StrSubstNo(NoRuleFoundErr, 'Sales Quote', RegExPrefix, RegexText))
        else
            Assert.IsTrue(StrPos(RegexText, RegExPrefix) = 0, StrSubstNo(RuleFoundErr, 'Sales Quote', RegExPrefix, RegexText));
    end;

    [Normal]
    local procedure ValidateSalesInvoiceSeriesPrefixInRegex(RegexText: Text; ShouldInclude: Boolean)
    var
        RegExPrefix: Text;
    begin
        RegExPrefix := HyperlinkManifest.GetNoSeriesPrefixes(HyperlinkManifest.GetNoSeriesForSalesInvoice());
        if ShouldInclude then
            Assert.IsTrue(StrPos(RegexText, RegExPrefix) <> 0, StrSubstNo(NoRuleFoundErr, 'Sales Invoice', RegExPrefix, RegexText))
        else
            Assert.IsTrue(StrPos(RegexText, RegExPrefix) = 0, StrSubstNo(RuleFoundErr, 'Sales Invoice', RegExPrefix, RegexText));
    end;

    [Normal]
    local procedure ValidateSalesCrMemoSeriesPrefixInRegex(RegexText: Text; ShouldInclude: Boolean)
    var
        RegExPrefix: Text;
    begin
        RegExPrefix := HyperlinkManifest.GetNoSeriesPrefixes(HyperlinkManifest.GetNoSeriesForSalesCrMemo());
        if ShouldInclude then
            Assert.IsTrue(StrPos(RegexText, RegExPrefix) <> 0, StrSubstNo(NoRuleFoundErr, 'Sales CrMemo', RegExPrefix, RegexText))
        else
            Assert.IsTrue(StrPos(RegexText, RegExPrefix) = 0, StrSubstNo(RuleFoundErr, 'Sales CrMemo', RegExPrefix, RegexText));
    end;

    local procedure VerifyAddinByHostType(HostType: Text; CodeunitID: Integer)
    var
        OfficeAddin: Record "Office Add-in";
    begin
        AddinManifestManagement.GetAddinByHostType(OfficeAddin, HostType);
        Assert.AreEqual(CodeunitID, OfficeAddin."Manifest Codeunit", StrSubstNo('Incorrect add-in retrieved for %1.', HostType));
    end;

    local procedure VerifyAddinManifestCodeunit(HostType: Text; ExpectedCodeunit: Integer)
    var
        ActualCodeunit: Integer;
    begin
        AddinManifestManagement.GetManifestCodeunit(ActualCodeunit, HostType);
        Assert.AreEqual(ExpectedCodeunit, ActualCodeunit, StrSubstNo('Incorrect manifest codeunit retrieved for %1', HostType));
    end;

    [Normal]
    local procedure VerifyHyperlinkManifest(FileName: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        FileManagement: Codeunit "File Management";
        XMLDomManagement: Codeunit "XML DOM Management";
        ManifestStream: InStream;
        XMLRootNode: DotNet XmlNode;
        XMLFoundNodes: DotNet XmlNodeList;
        XMLNamespaceMgr: DotNet XmlNamespaceManager;
        NodeText: Text;
    begin
        VerifyCommonManifestItems(FileName);
        FileManagement.BLOBImportFromServerFile(TempBlob, FileName);
        TempBlob.CreateInStream(ManifestStream);

        XMLDomManagement.LoadXMLNodeFromInStream(ManifestStream, XMLRootNode);
        XMLDomManagement.AddNamespaces(XMLNamespaceMgr, XMLRootNode.OwnerDocument);

        // Need to add the default with a 'dummy' prefix - xpath doesn't like default namespaces
        XMLNamespaceMgr.AddNamespace('x', 'http://schemas.microsoft.com/office/appforoffice/1.1');

        // Validate that the regex has the first trigger
        XMLDomManagement.FindNodesWithNamespaceManager(
          XMLRootNode,
          'x:Rule[@xsi:type="RuleCollection"]/x:Rule[@xsi:type="RuleCollection"]/x:Rule[@xsi:type="ItemHasRegularExpressionMatch"]',
          XMLNamespaceMgr, XMLFoundNodes);
        Assert.IsTrue(XMLFoundNodes.Count > 0, 'Missing triggers in XML');

        // Validate URLs
        XMLDomManagement.FindNodesWithNamespaceManager(
          XMLRootNode, 'x:FormSettings/x:Form[@xsi:type="ItemRead"]/x:DesktopSettings/x:SourceLocation', XMLNamespaceMgr, XMLFoundNodes);
        NodeText := XMLDomManagement.GetAttributeValue(XMLFoundNodes.Item(0), 'DefaultValue');
        Assert.IsTrue(NodeText <> '', 'SourceLocation is empty for DesktopSettings');

        XMLDomManagement.FindNodesWithNamespaceManager(
          XMLRootNode, 'x:FormSettings/x:Form[@xsi:type="ItemRead"]/x:PhoneSettings/x:SourceLocation', XMLNamespaceMgr, XMLFoundNodes);
        NodeText := XMLDomManagement.GetAttributeValue(XMLFoundNodes.Item(0), 'DefaultValue');
        Assert.IsTrue(NodeText <> '', 'SourceLocation is empty for PhoneSettings');

        XMLDomManagement.FindNodesWithNamespaceManager(
          XMLRootNode, 'x:FormSettings/x:Form[@xsi:type="ItemRead"]/x:TabletSettings/x:SourceLocation', XMLNamespaceMgr, XMLFoundNodes);
        NodeText := XMLDomManagement.GetAttributeValue(XMLFoundNodes.Item(0), 'DefaultValue');
        Assert.IsTrue(NodeText <> '', 'SourceLocation is empty for TabletSettings');
    end;

    [Normal]
    [Scope('OnPrem')]
    procedure VerifyCommonManifestItems(FileName: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        FileManagement: Codeunit "File Management";
        XMLDomManagement: Codeunit "XML DOM Management";
        ManifestStream: InStream;
        XMLRootNode: DotNet XmlNode;
        XMLFoundNodes: DotNet XmlNodeList;
        XMLNamespaceMgr: DotNet XmlNamespaceManager;
        NodeText: Text;
        BaseUrl: Text;
    begin
        FileManagement.BLOBImportFromServerFile(TempBlob, FileName);
        TempBlob.CreateInStream(ManifestStream);

        XMLDomManagement.LoadXMLNodeFromInStream(ManifestStream, XMLRootNode);
        XMLDomManagement.AddNamespaces(XMLNamespaceMgr, XMLRootNode.OwnerDocument);

        // Need to add the default with a 'dummy' prefix - xpath doesn't like default namespaces
        XMLNamespaceMgr.AddNamespace('x', 'http://schemas.microsoft.com/office/appforoffice/1.1');

        // Validate some of the basic configuration values
        // Make sure that URLs appear in necessary areas

        BaseUrl := GetUrl(CLIENTTYPE::Web);
        if StrPos(BaseUrl, '?') > 0 then
            BaseUrl := CopyStr(BaseUrl, 1, StrPos(BaseUrl, '?') - 1);

        Assert.AreNotEqual(
          '', XMLDomManagement.FindNodeTextNs(XMLRootNode, 'x:DefaultLocale', XMLNamespaceMgr),
          'Did not find DefaultLocale node in generated manifest.');
        Assert.IsTrue(
          0 <> StrPos(XMLDomManagement.FindNodeTextNs(XMLRootNode, 'x:AppDomains/x:AppDomain', XMLNamespaceMgr), BaseUrl),
          'Did not find URL in AppDomain node in generated manifest.');

        XMLDomManagement.FindNodesWithNamespaceManager(XMLRootNode, 'x:IconUrl', XMLNamespaceMgr, XMLFoundNodes);
        NodeText := XMLDomManagement.GetAttributeValue(XMLFoundNodes.Item(0), 'DefaultValue');
        Assert.IsTrue(StrPos(NodeText, BaseUrl) <> 0, 'IconUrl does not contain web server URL.');

        XMLDomManagement.FindNodesWithNamespaceManager(XMLRootNode, 'x:HighResolutionIconUrl', XMLNamespaceMgr, XMLFoundNodes);
        NodeText := XMLDomManagement.GetAttributeValue(XMLFoundNodes.Item(0), 'DefaultValue');
        Assert.IsTrue(StrPos(NodeText, BaseUrl) <> 0, 'HighResolutionIconUrl does not contain web server URL.');
    end;

    [Normal]
    [Scope('OnPrem')]
    procedure VerifyNoSeriesRegex5Prefix(FileName: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        FileManagement: Codeunit "File Management";
        XMLDomManagement: Codeunit "XML DOM Management";
        ManifestStream: InStream;
        XMLRootNode: DotNet XmlNode;
        XMLFoundNodes: DotNet XmlNodeList;
        XMLNamespaceMgr: DotNet XmlNamespaceManager;
        NodeText: Text;
    begin
        FileManagement.BLOBImportFromServerFile(TempBlob, FileName);
        TempBlob.CreateInStream(ManifestStream);

        XMLDomManagement.LoadXMLNodeFromInStream(ManifestStream, XMLRootNode);
        XMLDomManagement.AddNamespaces(XMLNamespaceMgr, XMLRootNode.OwnerDocument);

        // Need to add the default with a 'dummy' prefix - xpath doesn't like default namespaces
        XMLNamespaceMgr.AddNamespace('x', 'http://schemas.microsoft.com/office/appforoffice/1.1');

        // Validate that the number series is associated with the appropriate doc type and that the doc types exist in the generated manifest
        XMLDomManagement.FindNodesWithNamespaceManager(XMLRootNode,
          'x:Rule/x:Rule[@xsi:type="RuleCollection"]/x:Rule[@xsi:type="ItemHasRegularExpressionMatch" and @RegExName="No.Series"]',
          XMLNamespaceMgr, XMLFoundNodes);

        Assert.IsTrue(XMLFoundNodes.Count > 0, 'Could not find No. Series regex match in manifest.');

        NodeText := XMLDomManagement.GetAttributeValue(XMLFoundNodes.Item(0), 'RegExValue');

        VerifyNoSeriesRegex5PrefixPurchases(NodeText);
        VerifyNoSeriesRegex5PrefixSales(NodeText);
    end;

    [Normal]
    [Scope('OnPrem')]
    procedure VerifyNoSeriesRegex5PrefixSales(NodeText: Text)
    begin
        ValidateSalesInvoiceSeriesPrefixInRegex(NodeText, true);
        ValidateSalesOrderSeriesPrefixInRegex(NodeText, true);
        ValidateSalesCrMemoSeriesPrefixInRegex(NodeText, true);
        ValidateSalesQuoteSeriesPrefixInRegex(NodeText, false);
    end;

    [Normal]
    [Scope('OnPrem')]
    procedure VerifyNoSeriesRegex5PrefixPurchases(NodeText: Text)
    begin
        ValidatePurchaseInvoiceSeriesPrefixInRegex(NodeText, false);
        ValidatePurchaseOrderSeriesPrefixInRegex(NodeText, true);
        ValidatePurchaseQuoteSeriesPrefixInRegex(NodeText, true);
        ValidatePurchaseCrMemoSeriesPrefixInRegex(NodeText, false);
    end;

    [Normal]
    [Scope('OnPrem')]
    procedure VerifyNoSeriesRegex1Prefix(FileName: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        FileManagement: Codeunit "File Management";
        XMLDomManagement: Codeunit "XML DOM Management";
        ManifestStream: InStream;
        XMLRootNode: DotNet XmlNode;
        XMLFoundNodes: DotNet XmlNodeList;
        XMLNamespaceMgr: DotNet XmlNamespaceManager;
        NodeText: Text;
    begin
        FileManagement.BLOBImportFromServerFile(TempBlob, FileName);
        TempBlob.CreateInStream(ManifestStream);

        XMLDomManagement.LoadXMLNodeFromInStream(ManifestStream, XMLRootNode);
        XMLDomManagement.AddNamespaces(XMLNamespaceMgr, XMLRootNode.OwnerDocument);

        // Need to add the default with a 'dummy' prefix - xpath doesn't like default namespaces
        XMLNamespaceMgr.AddNamespace('x', 'http://schemas.microsoft.com/office/appforoffice/1.1');

        // Validate that the number series is associated with the appropriate doc type and that the doc types exist in the generated manifest
        XMLDomManagement.FindNodesWithNamespaceManager(XMLRootNode,
          'x:Rule/x:Rule[@xsi:type="RuleCollection"]/x:Rule[@xsi:type="ItemHasRegularExpressionMatch" and @RegExName="No.Series"]',
          XMLNamespaceMgr, XMLFoundNodes);

        Assert.IsTrue(XMLFoundNodes.Count > 0, 'Could not find No. Series regex match in manifest.');

        NodeText := XMLDomManagement.GetAttributeValue(XMLFoundNodes.Item(0), 'RegExValue');

        VerifyNoSeriesRegex1PrefixPurchases(NodeText);
        VerifyNoSeriesRegex1PrefixSales(NodeText);
    end;

    [Normal]
    [Scope('OnPrem')]
    procedure VerifyNoSeriesRegex1PrefixSales(NodeText: Text)
    begin
        ValidateSalesInvoiceSeriesPrefixInRegex(NodeText, false);
        ValidateSalesOrderSeriesPrefixInRegex(NodeText, false);
        ValidateSalesCrMemoSeriesPrefixInRegex(NodeText, false);
        ValidateSalesQuoteSeriesPrefixInRegex(NodeText, true);
    end;

    [Normal]
    [Scope('OnPrem')]
    procedure VerifyNoSeriesRegex1PrefixPurchases(NodeText: Text)
    begin
        ValidatePurchaseInvoiceSeriesPrefixInRegex(NodeText, false);
        ValidatePurchaseOrderSeriesPrefixInRegex(NodeText, false);
        ValidatePurchaseQuoteSeriesPrefixInRegex(NodeText, false);
        ValidatePurchaseCrMemoSeriesPrefixInRegex(NodeText, false);
    end;

    [Normal]
    local procedure VerifySameServerInformation(OldXML: DotNet XmlNode; NewXML: DotNet XmlNode)
    var
        XMLNamespaceMgr: DotNet XmlNamespaceManager;
    begin
        XMLDomManagement.AddNamespaces(XMLNamespaceMgr, OldXML.OwnerDocument);

        // Need to add the default with a 'dummy' prefix - xpath doesn't like default namespaces
        XMLNamespaceMgr.AddNamespace('x', 'http://schemas.microsoft.com/office/appforoffice/1.1');

        ValidateUnchangedXML(OldXML, NewXML, 'x:FormSettings/x:Form/x:DesktopSettings/x:SourceLocation', XMLNamespaceMgr);
        ValidateUnchangedXML(OldXML, NewXML, 'x:FormSettings/x:Form/x:PhoneSettings/x:SourceLocation', XMLNamespaceMgr);
        ValidateUnchangedXML(OldXML, NewXML, 'x:FormSettings/x:Form/x:DesktopSettings/x:TabletSettings', XMLNamespaceMgr);
    end;

    [Normal]
    local procedure GetOfficeAdminCredentials(var TempOfficeAdminCredentials: Record "Office Admin. Credentials" temporary)
    begin
        TempOfficeAdminCredentials.Init();
        TempOfficeAdminCredentials.Insert();
        PAGE.RunModal(PAGE::"Office Admin. Credentials", TempOfficeAdminCredentials);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;

    [ModalPageHandler]
    procedure AcceptPrivacyNotice(var PrivacyNotice: TestPage "Privacy Notice")
    begin
        PrivacyNotice.Accept.Invoke();
    end;
}

