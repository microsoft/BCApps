// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument.Interfactura;

using Microsoft.eServices.EDocument;

page 3358 "E-Doc. CFDI Data MX"
{
    Caption = 'CFDI Data';
    PageType = Card;
    SourceTable = "E-Document";
    InsertAllowed = false;
    DeleteAllowed = false;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';
                Editable = PageEditable;

                field("CFDI Export Code"; Rec."CFDI Export Code")
                {
                    ToolTip = 'Specifies the SAT export code (Exportacion) sent in the CFDI.';
                }
                field("CFDI Exchange Rate USD"; Rec."CFDI Exchange Rate USD")
                {
                    ToolTip = 'Specifies the USD exchange rate (TipoCambioUSD) sent in the foreign trade complement.';
                }
                field("CFDI Foreign Trade"; Rec."CFDI Foreign Trade")
                {
                    ToolTip = 'Specifies whether the CFDI includes the foreign trade complement (Comercio Exterior).';
                }
                field("CFDI SAT Address ID"; Rec."CFDI SAT Address ID")
                {
                    Visible = SATAddressVisible;
                    ToolTip = 'Specifies the SAT address of the receiver used in the foreign trade complement.';
                }
                field("CFDI Intl. Trade Term"; Rec."CFDI Intl. Trade Term")
                {
                    ToolTip = 'Specifies the international trade term (Incoterm) sent in the foreign trade complement.';
                }
                field("CFDI Cert. of Origin No."; Rec."CFDI Cert. of Origin No.")
                {
                    Visible = CertificateOfOriginVisible;
                    ToolTip = 'Specifies the certificate of origin number (NumCertificadoOrigen) sent in the foreign trade complement.';
                }
                field("CFDI Transport Type"; Rec."CFDI Transport Type")
                {
                    Visible = CartaPorteVisible;
                    ToolTip = 'Specifies the mode of transport for the Carta Porte complement (ViaEntradaSalida). Defaults to 01 if left blank.';
                }
                field(TransportOperators; TransportOperatorCount)
                {
                    Visible = CartaPorteVisible;
                    Caption = 'Transport Operators';
                    Editable = false;
                    ToolTip = 'Specifies the operators of the vehicle that transports the goods.';

                    trigger OnDrillDown()
                    begin
                        EDocCFDIDataMX.OpenTransportOperators(Rec);
                        TransportOperatorCount := EDocCFDIDataMX.CountTransportOperators(Rec);
                    end;
                }
                field("CFDI Transit-from Date/Time"; Rec."CFDI Transit-from Date/Time")
                {
                    Visible = CartaPorteVisible;
                    ToolTip = 'Specifies when the goods leave the origin location.';
                }
                field("CFDI Transit Hours"; Rec."CFDI Transit Hours")
                {
                    Visible = CartaPorteVisible;
                    ToolTip = 'Specifies the estimated transit time in hours.';
                }
                field("CFDI Transit Distance"; Rec."CFDI Transit Distance")
                {
                    Visible = CartaPorteVisible;
                    ToolTip = 'Specifies the distance traveled in kilometers.';
                }
                field("CFDI Vehicle Code"; Rec."CFDI Vehicle Code")
                {
                    Visible = CartaPorteVisible;
                    ToolTip = 'Specifies the vehicle that transports the goods.';
                }
                field("CFDI Trailer 1"; Rec."CFDI Trailer 1")
                {
                    Visible = CartaPorteVisible;
                    ToolTip = 'Specifies the first trailer used to transport the goods.';
                }
                field("CFDI Trailer 2"; Rec."CFDI Trailer 2")
                {
                    Visible = CartaPorteVisible;
                    ToolTip = 'Specifies the second trailer used to transport the goods.';
                }
                field("CFDI Customs Regime"; Rec."CFDI Customs Regime")
                {
                    Visible = CartaPorteVisible;
                    ToolTip = 'Specifies the SAT customs regime (RegimenAduanero) for foreign trade shipments.';
                }
                field("CFDI Transfer Reason"; Rec."CFDI Transfer Reason")
                {
                    Visible = CartaPorteVisible;
                    ToolTip = 'Specifies the SAT transfer reason (MotivoTraslado) for foreign trade shipments.';
                }
                field("CFDI SAT ISTMO"; Rec."CFDI SAT ISTMO")
                {
                    Visible = CartaPorteVisible;
                    ToolTip = 'Specifies whether the shipment is within the Istmo de Tehuantepec development zone (RegistroISTMO).';
                }
                field("CFDI ISTMO Polo Origen"; Rec."CFDI ISTMO Polo Origen")
                {
                    Visible = CartaPorteVisible;
                    ToolTip = 'Specifies the origin pole within the Istmo de Tehuantepec development zone (UbicacionPoloOrigen).';
                }
                field("CFDI ISTMO Polo Destino"; Rec."CFDI ISTMO Polo Destino")
                {
                    Visible = CartaPorteVisible;
                    ToolTip = 'Specifies the destination pole within the Istmo de Tehuantepec development zone (UbicacionPoloDestino).';
                }
                field("CFDI Insurer Name"; Rec."CFDI Insurer Name")
                {
                    Visible = CartaPorteVisible;
                    ToolTip = 'Specifies the insurer that covers the civil liability of the vehicle.';
                }
                field("CFDI Insurer Policy Number"; Rec."CFDI Insurer Policy Number")
                {
                    Visible = CartaPorteVisible;
                    ToolTip = 'Specifies the civil liability insurance policy number.';
                }
                field("CFDI Medical Insurer Name"; Rec."CFDI Medical Insurer Name")
                {
                    Visible = CartaPorteVisible;
                    ToolTip = 'Specifies the insurer that covers environmental damage for hazardous materials.';
                }
                field("CFDI Medical Ins. Policy No."; Rec."CFDI Medical Ins. Policy No.")
                {
                    Visible = CartaPorteVisible;
                    ToolTip = 'Specifies the environmental damage insurance policy number.';
                }
                field("CFDI Weight Unit Of Measure"; Rec."CFDI Weight Unit Of Measure")
                {
                    Visible = CartaPorteVisible;
                    ToolTip = 'Specifies the SAT unit of measure for the gross weight (UnidadPeso).';
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        EDocument: Record "E-Document";
    begin
        EDocument.CopyFilters(Rec);
        if EDocument.FindFirst() then
            EDocCFDIDataMX.GetFieldVisibility(EDocument, CartaPorteVisible, SATAddressVisible, CertificateOfOriginVisible);
    end;

    trigger OnAfterGetRecord()
    begin
        PageEditable := EDocCFDIDataMX.IsEditable(Rec);
        TransportOperatorCount := EDocCFDIDataMX.CountTransportOperators(Rec);
    end;

    var
        EDocCFDIDataMX: Codeunit "EDoc CFDI Data MX";
        TransportOperatorCount: Integer;
        PageEditable: Boolean;
        CartaPorteVisible: Boolean;
        SATAddressVisible: Boolean;
        CertificateOfOriginVisible: Boolean;
}
