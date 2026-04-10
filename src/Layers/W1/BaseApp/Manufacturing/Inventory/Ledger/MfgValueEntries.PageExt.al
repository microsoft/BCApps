// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Ledger;

using Microsoft.Manufacturing.Document;

pageextension 99000788 "Mfg. Value Entries" extends "Value Entries"
{
    DataCaptionExpression = GetMfgCaption();

    local procedure GetMfgCaption(): Text
    var
        ObjTransl: Record System.Globalization."Object Translation";
        ProdOrder: Record "Production Order";
        SourceTableName: Text;
        SourceFilter: Text;
        SourceDescription: Text;
    begin
        SourceDescription := '';

        case true of
            (Rec.GetFilter("Order No.") <> '') and (Rec."Order Type" = Rec."Order Type"::Production):
                begin
                    SourceTableName := ObjTransl.TranslateObject(ObjTransl."Object Type"::Table, 5405);
                    SourceFilter := Rec.GetFilter("Order No.");
                    if MaxStrLen(ProdOrder."No.") >= StrLen(SourceFilter) then
                        if ProdOrder.Get(ProdOrder.Status::Released, SourceFilter) or
                           ProdOrder.Get(ProdOrder.Status::Finished, SourceFilter)
                        then begin
                            SourceTableName := StrSubstNo('%1 %2', ProdOrder.Status, SourceTableName);
                            SourceDescription := ProdOrder.Description;
                        end;
                end;
        end;

        exit(StrSubstNo('%1 %2 %3', SourceTableName, SourceFilter, SourceDescription));
    end;
}