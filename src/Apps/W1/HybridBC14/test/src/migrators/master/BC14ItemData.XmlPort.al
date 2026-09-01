// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14.Tests;

using Microsoft.DataMigration.BC14Reimplementation;

xmlport 148905 "BC14 Item Data"
{
    Direction = Both;
    FieldSeparator = ',';
    RecordSeparator = '<CR><LF>';
    Format = VariableText;
    FormatEvaluate = Xml;

    schema
    {
        textelement(root)
        {
            tableelement(BC14Item; "BC14 Item")
            {
                AutoSave = false;
                XmlName = 'BC14Item';

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
                var
                    NewBC14Item: Record "BC14 Item";
                begin
                    if CaptionRow then begin
                        CaptionRow := false;
                        currXMLport.Skip();
                        exit;
                    end;

                    NewBC14Item.Init();
                    NewBC14Item."No." := CopyStr(No, 1, MaxStrLen(NewBC14Item."No."));
                    NewBC14Item.Description := CopyStr(Description, 1, MaxStrLen(NewBC14Item.Description));
                    Evaluate(NewBC14Item.Type, TypeValue);
                    Evaluate(NewBC14Item."Unit Price", UnitPrice);
                    Evaluate(NewBC14Item."Standard Cost", StandardCost);
                    Evaluate(NewBC14Item."Unit Cost", UnitCost);
                    Evaluate(NewBC14Item.Blocked, BlockedValue);
                    NewBC14Item."Inventory Posting Group" := CopyStr(InventoryPostingGroup, 1, MaxStrLen(NewBC14Item."Inventory Posting Group"));
                    NewBC14Item."Gen. Prod. Posting Group" := CopyStr(GenProdPostingGroup, 1, MaxStrLen(NewBC14Item."Gen. Prod. Posting Group"));
                    Evaluate(NewBC14Item."Costing Method", CostingMethod);
                    Evaluate(NewBC14Item."Net Weight", NetWeight);
                    Evaluate(NewBC14Item."Unit Volume", UnitVolume);
                    NewBC14Item.Insert();

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
