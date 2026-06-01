// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;

/// <summary>
/// Codeunit Shpfy GraphQL Queries (ID 30154).
/// </summary>
codeunit 30154 "Shpfy GraphQL Queries"
{
    Access = Internal;
    SingleInstance = true;

    internal procedure GetQuery(GraphQLType: enum "Shpfy GraphQL Type"; Parameters: Dictionary of [Text, Text]) Result: Text
    var
        ExpectedCost: Integer;
    begin
        exit(GetQuery(GraphQLType, Parameters, ExpectedCost));
    end;

    internal procedure GetQuery(GraphQLType: enum "Shpfy GraphQL Type"; Parameters: Dictionary of [Text, Text]; var ExpectedCost: Integer) GraphQL: Text
    var
        Param: Text;
    begin
        GraphQL := GetQueryWithCost(GraphQLType, ExpectedCost);

        if (GraphQL <> '') and (Parameters.Count > 0) then
            foreach Param in Parameters.Keys do
                GraphQL := GraphQL.Replace('{{' + Param + '}}', Parameters.Get(Param));
    end;

    internal procedure GetQueryWithCost(GraphQLType: enum "Shpfy GraphQL Type"; var ExpectedCost: Integer) GraphQL: Text
    var
        ResourceText: Text;
        CostText: Text;
        EnumName: Text;
        AreaName: Text;
        QueryName: Text;
        SepPos: Integer;
        JsonStart: Integer;
        EnumIndex: Integer;
        ResourcePathLbl: Label 'graphql/%1/%2.graphql', Locked = true;
        CostPrefixTok: Label '# cost: ', Locked = true;
    begin
        EnumIndex := GraphQLType.Ordinals().IndexOf(GraphQLType.AsInteger());
        EnumName := GraphQLType.Names().Get(EnumIndex);
        SepPos := EnumName.IndexOf('_');
        AreaName := EnumName.Substring(1, SepPos - 1);
        QueryName := EnumName.Substring(SepPos + 1);
        ResourceText := NavApp.GetResourceAsText(StrSubstNo(ResourcePathLbl, AreaName, QueryName));

        // Parse cost: skip "# cost: " prefix, read until the JSON body starts
        JsonStart := ResourceText.IndexOf('{');
        CostText := ResourceText.Substring(StrLen(CostPrefixTok) + 1, JsonStart - StrLen(CostPrefixTok) - 1).Trim();
        Evaluate(ExpectedCost, CostText);

        GraphQL := ResourceText.Substring(JsonStart);
    end;
}
