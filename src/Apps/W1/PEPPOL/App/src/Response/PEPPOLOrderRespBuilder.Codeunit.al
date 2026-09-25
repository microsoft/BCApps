// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Peppol.Response;

using System.Utilities;

/// <summary>
/// Builds a minimal, well-formed PEPPOL BIS 28 Order Response (code AB = Acknowledged)
/// for an inbound Sales Order that was read into draft.
/// </summary>
codeunit 37209 "PEPPOL Order Resp. Builder"
{
    Access = Public;
    InherentEntitlements = X;
    InherentPermissions = X;

    /// <summary>
    /// Generates a minimal UBL OrderResponse XML blob using primitive parameters.
    /// Writes the result into TempBlob.
    /// </summary>
    /// <param name="ResponseCode">The UNCL4343 OrderResponseCode used on the wire (e.g. AB = Acknowledged, AC = Accepted, RE = Rejected).</param>
    procedure Build(EDocEntryNo: Integer; BuyerOrderNo: Code[20]; SellerName: Text[100]; BuyerName: Text[100]; ResponseCode: Code[10]; var TempBlob: Codeunit "Temp Blob")
    var
        XmlDoc: XmlDocument;
        RootNode: XmlElement;
        OutStr: OutStream;
    begin
        XmlDoc := XmlDocument.Create();
        XmlDoc.SetDeclaration(XmlDeclaration.Create('1.0', 'UTF-8', 'no'));

        RootNode := BuildOrderResponse(EDocEntryNo, BuyerOrderNo, SellerName, BuyerName, ResponseCode);
        XmlDoc.Add(RootNode);

        TempBlob.CreateOutStream(OutStr, TextEncoding::UTF8);
        XmlDoc.WriteTo(OutStr);
    end;

    local procedure BuildOrderResponse(EDocEntryNo: Integer; BuyerOrderNo: Code[20]; SellerName: Text[100]; BuyerName: Text[100]; ResponseCode: Code[10]) RootNode: XmlElement
    var
        OrderRefId: Text;
    begin
        RootNode := XmlElement.Create('OrderResponse', 'urn:oasis:names:specification:ubl:schema:xsd:OrderResponse-2');
        RootNode.Add(XmlAttribute.CreateNamespaceDeclaration('cac', 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2'));
        RootNode.Add(XmlAttribute.CreateNamespaceDeclaration('cbc', 'urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2'));

        // BIS 28 customization / profile
        RootNode.Add(XmlElement.Create('CustomizationID', 'urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2',
            'urn:fdc:peppol.eu:poacc:trns:order_response:3'));
        RootNode.Add(XmlElement.Create('ProfileID', 'urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2',
            'urn:fdc:peppol.eu:poacc:bis:order_only:3'));

        RootNode.Add(XmlElement.Create('ID', 'urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2',
            Format(EDocEntryNo)));
        RootNode.Add(XmlElement.Create('IssueDate', 'urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2',
            Format(Today(), 0, '<Year4>-<Month,2>-<Day,2>')));

        RootNode.Add(XmlElement.Create('OrderResponseCode', 'urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2', ResponseCode));

        // OrderReference
        OrderRefId := BuyerOrderNo;
        if OrderRefId = '' then
            OrderRefId := Format(EDocEntryNo);
        RootNode.Add(BuildOrderReference(OrderRefId));

        // SellerSupplierParty
        RootNode.Add(BuildParty('SellerSupplierParty', SellerName));

        // BuyerCustomerParty
        RootNode.Add(BuildParty('BuyerCustomerParty', BuyerName));
    end;

    local procedure BuildOrderReference(OrderId: Text) Node: XmlElement
    var
        IdNode: XmlElement;
    begin
        Node := XmlElement.Create('OrderReference', 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2');
        IdNode := XmlElement.Create('ID', 'urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2', OrderId);
        Node.Add(IdNode);
    end;

    local procedure BuildParty(PartyRoleName: Text; PartyName: Text) RoleNode: XmlElement
    var
        PartyNode: XmlElement;
        PartyNameNode: XmlElement;
        NameNode: XmlElement;
    begin
        RoleNode := XmlElement.Create(PartyRoleName, 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2');

        PartyNode := XmlElement.Create('Party', 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2');
        PartyNameNode := XmlElement.Create('PartyName', 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2');
        NameNode := XmlElement.Create('Name', 'urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2', PartyName);

        PartyNameNode.Add(NameNode);
        PartyNode.Add(PartyNameNode);
        RoleNode.Add(PartyNode);
    end;
}
