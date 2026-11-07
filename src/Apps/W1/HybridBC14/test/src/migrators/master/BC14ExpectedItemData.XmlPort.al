// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14.Tests;

using Microsoft.Inventory.Item;

xmlport 148906 "BC14 Expected Item Data"
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
            tableelement(Item; Item)
            {
                AutoSave = false;
                XmlName = 'Item';

                textelement(No) { }
                textelement(Description) { }
                textelement(TypeValue) { }
                textelement(UnitPrice) { }
                textelement(StandardCost) { }
                textelement(UnitCost) { }
                textelement(BlockedValue) { }
                textelement(InventoryPostingGroup) { }
                textelement(GenProdPostingGroup) { }
                textelement(CostingMethod) { }
                textelement(NetWeight) { }
                textelement(UnitVolume) { }

                trigger OnBeforeInsertRecord()
                begin
                    if CaptionRow then begin
                        CaptionRow := false;
                        currXMLport.Skip();
                        exit;
                    end;

                    TempItem.Init();
                    TempItem."No." := CopyStr(No, 1, MaxStrLen(TempItem."No."));
                    TempItem.Description := CopyStr(Description, 1, MaxStrLen(TempItem.Description));
                    Evaluate(TempItem.Type, TypeValue);
                    Evaluate(TempItem."Unit Price", UnitPrice);
                    Evaluate(TempItem."Standard Cost", StandardCost);
                    Evaluate(TempItem."Unit Cost", UnitCost);
                    Evaluate(TempItem.Blocked, BlockedValue);
                    TempItem."Inventory Posting Group" := CopyStr(InventoryPostingGroup, 1, MaxStrLen(TempItem."Inventory Posting Group"));
                    TempItem."Gen. Prod. Posting Group" := CopyStr(GenProdPostingGroup, 1, MaxStrLen(TempItem."Gen. Prod. Posting Group"));
                    Evaluate(TempItem."Costing Method", CostingMethod);
                    Evaluate(TempItem."Net Weight", NetWeight);
                    Evaluate(TempItem."Unit Volume", UnitVolume);
                    TempItem.Insert();

                    currXMLport.Skip();
                end;
            }
        }
    }

    trigger OnPreXmlPort()
    begin
        CaptionRow := true;
        TempItem.Reset();
        TempItem.DeleteAll();
    end;

    procedure GetExpectedItems(var DestTempItem: Record Item temporary)
    begin
        DestTempItem.Reset();
        DestTempItem.DeleteAll();
        if TempItem.FindSet() then
            repeat
                DestTempItem := TempItem;
                DestTempItem.Insert();
            until TempItem.Next() = 0;
    end;

    var
        TempItem: Record Item temporary;
        CaptionRow: Boolean;
}
