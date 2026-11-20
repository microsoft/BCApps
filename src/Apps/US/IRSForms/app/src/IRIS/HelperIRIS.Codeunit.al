// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Foundation.Address;
using Microsoft.Purchases.Vendor;
using System.Reflection;
using System.Telemetry;
using System.Utilities;
using System.Xml;

codeunit 10035 "Helper IRIS"
{
    Access = Public;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        IRSFormsFacade: Codeunit "IRS Forms Facade";
        XMLDOMManagement: Codeunit "XML DOM Management";
        TypeHelper: Codeunit "Type Helper";
        Supplemental: Codeunit "IRS 1099 Supplemental";
        XMLDoc: XmlDocument;
        CurrXMLElement: array[100] of XmlElement;
        Depth: Integer;
        NamespacePrefix: Text;
        NamespaceUri: Text;
        XPathParent: Text;
        UTF8BOMSymbols: Text;
        IRIS1099FeatureNameTxt: Label 'IRS Forms IRIS', Locked = true;
        UTIDTxt: Label '%1:%2:%3::%4', Comment = '%1 - UUID, %2 - Application ID, %3 - TCC, %4 - Request Type', Locked = true;
        NamespacePrefixTxt: label 'n1', Locked = true;
        NamespaceUriTxt: label 'urn:us:gov:treasury:irs:ir', Locked = true;
        ElementNamesTok: Label 'ElementNames', Locked = true;
        ElementOrderTotalsTok: Label 'ElementOrderTotals', Locked = true;
        ElementOrderDetailsTok: Label 'ElementOrderDetails', Locked = true;
        NotPossibleToInsertErr: label 'Not possible to insert element %1', Comment = '%1 - node text';
        AmountXmlElementsFileNameTxt: Label 'AmountXmlElementsIRIS%1.json', Comment = '%1 - period year, e.g. 2024', Locked = true;
        ResourceFileNotFoundErr: Label 'The resource file for the period %1 is not found.', Comment = '%1 - period year, e.g. 2024';
        UnsupportedSchemaErr: Label 'The IRIS XML schema version is not supported. Select 2.0.3 or 5.0.7, or clear the reporting-period override to use the configured environment setting.';
        SoftwareIdFormatErr: Label 'The IRIS Software ID for tax year %1 must start with %2 and contain 3 to 10 letters or digits. Configure the IRS-approved Software ID for this tax year before filing.', Comment = '%1 - requested tax year, %2 - required two-digit prefix';
        TaxYearFormatErr: Label 'The IRIS tax year %1 must contain four digits and be between 2000 and 3000.', Comment = '%1 - requested tax year';
        SchemaFailureTxt: Label 'The selected IRIS schema configuration is unsupported or empty.', Locked = true;
        UnverifiedYearQst: Label 'Tax year %1 has not been verified for IRIS XML schema %3. This operation will use the form box mappings for tax year %2. IRS acceptance does not guarantee that the reported information is correct. Check the reporting requirements before continuing. Do you want to use these mappings for this operation only?', Comment = '%1 - requested tax year, %2 - actual mapping resource year, %3 - exact XML schema version';
        YearConfirmationRequiredErr: Label 'Using tax year %2 form box mappings for unverified tax year %1 with IRIS XML schema %3 requires confirmation. Run the operation interactively and review the warning before continuing.', Comment = '%1 - requested tax year, %2 - actual mapping resource year, %3 - exact XML schema version';
        TestDestinationTxt: Label 'Test';
        ProductionDestinationTxt: Label 'Production';

    #region Transmission Identity
    internal procedure GetDestinationName(IsTestDestination: Boolean): Text
    begin
        if IsTestDestination then
            exit(TestDestinationTxt);
        exit(ProductionDestinationTxt);
    end;

    procedure GetIRISFeatureName(): Text
    begin
        exit(IRIS1099FeatureNameTxt);
    end;

    procedure GetRequestType(): Text
    begin
        exit('A');      // A for A2A
    end;

    procedure CreateUniqueTransmissionIdentifier(): Text[100]
    begin
        exit(CreateUniqueTransmissionIdentifier(IRSFormsFacade.GetTCC()));
    end;

    internal procedure CreateUniqueTransmissionIdentifier(TCC: Text): Text[100]
    begin
        // example of UTID: da20a4de-1357-11ed-861d-0242ac120002:IRIS:00000::A
        exit(StrSubstNo(UTIDTxt, CreateUUID(), GetApplicationID(), TCC, GetRequestType()));
    end;

    procedure CreateUUID(): Text[36]
    begin
        exit(CopyStr(DelChr(LowerCase(Format(CreateGuid())), '=', '{}'), 1, 36));
    end;

    local procedure GetApplicationID(): Text
    begin
        exit('IRIS');
    end;
    #endregion Transmission Identity

    #region XML Construction
    procedure Initialize(RootNodeName: Text)
    begin
        Clear(XMLDoc);
        Clear(CurrXMLElement);
        Depth := 0;

        UTF8BOMSymbols := XMLDOMManagement.GetUTF8BOMSymbols();

        XMLDoc := XmlDocument.Create();
        XMLDoc.SetDeclaration(XmlDeclaration.Create('1.0', 'UTF-8', 'yes'));
        GetNamespace(NamespacePrefix, NamespaceUri);
        CreateRootWithNamespace(RootNodeName);
    end;

    local procedure CreateRootWithNamespace(RootNodeName: Text)
    begin
        Depth += 1;
        CurrXMLElement[Depth] := XmlElement.Create(RootNodeName, NamespaceUri);
        AddElementNameToXPath(RootNodeName);
        CurrXMLElement[Depth].Add(XmlAttribute.CreateNamespaceDeclaration(NamespacePrefix, NamespaceUri));
        XMLDoc.Add(CurrXMLElement[Depth]);
        XMLDoc.GetRoot(CurrXMLElement[Depth]);
    end;

    procedure AddParentXmlNode(NodeName: Text)
    var
        NewXMLElement: XmlElement;
    begin
        AddXmlElement(NewXMLElement, NodeName, '');
        Depth += 1;
        CurrXMLElement[Depth] := NewXMLElement;
        AddElementNameToXPath(NodeName);
    end;

    procedure AppendXmlNode(NodeName: Text; NodeText: Text)
    var
        NewXMLElement: XmlElement;
    begin
        if NodeText <> '' then
            AddXmlElement(NewXMLElement, NodeName, NodeText);
    end;

    procedure AppendXmlNodeIfNotZero(NodeName: Text; NodeValue: Decimal)
    var
        NewXMLElement: XmlElement;
        NodeText: Text;
    begin
        if NodeValue = 0 then
            exit;
        NodeText := FormatDecimal(NodeValue);
        AddXmlElement(NewXMLElement, NodeName, NodeText);
    end;

    local procedure AddXmlElement(var NewXMLElement: XmlElement; Name: Text; NodeText: Text)
    begin
        ClearUTF8BOMSymbols(NodeText);
        ClearProhibitedCharacters(NodeText);
        NewXMLElement := XmlElement.Create(Name, NamespaceUri, NodeText);
        if not CurrXMLElement[Depth].Add(NewXMLElement) then
            Error(NotPossibleToInsertErr, NodeText);
    end;

    procedure CloseParentXmlNode()
    begin
        Depth -= 1;
        RemoveLastElementNameFromXPath();
        if Depth < 0 then
            Error('Incorrect XML structure');
    end;

    local procedure AddElementNameToXPath(ElementName: Text)
    begin
        XPathParent += ('/' + ElementName);
    end;

    local procedure RemoveLastElementNameFromXPath()
    begin
        XPathParent := XPathParent.Substring(1, XPathParent.LastIndexOf('/') - 1);
    end;

    procedure UpdateSingleXmlNode(NodeName: Text; NodeText: Text)
    var
        XMLNamespaceManager: XmlNamespaceManager;
        XmlNode: XmlNode;
        NewXMLElement: XmlElement;
        NewNodeText: Text;
        NodeXPath: Text;
    begin
        NodeXPath := StrSubstNo('//%1:%2', NamespacePrefix, NodeName);
        XMLNamespaceManager.AddNamespace(NamespacePrefix, NamespaceUri);
        if not XMLDoc.SelectSingleNode(NodeXPath, XMLNamespaceManager, XmlNode) then
            Error('Node with XPath %1 not found', NodeXPath);

        NewNodeText := NodeText;
        ClearUTF8BOMSymbols(NewNodeText);
        ClearProhibitedCharacters(NewNodeText);

        NewXMLElement := XmlElement.Create(NodeName, NamespaceUri, NewNodeText);
        XmlNode.ReplaceWith(NewXMLElement);
    end;

    procedure AddPrefixToXPath(XPath: Text; Prefix: Text): Text
    var
        TB: TextBuilder;
        PrevChar: Char;
        CurrChar: Char;
    begin
        if IsLatinLetter(XPath[1]) then
            PrevChar := '/';        // to add prefix before the first element

        foreach CurrChar in XPath do begin
            if PrevChar = '/' then
                if IsLatinLetter(CurrChar) then begin
                    TB.Append(Prefix);
                    TB.Append(':');
                end;
            TB.Append(CurrChar);
            PrevChar := CurrChar;
        end;

        exit(TB.ToText());
    end;

    local procedure ClearUTF8BOMSymbols(var RawXmlText: Text)
    begin
        if StrPos(RawXmlText, UTF8BOMSymbols) = 1 then
            RawXmlText := DelStr(RawXmlText, 1, StrLen(UTF8BOMSymbols));
    end;

    local procedure ClearProhibitedCharacters(var RawXmlText: Text)
    begin
        // double dash (--) and hash (#) are not allowed
        RawXmlText := RawXmlText.Replace('--', '');
        RawXmlText := RawXmlText.Replace('#', '');
    end;

    local procedure GetNamespace(var Prefix: Text; var Uri: Text)
    begin
        Prefix := NamespacePrefixTxt;
        Uri := NamespaceUriTxt;
    end;

    procedure WriteXmlDocToTempBlob(var TempBlob: Codeunit "Temp Blob")
    var
        BlobOutStream: OutStream;
        XMLDocText: Text;
    begin
        TempBlob.CreateOutStream(BlobOutStream, TextEncoding::UTF8);
        XMLDoc.WriteTo(XMLDocText);
        BlobOutStream.WriteText(XMLDocText);
        Clear(XMLDoc);
    end;
    #endregion XML Construction

    #region Blob and Transmission Utilities
    procedure WriteTextToTempBlob(var TempBlob: Codeunit "Temp Blob"; TextToWrite: Text)
    var
        BlobOutStream: OutStream;
    begin
        TempBlob.CreateOutStream(BlobOutStream, TextEncoding::UTF8);
        BlobOutStream.WriteText(TextToWrite);
    end;

    procedure WriteTempBlobToText(var TempBlob: Codeunit "Temp Blob"): Text
    var
        BlobInStream: InStream;
        Content: Text;
    begin
        TempBlob.CreateInStream(BlobInStream, TextEncoding::UTF8);
        XMLDOMManagement.TryGetXMLAsText(BlobInStream, Content);
        exit(Content);
    end;

    internal procedure GetTransmissionFileSizeText(var TransmissionLog: Record "Transmission Log IRIS"): Text[20]
    var
        SizeInKbytes: Decimal;
        SizeInMbytes: Decimal;
    begin
        SizeInKbytes := Round(TransmissionLog."Transmission Content".Length / 1024);
        if SizeInKbytes <= 1024 then
            exit(StrSubstNo('%1 %2', Format(SizeInKbytes), 'KB'));

        SizeInMbytes := Round(SizeInKbytes / 1024);
        if SizeInMbytes <= 1024 then
            exit(StrSubstNo('%1 %2', Format(SizeInMbytes), 'MB'));
    end;

    procedure GetTransmissionTypeName(TransmissionType: Enum "Transmission Type IRIS"): Text
    begin
        exit(TransmissionType.Names.Get(TransmissionType.Ordinals.IndexOf(TransmissionType.AsInteger())));
    end;
    #endregion Blob and Transmission Utilities

    #region Reporting Configuration
    #region XML Schema
    internal procedure GetXmlSchemaVersion(PeriodNo: Code[20]): Enum "XML Schema Version IRIS"
    var
        Source: Text;
    begin
        exit(GetXmlSchemaVersion(PeriodNo, Source));
    end;

    internal procedure GetXmlSchemaVersion(PeriodNo: Code[20]; var Source: Text): Enum "XML Schema Version IRIS"
    var
        ReportingPeriod: Record "IRS Reporting Period";
        KeyVaultClient: Codeunit "Key Vault Client IRIS";
        SchemaVersion: Enum "XML Schema Version IRIS";
    begin
        ReportingPeriod.Get(PeriodNo);
        SchemaVersion := ReportingPeriod.GetSchemaOverride(IRSFormsFacade.TestMode());
        if SchemaVersion <> SchemaVersion::" " then begin
            CheckSchemaVersionSupported(SchemaVersion);
            Source := 'ReportingPeriod';
            exit(SchemaVersion);
        end;

        Source := 'KeyVault';
        exit(ParseSchemaVersion(KeyVaultClient.GetXmlSchemaVersion()));
    end;

    internal procedure ParseSchemaVersion(Version: Text): Enum "XML Schema Version IRIS"
    begin
        case Version of
            '2.0.3':
                exit("XML Schema Version IRIS"::"2.0.3");
            '5.0.7':
                exit("XML Schema Version IRIS"::"5.0.7");
            else
                UnsupportedSchema();
        end;
    end;

    internal procedure GetSchemaVersionText(SchemaVersion: Enum "XML Schema Version IRIS"): Text
    var
        Schema: Interface "IRIS XML Schema";
    begin
        Schema := SchemaVersion;
        exit(Schema.GetVersionText());
    end;

    internal procedure CheckSchemaVersionSupported(SchemaVersion: Enum "XML Schema Version IRIS")
    begin
        GetSchemaVersionText(SchemaVersion);
    end;

    internal procedure ConfirmTaxYearMapping(VersionText: Text; TaxYear: Text; VerifiedTaxYear: Boolean)
    var
        ConfirmMgt: Codeunit "Confirm Management";
        MappingYear: Text;
    begin
        ValidateTaxYear(TaxYear);
        GetAmtXmlElementsFileContent(TaxYear, MappingYear);
        if VerifiedTaxYear then
            exit;
        if not GuiAllowed() then
            Error(YearConfirmationRequiredErr, TaxYear, MappingYear, VersionText);
        if not ConfirmMgt.GetResponse(StrSubstNo(UnverifiedYearQst, TaxYear, MappingYear, VersionText), false) then
            Error('');
    end;

    internal procedure UnsupportedSchema()
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
    begin
        FeatureTelemetry.LogError('', GetIRISFeatureName(), 'SchemaConfiguration', SchemaFailureTxt);
        Error(UnsupportedSchemaErr);
    end;
    #endregion XML Schema

    internal procedure GetSoftwareId(TaxYear: Text): Text
    var
        IRSFormsSetup: Record "IRS Forms Setup";
        KeyVaultClient: Codeunit "Key Vault Client IRIS";
        SoftwareId: Text;
    begin
        ValidateTaxYear(TaxYear);
        IRSFormsSetup.InitSetup();
        if IRSFormsSetup.Implementation = IRSFormsSetup.Implementation::Standard then
            SoftwareId := KeyVaultClient.GetSoftwareId(TaxYear)
        else
            SoftwareId := IRSFormsFacade.GetSoftwareId();
        ValidateSoftwareId(TaxYear, SoftwareId);
        exit(SoftwareId);
    end;

    internal procedure ValidateSoftwareId(TaxYear: Text; SoftwareId: Text)
    begin
        ValidateTaxYear(TaxYear);
        if (StrLen(SoftwareId) < 3) or (StrLen(SoftwareId) > 10) or
           (CopyStr(SoftwareId, 1, 2) <> CopyStr(TaxYear, 3, 2)) or
           (DelChr(SoftwareId, '=', '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz') <> '')
        then
            Error(SoftwareIdFormatErr, TaxYear, CopyStr(TaxYear, 3, 2));
    end;

    [TryFunction]
    internal procedure ValidateTaxYear(TaxYear: Text)
    var
        TaxYearNumber: Integer;
    begin
        if (StrLen(TaxYear) <> 4) or (DelChr(TaxYear, '=', '0123456789') <> '') then
            Error(TaxYearFormatErr, TaxYear);

        Evaluate(TaxYearNumber, TaxYear);
        if not (TaxYearNumber in [2000 .. 3000]) then
            Error(TaxYearFormatErr, TaxYear);
    end;
    #endregion Reporting Configuration

    #region Document Navigation
    internal procedure ShowIRS1099FormDocuments(ErrorInfo: ErrorInfo)
    begin
        Page.Run(Page::"IRS 1099 Form Documents");
    end;
    #endregion Document Navigation

    #region Tax-Year Resources and Form Mappings
    local procedure TryGetAmtXmlElementsFileName(PeriodNo: Text; var ResourceFileName: Text): Boolean
    var
        FileName: Text;
    begin
        FileName := StrSubstNo(AmountXmlElementsFileNameTxt, PeriodNo);
        if ResourceFileExists(FileName) then begin
            ResourceFileName := FileName;
            exit(true);
        end;
        exit(false);
    end;

    [TryFunction]
    local procedure ResourceFileExists(FileName: Text)
    var
        ResourceInStream: InStream;
    begin
        NavApp.GetResource(FileName, ResourceInStream);
    end;

    internal procedure GetAmtXmlElementsFileContent(PeriodNo: Text) FileContentObject: JsonObject
    var
        MappingResourceYear: Text;
    begin
        exit(GetAmtXmlElementsFileContent(PeriodNo, MappingResourceYear));
    end;

    internal procedure GetAmtXmlElementsFileContent(PeriodNo: Text; var MappingResourceYear: Text) FileContentObject: JsonObject
    var
        ResourceFileName: Text;
        PeriodNoInt: Integer;
        ResourceStream: InStream;
    begin
        ValidateTaxYear(PeriodNo);
        Evaluate(PeriodNoInt, PeriodNo);

        Clear(MappingResourceYear);
        while PeriodNoInt >= 2020 do begin
            MappingResourceYear := Format(PeriodNoInt, 0, 9);
            if TryGetAmtXmlElementsFileName(MappingResourceYear, ResourceFileName) then
                break;
            PeriodNoInt -= 1;
        end;
        if ResourceFileName = '' then
            Error(ResourceFileNotFoundErr, PeriodNo);

        NavApp.GetResource(ResourceFileName, ResourceStream);
        FileContentObject.ReadFrom(ResourceStream);
    end;

    internal procedure GetOccupationCodes(TaxYear: Text) OccupationCodes: List of [Text]
    var
        FileContent: JsonObject;
        OccupationCodesToken: JsonToken;
        OccupationCodeToken: JsonToken;
    begin
        FileContent := GetAmtXmlElementsFileContent(TaxYear);
        FileContent.Get('OccupationCodes', OccupationCodesToken);
        foreach OccupationCodeToken in OccupationCodesToken.AsArray() do
            OccupationCodes.Add(OccupationCodeToken.AsValue().AsText());
    end;

    /// <summary>
    /// Returns the dictionary of Form Boxes and their corresponding Amount Xml Element Names for the specified Form Type, for example MISC-01 -> RentAmt
    /// </summary>
    internal procedure GetFormBoxAmountXmlElementNames(PeriodNo: Text; FormType: Text) FormAmountXmlElementNames: Dictionary of [Text, Text]
    var
        JsonObject: JsonObject;
        JsonToken: JsonToken;
        FormList: JsonToken;
        FormBoxes: JsonToken;
        FormBoxNo: JsonToken;
        AmtXmlElementName: JsonToken;
    begin
        JsonObject := GetAmtXmlElementsFileContent(PeriodNo);
        JsonObject.Get(ElementNamesTok, FormList);
        FormList.AsObject().Get(FormType, FormBoxes);
        foreach JsonToken in FormBoxes.AsArray() do begin
            JsonToken.AsObject().Get('FormBoxNo', FormBoxNo);
            JsonToken.AsObject().Get('AmtXmlElementName', AmtXmlElementName);
            if FormAmountXmlElementNames.Add(FormBoxNo.AsValue().AsText(), AmtXmlElementName.AsValue().AsText()) then;
        end;
        OnAfterGetFormBoxAmountXmlElementNames(PeriodNo, FormType, FormAmountXmlElementNames);
    end;

    /// <summary>
    /// Returns the dictionary of Form Boxes and their corresponding Amount Xml Element Names, for example MISC-01 -> RentAmt
    /// </summary>
    internal procedure GetFormBoxAmountXmlElementNames(PeriodNo: Text) AmountXmlElementNames: Dictionary of [Text, Text]
    var
        JsonObject: JsonObject;
        JsonToken: JsonToken;
        FormList: JsonToken;
        FormTok: JsonToken;
        FormBoxNo: JsonToken;
        AmtXmlElementName: JsonToken;
    begin
        JsonObject := GetAmtXmlElementsFileContent(PeriodNo);
        JsonObject.Get(ElementNamesTok, FormList);
        foreach FormTok in FormList.AsObject().Values() do
            foreach JsonToken in FormTok.AsArray() do begin
                JsonToken.AsObject().Get('FormBoxNo', FormBoxNo);
                JsonToken.AsObject().Get('AmtXmlElementName', AmtXmlElementName);
                if AmountXmlElementNames.Add(FormBoxNo.AsValue().AsText(), AmtXmlElementName.AsValue().AsText()) then;
            end;
        OnAfterGetFormBoxAmountXmlElementNames(PeriodNo, '', AmountXmlElementNames);
    end;

    /// <summary>
    /// Returns the dictionary (HashSet) of Form Boxes that are used for Federal Income Tax Withheld, for example MISC-04
    /// </summary>
    internal procedure GetFederalIncomeTaxWithheldFormBoxes(PeriodNo: Text) FormBoxes: Dictionary of [Text, Boolean]
    var
        JsonObject: JsonObject;
        JsonToken: JsonToken;
        FormList: JsonToken;
        FormTok: JsonToken;
        FormBoxNo: JsonToken;
        FederalIncomeTaxWithheld: JsonToken;
    begin
        // Dictionary is used as HashSet.
        JsonObject := GetAmtXmlElementsFileContent(PeriodNo);
        JsonObject.Get(ElementNamesTok, FormList);
        foreach FormTok in FormList.AsObject().Values() do
            foreach JsonToken in FormTok.AsArray() do begin
                Clear(FederalIncomeTaxWithheld);
                if JsonToken.AsObject().Get('FederalIncomeTaxWithheld', FederalIncomeTaxWithheld) then
                    if FederalIncomeTaxWithheld.AsValue().AsBoolean() then begin
                        JsonToken.AsObject().Get('FormBoxNo', FormBoxNo);
                        if FormBoxes.Add(FormBoxNo.AsValue().AsText(), true) then;
                    end;
            end;
        OnAfterGetFederalIncomeTaxWithheldFormBoxes(PeriodNo, FormBoxes);
    end;

    local procedure GetAmountXmlElementList(PeriodNo: Text; FormType: Text; ElementOrderType: Text) AmountXmlElementNames: List of [Text]
    var
        JsonObject: JsonObject;
        JsonToken: JsonToken;
        FormList: JsonToken;
        AmtXmlElemNames: JsonToken;
    begin
        JsonObject := GetAmtXmlElementsFileContent(PeriodNo);
        JsonObject.Get(ElementOrderType, FormList);
        FormList.AsObject().Get(FormType, AmtXmlElemNames);
        foreach JsonToken in AmtXmlElemNames.AsArray() do
            AmountXmlElementNames.Add(JsonToken.AsValue().AsText());
        OnAfterGetAmountXmlElementList(PeriodNo, FormType, ElementOrderType, AmountXmlElementNames);
    end;

    procedure GetTotalAmountsXmlElementsOrder(PeriodNo: Text; FormType: Enum "Form Type IRIS") AmountXmlElementNames: List of [Text]
    begin
        AmountXmlElementNames := GetAmountXmlElementList(PeriodNo, Format(FormType), ElementOrderTotalsTok);
    end;

    procedure GetDetailAmountsXmlElementsOrder(PeriodNo: Text; FormType: Enum "Form Type IRIS") AmountXmlElementNames: List of [Text]
    begin
        AmountXmlElementNames := GetAmountXmlElementList(PeriodNo, Format(FormType), ElementOrderDetailsTok);
    end;
    #endregion Tax-Year Resources and Form Mappings

    #region Supplemental Reporting
    /// <summary>
    /// Gets the standard parent box, XML element and value type for a supplemental box using the tax-year resource.
    /// </summary>
    /// <returns>True if the supplemental box has a standard XML mapping.</returns>
    procedure GetMapping(TaxYear: Text; FormNo: Code[20]; BoxNo: Code[20]; var ParentBoxNo: Code[20]; var ElementName: Text[100]; var ValueType: Enum "IRS 1099 Supplemental Type"): Boolean
    begin
        exit(Supplemental.GetMapping(TaxYear, FormNo, BoxNo, ParentBoxNo, ElementName, ValueType));
    end;

    /// <summary>
    /// Checks whether a supplemental line is reportable based on its parent income and saved tips.
    /// </summary>
    procedure IsReportable(var SupplLine: Record "IRS 1099 Doc. Suppl. Line"): Boolean
    begin
        exit(Supplemental.IsReportable(SupplLine));
    end;

    /// <summary>
    /// Rounds a supplemental amount to two decimal places for output.
    /// </summary>
    procedure RoundAmountForOutput(Amount: Decimal): Decimal
    begin
        exit(Supplemental.RoundAmount(Amount));
    end;
    #endregion Supplemental Reporting

    #region Additional Form XML
    internal procedure AddOtherForm1099DetailsPart(var TempIRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header" temporary)
    var
        XmlNodesNameValue: Dictionary of [Text, Text];
        NodeName: Text;
    begin
        OnBeforeAddOtherForm1099DetailsPart(TempIRS1099FormDocHeader, XmlNodesNameValue);
        if XmlNodesNameValue.Count() = 0 then
            exit;
        foreach NodeName in XmlNodesNameValue.Keys() do
            AppendXmlNode(NodeName, XmlNodesNameValue.Get(NodeName));
    end;
    #endregion Additional Form XML

    #region Data Formatting and Normalization
    procedure IsForeignCountryRegion(CountryRegionCode: Code[10]): Boolean
    var
        CountryRegion: Record "Country/Region";
    begin
        // return foreign only when the ISO code is set and it is not US
        if CountryRegion.Get(CountryRegionCode) then
            if (CountryRegion."ISO Code" <> '') and (CountryRegion."ISO Code" <> 'US') then
                exit(true);
        exit(false);
    end;

    procedure ConcatenateWithSpace(FirstString: Text; SecondString: Text) Result: Text
    begin
        Result := FirstString;
        if (Result <> '') and (SecondString <> '') then
            Result += ' ';
        exit(Result + SecondString);
    end;

    procedure FormatTIN(InputText: Text): Text
    var
        TB: TextBuilder;
        Ch: Char;
    begin
        foreach Ch in InputText do
            if IsDigit(Ch) then
                TB.Append(Ch);

        exit(TB.ToText());
    end;

    procedure FormatBusinessName(InputText: Text; var BusinessNameLine1: Text; var BusinessNameLine2: Text)
    var
        TB1: TextBuilder;
        TB2: TextBuilder;
        Ch: Char;
    begin
        InputText := RemoveExtraSpaces(InputText);
        foreach Ch in InputText do
            if IsLatinLetter(Ch) or IsDigit(Ch) or
               (Ch = '#') or (Ch = '-') or (Ch = '(') or (Ch = ')') or
               (Ch = '&') or (Ch = '''') or (Ch = ' ')
            then
                if TB1.Length < 75 then
                    TB1.Append(Ch)
                else
                    if TB2.Length < 75 then
                        TB2.Append(Ch);

        BusinessNameLine1 := RemoveExtraSpaces(TB1.ToText());
        BusinessNameLine2 := RemoveExtraSpaces(TB2.ToText());
    end;

    procedure FormatContactPersonName(InputText: Text): Text
    var
        TB: TextBuilder;
        Ch: Char;
    begin
        InputText := RemoveExtraSpaces(InputText);
        foreach Ch in InputText do
            if IsLatinLetter(Ch) or IsDigit(Ch) or
               (Ch = '-') or (Ch = '''') or (Ch = ' ')
            then
                TB.Append(Ch);

        exit(RemoveExtraSpaces(TB.ToText()));
    end;

    procedure FormatPersonName(InputText: Text): Text
    var
        TB: TextBuilder;
        Ch: Char;
    begin
        InputText := RemoveExtraSpaces(InputText);
        foreach Ch in InputText do
            if IsLatinLetter(Ch) or (Ch = '-') or (Ch = ' ') then
                if TB.Length < 20 then
                    TB.Append(Ch);

        exit(RemoveExtraSpaces(TB.ToText()));
    end;

    procedure FormatStreetAddress(InputText: Text; var AddressLine1: Text; var AddressLine2: Text)
    var
        TB1: TextBuilder;
        TB2: TextBuilder;
        Ch: Char;
    begin
        InputText := RemoveExtraSpaces(InputText);
        foreach Ch in InputText do
            if IsLatinLetter(Ch) or IsDigit(Ch) or
               (Ch = ' ') or (Ch = '/') or (Ch = '-')
            then
                if TB1.Length < 35 then
                    TB1.Append(Ch)
                else
                    if TB2.Length < 35 then
                        TB2.Append(Ch);

        AddressLine1 := RemoveExtraSpaces(TB1.ToText());
        AddressLine2 := RemoveExtraSpaces(TB2.ToText());

        AddressLine1 := RemoveLeadingNonAlphanumChars(AddressLine1);
        AddressLine2 := RemoveLeadingNonAlphanumChars(AddressLine2);
    end;

    procedure FormatCityName(InputText: Text; AddressType: Enum "Address Type IRIS"): Text
    var
        TB: TextBuilder;
        Ch: Char;
        AddrMaxLength: Integer;
    begin
        InputText := RemoveExtraSpaces(InputText);
        case AddressType of
            AddressType::USAddress:
                AddrMaxLength := 40;
            AddressType::ForeignAddress:
                AddrMaxLength := 50;
        end;
        foreach Ch in InputText do
            if IsLatinLetter(Ch) or (Ch = ' ') then
                if TB.Length < AddrMaxLength then
                    TB.Append(Ch);

        exit(RemoveExtraSpaces(TB.ToText()));
    end;

    procedure FormatZipCode(InputText: Text): Text
    var
        TB: TextBuilder;
        Ch: Char;
    begin
        // ZIP Code - 5 digits plus optional 4 or 7 digits
        foreach Ch in InputText do
            if IsDigit(Ch) then
                TB.Append(Ch);

        exit(TB.ToText());
    end;

    procedure MatchStateCode(InputText: Text; var StateCode: Text): Boolean
    var
        StateTypeIRIS: Enum "State Type IRIS";
        TrimmedText: Text;
        StateName: Text;
    begin
        TrimmedText := DelChr(InputText, '<>', ' ');
        if TrimmedText = '' then begin
            StateCode := '';
            exit(false);
        end;
        foreach StateName in StateTypeIRIS.Names() do
            if UpperCase(TrimmedText) = UpperCase(StateName) then begin
                StateCode := StateName;
                exit(true);
            end;

        exit(false);
    end;

    procedure FormatPhoneNumber(InputText: Text): Text
    var
        TB: TextBuilder;
        Ch: Char;
    begin
        foreach Ch in InputText do
            if IsDigit(Ch) or (Ch = ',') then
                TB.Append(Ch);

        exit(TB.ToText());
    end;

    procedure FormatText(InputText: Text; MaxLength: Integer): Text
    begin
        InputText := RemoveExtraSpaces(InputText);
        exit(CopyStr(InputText, 1, MaxLength));
    end;

    procedure FormatText(InputText: Text): Text
    begin
        exit(RemoveExtraSpaces(InputText));
    end;

    procedure FormatDecimal(InputDecimal: Decimal): Text
    begin
        exit(Format(Round(InputDecimal, 0.01), 0, 9));
    end;

    procedure FormatBoolean(InputBoolean: Boolean): Text
    begin
        exit(Format(InputBoolean, 0, 2));       // 0 or 1
    end;

    local procedure IsLatinLetter(Ch: Char): Boolean
    begin
        exit(TypeHelper.IsLatinLetter(Ch));
    end;

    local procedure IsDigit(Ch: Char): Boolean
    begin
        exit(TypeHelper.IsDigit(Ch));
    end;

    local procedure RemoveExtraSpaces(InputText: Text): Text
    var
        IRSFormsData: Codeunit "IRS Forms Data";
    begin
        exit(IRSFormsData.RemoveExtraSpaces(InputText));
    end;

    local procedure RemoveLeadingNonAlphanumChars(InputText: Text): Text
    var
        TB: TextBuilder;
        Ch: Char;
        FirstValidCharFound: Boolean;
    begin
        foreach Ch in InputText do begin
            if not FirstValidCharFound then
                if IsLatinLetter(Ch) or IsDigit(Ch) then
                    FirstValidCharFound := true
                else
                    continue;
            TB.Append(Ch);
        end;

        exit(TB.ToText());
    end;

    procedure ISOToFIPSCountryCode(ISOCountryCode: Code[10]): Code[2]
    begin
        case ISOCountryCode of
            'DZ':
                exit('AG');     // Algeria
            'AS':
                exit('AQ');     // American Samoa
            'AD':
                exit('AN');     // Andorra
            'AI':
                exit('AV');     // Anguilla
            'AQ':
                exit('AY');     // Antarctica
            'AG':
                exit('AC');     // Antigua and Barbuda
            'AW':
                exit('AA');     // Aruba
            'AU':
                exit('AS');     // Australia
            'AT':
                exit('AU');     // Austria
            'AZ':
                exit('AJ');     // Azerbaijan
            'BA':
                exit('BK');     // Bosnia and Herzegovina
            'BL':
                exit('TB');     // Saint Barthélemy
            'BN':
                exit('BX');     // Brunei Darussalam
            'BS':
                exit('BF');     // Bahamas
            'BH':
                exit('BA');     // Bahrain
            'BD':
                exit('BG');     // Bangladesh
            'BY':
                exit('BO');     // Belarus
            'BZ':
                exit('BH');     // Belize
            'BJ':
                exit('BN');     // Benin
            'BM':
                exit('BD');     // Bermuda
            'BW':
                exit('BC');     // Botswana
            'BG':
                exit('BU');     // Bulgaria
            'BF':
                exit('UV');     // Burkina Faso
            'BI':
                exit('BY');     // Burundi
            'KH':
                exit('CB');     // Cambodia
            'KY':
                exit('CJ');     // Cayman Islands
            'CF':
                exit('CT');     // Central African Republic
            'TD':
                exit('CD');     // Chad
            'CL':
                exit('CI');     // Chile
            'CN':
                exit('CH');     // China
            'CX':
                exit('KT');     // Christmas Island
            'CC':
                exit('CK');     // Cocos (Keeling) Islands
            'CD':
                exit('CG');     // Congo (Democratic Republic of the)
            'CG':
                exit('CF');     // Congo
            'KM':
                exit('CN');     // Comoros
            'CK':
                exit('CW');     // Cook Islands
            'CR':
                exit('CS');     // Costa Rica
            'CW':
                exit('UC');     // Curaçao
            'CZ':
                exit('EZ');     // Czechia
            'DK':
                exit('DA');     // Denmark
            'DM':
                exit('DO');     // Dominica
            'DO':
                exit('DR');     // Dominican Republic
            'SV':
                exit('ES');     // El Salvador
            'GQ':
                exit('EK');     // Equatorial Guinea
            'EE':
                exit('EN');     // Estonia
            'PF':
                exit('FP');     // French Polynesia
            'GA':
                exit('GB');     // Gabon
            'GB':
                exit('UK');     // United Kingdom
            'GE':
                exit('GG');     // Georgia
            'DE':
                exit('GM');     // Germany
            'GD':
                exit('GJ');     // Grenada
            'GU':
                exit('GQ');     // Guam
            'GG':
                exit('GK');     // Guernsey
            'GN':
                exit('GV');     // Guinea
            'GW':
                exit('PU');     // Guinea-Bissau
            'HT':
                exit('HA');     // Haiti
            'HM':
                exit('HQ');     // Heard Island and McDonald Islands
            'HN':
                exit('HO');     // Honduras
            'IS':
                exit('IC');     // Iceland
            'IQ':
                exit('IZ');     // Iraq
            'IE':
                exit('EI');     // Ireland
            'IL':
                exit('IS');     // Israel
            'JP':
                exit('JA');     // Japan
            'UM':
                exit('JQ');     // United States Minor Outlying Islands
            'KI':
                exit('KR');     // Kiribati
            'KW':
                exit('KU');     // Kuwait
            'LV':
                exit('LG');     // Latvia
            'LB':
                exit('LE');     // Lebanon
            'LS':
                exit('LT');     // Lesotho
            'LR':
                exit('LI');     // Liberia
            'LI':
                exit('LS');     // Liechtenstein
            'LT':
                exit('LH');     // Lithuania
            'MG':
                exit('MA');     // Madagascar
            'MW':
                exit('MI');     // Malawi
            'MH':
                exit('RM');     // Marshall Islands
            'MU':
                exit('MP');     // Mauritius
            'MC':
                exit('MN');     // Monaco
            'MN':
                exit('MG');     // Mongolia
            'ME':
                exit('MJ');     // Montenegro
            'MS':
                exit('MH');     // Montserrat
            'MA':
                exit('MO');     // Morocco
            'NA':
                exit('WA');     // Namibia
            'NI':
                exit('NU');     // Nicaragua
            'NE':
                exit('NG');     // Niger
            'NG':
                exit('NI');     // Nigeria
            'NU':
                exit('NE');     // Niue
            'MP':
                exit('CQ');     // Northern Mariana Islands
            'OM':
                exit('MU');     // Oman
            'PW':
                exit('PS');     // Palau
            'PA':
                exit('PM');     // Panama
            'PG':
                exit('PP');     // Papua New Guinea
            'PN':
                exit('PC');     // Pitcairn Islands
            'PY':
                exit('PA');     // Paraguay
            'PH':
                exit('RP');     // Philippines
            'PT':
                exit('PO');     // Portugal
            'PR':
                exit('RQ');     // Puerto Rico
            'ST':
                exit('TP');     // Sao Tome and Principe
            'SN':
                exit('SG');     // Senegal
            'RS':
                exit('RI');     // Serbia
            'SC':
                exit('SE');     // Seychelles
            'SG':
                exit('SN');     // Singapore
            'SK':
                exit('LO');     // Slovakia
            'SB':
                exit('BP');     // Solomon Islands
            'ZA':
                exit('SF');     // South Africa
            'GS':
                exit('SX');     // South Georgia and the South Sandwich Islands
            'SS':
                exit('OD');     // South Sudan
            'ES':
                exit('SP');     // Spain
            'LK':
                exit('CE');     // Sri Lanka
            'SD':
                exit('SU');     // Sudan
            'SR':
                exit('NS');     // Suriname
            'SE':
                exit('SW');     // Sweden
            'CH':
                exit('SZ');     // Switzerland
            'TJ':
                exit('TI');     // Tajikistan
            'TF':
                exit('FS');     // French Southern Territories
            'TG':
                exit('TO');     // Togo
            'TK':
                exit('TL');     // Tokelau
            'TO':
                exit('TN');     // Tonga
            'TT':
                exit('TD');     // Trinidad and Tobago
            'TN':
                exit('TS');     // Tunisia
            'TM':
                exit('TX');     // Turkmenistan
            'TC':
                exit('TK');     // Turks and Caicos Islands
            'UA':
                exit('UP');     // Ukraine
            'VU':
                exit('NH');     // Vanuatu
            'VN':
                exit('VM');     // Vietnam
            'WF':
                exit('WQ');     // Wallis and Futuna
            'EH':
                exit('WI');     // Western Sahara
            'ZM':
                exit('ZA');     // Zambia
            'ZW':
                exit('ZI');     // Zimbabwe
            else
                exit(CopyStr(ISOCountryCode, 1, 2));
        end;
    end;

    procedure GetVendorBankAccountNo(var Vendor: Record Vendor) BankAccountNo: Text
    var
        VendorBankAccount: Record "Vendor Bank Account";
    begin
        if Vendor."Preferred Bank Account Code" <> '' then
            if VendorBankAccount.Get(Vendor."No.", Vendor."Preferred Bank Account Code") then
                BankAccountNo := VendorBankAccount.GetBankAccountNo();

        BankAccountNo := FormatText(BankAccountNo);
        if StrLen(BankAccountNo) > GetRecipientBankAccountNoMaxLength() then        // RecipientAccountNum is optional, but cannot exceed 30 chars
            BankAccountNo := '';
    end;

    local procedure GetRecipientBankAccountNoMaxLength(): Integer
    begin
        exit(30);
    end;
    #endregion Data Formatting and Normalization

    #region Integration Events
    [IntegrationEvent(false, false)]
    local procedure OnAfterGetFormBoxAmountXmlElementNames(PeriodNo: Text; FormType: Text; var FormAmountXmlElementNames: Dictionary of [Text, Text])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetAmountXmlElementList(PeriodNo: Text; FormType: Text; ElementOrderType: Text; var AmountXmlElementNames: List of [Text])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetFederalIncomeTaxWithheldFormBoxes(PeriodNo: Text; var FormBoxes: Dictionary of [Text, Boolean])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAddOtherForm1099DetailsPart(var TempIRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header" temporary; var XmlNodesNameValue: Dictionary of [Text, Text])
    begin
    end;
    #endregion Integration Events
}