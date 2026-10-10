namespace Microsoft.Finance.VAT.Reporting;

codeunit 13617 "Elec. VAT Decl. Period Builder" implements "Elec. VAT Decl. Payload Builder"
{
    Access = Internal;

    procedure BuildPayload(ElecVATDeclParameters: Record "Elec. VAT Decl. Parameters"; var Body: XmlNode; var ReferenceList: List of [Text]; var TransactionID: Code[100])
    var
        ElecVATDeclXml: Codeunit "Elec. VAT Decl. Xml";
        VirksomhedKalenderHent_I: XmlNode;
        HovedOplysninger: XmlNode;
        TransaktionIdentifikator: XmlNode;
        TransaktionTid: XmlNode;
        AngivelseTypeNavn: XmlNode;
        VirksomhedSENummerIdentifikator: XmlNode;
        AngivelseBetalingFristHentFra: XmlNode;
        SoegeDatoFraDate: XmlNode;
        SoegeDatoTilDate: XmlNode;
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
        // -VirksomhedKalenderHent_I
        ElecVATDeclXml.AddElement(Body, 'VirksomhedKalenderHent_I', '', ElecVATDeclXml.GetSkatNamespace1(), VirksomhedKalenderHent_I);
        // --HovedOplysninger start
        ElecVATDeclXml.AddElement(VirksomhedKalenderHent_I, 'HovedOplysninger', '', ElecVATDeclXml.GetSkatNamespace2(), HovedOplysninger);
        // ---TransaktionIdentifikator
        TransactionID := ElecVATDeclXml.GetTransactionID();
        ElecVATDeclXml.AddElement(HovedOplysninger, 'TransaktionIdentifikator', TransactionID, ElecVATDeclXml.GetSkatNamespace2(), TransaktionIdentifikator);
        // ---TransaktionTid
        ElecVATDeclXml.AddElement(HovedOplysninger, 'TransaktionTid', ElecVATDeclXml.GetTimeStamp(0), ElecVATDeclXml.GetSkatNamespace2(), TransaktionTid);
        // --HovedOplysninger end
        // --VirksomhedSENummerIdentifikator
        ElecVATDeclXml.AddElement(VirksomhedKalenderHent_I, 'VirksomhedSENummerIdentifikator', ElecVATDeclXml.GetCompanyID(), ElecVATDeclXml.GetSkatNamespace3(), VirksomhedSENummerIdentifikator);
        // --AngivelseTypeNavn
        ElecVATDeclXml.AddElement(VirksomhedKalenderHent_I, 'AngivelseTypeNavn', 'Moms', ElecVATDeclXml.GetSkatNamespace4(), AngivelseTypeNavn);
        // --AngivelseBetalingFristHentFra start
        ElecVATDeclXml.AddElement(VirksomhedKalenderHent_I, 'AngivelseBetalingFristHentFra', '', ElecVATDeclXml.GetSkatNamespace1(), AngivelseBetalingFristHentFra);
        // ---SoegeDatoFraDate
        ElecVATDeclXml.AddElement(AngivelseBetalingFristHentFra, 'SoegeDatoFraDate', ElecVATDeclXml.Date_AsXMLText(ElecVATDeclParameters."From Date"), ElecVATDeclXml.GetSkatNamespace4(), SoegeDatoFraDate);
        // ---SoegeDatoTilDate
        ElecVATDeclXml.AddElement(AngivelseBetalingFristHentFra, 'SoegeDatoTilDate', ElecVATDeclXml.Date_AsXMLText(ElecVATDeclParameters."To Date"), ElecVATDeclXml.GetSkatNamespace4(), SoegeDatoTilDate);
        // --AngivelseBetalingFristHentFra end
        // -VirksomhedKalenderHent_I end
        // Body end
    end;
}