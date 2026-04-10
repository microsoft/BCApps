codeunit 131339 "Library - Verify XML Schema"
{

    trigger OnRun()
    begin
    end;

    var
        AdditionalSchemaPaths: array[5] of Text;
        CountOfAdditionalSchemaPaths: Integer;
        AdditionalXmlSchemaPathsLimitReachedErr: Label 'You cannot set any more additional schema paths.';

    [TryFunction]
    local procedure VerifyXMLAgainstSchemaLocal(XmlFilePath: Text; XmlSchemaPath: Text)
    var
        XmlDoc: DotNet XmlDocument;
        XmlUrlResolver: DotNet XmlUrlResolver;
        NetCredentialCache: DotNet CredentialCache;
        ValidationEventHandler: DotNet "System.Xml.Schema.ValidationEventHandler";
        I: Integer;
    begin
        XmlDoc := XmlDoc.XmlDocument();

        XmlUrlResolver := XmlUrlResolver.XmlUrlResolver();
        XmlUrlResolver.Credentials := NetCredentialCache.DefaultNetworkCredentials;
        XmlDoc.Schemas.XmlResolver := XmlUrlResolver;

        AddSchemaToDoc(XmlDoc, XmlSchemaPath);
        if CountOfAdditionalSchemaPaths > 0 then
            for I := 1 to CountOfAdditionalSchemaPaths do
                AddSchemaToDoc(XmlDoc, AdditionalSchemaPaths[I]);
        XmlDoc.Load(XmlFilePath);
        XmlDoc.Validate(ValidationEventHandler);
    end;

    [TryFunction]
    local procedure VerifyXMLStreamAgainstSchemaLocal(XmlInStream: InStream; XmlSchemaPath: Text)
    var
        XmlDoc: DotNet XmlDocument;
        XmlUrlResolver: DotNet XmlUrlResolver;
        NetCredentialCache: DotNet CredentialCache;
        ValidationEventHandler: DotNet "System.Xml.Schema.ValidationEventHandler";
        I: Integer;
    begin
        XmlDoc := XmlDoc.XmlDocument();

        XmlUrlResolver := XmlUrlResolver.XmlUrlResolver();
        XmlUrlResolver.Credentials := NetCredentialCache.DefaultNetworkCredentials;
        XmlDoc.Schemas.XmlResolver := XmlUrlResolver;

        AddSchemaToDoc(XmlDoc, XmlSchemaPath);
        IF CountOfAdditionalSchemaPaths > 0 THEN
            FOR I := 1 TO CountOfAdditionalSchemaPaths DO
                AddSchemaToDoc(XmlDoc, AdditionalSchemaPaths[I]);
        XmlDoc.Load(XmlInStream);
        XmlDoc.Validate(ValidationEventHandler);
    end;

    local procedure AddSchemaToDoc(var XmlDoc: DotNet XmlDocument; XmlSchemaPath: Text)
    var
        XmlTextReader: DotNet XmlTextReader;
        XmlSchema: DotNet "System.Xml.Schema.XmlSchema";
        ValidationEventHandler: DotNet "System.Xml.Schema.ValidationEventHandler";
    begin
        XmlTextReader := XmlTextReader.XmlTextReader(XmlSchemaPath);
        XmlSchema := XmlSchema.Read(XmlTextReader, ValidationEventHandler);
        XmlDoc.Schemas.Add(XmlSchema);
    end;

    procedure VerifyXMLAgainstSchema(XmlFilePath: Text; XmlSchemaPath: Text; var Message: Text) Result: Boolean
    begin
        Result := VerifyXMLAgainstSchemaLocal(XmlFilePath, XmlSchemaPath);
        ResetSchemaPathGlobals();

        if Result then
            exit;

        Message := GetXmlSchemaValidationExceptionMessage();
    end;

    procedure VerifyXMLStreamAgainstSchema(XmlFileInStream: InStream; XmlSchemaPath: Text; var Message: Text) Result: Boolean
    begin
        Result := VerifyXMLStreamAgainstSchemaLocal(XmlFileInStream, XmlSchemaPath);
        ResetSchemaPathGlobals();

        if Result then
            exit;

        Message := GetXmlSchemaValidationExceptionMessage();
    end;

    procedure SetAdditionalSchemaPath(XmlSchemaPath: Text)
    begin
        if CountOfAdditionalSchemaPaths = ArrayLen(AdditionalSchemaPaths) then
            Error(AdditionalXmlSchemaPathsLimitReachedErr);
        CountOfAdditionalSchemaPaths += 1;
        AdditionalSchemaPaths[CountOfAdditionalSchemaPaths] := XmlSchemaPath;
    end;

    local procedure ResetSchemaPathGlobals()
    var
        i: Integer;
    begin
        if CountOfAdditionalSchemaPaths > 0 then
            for i := 1 to CountOfAdditionalSchemaPaths do
                AdditionalSchemaPaths[i] := '';
        CountOfAdditionalSchemaPaths := 0;
    end;

    local procedure GetXmlSchemaValidationExceptionMessage(): Text;
    var
        DotNetExceptionHandler: Codeunit "DotNet Exception Handler";
    begin
        DotNetExceptionHandler.Collect();
        exit(DotNetExceptionHandler.GetMessage());
    end;
}

