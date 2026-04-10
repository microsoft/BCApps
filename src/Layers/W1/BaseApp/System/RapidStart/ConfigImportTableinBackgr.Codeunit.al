namespace System.IO;

using System;
using System.Threading;

codeunit 8626 "Config. Import Table in Backgr"
{
    TableNo = "Parallel Session Entry";

    trigger OnRun()
    var
        ConfigXMLExchange: Codeunit "Config. XML Exchange";
        MemoryMappedFile: Codeunit "Memory Mapped File";
        PackageXML: DotNet XmlDocument;
        DocumentElement: DotNet XmlElement;
        TableNode: DotNet XmlNode;
        nodetext: Text;
        PackageCode: Code[20];
    begin
        PackageCode := CopyStr(Rec.Parameter, 1, MaxStrLen(PackageCode));
        if PackageCode = '' then
            exit;

        if not MemoryMappedFile.OpenMemoryMappedFile(Format(Rec.ID)) then
            exit;
        MemoryMappedFile.ReadTextWithSeparatorsFromMemoryMappedFile(nodetext);
        MemoryMappedFile.Dispose();

        PackageXML := PackageXML.XmlDocument();
        PackageXML.LoadXml(nodetext);
        if IsNull(PackageXML) then
            exit;
        DocumentElement := PackageXML.DocumentElement;
        if IsNull(DocumentElement) then
            exit;
        TableNode := DocumentElement.FirstChild;
        if IsNull(TableNode) then
            exit;
        ConfigXMLExchange.SetHideDialog(true);
        ConfigXMLExchange.ImportTableFromXMLNode(TableNode, PackageCode);
    end;
}

