namespace System.IO;

using System.Threading;

codeunit 8626 "Config. Import Table in Backgr"
{
    TableNo = "Parallel Session Entry";

    trigger OnRun()
    var
        ConfigXMLExchange: Codeunit "Config. XML Exchange";
        MemoryMappedFile: Codeunit "Memory Mapped File";
        PackageXML: XmlDocument;
        DocumentElement: XmlElement;
        TableXmlNode: XmlNode;
        TableNode: XmlElement;
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

        XmlDocument.ReadFrom(nodetext, PackageXML);
        if not PackageXML.GetRoot(DocumentElement) then
            exit;
        if not DocumentElement.GetChildNodes().Get(1, TableXmlNode) then
            exit;
        if not TableXmlNode.IsXmlElement() then
            exit;
        TableNode := TableXmlNode.AsXmlElement();
        ConfigXMLExchange.SetHideDialog(true);
        ConfigXMLExchange.ImportTableFromXMLNode(TableNode, PackageCode);
    end;
}