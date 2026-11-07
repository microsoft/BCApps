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
        TableNode: XmlNode;
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

        if not XmlDocument.ReadFrom(nodetext, PackageXML) then
            exit;

        if not PackageXML.GetRoot(DocumentElement) then
            exit;

        if not GetFirstChildNode(DocumentElement.AsXmlNode(), TableNode) then
            exit;

        ConfigXMLExchange.SetHideDialog(true);
        ConfigXMLExchange.ImportTableFromXMLNode(TableNode, PackageCode);
    end;

    local procedure GetFirstChildNode(ParentNode: XmlNode; var FirstChild: XmlNode): Boolean
    var
        ChildNodes: XmlNodeList;
    begin
        ChildNodes := ParentNode.AsXmlElement().GetChildNodes();
        if ChildNodes.Count() = 0 then
            exit(false);
        exit(ChildNodes.Get(1, FirstChild));
    end;
}