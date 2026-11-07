// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14.Tests;

using Microsoft.Inventory.Item.Attribute;

xmlport 148958 "BC14 Exp ItemAttribute"
{
    Caption = 'Expected Item Attribute data';
    Direction = Import;
    FieldSeparator = ',';
    RecordSeparator = '<CR><LF>';
    Format = VariableText;
    FormatEvaluate = Xml;

    schema
    {
        textelement(root)
        {
            tableelement(ItemAttribute; "Item Attribute")
            {
                AutoSave = false;
                XmlName = 'ItemAttribute';

                textelement(ID) { }
                textelement(Name) { }
                textelement(Type) { }
                textelement(UnitOfMeasure) { }
                textelement(Blocked) { }

                trigger OnBeforeInsertRecord()
                begin
                    if CaptionRow then begin
                        CaptionRow := false;
                        currXMLport.Skip();
                        exit;
                    end;

                    TempItemAttribute.Init();
                    Evaluate(TempItemAttribute.ID, ID);
                    TempItemAttribute.Name := CopyStr(Name, 1, MaxStrLen(TempItemAttribute.Name));
                    Evaluate(TempItemAttribute.Type, Type);
                    TempItemAttribute."Unit of Measure" := CopyStr(UnitOfMeasure, 1, MaxStrLen(TempItemAttribute."Unit of Measure"));
                    Evaluate(TempItemAttribute.Blocked, Blocked);
                    TempItemAttribute.Insert();

                    currXMLport.Skip();
                end;
            }
        }
    }

    trigger OnPreXmlPort()
    begin
        CaptionRow := true;
        TempItemAttribute.Reset();
        TempItemAttribute.DeleteAll();
    end;

    procedure GetExpectedItemAttributes(var Dest: Record "Item Attribute" temporary)
    begin
        Dest.Reset();
        Dest.DeleteAll();
        if TempItemAttribute.FindSet() then
            repeat
                Dest := TempItemAttribute;
                Dest.Insert();
            until TempItemAttribute.Next() = 0;
    end;

    var
        TempItemAttribute: Record "Item Attribute" temporary;
        CaptionRow: Boolean;
}
