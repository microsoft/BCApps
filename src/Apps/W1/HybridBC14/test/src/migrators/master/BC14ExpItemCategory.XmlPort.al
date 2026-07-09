// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14.Tests;

using Microsoft.Inventory.Item;

xmlport 148948 "BC14 Exp ItemCategory"
{
    Caption = 'Expected Item Category data';
    Direction = Import;
    FieldSeparator = ',';
    RecordSeparator = '<CR><LF>';
    Format = VariableText;
    FormatEvaluate = Xml;

    schema
    {
        textelement(root)
        {
            tableelement(ItemCategory; "Item Category")
            {
                AutoSave = false;
                XmlName = 'ItemCategory';

                textelement(Code) { }
                textelement(Description) { }
                textelement(ParentCategory) { }
                textelement(PresentationOrder) { }
                textelement(Indentation) { }

                trigger OnBeforeInsertRecord()
                begin
                    if CaptionRow then begin
                        CaptionRow := false;
                        currXMLport.Skip();
                        exit;
                    end;

                    TempItemCategory.Init();
                    TempItemCategory.Code := CopyStr(Code, 1, MaxStrLen(TempItemCategory.Code));
                    TempItemCategory.Description := CopyStr(Description, 1, MaxStrLen(TempItemCategory.Description));
                    TempItemCategory."Parent Category" := CopyStr(ParentCategory, 1, MaxStrLen(TempItemCategory."Parent Category"));
                    Evaluate(TempItemCategory."Presentation Order", PresentationOrder);
                    Evaluate(TempItemCategory.Indentation, Indentation);
                    TempItemCategory.Insert();

                    currXMLport.Skip();
                end;
            }
        }
    }

    trigger OnPreXmlPort()
    begin
        CaptionRow := true;
        TempItemCategory.Reset();
        TempItemCategory.DeleteAll();
    end;

    procedure GetExpectedItemCategories(var Dest: Record "Item Category" temporary)
    begin
        Dest.Reset();
        Dest.DeleteAll();
        if TempItemCategory.FindSet() then
            repeat
                Dest := TempItemCategory;
                Dest.Insert();
            until TempItemCategory.Next() = 0;
    end;

    var
        TempItemCategory: Record "Item Category" temporary;
        CaptionRow: Boolean;
}
