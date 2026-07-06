// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14.Tests;

using Microsoft.Inventory.BOM;

xmlport 148916 "BC14 Exp BOM Component Data"
{
    Direction = Import;
    FieldSeparator = ',';
    RecordSeparator = '<CR><LF>';
    Format = VariableText;
    FormatEvaluate = Xml;

    schema
    {
        textelement(root)
        {
            tableelement(BOMComponent; "BOM Component")
            {
                AutoSave = false;
                XmlName = 'BOMComponent';

                textelement(ParentItemNo) { }
                textelement(LineNo) { }
                textelement(TypeValue) { }
                textelement(No) { }
                textelement(Description) { }
                textelement(UoMCode) { }
                textelement(QtyPer) { }

                trigger OnBeforeInsertRecord()
                begin
                    if CaptionRow then begin
                        CaptionRow := false;
                        currXMLport.Skip();
                        exit;
                    end;

                    TempBOMComponent.Init();
                    TempBOMComponent."Parent Item No." := CopyStr(ParentItemNo, 1, MaxStrLen(TempBOMComponent."Parent Item No."));
                    Evaluate(TempBOMComponent."Line No.", LineNo);
                    Evaluate(TempBOMComponent.Type, TypeValue);
                    TempBOMComponent."No." := CopyStr(No, 1, MaxStrLen(TempBOMComponent."No."));
                    TempBOMComponent.Description := CopyStr(Description, 1, MaxStrLen(TempBOMComponent.Description));
                    TempBOMComponent."Unit of Measure Code" := CopyStr(UoMCode, 1, MaxStrLen(TempBOMComponent."Unit of Measure Code"));
                    Evaluate(TempBOMComponent."Quantity per", QtyPer);
                    TempBOMComponent.Insert();

                    currXMLport.Skip();
                end;
            }
        }
    }

    trigger OnPreXmlPort()
    begin
        CaptionRow := true;
        TempBOMComponent.Reset();
        TempBOMComponent.DeleteAll();
    end;

    procedure GetExpectedBOMComponents(var DestTemp: Record "BOM Component" temporary)
    begin
        DestTemp.Reset();
        DestTemp.DeleteAll();
        if TempBOMComponent.FindSet() then
            repeat
                DestTemp := TempBOMComponent;
                DestTemp.Insert();
            until TempBOMComponent.Next() = 0;
    end;

    var
        TempBOMComponent: Record "BOM Component" temporary;
        CaptionRow: Boolean;
}
