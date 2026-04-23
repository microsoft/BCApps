// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.TestLibraries.RedTeamScan;

codeunit 135606 "Red Team Scan Impl."
{
    Access = Internal;

    var
        RedTeamPathTxt: Label '/redteam', Locked = true;
        DefaultRedTeamUriTxt: Label 'http://localhost:8000', Locked = true;
        PeekPathTxt: Label '%1/%2/queries/peek', Locked = true;
        GetQueryPathTxt: Label '%1/%2/queries', Locked = true;
        ResponsesPathTxt: Label '%1/%2/responses', Locked = true;
        ResultsPathTxt: Label '%1/%2/results', Locked = true;
        StartScanErr: Label 'Failed to start red team scan: %1', Comment = '%1 = reason';
        GetQueryErr: Label 'Failed to get red team query: %1', Comment = '%1 = reason';
        ResponseSendErr: Label 'Failed to send response to red team query: %1', Comment = '%1 = reason';
        GetResultsErr: Label 'Failed to get red team results: %1', Comment = '%1 = reason';
        BaseRedTeamUri: Text;
        ScanId: Text;
        AttackNumber: Integer;
        ConversationTurnNumber: Integer;
        ScanCompleted: Boolean;

    procedure Start(var Config: Codeunit "Red Team Scan Config")
    var
        RedTeamHttpClient: HttpClient;
        HttpRequestMessage: HttpRequestMessage;
        HttpResponseMessage: HttpResponseMessage;
        HttpHeaders: HttpHeaders;
        RequestJson: JsonObject;
        RiskCategoriesArray: JsonArray;
        AttackStrategiesArray: JsonArray;
        SeedPrompts: JsonArray;
        RequestText: Text;
        ResponseJson: JsonObject;
        ResponseText: Text;
        JsonToken: JsonToken;
        RiskCategory: Text;
    begin
        BaseRedTeamUri := Config.GetBaseUri();

        HttpRequestMessage.Method('POST');
        HttpRequestMessage.SetRequestUri(GetBaseRedTeamUri());

        foreach RiskCategory in Config.GetRiskCategories() do
            RiskCategoriesArray.Add(RiskCategory);

        AttackStrategiesArray := Config.GetAttackStrategies();

        if Config.GetLocale() <> '' then
            RequestJson.Add('locale', Config.GetLocale());
        if RiskCategoriesArray.Count > 0 then
            RequestJson.Add('risk_categories', RiskCategoriesArray);
        if AttackStrategiesArray.Count > 0 then
            RequestJson.Add('attack_strategies', AttackStrategiesArray);
        if Config.GetNumObjectives() > 0 then
            RequestJson.Add('num_objectives', Config.GetNumObjectives());
        SeedPrompts := Config.GetCustomAttackSeedPrompts();
        if SeedPrompts.Count > 0 then
            RequestJson.Add('custom_attack_seed_prompts', SeedPrompts);
        RequestJson.WriteTo(RequestText);
        HttpRequestMessage.Content.WriteFrom(RequestText);

        HttpRequestMessage.Content.GetHeaders(HttpHeaders);
        if HttpHeaders.Contains('Content-Type') then
            HttpHeaders.Remove('Content-Type');
        HttpHeaders.Add('Content-Type', 'application/json');

        RedTeamHttpClient.Timeout(GetTimeout());
        RedTeamHttpClient.Send(HttpRequestMessage, HttpResponseMessage);
        if not HttpResponseMessage.IsSuccessStatusCode then
            Error(StartScanErr, GetErrorDetail(HttpResponseMessage));

        HttpResponseMessage.Content.ReadAs(ResponseText);
        ResponseJson.ReadFrom(ResponseText);
        ResponseJson.Get('id', JsonToken);
        ScanId := JsonToken.AsValue().AsText();

        AttackNumber := 0;
        ConversationTurnNumber := 0;
        ScanCompleted := false;
    end;

    procedure HasNextTurn(): Boolean
    var
        NextAttackNumber: Integer;
        NextConversationTurnNumber: Integer;
        Query: Text;
        IsCompleted: Boolean;
    begin
        if ScanCompleted then
            exit(false);

        GetOrPeekQueryInternal(Query, NextAttackNumber, NextConversationTurnNumber, IsCompleted, true);
        if IsCompleted then begin
            ScanCompleted := true;
            exit(false);
        end;

        // There's a next turn if it's the same attack number but a higher turn number
        exit((NextAttackNumber = AttackNumber) and (NextConversationTurnNumber > ConversationTurnNumber));
    end;

    procedure HasNextAttack(): Boolean
    var
        NextAttackNumber: Integer;
        NextConversationTurnNumber: Integer;
        Query: Text;
        IsCompleted: Boolean;
    begin
        if ScanCompleted then
            exit(false);

        if AttackNumber = 0 then
            exit(true);

        GetOrPeekQueryInternal(Query, NextAttackNumber, NextConversationTurnNumber, IsCompleted, true);
        if IsCompleted then begin
            ScanCompleted := true;
            exit(false);
        end;

        // There's a next attack if it's a higher attack number
        exit(NextAttackNumber > AttackNumber);
    end;

    procedure GetQuery(): Text
    var
        Query: Text;
        IsCompleted: Boolean;
    begin
        GetOrPeekQueryInternal(Query, AttackNumber, ConversationTurnNumber, IsCompleted, false);
        if IsCompleted then
            ScanCompleted := true;
        exit(Query);
    end;

    procedure GetAttackNumber(): Integer
    begin
        exit(AttackNumber);
    end;

    procedure GetConversationTurnNumber(): Integer
    begin
        exit(ConversationTurnNumber);
    end;

    local procedure GetOrPeekQueryInternal(
        var Query: Text;
        var LocalAttackNumber: Integer;
        var LocalConversationTurnNumber: Integer;
        var IsCompleted: Boolean;
        Peek: Boolean)
    var
        RedTeamHttpClient: HttpClient;
        HttpRequestMessage: HttpRequestMessage;
        HttpResponseMessage: HttpResponseMessage;
        ResponseJson: JsonObject;
        ResponseText: Text;
        JsonToken: JsonToken;
    begin
        IsCompleted := false;
        HttpRequestMessage.Method('GET');
        if Peek then
            HttpRequestMessage.SetRequestUri(StrSubstNo(PeekPathTxt, GetBaseRedTeamUri(), ScanId))
        else
            HttpRequestMessage.SetRequestUri(StrSubstNo(GetQueryPathTxt, GetBaseRedTeamUri(), ScanId));

        RedTeamHttpClient.Timeout(GetTimeout());
        RedTeamHttpClient.Send(HttpRequestMessage, HttpResponseMessage);
        if not HttpResponseMessage.IsSuccessStatusCode then
            Error(GetQueryErr, GetErrorDetail(HttpResponseMessage));

        HttpResponseMessage.Content.ReadAs(ResponseText);
        ResponseJson.ReadFrom(ResponseText);

        if ResponseJson.Get('completed', JsonToken) then
            if JsonToken.AsValue().AsBoolean() then begin
                IsCompleted := true;
                Query := '';
                exit;
            end;

        ResponseJson.Get('query', JsonToken);
        Query := JsonToken.AsValue().AsText();
        ResponseJson.Get('conversation_turn_number', JsonToken);
        LocalConversationTurnNumber := JsonToken.AsValue().AsInteger();
        ResponseJson.Get('attack_number', JsonToken);
        LocalAttackNumber := JsonToken.AsValue().AsInteger();
    end;

    procedure Respond(Response: Text)
    var
        RedTeamHttpClient: HttpClient;
        HttpRequestMessage: HttpRequestMessage;
        HttpResponseMessage: HttpResponseMessage;
        HttpHeaders: HttpHeaders;
        RequestJson: JsonObject;
        RequestText: Text;
    begin
        HttpRequestMessage.Method('PUT');
        HttpRequestMessage.SetRequestUri(StrSubstNo(ResponsesPathTxt, GetBaseRedTeamUri(), ScanId));

        RequestJson.Add('response', Response);
        RequestJson.WriteTo(RequestText);
        HttpRequestMessage.Content.WriteFrom(RequestText);
        HttpRequestMessage.Content.GetHeaders(HttpHeaders);
        if HttpHeaders.Contains('Content-Type') then
            HttpHeaders.Remove('Content-Type');
        HttpHeaders.Add('Content-Type', 'application/json');

        RedTeamHttpClient.Timeout(GetTimeout());
        RedTeamHttpClient.Send(HttpRequestMessage, HttpResponseMessage);
        if not HttpResponseMessage.IsSuccessStatusCode then
            Error(ResponseSendErr, GetErrorDetail(HttpResponseMessage));
    end;

    procedure GetResults(): JsonObject
    var
        RedTeamHttpClient: HttpClient;
        HttpRequestMessage: HttpRequestMessage;
        HttpResponseMessage: HttpResponseMessage;
        ResponseText: Text;
        ResultsJson: JsonObject;
    begin
        HttpRequestMessage.Method('GET');
        HttpRequestMessage.SetRequestUri(StrSubstNo(ResultsPathTxt, GetBaseRedTeamUri(), ScanId));

        RedTeamHttpClient.Timeout(GetTimeout());
        RedTeamHttpClient.Send(HttpRequestMessage, HttpResponseMessage);
        if not HttpResponseMessage.IsSuccessStatusCode then
            Error(GetResultsErr, GetErrorDetail(HttpResponseMessage));

        HttpResponseMessage.Content.ReadAs(ResponseText);
        ResultsJson.ReadFrom(ResponseText);
        exit(ResultsJson);
    end;

    procedure GetAttackSuccessRate(): Decimal
    var
        ResultsJson: JsonObject;
        ScorecardToken: JsonToken;
        ScorecardJson: JsonObject;
        SummaryToken: JsonToken;
        SummaryArray: JsonArray;
        AsrToken: JsonToken;
    begin
        ResultsJson := GetResults();
        if not ResultsJson.Get('scorecard', ScorecardToken) then
            exit(0);

        ScorecardJson := ScorecardToken.AsObject();
        if not ScorecardJson.Get('risk_category_summary', SummaryToken) then
            exit(0);

        SummaryArray := SummaryToken.AsArray();
        if SummaryArray.Count = 0 then
            exit(0);

        SummaryArray.Get(0, SummaryToken);
        SummaryToken.AsObject().Get('overall_asr', AsrToken);
        exit(AsrToken.AsValue().AsDecimal());
    end;

    local procedure GetBaseRedTeamUri(): Text
    begin
        if BaseRedTeamUri = '' then
            exit(DefaultRedTeamUriTxt + RedTeamPathTxt);

        exit(BaseRedTeamUri + RedTeamPathTxt);
    end;

    local procedure GetTimeout(): Integer
    begin
        exit(5 * 60 * 1000);
    end;

    local procedure GetErrorDetail(HttpResponseMessage: HttpResponseMessage): Text
    var
        ResponseText: Text;
        ResponseJson: JsonObject;
        ErrorToken: JsonToken;
    begin
        if not HttpResponseMessage.Content.ReadAs(ResponseText) then
            exit(HttpResponseMessage.ReasonPhrase);
        if not ResponseJson.ReadFrom(ResponseText) then
            exit(HttpResponseMessage.ReasonPhrase);
        if not ResponseJson.Get('error', ErrorToken) then
            exit(HttpResponseMessage.ReasonPhrase);
        exit(ErrorToken.AsValue().AsText());
    end;
}
