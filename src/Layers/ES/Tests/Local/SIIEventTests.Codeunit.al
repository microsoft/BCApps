codeunit 147564 "SII Event Tests"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [Scope('OnPrem')]
    procedure GenerateXMLDocumentIsHandledBy3rdParty()
    var
        GLEntry: Record "G/L Entry";
        SIIEventTests: codeunit "SII Event Tests";
        SIIXMLCreator: codeunit "SII XML Creator";
        ResultXmlDocument, ExpectedXmlDocument : DotNet XmlDocument;
        ResultXML, ExpectedXML : text;
    begin
        BindSubscription(SIIEventTests);
        SIIXMLCreator.GenerateXml(GLEntry, ResultXmlDocument, 0, false);
        ResultXML := ResultXmlDocument.OuterXml();

        ExpectedXmlDocument := ExpectedXmlDocument.XmlDocument();
        ExpectedXmlDocument.LoadXml(GetSampleXml());
        ExpectedXML := ExpectedXmlDocument.OuterXml();

        Assert.AreEqual(ExpectedXML, ResultXML, 'Xml Document did not match.');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"SII XML Creator", 'OnBeforeGenerateXmlDocument', '', true, true)]
    local procedure GenerateXmlDocument(LedgerEntry: Variant; var XMLDocOut: XmlDocument; UploadType: Option; IsCreditMemoRemoval: Boolean; var ResultValue: Boolean; var IsHandled: Boolean; RetryAccepted: Boolean; SIIVersion: Option)
    begin
        XmlDocument.ReadFrom(GetSampleXml(), XMLDocOut);

        IsHandled := true;
        ResultValue := true;
    end;

    local procedure GetSampleXml() Xml: Text
    var
        StringBuilder: TextBuilder;
    begin
        StringBuilder.Append('<?xml version="1.0" encoding="utf-8" ?>');
        StringBuilder.Append('<bookstore xmlns="http://www.contoso.com/books">');
        StringBuilder.Append('    <book genre="autobiography" publicationdate="1981-03-22" ISBN="1-861003-11-0">');
        StringBuilder.Append('        <title>The Autobiography of Benjamin Franklin</title>');
        StringBuilder.Append('        <author>');
        StringBuilder.Append('            <first-name>Benjamin</first-name>');
        StringBuilder.Append('            <last-name>Franklin</last-name>');
        StringBuilder.Append('        </author>');
        StringBuilder.Append('        <price>8.99</price>');
        StringBuilder.Append('    </book>');
        StringBuilder.Append('</bookstore>');

        Xml := StringBuilder.ToText();
    end;

    var
        Assert: Codeunit Assert;
}