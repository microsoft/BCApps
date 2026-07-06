// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14.Tests;

using Microsoft.DataMigration.BC14Reimplementation;

xmlport 148969 "BC14 Shipment Method Data"
{
    Caption = 'BC14 Shipment Method buffer data';
    Direction = Both;
    FieldSeparator = ',';
    RecordSeparator = '<CR><LF>';
    Format = VariableText;
    FormatEvaluate = Xml;

    schema
    {
        textelement(root)
        {
            tableelement(BC14ShipmentMethod; "BC14 Shipment Method")
            {
                AutoSave = false;
                XmlName = 'BC14ShipmentMethod';

                textelement(Code) { }
                textelement(Description) { }

                trigger OnBeforeInsertRecord()
                var
                    NewBC14ShipmentMethod: Record "BC14 Shipment Method";
                begin
                    if CaptionRow then begin
                        CaptionRow := false;
                        currXMLport.Skip();
                        exit;
                    end;

                    NewBC14ShipmentMethod.Init();
                    NewBC14ShipmentMethod.Code := CopyStr(Code, 1, MaxStrLen(NewBC14ShipmentMethod.Code));
                    NewBC14ShipmentMethod.Description := CopyStr(Description, 1, MaxStrLen(NewBC14ShipmentMethod.Description));
                    NewBC14ShipmentMethod.Insert();

                    currXMLport.Skip();
                end;
            }
        }
    }

    trigger OnPreXmlPort()
    begin
        CaptionRow := true;
    end;

    var
        CaptionRow: Boolean;
}
