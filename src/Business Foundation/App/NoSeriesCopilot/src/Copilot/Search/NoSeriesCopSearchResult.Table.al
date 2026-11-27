// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.NoSeries;

table 393 "No. Series Cop. Search Result"
{
    Access = Internal;
    TableType = Temporary;
    InherentEntitlements = X;
    InherentPermissions = X;

    fields
    {
        field(1; "Table No."; Integer)
        {
            Caption = 'Table No.';
        }
        field(2; "Field No."; Integer)
        {
            Caption = 'Field No.';
        }
        field(3; "Search Method"; Enum "No. Series Cop. Search Method")
        {
            Caption = 'Search Method';
        }
        field(4; "Original Similarity"; Decimal)
        {
            Caption = 'Original Similarity';
            AutoFormatType = 0;
            DecimalPlaces = 0 : 5;
        }
        field(5; "Normalized Similarity"; Decimal)
        {
            Caption = 'Normalized Similarity';
            AutoFormatType = 0;
            DecimalPlaces = 0 : 5;
        }
    }

    keys
    {
        key(PK; "Table No.", "Field No.")
        {
            Clustered = true;
        }
        key(Similarity; "Normalized Similarity")
        {
        }
    }

    /// <summary>
    /// Calculates the similarity of a search method rescaled to 0..1 between fixed bounds: LowerBound becomes 0, UpperBound and above become 1.
    /// </summary>
    procedure CalcNormalizedSimilarity(OriginalSimilarity: Decimal; LowerBound: Decimal; UpperBound: Decimal): Decimal
    begin
        if OriginalSimilarity <= LowerBound then
            exit(0);
        if OriginalSimilarity >= UpperBound then
            exit(1);
        exit((OriginalSimilarity - LowerBound) / (UpperBound - LowerBound));
    end;

    /// <summary>
    /// Adds the fields of another search result. A field found more than once keeps the method that found it with the highest similarity.
    /// </summary>
    /// <param name="TempSearchResultToAdd">The search result whose fields are added.</param>
    procedure AddFields(var TempSearchResultToAdd: Record "No. Series Cop. Search Result" temporary)
    begin
        if TempSearchResultToAdd.FindSet() then
            repeat
                AddField(
                    TempSearchResultToAdd."Table No.", TempSearchResultToAdd."Field No.", TempSearchResultToAdd."Search Method",
                    TempSearchResultToAdd."Original Similarity", TempSearchResultToAdd."Normalized Similarity");
            until TempSearchResultToAdd.Next() = 0;
    end;

    /// <summary>
    /// Adds a field found by a search method. A field found more than once keeps the method that found it with the highest similarity.
    /// </summary>
    /// <param name="OriginalSimilarity">The similarity as returned by the search method: nearness for keyword search, cosine similarity for semantic search.</param>
    /// <param name="NormalizedSimilarity">The similarity from CalcNormalizedSimilarity, comparable across search methods.</param>
    procedure AddField(TableNo: Integer; FieldNo: Integer; SearchMethod: Enum "No. Series Cop. Search Method"; OriginalSimilarity: Decimal; NormalizedSimilarity: Decimal)
    begin
        if Rec.Get(TableNo, FieldNo) then
            UpdateIfHigherSimilarity(SearchMethod, OriginalSimilarity, NormalizedSimilarity)
        else
            InsertField(TableNo, FieldNo, SearchMethod, OriginalSimilarity, NormalizedSimilarity);
    end;

    /// <summary>
    /// Keeps only the fields close to the best match: fields whose normalized similarity is more than MaxDistanceFromBest below the highest normalized similarity are removed.
    /// </summary>
    /// <param name="MaxDistanceFromBest">How far below the highest normalized similarity a field may be and still be kept.</param>
    procedure KeepBestMatches(MaxDistanceFromBest: Decimal)
    begin
        RemoveFieldsBelow(GetBestSimilarity() - MaxDistanceFromBest);
    end;

    local procedure GetBestSimilarity() BestSimilarity: Decimal
    begin
        Rec.SetCurrentKey("Normalized Similarity");
        if Rec.FindLast() then
            BestSimilarity := Rec."Normalized Similarity";
        Rec.SetCurrentKey("Table No.", "Field No.");
    end;

    local procedure RemoveFieldsBelow(MinSimilarity: Decimal)
    begin
        Rec.SetFilter("Normalized Similarity", '<%1', MinSimilarity);
        Rec.DeleteAll();
        Rec.SetRange("Normalized Similarity");
    end;

    local procedure UpdateIfHigherSimilarity(SearchMethod: Enum "No. Series Cop. Search Method"; OriginalSimilarity: Decimal; NormalizedSimilarity: Decimal)
    begin
        if NormalizedSimilarity <= Rec."Normalized Similarity" then
            exit;

        Rec."Search Method" := SearchMethod;
        Rec."Original Similarity" := OriginalSimilarity;
        Rec."Normalized Similarity" := NormalizedSimilarity;
        Rec.Modify();
    end;

    local procedure InsertField(TableNo: Integer; FieldNo: Integer; SearchMethod: Enum "No. Series Cop. Search Method"; OriginalSimilarity: Decimal; NormalizedSimilarity: Decimal)
    begin
        Rec.Init();
        Rec."Table No." := TableNo;
        Rec."Field No." := FieldNo;
        Rec."Search Method" := SearchMethod;
        Rec."Original Similarity" := OriginalSimilarity;
        Rec."Normalized Similarity" := NormalizedSimilarity;
        Rec.Insert();
    end;
}
