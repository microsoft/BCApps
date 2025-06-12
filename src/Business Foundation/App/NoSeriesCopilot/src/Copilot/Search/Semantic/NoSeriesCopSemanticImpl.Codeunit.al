// start of <todo>
// TODO: Refactor the code below when embedding is supported by the platform

// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.NoSeries;
using System.AI;
using System.Utilities;

codeunit 348 "No. Series Cop. Semantic Impl."
{
    Access = Internal;
    InherentPermissions = X;
    InherentEntitlements = X;

    var
        TempNoSeriesSemanticVocabularyBuffer: Record "No. Series Semantic Vocabulary" temporary;

    procedure IsRelevant(FirstString: Text; SecondString: Text): Boolean
    var
        Score: Decimal;
    begin
        Score := Round(CalculateSemanticNearness(FirstString, SecondString), 0.01, '>');
        exit(Score >= RequiredNearness());
    end;

    local procedure CalculateSemanticNearness(FirstString: Text; SecondString: Text): Decimal
    var
        FirstStringVector: List of [Decimal];
        SecondStringVector: List of [Decimal];
    begin
        if (FirstString = '') or (SecondString = '') then
            exit(0);

        FirstStringVector := GetVectorFromText(FirstString);
        SecondStringVector := GetVectorFromText(SecondString);
        exit(CalculateCosineSimilarityFromNormalizedVectors(FirstStringVector, SecondStringVector));
    end;

    local procedure GetVectorFromText(Input: Text): List of [Decimal]
    var
        NoSeriesSemanticVocabulary: Record "No. Series Semantic Vocabulary";
        VectorsArray: JsonArray;
    begin
        Input := PrepareTextForEmbeddings(Input);

        if GetEmbeddingsFromVocabulary(Input, VectorsArray, NoSeriesSemanticVocabulary) then
            exit(ConvertJsonArrayToListOfDecimals(VectorsArray));

        if GetEmbeddingsFromVocabulary(Input, VectorsArray, TempNoSeriesSemanticVocabularyBuffer) then
            exit(ConvertJsonArrayToListOfDecimals(VectorsArray));

        VectorsArray := GetAzureOpenAIEmbeddings(Input);
        // start of <todo>
        // TODO: Remove this if the semantic vocabulary is not required
        SaveEmbeddingsToVocabulary(CopyStr(Input, 1, 2048), VectorsArray, TempNoSeriesSemanticVocabularyBuffer);
        // end of <todo>
        exit(ConvertJsonArrayToListOfDecimals(VectorsArray));
    end;

    // start of <todo>
    // TODO: Remove this procedure if semantic vocabulary is not required
    local procedure GetEmbeddingsFromVocabulary(Input: Text; var EmbeddingsArray: JsonArray; var NoSeriesSemanticVocabulary: Record "No. Series Semantic Vocabulary"): Boolean
    begin
        NoSeriesSemanticVocabulary.SetCurrentKey(Payload);
        NoSeriesSemanticVocabulary.SetLoadFields(Payload);
        NoSeriesSemanticVocabulary.SetRange(Payload, Input);
        if not NoSeriesSemanticVocabulary.FindFirst() then
            exit(false);

        EmbeddingsArray.ReadFrom(NoSeriesSemanticVocabulary.LoadVectorText());
        exit(true);
    end;
    // end of <todo>

    local procedure PrepareTextForEmbeddings(Input: Text): Text
    begin
        exit(Input.ToLower().TrimStart().TrimEnd());
    end;

    // start of <todo>
    // TODO: Remove this procedure if semantic vocabulary is not required
    local procedure SaveEmbeddingsToVocabulary(Input: Text[2048]; EmbeddingsArray: JsonArray; var NoSeriesSemanticVocabulary: Record "No. Series Semantic Vocabulary")
    var
        VectorText: Text;
    begin
        EmbeddingsArray.WriteTo(VectorText);

        NoSeriesSemanticVocabulary.InsertRecord(Input);
        NoSeriesSemanticVocabulary.SaveVectorText(VectorText);
    end;
    // end of <todo>

    // start of <todo>
    // TODO: Remove this procedure if semantic vocabulary is not required
    internal procedure UpdateSemanticVocabulary()
    var
        NoSeriesSemanticVocabulary: Record "No. Series Semantic Vocabulary";
    begin
        TempNoSeriesSemanticVocabularyBuffer.Reset();
        if TempNoSeriesSemanticVocabularyBuffer.FindSet() then
            repeat
                NoSeriesSemanticVocabulary.InsertRecord(TempNoSeriesSemanticVocabularyBuffer.Payload);
                NoSeriesSemanticVocabulary.SaveVectorText(TempNoSeriesSemanticVocabularyBuffer.LoadVectorText());
            until TempNoSeriesSemanticVocabularyBuffer.Next() = 0;
    end;
    // end of <todo>
    local procedure GetAzureOpenAIEmbeddings(Input: Text): JsonArray
    var
        // start of <todo>
        // TODO: Remove this once the semantic search is implemented in production.
        NoSeriesCopilotSetup: Record "No. Series Copilot Setup";
        // end of <todo>
        AzureOpenAI: Codeunit "Azure OpenAI";
        AOAIOperationResponse: Codeunit "AOAI Operation Response";
    // start of <todo>
    // TODO: Uncomment this line when Microsoft Deployment is used or when embedding is supported by the platform
    // AOAIDeployments: Codeunit "AOAI Deployments";
    // end of <todo>
    begin
        if not AzureOpenAI.IsEnabled(Enum::"Copilot Capability"::"No. Series Copilot") then
            exit;

        // start of <todo>
        // TODO: Remove this once the semantic search is implemented in production.
        if NoSeriesCopilotSetup.Get() then
            AzureOpenAI.SetAuthorization(Enum::"AOAI Model Type"::Embeddings, NoSeriesCopilotSetup.GetEndpoint(), NoSeriesCopilotSetup.GetEmbeddingsDeployment(), NoSeriesCopilotSetup.GetSecretKeyFromIsolatedStorage());
        // end of <todo>
        // start of <todo>
        // TODO: Add text-embedding-ada-002 deployment and uncomment this line when Microsoft Deployment is used or when embedding is supported by the platform
        // AzureOpenAI.SetAuthorization(Enum::"AOAI Model Type"::Embeddings, AOAIDeployments.GetEmbeddingAda002()); 
        // end of <todo>
        AzureOpenAI.SetCopilotCapability(Enum::"Copilot Capability"::"No. Series Copilot");
        AzureOpenAI.GenerateEmbeddings(Input, AOAIOperationResponse);

        if AOAIOperationResponse.IsSuccess() then
            exit(GetVectorArray(AOAIOperationResponse.GetResult()))
        else
            Error(AOAIOperationResponse.GetError());
    end;

    // <summary>
    // Calculates the cosine similarity between two vectors.
    // </summary>
    internal procedure CalculateCosineSimilarity(FirstVector: List of [Decimal]; SecondVector: List of [Decimal]): Decimal
    var
        Math: Codeunit Math;
        DotProduct: Decimal;
        MagnitudeFirstVector: Decimal;
        MagnitudeSecondVector: Decimal;
        i: Integer;
    begin
        DotProduct := 0;
        MagnitudeFirstVector := 0;
        MagnitudeSecondVector := 0;

        for i := 1 to FirstVector.Count() do begin
            DotProduct += FirstVector.Get(i) * SecondVector.Get(i);
            MagnitudeFirstVector += Math.Pow(FirstVector.Get(i), 2);
            MagnitudeSecondVector += Math.Pow(SecondVector.Get(i), 2);
        end;

        MagnitudeFirstVector := Math.Sqrt(MagnitudeFirstVector);
        MagnitudeSecondVector := Math.Sqrt(MagnitudeSecondVector);

        if (MagnitudeFirstVector = 0) or (MagnitudeSecondVector = 0) then
            exit(0);

        exit(DotProduct / (MagnitudeFirstVector * MagnitudeSecondVector));
    end;

    // <summary>
    // Calculates the cosine similarity between two normalized vectors.
    // </summary>
    internal procedure CalculateCosineSimilarityFromNormalizedVectors(FirstVector: List of [Decimal]; SecondVector: List of [Decimal]): Decimal
    var
        DotProduct: Decimal;
        i: Integer;
    begin
        DotProduct := 0;

        for i := 1 to FirstVector.Count() do
            DotProduct += FirstVector.Get(i) * SecondVector.Get(i);

        exit(DotProduct);
    end;

    local procedure GetVectorArray(Response: Text): JsonArray
    var
        Vector: JsonObject;
        Tok: JsonToken;
    begin
        Vector.ReadFrom(Response);
        Vector.Get('vector', Tok);
        exit(Tok.AsArray());
    end;

    local procedure ConvertJsonArrayToListOfDecimals(EmbeddingArray: JsonArray) Result: List of [Decimal]
    var
        i: Integer;
        EmbeddingValue: JsonToken;
    begin
        for i := 0 to EmbeddingArray.Count() - 1 do begin
            EmbeddingArray.Get(i, EmbeddingValue);
            Result.Add(EmbeddingValue.AsValue().AsDecimal());
        end;
    end;

    local procedure RequiredNearness(): Decimal
    begin
        exit(0.8)
    end;

}

// end of <todo>