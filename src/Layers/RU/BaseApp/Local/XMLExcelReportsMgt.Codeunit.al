#pragma warning disable AA0247
codeunit 12408 "XML-Excel Reports Mgt."
{

    trigger OnRun()
    begin
    end;

    var
        XMLReport: DotNet XmlDocument;

    [Scope('OnPrem')]
    procedure AddSubNode(var ParentNode: DotNet XmlNode; var ChildNode: DotNet XmlNode; Tag: Text[260])
    var
        XMLElement: DotNet XmlElement;
    begin
        XMLElement := XMLReport.CreateElement(Tag);
        ChildNode := ParentNode.AppendChild(XMLElement);
    end;

    [Scope('OnPrem')]
    procedure AddAttributeNode(var Node: DotNet XmlNode; var Attr: DotNet XmlAttribute; Name: Text[250]; Value: Variant)
    begin
        Attr := XMLReport.CreateAttribute(Name);
        Attr.Value := Value;

        Attr := Node.Attributes.SetNamedItem(Attr);
        Attr.Value := Value;
    end;

    [Scope('OnPrem')]
    procedure AddAttributeDate(var Node: DotNet XmlNode; var Attr: DotNet XmlAttribute; Name: Text[260]; Date: Date)
    var
        Value: Variant;
    begin
        Attr := XMLReport.CreateAttribute(Name);
        Value := Format(Date, 10, '<Year4>-<Month,2>-<Day,2>');
        Attr.Value := Value;
        Attr := Node.Attributes.SetNamedItem(Attr);
    end;

    [Scope('OnPrem')]
    procedure CreateXMLDoc(var XMLDoc: DotNet XmlDocument; TxtEncoding: Text[60]; var RootNode: DotNet XmlNode; TxtRootTagName: Text[100])
    var
        ProcInstr: DotNet XmlProcessingInstruction;
    begin
        XMLReport := XMLDoc;
        if IsNull(XMLReport) then
            XMLReport := XMLReport.XmlDocument();

        ProcInstr := XMLReport.CreateProcessingInstruction('xml', ' version="1.0" encoding="' + TxtEncoding + '"');
        XMLReport.AppendChild(ProcInstr);

        RootNode := XMLReport.CreateElement(TxtRootTagName);
        XMLReport.AppendChild(RootNode);
    end;

    [Scope('OnPrem')]
    procedure AddAttribute(var Node: DotNet XmlNode; TxtName: Text[250]; VarValue: Variant)
    var
        Attribute: DotNet XmlAttribute;
        DtDateTime: DateTime;
    begin
        if VarValue.IsDate then begin
            Attribute := Node.OwnerDocument.CreateAttribute(TxtName);
            AddAttributeDate(Node, Attribute, TxtName, VarValue);
        end else
            if Evaluate(DtDateTime, Format(VarValue)) and
               (Format(DtDateTime) = Format(VarValue))
            then
                AddAttributeDateTime(Node, TxtName, DtDateTime)
            else begin
                Attribute := Node.OwnerDocument.CreateAttribute(TxtName);
                Attribute.Value := Format(VarValue);
                Attribute := Node.Attributes.SetNamedItem(Attribute);
                Clear(Attribute);
            end;
    end;

    [Scope('OnPrem')]
    procedure AddAttributeDateTime(var Node: DotNet XmlNode; TxtName: Text[250]; DtValue: DateTime)
    var
        Attribute: DotNet XmlAttribute;
        VarValue: Variant;
    begin
        Attribute := Node.OwnerDocument.CreateAttribute(TxtName);
        VarValue :=
          Format(DtValue, 20, '<Year4>-<Month,2>-<Day,2>T <Hours24,2>:<Minutes,2>:<Seconds,2>');
        Attribute.Value := VarValue;
        Attribute := Node.Attributes.SetNamedItem(Attribute);
        Attribute.Value := VarValue;
        Clear(Attribute);
    end;

    [Scope('OnPrem')]
    procedure SaveXMLDocWithEncoding(OutStr: OutStream; XmlDoc: DotNet XmlDocument; EncodingName: Text)
    var
        XmlWriterSettings: DotNet XmlWriterSettings;
        XmlWriter: DotNet XmlWriter;
        Encoding: DotNet Encoding;
    begin
        XmlWriterSettings := XmlWriterSettings.XmlWriterSettings();
        XmlWriterSettings.Indent := true;
        XmlWriterSettings.Encoding := Encoding.GetEncoding(EncodingName);

        XmlWriter := XmlWriter.Create(OutStr, XmlWriterSettings);
        XmlDoc.WriteTo(XmlWriter);
        XmlWriter.Close();
    end;
}

