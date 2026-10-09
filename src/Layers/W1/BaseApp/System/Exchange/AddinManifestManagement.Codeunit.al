namespace System.Integration;

using Microsoft.CRM.Outlook;
using System;
using System.Environment;
using System.IO;
using System.Privacy;
using System.Utilities;

codeunit 1652 "Add-in Manifest Management"
{

    trigger OnRun()
    begin
    end;

    var
        EnvironmentInfo: Codeunit "Environment Information";
        NodeType: Option Version,ProviderName,DefaultLocale,DisplayName,Description,DesktopSourceLoc,TabletSourceLoc,PhoneSourceLoc,AppDomain,IconUrl,HighResolutionIconUrl;
        TestMode: Boolean;

        RuleCollectionXPathTxt: Label 'x:Rule[@xsi:type="RuleCollection" and @Mode="And"]/x:Rule[@xsi:type="RuleCollection" and @Mode="Or"]', Locked = true;
        OverridesExtensionPointXPathTxt: Label 'o10:VersionOverrides/o11:VersionOverrides/o11:Hosts/o11:Host[1]/o11:DesktopFormFactor/o11:ExtensionPoint', Locked = true;
        MissingNodeErr: Label 'Cannot find an XML node that matches %1.', Comment = '%1=XML node name';
        UnsupportedNodeTypeErr: Label 'You have specified a node of type %1. This type is not supported.', Comment = '%1 = The type of XML node.';
        RuleXPathTxt: Label 'x:Rule[@xsi:type="RuleCollection" and @Mode="Or"]/x:Rule[@xsi:type="RuleCollection" and @Mode="And"]/x:Rule[@xsi:type="ItemHasRegularExpressionMatch"]', Locked = true;
        WebClientHttpsErr: Label 'Cannot set up the add-in because the %1 Server instance is not configured to use Secure Sockets Layer (SSL), or the Web Client Base URL is not defined in the server configuration.', Comment = '%1=product name';
        MicrosoftTxt: Label 'Microsoft';
        BrandingFolderTxt: Label 'ProjectMadeira/', Locked = true;
        ManifestFileNameTxt: Label '%1.xml', Locked = true;
        ManifestZipFileNameTxt: Label 'OutlookAddins.zip', Comment = 'Name of the zip file containing Outlook Addin manifest files.';

    [Scope('OnPrem')]
    procedure DownloadManifestToClient(var NewOfficeAddin: Record "Office Add-in"; FileName: Text): Boolean
    var
        FileManagement: Codeunit "File Management";
        PrivacyNotice: Codeunit "Privacy Notice";
        PrivacyNoticeRegistrations: Codeunit "Privacy Notice Registrations";
        ServerLocation: Text;
    begin
        if not PrivacyNotice.ConfirmPrivacyNoticeApproval(PrivacyNoticeRegistrations.GetExchangePrivacyNoticeId()) then
            exit(false);

        ServerLocation := SaveManifestToServer(NewOfficeAddin);

        if TestMode then begin
            FileManagement.CopyServerFile(ServerLocation, FileName, true);
            exit(true);
        end;

        exit(FileManagement.DownloadHandler(ServerLocation, '', '', '', FileName));
    end;

    [Scope('OnPrem')]
    procedure SaveManifestToServer(var NewOfficeAddin: Record "Office Add-in"): Text
    var
        TempBlob: Codeunit "Temp Blob";
        FileManagement: Codeunit "File Management";
        FileOutStream: OutStream;
        TempFileName: Text;
        ManifestText: Text;
    begin
        GenerateManifest(NewOfficeAddin, ManifestText);
        TempBlob.CreateOutStream(FileOutStream, TEXTENCODING::UTF8);
        FileOutStream.WriteText(ManifestText);
        TempFileName := FileManagement.ServerTempFileName('xml');
        FileManagement.BLOBExportToServerFile(TempBlob, TempFileName);
        exit(TempFileName);
    end;

    [Scope('OnPrem')]
    procedure UploadDefaultManifest(var OfficeAddin: Record "Office Add-in"; ManifestLocation: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        FileManagement: Codeunit "File Management";
        TempInStream: InStream;
        ManifestText: Text;
    begin
        FileManagement.BLOBImportFromServerFile(TempBlob, ManifestLocation);
        TempBlob.CreateInStream(TempInStream, TEXTENCODING::UTF8);
        TempInStream.Read(ManifestText);
        UploadDefaultManifestText(OfficeAddin, ManifestText);
    end;

    [Scope('OnPrem')]
    procedure UploadDefaultManifestText(var OfficeAddin: Record "Office Add-in"; ManifestText: Text)
    begin
        // Set the AppID from the manifest
        OfficeAddin."Application ID" := GetAppID(ManifestText);
        if IsNullGuid(OfficeAddin."Application ID") then
            OfficeAddin."Application ID" := CreateGuid();
        if OfficeAddin.Name = '' then
            OfficeAddin.Name := GetAppName(ManifestText);
        if OfficeAddin.Description = '' then
            OfficeAddin.Description := GetAppDescription(ManifestText);
        OfficeAddin.Version := GetAppVersion(ManifestText);

        OfficeAddin.SetDefaultManifestText(ManifestText);
    end;

    [Scope('OnPrem')]
    procedure CreateAddin(var OfficeAddin: Record "Office Add-in"; ManifestText: Text; AddinName: Text[50]; AddinDescription: Text[250]; AddinID: Text[50]; ManifestCodeunit: Integer)
    begin
        OfficeAddin.Init();
        OfficeAddin."Application ID" := AddinID;
        OfficeAddin."Manifest Codeunit" := ManifestCodeunit;
        OfficeAddin.Name := AddinName;
        OfficeAddin.Description := AddinDescription;
        UploadDefaultManifestText(OfficeAddin, ManifestText);
        OfficeAddin.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure GenerateManifest(OfficeAddin: Record "Office Add-in"; var ManifestText: Text)
    begin
        // Uses the current value of Manifest and updates XML nodes to reflect the current values
        VerifyHttps();
        if OfficeAddin."Manifest Codeunit" <> 0 then
            OnGenerateManifest(OfficeAddin, ManifestText, OfficeAddin."Manifest Codeunit")
        else begin
            ManifestText := OfficeAddin.GetDefaultManifestText();
            SetCommonManifestItems(ManifestText);
        end;
    end;

    [Scope('OnPrem')]
    procedure SetCommonManifestItems(var ManifestText: Text)
    var
        Thread: DotNet Thread;
    begin
        // Set general metadata
        SetNodeValue(ManifestText, Thread.CurrentThread.CurrentCulture.Name, NodeType::DefaultLocale, 0);
        SetNodeValue(ManifestText, MicrosoftTxt, NodeType::ProviderName, 0);
        SetNodeValue(ManifestText, GetUrl(CLIENTTYPE::Web), NodeType::AppDomain, 0);
        SetNodeValue(ManifestText, GetAppName(ManifestText), NodeType::DisplayName, 0);
        SetNodeValue(ManifestText, XMLEncode(GetAppDescription(ManifestText)), NodeType::Description, 0);
        if EnvironmentInfo.IsSaaS() then begin
            SetNodeValue(ManifestText, GetImageUrl(BrandingFolderTxt + 'OfficeAddin_64x.png'), NodeType::IconUrl, 0);
            SetNodeValue(ManifestText, GetImageUrl(BrandingFolderTxt + 'OfficeAddin_80x.png'), NodeType::HighResolutionIconUrl, 0);
        end else begin
            SetNodeValue(ManifestText, GetImageUrl('OfficeAddin_64x.png'), NodeType::IconUrl, 0);
            SetNodeValue(ManifestText, GetImageUrl('OfficeAddin_80x.png'), NodeType::HighResolutionIconUrl, 0);
        end;
    end;

    [Scope('OnPrem')]
    procedure DownloadMultipleManifestsToClient(var OfficeAddin: Record "Office Add-in"): Boolean
    var
        FileManagement: Codeunit "File Management";
        DataCompression: Codeunit "Data Compression";
        MemoryStream: Dotnet MemoryStream;
        UTF8Encoding: DotNet UTF8Encoding;
        ServerLocation: Text;
        ManifestText: Text;
    begin
        if OfficeAddin.Count() = 1 then begin
            // If there's a single file, download the xml directly instead of the zip file
            if OfficeAddin.FindFirst() then;
            ServerLocation := SaveManifestToServer(OfficeAddin);
            FileManagement.DownloadHandler(ServerLocation, '', '', '', StrSubstNo(ManifestFileNameTxt, OfficeAddin.Name))
        end else begin
            // Create and download .zip file containing the outlook add-ins
            if not OfficeAddin.Findset() then
                exit;
            DataCompression.CreateZipArchive();
            repeat
                GenerateManifest(OfficeAddin, ManifestText);
                UTF8Encoding := UTF8Encoding.UTF8Encoding();
                MemoryStream := MemoryStream.MemoryStream(UTF8Encoding.GetBytes(ManifestText));
                DataCompression.AddEntry(MemoryStream, StrSubstNo(ManifestFileNameTxt, OfficeAddin.Name));
            until OfficeAddin.Next() = 0;
            MemoryStream := MemoryStream.MemoryStream();
            DataCompression.SaveZipArchive(MemoryStream);
            DataCompression.CloseZipArchive();
            FileManagement.DownloadFromStreamHandler(MemoryStream, '', '', '', ManifestZipFileNameTxt);
        end;
    end;

    local procedure LoadManifest(ManifestText: Text; var ManifestXmlDocument: XmlDocument; var XMLRootElement: XmlElement; var XMLNamespaceMgr: XmlNamespaceManager)
    var
        ByteOrderMark: Text[1];
    begin
        ByteOrderMark[1] := 65279;
        if CopyStr(ManifestText, 1, 1) = ByteOrderMark then
            ManifestText := CopyStr(ManifestText, 2);
        XmlDocument.ReadFrom(ManifestText, ManifestXmlDocument);
        ManifestXmlDocument.GetRoot(XMLRootElement);
        RemoveWhitespaceNodes(XMLRootElement);
        GetManifestNamespaceManager(ManifestXmlDocument, XMLRootElement, XMLNamespaceMgr);
    end;

    local procedure RemoveWhitespaceNodes(ParentXmlElement: XmlElement)
    var
        ChildNodes: XmlNodeList;
        ChildNode: XmlNode;
        XmlSpaceAttribute: XmlAttribute;
        Whitespace: Text;
        Tab: Char;
        LineFeed: Char;
        CarriageReturn: Char;
        i: Integer;
    begin
        // Like the .NET XmlDocument with PreserveWhitespace = false, drop insignificant whitespace unless xml:space="preserve"
        if ParentXmlElement.Attributes().Get('space', 'http://www.w3.org/XML/1998/namespace', XmlSpaceAttribute) then
            if XmlSpaceAttribute.Value() = 'preserve' then
                exit;
        Tab := 9;
        LineFeed := 10;
        CarriageReturn := 13;
        Whitespace := ' ' + Format(Tab) + Format(LineFeed) + Format(CarriageReturn);
        ChildNodes := ParentXmlElement.GetChildNodes();
        for i := ChildNodes.Count() downto 1 do begin
            ChildNodes.Get(i, ChildNode);
            if ChildNode.IsXmlText() then begin
                if DelChr(ChildNode.AsXmlText().Value(), '=', Whitespace) = '' then
                    ChildNode.Remove();
            end else
                if ChildNode.IsXmlElement() then
                    RemoveWhitespaceNodes(ChildNode.AsXmlElement());
        end;
    end;

    local procedure GetManifestNamespaceManager(ManifestXmlDocument: XmlDocument; XMLRootElement: XmlElement; var XMLNamespaceManager: XmlNamespaceManager)
    var
        NamespaceAttribute: XmlAttribute;
    begin
        XMLNamespaceManager.NameTable(ManifestXmlDocument.NameTable());
        if XMLRootElement.NamespaceUri() <> '' then
            XMLNamespaceManager.AddNamespace('', XMLRootElement.NamespaceUri());
        foreach NamespaceAttribute in XMLRootElement.Attributes() do
            if NamespaceAttribute.IsNamespaceDeclaration() and (NamespaceAttribute.NamespaceUri() <> '') then // xmlns:prefix="..."
                XMLNamespaceManager.AddNamespace(NamespaceAttribute.LocalName(), NamespaceAttribute.Value());

        // Need to explicitly add the default namespace to a namespace
        XMLNamespaceManager.AddNamespace('x', XMLRootElement.NamespaceUri());
    end;

    local procedure FindNodes(XMLRootElement: XmlElement; XPath: Text; XMLNamespaceMgr: XmlNamespaceManager; var FoundXmlNodeList: XmlNodeList): Boolean
    begin
        if not XMLRootElement.SelectNodes(XPath, XMLNamespaceMgr, FoundXmlNodeList) then
            exit(false);
        exit(FoundXmlNodeList.Count() > 0);
    end;

    local procedure FindFirstNode(XMLRootElement: XmlElement; XPath: Text; XMLNamespaceMgr: XmlNamespaceManager; NodeName: Text; var FoundXmlNode: XmlNode)
    var
        FoundXmlNodeList: XmlNodeList;
    begin
        if not FindNodes(XMLRootElement, XPath, XMLNamespaceMgr, FoundXmlNodeList) then
            Error(MissingNodeErr, NodeName);
        FoundXmlNodeList.Get(1, FoundXmlNode);
    end;

    local procedure SetFirstNodeText(XMLRootElement: XmlElement; XPath: Text; XMLNamespaceMgr: XmlNamespaceManager; NodeName: Text; Value: Text)
    var
        FoundXmlNode: XmlNode;
    begin
        FindFirstNode(XMLRootElement, XPath, XMLNamespaceMgr, NodeName, FoundXmlNode);
        SetInnerText(FoundXmlNode, Value);
    end;

    local procedure SetFirstNodeDefaultValue(XMLRootElement: XmlElement; XPath: Text; XMLNamespaceMgr: XmlNamespaceManager; NodeName: Text; Value: Text)
    var
        FoundXmlNode: XmlNode;
    begin
        FindFirstNode(XMLRootElement, XPath, XMLNamespaceMgr, NodeName, FoundXmlNode);
        SetDefaultValueAttribute(FoundXmlNode, Value);
    end;

    local procedure SetInnerText(XmlNode: XmlNode; Value: Text)
    var
        TargetXmlElement: XmlElement;
    begin
        TargetXmlElement := XmlNode.AsXmlElement();
        TargetXmlElement.RemoveNodes();
        TargetXmlElement.Add(XmlText.Create(Value));
    end;

    local procedure SetDefaultValueAttribute(XmlNode: XmlNode; Value: Text)
    var
        DefaultValueXmlAttribute: XmlAttribute;
    begin
        XmlNode.AsXmlElement().Attributes().Get('DefaultValue', DefaultValueXmlAttribute);
        DefaultValueXmlAttribute.Value(Value);
    end;

    local procedure GetDefaultValueAttribute(XmlNode: XmlNode): Text
    var
        DefaultValueXmlAttribute: XmlAttribute;
    begin
        XmlNode.AsXmlElement().Attributes().Get('DefaultValue', DefaultValueXmlAttribute);
        exit(DefaultValueXmlAttribute.Value());
    end;

    [Scope('OnPrem')]
    procedure SetNodeValue(var ManifestText: Text; Value: Variant; Node: Option; FormType: Option ItemRead,ItemEdit)
    var
        ManifestXmlDocument: XmlDocument;
        XMLRootElement: XmlElement;
        XMLNamespaceMgr: XmlNamespaceManager;
    begin
        LoadManifest(ManifestText, ManifestXmlDocument, XMLRootElement, XMLNamespaceMgr);

        case Node of
            NodeType::DefaultLocale:
                SetFirstNodeText(XMLRootElement, 'x:DefaultLocale', XMLNamespaceMgr, Format(Node), Format(Value));
            NodeType::Description:
                SetFirstNodeDefaultValue(XMLRootElement, 'x:Description', XMLNamespaceMgr, Format(Node), Format(Value));
            NodeType::DisplayName:
                SetFirstNodeDefaultValue(XMLRootElement, 'x:DisplayName', XMLNamespaceMgr, Format(Node), Format(Value));
            NodeType::IconUrl:
                SetFirstNodeDefaultValue(XMLRootElement, 'x:IconUrl', XMLNamespaceMgr, Format(Node), Format(Value));
            NodeType::HighResolutionIconUrl:
                SetFirstNodeDefaultValue(XMLRootElement, 'x:HighResolutionIconUrl', XMLNamespaceMgr, Format(Node), Format(Value));
            NodeType::ProviderName:
                SetFirstNodeText(XMLRootElement, 'x:ProviderName', XMLNamespaceMgr, Format(Node), Format(Value));
            NodeType::Version:
                SetFirstNodeText(XMLRootElement, 'x:Version', XMLNamespaceMgr, Format(Node), Format(Value));
            NodeType::DesktopSourceLoc:
                SetFirstNodeDefaultValue(
                  XMLRootElement, StrSubstNo('x:FormSettings/x:Form[@xsi:type="%1"]/x:DesktopSettings/x:SourceLocation', FormType),
                  XMLNamespaceMgr, Format(Node), Format(Value));
            NodeType::PhoneSourceLoc:
                SetFirstNodeDefaultValue(
                  XMLRootElement, StrSubstNo('x:FormSettings/x:Form[@xsi:type="%1"]/x:PhoneSettings/x:SourceLocation', FormType),
                  XMLNamespaceMgr, Format(Node), StrSubstNo('%1&isphone=1', Format(Value)));
            NodeType::TabletSourceLoc:
                SetFirstNodeDefaultValue(
                  XMLRootElement, StrSubstNo('x:FormSettings/x:Form[@xsi:type="%1"]/x:TabletSettings/x:SourceLocation', FormType),
                  XMLNamespaceMgr, Format(Node), Format(Value));
            NodeType::AppDomain:
                SetFirstNodeText(XMLRootElement, 'x:AppDomains/x:AppDomain', XMLNamespaceMgr, Format(Node), Format(Value));
            else
                Error(UnsupportedNodeTypeErr, Node);
        end;

        ReadXMLDocToText(ManifestXmlDocument, ManifestText);
    end;

    [Scope('OnPrem')]
    procedure SetNodeResource(var ManifestText: Text; Id: Text[32]; Value: Text; Type: Option Image,Url,ShortString,LongString)
    var
        ManifestXmlDocument: XmlDocument;
        XMLRootElement: XmlElement;
        XMLFoundNodes: XmlNodeList;
        XMLFoundNode: XmlNode;
        XMLNamespaceMgr: XmlNamespaceManager;
        NewValue: Text;
    begin
        LoadManifest(ManifestText, ManifestXmlDocument, XMLRootElement, XMLNamespaceMgr);
        NewValue := Value;
        if SetNodeLocationValue(
             'o10:VersionOverrides/o10:Resources/%1[@id="%2"]', Id, NewValue, Type, XMLFoundNodes, XMLRootElement, XMLNamespaceMgr)
        then begin
            XMLFoundNodes.Get(1, XMLFoundNode);
            SetDefaultValueAttribute(XMLFoundNode, NewValue);
        end;
        NewValue := Value;
        if SetNodeLocationValue(
             'o10:VersionOverrides/o11:VersionOverrides/o11:Resources/%1[@id="%2"]', Id, NewValue, Type, XMLFoundNodes,
             XMLRootElement, XMLNamespaceMgr)
        then begin
            XMLFoundNodes.Get(1, XMLFoundNode);
            SetDefaultValueAttribute(XMLFoundNode, NewValue);
        end;

        ReadXMLDocToText(ManifestXmlDocument, ManifestText);
    end;

    local procedure ReadXMLDocToText(ManifestXmlDocument: XmlDocument; var ManifestText: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        ManifestInStream: InStream;
        ManifestOutStream: OutStream;
    begin
        TempBlob.CreateOutStream(ManifestOutStream, TEXTENCODING::UTF8);
        ManifestXmlDocument.WriteTo(ManifestOutStream);
        TempBlob.CreateInStream(ManifestInStream, TEXTENCODING::UTF8);
        ManifestInStream.Read(ManifestText);
    end;

    [Scope('OnPrem')]
    procedure RemoveAddInTriggersFromManifest(var ManifestText: Text)
    var
        ManifestXmlDocument: XmlDocument;
        XMLRootElement: XmlElement;
        XMLNode: XmlNode;
        XMLFoundNodes: XmlNodeList;
        XMLNamespaceMgr: XmlNamespaceManager;
    begin
        LoadManifest(ManifestText, ManifestXmlDocument, XMLRootElement, XMLNamespaceMgr);

        // Find the nodes that trigger the add-in and remove them all
        if FindNodes(XMLRootElement, RuleXPathTxt, XMLNamespaceMgr, XMLFoundNodes) then
            foreach XMLNode in XMLFoundNodes do
                XMLNode.Remove();

        ReadXMLDocToText(ManifestXmlDocument, ManifestText);
    end;
    [Scope('OnPrem')]
    procedure SetSourceLocationNodes(var ManifestText: Text; URL: Text; FormType: Option ItemRead,ItemEdit)
    begin
        SetNodeValue(ManifestText, URL, NodeType::DesktopSourceLoc, FormType);
        SetNodeValue(ManifestText, URL, NodeType::PhoneSourceLoc, FormType);
        SetNodeValue(ManifestText, URL, NodeType::TabletSourceLoc, FormType);
    end;

    procedure ConstructURL(HostType: Text; Command: Text; Version: Text) BaseURL: Text
    var
        CompanyQueryPos: Integer;
    begin
        BaseURL := GetUrl(CLIENTTYPE::Web);

        CompanyQueryPos := StrPos(LowerCase(BaseURL), '?');
        if CompanyQueryPos > 0 then
            BaseURL := InsStr(BaseURL, '/OfficeAddin.aspx', CompanyQueryPos) + '&'
        else
            BaseURL := BaseURL + '/OfficeAddin.aspx?';

        BaseURL := BaseURL + 'OfficeContext=' + HostType;
        if Command <> '' then
            BaseURL := BaseURL + '&Command=' + Command;

        if Version <> '' then
            BaseURL := BaseURL + '&Version=' + Version;
    end;

    [Scope('OnPrem')]
    procedure AddRegExRuleNode(var ManifestText: Text; RegExName: Text; RegExText: Text)
    var
        ManifestXmlDocument: XmlDocument;
        XMLRootElement: XmlElement;
        XMLFoundNodesLegacy: XmlNodeList;
        XMLFoundNodesOverrides: XmlNodeList;
        XMLRuleCollectionNode: XmlNode;
        XMLNamespaceMgr: XmlNamespaceManager;
        OverridesRuleCollectionPath: Text;
    begin
        LoadManifest(ManifestText, ManifestXmlDocument, XMLRootElement, XMLNamespaceMgr);

        FindNodes(XMLRootElement, RuleCollectionXPathTxt, XMLNamespaceMgr, XMLFoundNodesLegacy);
        XMLFoundNodesLegacy.Get(1, XMLRuleCollectionNode);
        XMLRuleCollectionNode.AsXmlElement().Add(
          CreateRegExRuleElement('http://schemas.microsoft.com/office/appforoffice/1.1', RegExName, RegExText));

        OverridesRuleCollectionPath := StrSubstNo('%1/%2', OverridesExtensionPointXPathTxt, RuleCollectionXPathTxt);
        OverridesRuleCollectionPath := OverridesRuleCollectionPath.Replace('x:', 'o11:');
        FindNodes(XMLRootElement, OverridesRuleCollectionPath, XMLNamespaceMgr, XMLFoundNodesOverrides);
        XMLFoundNodesOverrides.Get(1, XMLRuleCollectionNode);
        XMLRuleCollectionNode.AsXmlElement().Add(
          CreateRegExRuleElement('http://schemas.microsoft.com/office/mailappversionoverrides/1.1', RegExName, RegExText));

        ReadXMLDocToText(ManifestXmlDocument, ManifestText);
    end;

    local procedure CreateRegExRuleElement(Namespace: Text; RegExName: Text; RegExText: Text) XMLRuleElement: XmlElement
    begin
        XMLRuleElement := XmlElement.Create('Rule', Namespace);
        XMLRuleElement.SetAttribute('type', 'http://www.w3.org/2001/XMLSchema-instance', 'ItemHasRegularExpressionMatch');
        XMLRuleElement.SetAttribute('RegExName', RegExName);
        XMLRuleElement.SetAttribute('RegExValue', RegExText);
        XMLRuleElement.SetAttribute('PropertyName', 'BodyAsPlaintext');
        XMLRuleElement.SetAttribute('IgnoreCase', 'true');
    end;
    procedure GetImageUrl(ImageName: Text): Text
    var
        BaseUrl: Text;
    begin
        BaseUrl := GetUrl(CLIENTTYPE::Web);
        if StrPos(BaseUrl, '?') > 0 then
            BaseUrl := CopyStr(BaseUrl, 1, StrPos(BaseUrl, '?') - 1);

        exit(StrSubstNo('%1/Resources/Images/%2', BaseUrl, ImageName));
    end;

    [Scope('OnPrem')]
    procedure GetAppID(ManifestText: Text): Text
    var
        XMLFoundNode: XmlNode;
    begin
        GetFirstXmlNode(ManifestText, XMLFoundNode, 'x:Id');
        exit(XMLFoundNode.AsXmlElement().InnerText())
    end;

    [Scope('OnPrem')]
    procedure GetAppName(ManifestText: Text): Text[50]
    var
        XMLFoundNode: XmlNode;
    begin
        GetFirstXmlNode(ManifestText, XMLFoundNode, 'x:DisplayName');
        exit(GetDefaultValueAttribute(XMLFoundNode))
    end;

    [Scope('OnPrem')]
    procedure GetAppDescription(ManifestText: Text): Text[250]
    var
        XMLFoundNode: XmlNode;
    begin
        GetFirstXmlNode(ManifestText, XMLFoundNode, 'x:Description');
        exit(GetDefaultValueAttribute(XMLFoundNode))
    end;

    [Scope('OnPrem')]
    procedure GetAppVersion(ManifestText: Text): Text[20]
    var
        XMLFoundNode: XmlNode;
    begin
        GetFirstXmlNode(ManifestText, XMLFoundNode, 'x:Version');
        exit(XMLFoundNode.AsXmlElement().InnerText())
    end;

    local procedure GetFirstXmlNode(ManifestText: Text; var XMLFoundNode: XmlNode; NodeName: Text)
    var
        ManifestXmlDocument: XmlDocument;
        XMLRootElement: XmlElement;
        XMLNamespaceMgr: XmlNamespaceManager;
    begin
        LoadManifest(ManifestText, ManifestXmlDocument, XMLRootElement, XMLNamespaceMgr);
        FindFirstNode(XMLRootElement, NodeName, XMLNamespaceMgr, NodeName, XMLFoundNode);
    end;
    local procedure VerifyHttps()
    var
        WebClientUrl: Text;
    begin
        WebClientUrl := ConstructURL('', '', '');
        if (not TestMode) and (LowerCase(CopyStr(WebClientUrl, 1, 5)) <> 'https') then
            Error(WebClientHttpsErr, PRODUCTNAME.Short());
    end;

    local procedure SetNodeLocationValue(NodeLocation: Text; Id: Text[32]; var Value: Text; Type: Option Image,Url,ShortString,LongString; var FoundXMLNodeList: XmlNodeList; XMLRootElement: XmlElement; XMLNamespaceMgr: XmlNamespaceManager): Boolean
    begin
        case Type of
            Type::Image:
                begin
                    NodeLocation := StrSubstNo(NodeLocation, 'bt:Images/bt:Image', Id);
                    Value := GetImageUrl(Value);
                end;
            Type::Url:
                NodeLocation := StrSubstNo(NodeLocation, 'bt:Urls/bt:Url', Id);
            Type::ShortString:
                NodeLocation := StrSubstNo(NodeLocation, 'bt:ShortStrings/bt:String', Id);
            Type::LongString:
                NodeLocation := StrSubstNo(NodeLocation, 'bt:LongStrings/bt:String', Id);
            else
                Error(UnsupportedNodeTypeErr, Type);
        end;

        exit(FindNodes(XMLRootElement, NodeLocation, XMLNamespaceMgr, FoundXMLNodeList));
    end;

    procedure SetTestMode(NewTestMode: Boolean)
    begin
        TestMode := NewTestMode;
    end;

    procedure XMLEncode(Value: Text) Encoded: Text
    var
        SystemWebHttpUtility: DotNet HttpUtility;
    begin
        SystemWebHttpUtility := SystemWebHttpUtility.HttpUtility();
        Encoded := SystemWebHttpUtility.HtmlEncode(Value);
    end;

    procedure GetAddinByHostType(var OfficeAddin: Record "Office Add-in"; HostType: Text)
    var
        ManifestCodeunit: Integer;
    begin
        GetManifestCodeunit(ManifestCodeunit, HostType);
        GetAddin(OfficeAddin, ManifestCodeunit);
    end;

    [IntegrationEvent(false, false)]
    [Scope('OnPrem')]
    procedure CreateBasicAddins(var OfficeAddin: Record "Office Add-in")
    begin
    end;

    [IntegrationEvent(false, false)]
    [Scope('OnPrem')]
    procedure CreateDefaultAddins(var OfficeAddin: Record "Office Add-in")
    begin
    end;

    [IntegrationEvent(false, false)]
    [Scope('OnPrem')]
    procedure GetAddin(var OfficeAddin: Record "Office Add-in"; CodeunitID: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    [Scope('OnPrem')]
    procedure GetAddinID(var ID: Text; CodeunitID: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    [Scope('OnPrem')]
    procedure GetAddinVersion(var Version: Text; CodeunitID: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    [Scope('OnPrem')]
    procedure GetManifestCodeunit(var CodeunitID: Integer; HostType: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGenerateManifest(var OfficeAddin: Record "Office Add-in"; var ManifestText: Text; CodeunitID: Integer)
    begin
    end;
}

