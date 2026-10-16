// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument.Interfactura;

using Microsoft.Sales.History;

pageextension 3374 "Sales Shipment Carta Porte MX" extends "Posted Sales Shipment"
{
    layout
    {
        addlast("ElectronicDocument")
        {
            field("SAT Transport Type"; Rec."SAT Transport Type")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the mode of transport for the Carta Porte complement. Used for international shipments (ViaEntradaSalida in the XML). Valid SAT catalog values: 01=Autotransporte Federal, 02=Transporte Marítimo, 03=Transporte Aéreo, 04=Transporte Ferroviario. Defaults to 01 if left blank.';
            }
            field("SAT ISTMO"; Rec."SAT ISTMO")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies whether the shipment is within the Istmo de Tehuantepec development zone. When enabled (RegistroISTMO=Sí), SAT ISTMO Polo Origen and SAT ISTMO Polo Destino become required.';
            }
            field("SAT ISTMO Polo Origen"; Rec."SAT ISTMO Polo Origen")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the origin pole code within the Istmo de Tehuantepec development zone (UbicacionPoloOrigen). Required when SAT ISTMO is enabled. Use SAT catalog c_RegistroISTMO values.';
            }
            field("SAT ISTMO Polo Destino"; Rec."SAT ISTMO Polo Destino")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the destination pole code within the Istmo de Tehuantepec development zone (UbicacionPoloDestino). Required when SAT ISTMO is enabled. Use SAT catalog c_RegistroISTMO values.';
            }
        }
    }
}
