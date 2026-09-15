// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14.Tests;

using Microsoft.Foundation.Shipping;

xmlport 148970 "BC14 Exp Shipment Method"
{
    Caption = 'Expected Shipment Method data for BC14 migration tests';
    Direction = Import;
    FieldSeparator = ',';
    RecordSeparator = '<CR><LF>';
    Format = VariableText;
    FormatEvaluate = Xml;

    schema
    {
        textelement(root)
        {
            tableelement(ShipmentMethod; "Shipment Method")
            {
                AutoSave = false;
                XmlName = 'ShipmentMethod';

                textelement(Code) { }
                textelement(Description) { }

                trigger OnBeforeInsertRecord()
                begin
                    if CaptionRow then begin
                        CaptionRow := false;
                        currXMLport.Skip();
                        exit;
                    end;

                    TempShipmentMethod.Init();
                    TempShipmentMethod.Code := CopyStr(Code, 1, MaxStrLen(TempShipmentMethod.Code));
                    TempShipmentMethod.Description := CopyStr(Description, 1, MaxStrLen(TempShipmentMethod.Description));
                    TempShipmentMethod.Insert();

                    currXMLport.Skip();
                end;
            }
        }
    }

    trigger OnPreXmlPort()
    begin
        CaptionRow := true;
        TempShipmentMethod.Reset();
        TempShipmentMethod.DeleteAll();
    end;

    procedure GetExpectedShipmentMethods(var DestTempShipmentMethod: Record "Shipment Method" temporary)
    begin
        DestTempShipmentMethod.Reset();
        DestTempShipmentMethod.DeleteAll();
        if TempShipmentMethod.FindSet() then
            repeat
                DestTempShipmentMethod := TempShipmentMethod;
                DestTempShipmentMethod.Insert();
            until TempShipmentMethod.Next() = 0;
    end;

    var
        TempShipmentMethod: Record "Shipment Method" temporary;
        CaptionRow: Boolean;
}
