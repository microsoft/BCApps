namespace Microsoft.Finance.VAT.Reporting;

codeunit 13615 "Elec. VAT Decl. Check Builder" implements "Elec. VAT Decl. Payload Builder"
{
    Access = Internal;

    procedure BuildPayload(ElecVATDeclParameters: Record "Elec. VAT Decl. Parameters"; var Body: XmlNode; var ReferenceList: List of [Text]; var TransactionID: Code[100])
    var
        ElecVATDeclXml: Codeunit "Elec. VAT Decl. Xml";
        MomsangivelseKvitteringHent_I: XmlNode;
        HovedOplysninger: XmlNode;
        TransaktionIdentifikator: XmlNode;
        TransaktionTid: XmlNode;
        TransaktionIdentifier: XmlNode;
        Angiver: XmlNode;
        VirksomhedSENummerIdentifikator: XmlNode;
        BodyTokenId: Text;
    begin
        // Body start
        Body := XmlElement.Create('Body', ElecVATDeclXml.GetSoapNamespace()).AsXmlNode();
        BodyTokenId := ElecVATDeclXml.GetBodyIdTok();
        ElecVATDeclXml.AddAttribute(Body, 'Id', BodyTokenId);
        ReferenceList.Add(BodyTokenId);

        ElecVATDeclXml.AddNamespaceDeclaration(Body, 'ns1', ElecVATDeclXml.GetSkatNamespace1());
        ElecVATDeclXml.AddNamespaceDeclaration(Body, 'ns2', ElecVATDeclXml.GetSkatNamespace2());
        ElecVATDeclXml.AddNamespaceDeclaration(Body, 'ns3', ElecVATDeclXml.GetSkatNamespace3());
        ElecVATDeclXml.AddNamespaceDeclaration(Body, 'ns4', ElecVATDeclXml.GetSkatNamespace4());
        // -MomsangivelseKvitteringHent_I
        ElecVATDeclXml.AddElement(Body, 'MomsangivelseKvitteringHent_I', '', ElecVATDeclXml.GetSkatNamespace1(), MomsangivelseKvitteringHent_I);
        // --HovedOplysninger start
        ElecVATDeclXml.AddElement(MomsangivelseKvitteringHent_I, 'HovedOplysninger', '', ElecVATDeclXml.GetSkatNamespace2(), HovedOplysninger);
        // ---TransaktionIdentifikator
        TransactionID := ElecVATDeclXml.GetTransactionID();
        ElecVATDeclXml.AddElement(HovedOplysninger, 'TransaktionIdentifikator', TransactionID, ElecVATDeclXml.GetSkatNamespace2(), TransaktionIdentifikator);
        // ---TransaktionTid
        ElecVATDeclXml.AddElement(HovedOplysninger, 'TransaktionTid', ElecVATDeclXml.GetTimeStamp(0), ElecVATDeclXml.GetSkatNamespace2(), TransaktionTid);
        // --HovedOplysninger end
        // -TransaktionIdentifier
        ElecVATDeclXml.AddElement(MomsangivelseKvitteringHent_I, 'TransaktionIdentifier', ElecVATDeclParameters."Transaction ID", ElecVATDeclXml.GetSkatNamespace4(), TransaktionIdentifier);
        // -TransaktionIdentifier end
        // -Angiver
        ElecVATDeclXml.AddElement(MomsangivelseKvitteringHent_I, 'Angiver', '', ElecVATDeclXml.GetSkatNamespace1(), Angiver);
        // --VirksomhedSENummerIdentifikator
        ElecVATDeclXml.AddElement(Angiver, 'VirksomhedSENummerIdentifikator', ElecVATDeclXml.GetCompanyID(), ElecVATDeclXml.GetSkatNamespace3(), VirksomhedSENummerIdentifikator);
        // --VirksomhedSENummerIdentifikator end
        // -Angiver end
        // -MomsangivelseKvitteringHent_I end
        // Body end
    end;
}