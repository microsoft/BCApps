namespace Microsoft.Finance.VAT.Reporting;

codeunit 13616 "Elec. VAT Decl. Submit Builder" implements "Elec. VAT Decl. Payload Builder"
{
    Access = Internal;

    var
        ElecVATDeclXml: Codeunit "Elec. VAT Decl. Xml";
        VATReportErrNotFoundErr: Label 'VAT Report Header No. %1 does not exist', Comment = '%1 = VAT Report Header Number.';

    procedure BuildPayload(ElecVATDeclParameters: Record "Elec. VAT Decl. Parameters"; var Body: XmlNode; var ReferenceList: List of [Text]; var TransactionID: Code[100]);
    var
        VATReportHeader: Record "VAT Report Header";
        ModtagMomsangivelseForeloebig_I: XmlNode;
        HovedOplysninger: XmlNode;
        TransaktionIdentifikator: XmlNode;
        TransaktionTid: XmlNode;
        Angivelse: XmlNode;
        AngiverVirksomhedSENummer: XmlNode;
        VirksomhedSENummerIdentifikator: XmlNode;
        Angivelsesoplysninger: XmlNode;
        AngivelsePeriodeFraDato: XmlNode;
        AngivelsePeriodeTilDato: XmlNode;
        Angivelsesafgifter: XmlNode;
        BodyTokenId: Text;
    begin
        if not VATReportHeader.Get(ElecVATDeclParameters."VAT Report Config. Code", ElecVATDeclParameters."VAT Report Header No.") then
            Error(VATReportErrNotFoundErr);

        // Body
        Body := XmlElement.Create('Body', ElecVATDeclXml.GetSoapNamespace()).AsXmlNode();
        BodyTokenId := ElecVATDeclXml.GetBodyIdTok();
        ElecVATDeclXml.AddAttribute(Body, 'Id', BodyTokenId);
        ReferenceList.Add(BodyTokenId);

        ElecVATDeclXml.AddNamespaceDeclaration(Body, 'ns1', ElecVATDeclXml.GetSkatNamespace1());
        ElecVATDeclXml.AddNamespaceDeclaration(Body, 'ns2', ElecVATDeclXml.GetSkatNamespace2());
        ElecVATDeclXml.AddNamespaceDeclaration(Body, 'ns3', ElecVATDeclXml.GetSkatNamespace3());
        ElecVATDeclXml.AddNamespaceDeclaration(Body, 'ns4', ElecVATDeclXml.GetSkatNamespace4());
        // -ModtagMomsangivelseForeloebig_I
        ElecVATDeclXml.AddElement(Body, 'ModtagMomsangivelseForeloebig_I', '', ElecVATDeclXml.GetSkatNamespace1(), ModtagMomsangivelseForeloebig_I);
        // --HovedOplysninger
        ElecVATDeclXml.AddElement(ModtagMomsangivelseForeloebig_I, 'HovedOplysninger', '', ElecVATDeclXml.GetSkatNamespace2(), HovedOplysninger);
        // ---TransaktionIdentifikator
        TransactionID := ElecVATDeclXml.GetTransactionID();
        ElecVATDeclXml.AddElement(HovedOplysninger, 'TransaktionIdentifikator', TransactionID, ElecVATDeclXml.GetSkatNamespace2(), TransaktionIdentifikator);
        // ---TransaktionTid
        ElecVATDeclXml.AddElement(HovedOplysninger, 'TransaktionTid', ElecVATDeclXml.GetTimeStamp(0), ElecVATDeclXml.GetSkatNamespace2(), TransaktionTid);
        // --HovedOplysninger end
        // --Angivelse
        ElecVATDeclXml.AddElement(ModtagMomsangivelseForeloebig_I, 'Angivelse', '', ElecVATDeclXml.GetSkatNamespace1(), Angivelse);
        // ---AngiverVirksomhedSENummer
        ElecVATDeclXml.AddElement(Angivelse, 'AngiverVirksomhedSENummer', '', ElecVATDeclXml.GetSkatNamespace1(), AngiverVirksomhedSENummer);
        // ----VirksomhedSENummerIdentifikator start-end
        ElecVATDeclXml.AddElement(AngiverVirksomhedSENummer, 'VirksomhedSENummerIdentifikator', ElecVATDeclXml.GetCompanyID(), ElecVATDeclXml.GetSkatNamespace3(), VirksomhedSENummerIdentifikator);
        // ---AngiverVirksomhedSENummer end
        // ---Angivelsesoplysninger
        ElecVATDeclXml.AddElement(Angivelse, 'Angivelsesoplysninger', '', ElecVATDeclXml.GetSkatNamespace1(), Angivelsesoplysninger);
        // ----AngivelsePeriodeFraDato
        ElecVATDeclXml.AddElement(Angivelsesoplysninger, 'AngivelsePeriodeFraDato', ElecVATDeclXml.Date_AsXMLText(VATReportHeader."Start Date"), ElecVATDeclXml.GetSkatNamespace4(), AngivelsePeriodeFraDato);
        // ----AngivelsePeriodeTilDato
        ElecVATDeclXml.AddElement(Angivelsesoplysninger, 'AngivelsePeriodeTilDato', ElecVATDeclXml.Date_AsXMLText(VATReportHeader."End Date"), ElecVATDeclXml.GetSkatNamespace4(), AngivelsePeriodeTilDato);
        // ---Angivelsesoplysninger end
        // ---Angivelsesafgifter
        ElecVATDeclXml.AddElement(Angivelse, 'Angivelsesafgifter', '', ElecVATDeclXml.GetSkatNamespace1(), Angivelsesafgifter);
        FillDataRows(VATReportHeader, Angivelsesafgifter);
        // ---Angivelsesafgifter end
        // --Angivelse end
        // -ModtagMomsangivelseForeloebig_I end
        // Body end
    end;

    local procedure FillDataRows(VATReportHeaderParam: Record "VAT Report Header"; ParentNode: XmlNode)
    var
        RowData: Dictionary of [Text, Decimal];
        RowNode: XmlNode;
        NodeName: Text;
        RowNoText: Text;
        RowNo: Integer;
        RowAmount: Decimal;
    begin
        RowData := GenerateRowData(VATReportHeaderParam);
        RowData.Add('1', CalculateDeclarationTotal(RowData));

        for RowNo := 1 to 17 do begin
            RowNoText := Format(RowNo);
            NodeName := ConvertRowNoToNodeName(RowNoText);
            if RowData.ContainsKey(RowNoText) then
                RowAmount := RowData.Get(RowNoText)
            else
                RowAmount := 0;
            ElecVATDeclXml.AddElement(ParentNode, NodeName, Format(Round(RowAmount, 1), 0, 9), ElecVATDeclXml.GetSkatNamespace4(), RowNode);
        end;
    end;

    local procedure GenerateRowData(VATReportHeaderParam: Record "VAT Report Header") RowData: Dictionary of [Text, Decimal]
    var
        VATStatementReportLine: Record "VAT Statement Report Line";
    begin
        VATStatementReportLine.SetRange("VAT Report No.", VATReportHeaderParam."No.");
        VATStatementReportLine.SetRange("VAT Report Config. Code", VATReportHeaderParam."VAT Report Config. Code");
        if VATStatementReportLine.FindSet() then
            repeat
                if VATStatementReportLine.Amount <> 0 then
                    if RowData.ContainsKey(VATStatementReportLine."Box No.") then
                        RowData.Set(VATStatementReportLine."Box No.", RowData.Get(VATStatementReportLine."Box No.") + VATStatementReportLine.Amount)
                    else
                        RowData.Add(VATStatementReportLine."Box No.", VATStatementReportLine.Amount);
            until VATStatementReportLine.Next() = 0;
    end;

    local procedure CalculateDeclarationTotal(RowData: Dictionary of [Text, Decimal]) Total: Decimal
    var
        RowNo: Text;
    begin
        foreach RowNo in RowData.Keys() do
            Total += GetSignForRowNo(RowNo) * Round(RowData.Get(RowNo), 1);
    end;

    local procedure GetSignForRowNo(RowNo: Text): Decimal
    begin
        // Deductions
        if RowNo in ['2', '6', '8', '9', '10', '13', '15'] then
            exit(-1);
        // Additional info, doesn't affect total
        if RowNo in ['3', '4', '5', '7', '16', '17'] then
            exit(0);
        exit(1);
    end;

    local procedure ConvertRowNoToNodeName(RowNo: Text) NodeName: Text
    begin
        case RowNo of
            '1':
                NodeName := 'MomsAngivelseAfgiftTilsvarBeloeb';
            '2':
                NodeName := 'MomsAngivelseCO2AfgiftBeloeb';
            '3':
                NodeName := 'MomsAngivelseEUKoebBeloeb';
            '4':
                NodeName := 'MomsAngivelseEUSalgBeloebVarerBeloeb';
            '5':
                NodeName := 'MomsAngivelseIkkeEUSalgBeloebVarerBeloeb';
            '6':
                NodeName := 'MomsAngivelseElAfgiftBeloeb';
            '7':
                NodeName := 'MomsAngivelseEksportOmsaetningBeloeb';
            '8':
                NodeName := 'MomsAngivelseGasAfgiftBeloeb';
            '9':
                NodeName := 'MomsAngivelseKoebsMomsBeloeb';
            '10':
                NodeName := 'MomsAngivelseKulAfgiftBeloeb';
            '11':
                NodeName := 'MomsAngivelseMomsEUKoebBeloeb';
            '12':
                NodeName := 'MomsAngivelseMomsEUYdelserBeloeb';
            '13':
                NodeName := 'MomsAngivelseOlieAfgiftBeloeb';
            '14':
                NodeName := 'MomsAngivelseSalgsMomsBeloeb';
            '15':
                NodeName := 'MomsAngivelseVandAfgiftBeloeb';
            '16':
                NodeName := 'MomsAngivelseEUKoebYdelseBeloeb';
            '17':
                NodeName := 'MomsAngivelseEUSalgYdelseBeloeb';
        end;
    end;
}