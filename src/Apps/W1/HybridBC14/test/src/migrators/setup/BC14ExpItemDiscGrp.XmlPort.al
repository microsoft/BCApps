// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14.Tests;

using Microsoft.Inventory.Item;

xmlport 148946 "BC14 Exp ItemDiscGrp"
{
    Caption = 'Expected Item Discount Group data';
    Direction = Import;
    FieldSeparator = ',';
    RecordSeparator = '<CR><LF>';
    Format = VariableText;
    FormatEvaluate = Xml;

    schema
    {
        textelement(root)
        {
            tableelement(ItemDiscountGroup; "Item Discount Group")
            {
                AutoSave = false;
                XmlName = 'ItemDiscountGroup';

                textelement(Code) { }
                textelement(Description) { }

                trigger OnBeforeInsertRecord()
                begin
                    if CaptionRow then begin
                        CaptionRow := false;
                        currXMLport.Skip();
                        exit;
                    end;

                    TempItemDiscountGroup.Init();
                    TempItemDiscountGroup.Code := CopyStr(Code, 1, MaxStrLen(TempItemDiscountGroup.Code));
                    TempItemDiscountGroup.Description := CopyStr(Description, 1, MaxStrLen(TempItemDiscountGroup.Description));
                    TempItemDiscountGroup.Insert();

                    currXMLport.Skip();
                end;
            }
        }
    }

    trigger OnPreXmlPort()
    begin
        CaptionRow := true;
        TempItemDiscountGroup.Reset();
        TempItemDiscountGroup.DeleteAll();
    end;

    procedure GetExpectedItemDiscountGroups(var Dest: Record "Item Discount Group" temporary)
    begin
        Dest.Reset();
        Dest.DeleteAll();
        if TempItemDiscountGroup.FindSet() then
            repeat
                Dest := TempItemDiscountGroup;
                Dest.Insert();
            until TempItemDiscountGroup.Next() = 0;
    end;

    var
        TempItemDiscountGroup: Record "Item Discount Group" temporary;
        CaptionRow: Boolean;
}
