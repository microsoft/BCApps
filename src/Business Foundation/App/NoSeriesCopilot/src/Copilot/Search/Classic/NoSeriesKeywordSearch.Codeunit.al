// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.NoSeries;

using System.Reflection;

codeunit 350 "No. Series Keyword Search" implements "No. Series Cop. Field Search"
{
    Access = Internal;
    InherentPermissions = X;
    InherentEntitlements = X;

    procedure Search(Entities: List of [Text]; var TempFieldToSearchIn: Record "Field" temporary; var TempSearchResult: Record "No. Series Cop. Search Result" temporary)
    var
        TextMatchImpl: Codeunit "No. Series Text Match Impl.";
        Nearness: Decimal;
    begin
        if TempFieldToSearchIn.FindSet() then
            repeat
                Nearness := GetBestNearness(TempFieldToSearchIn, Entities);
                if Nearness >= TextMatchImpl.RequiredNearness() then
                    TempSearchResult.AddField(
                        TempFieldToSearchIn.TableNo, TempFieldToSearchIn."No.", Enum::"No. Series Cop. Search Method"::Keyword,
                        Nearness, TempSearchResult.CalcNormalizedSimilarity(Nearness, TextMatchImpl.RequiredNearness(), StrongNearness()));
            until TempFieldToSearchIn.Next() = 0;
    end;

    local procedure GetBestNearness(Field: Record "Field"; Entities: List of [Text]) BestNearness: Decimal
    var
        TextMatchImpl: Codeunit "No. Series Text Match Impl.";
        ToolsImpl: Codeunit "No. Series Cop. Tools Impl.";
        Entity: Text;
        FieldText: Text;
        Nearness: Decimal;
    begin
        FieldText := ToolsImpl.RemoveTextPart(Field.TableName, '& ') + ' ' + Field.FieldName;
        foreach Entity in Entities do begin
            Nearness := TextMatchImpl.GetNearness(FieldText, Entity);
            if Nearness > BestNearness then
                BestNearness := Nearness;
        end;
    end;

    local procedure StrongNearness(): Decimal
    begin
        exit(1);
    end;
}
