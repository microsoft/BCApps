// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify.Test;

using Microsoft.Integration.Shopify;

/// <summary>
/// Codeunit Shpfy Inventory Subscriber (ID 139593).
/// Mock subscriber for inventory API tests to simulate GraphQL responses.
/// </summary>
codeunit 139593 "Shpfy Inventory Subscriber"
{
    SingleInstance = true;
    EventSubscriberInstance = Manual;

    var
        RetryScenario: Enum "Shpfy Inventory Retry Scenario";
        ErrorCode: Text;
        CallCount: Integer;
        LastGraphQLRequest: Text;

    internal procedure SetRetryScenario(NewScenario: Enum "Shpfy Inventory Retry Scenario")
    begin
        RetryScenario := NewScenario;
        CallCount := 0;
    end;

    internal procedure SetErrorCode(NewErrorCode: Text)
    begin
        ErrorCode := NewErrorCode;
    end;

    internal procedure GetCallCount(): Integer
    begin
        exit(CallCount);
    end;

    internal procedure GetLastGraphQLRequest(): Text
    begin
        exit(LastGraphQLRequest);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Shpfy Communication Events", 'OnClientSend', '', true, false)]
    local procedure OnClientSend(HttpRequestMessage: HttpRequestMessage; var HttpResponseMessage: HttpResponseMessage)
    begin
        MakeResponse(HttpRequestMessage, HttpResponseMessage);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Shpfy Communication Events", 'OnGetContent', '', true, false)]
    local procedure OnGetContent(HttpResponseMessage: HttpResponseMessage; var Response: Text)
    begin
        HttpResponseMessage.Content.ReadAs(Response);
    end;

    local procedure MakeResponse(HttpRequestMessage: HttpRequestMessage; var HttpResponseMessage: HttpResponseMessage)
    var
        Uri: Text;
        GraphQLQuery: Text;
        InventorySetQuantitiesGQLTxt: Label 'inventorySetQuantities', Locked = true;
        GraphQLCmdTxt: Label '/graphql.json', Locked = true;
    begin
        case HttpRequestMessage.Method of
            'POST':
                begin
                    Uri := HttpRequestMessage.GetRequestUri();
                    if Uri.EndsWith(GraphQLCmdTxt) then
                        if HttpRequestMessage.Content.ReadAs(GraphQLQuery) then begin
                            LastGraphQLRequest := GraphQLQuery;
                            if GraphQLQuery.Contains(InventorySetQuantitiesGQLTxt) then begin
                                CallCount += 1;
                                HttpResponseMessage := GetInventoryResponse();
                            end;
                        end;
                end;
        end;
    end;

    local procedure GetInventoryResponse(): HttpResponseMessage
    var
        HttpResponseMessage: HttpResponseMessage;
        ResponseJson: Text;
        SuccessResponseTxt: Label '{"data":{"inventorySetQuantities":{"inventoryAdjustmentGroup":{"id":"gid://shopify/InventoryAdjustmentGroup/12345"},"userErrors":[]}}}', Locked = true;
        ErrorResponseTxt: Label '{"data":{"inventorySetQuantities":{"inventoryAdjustmentGroup":null,"userErrors":[{"field":["input"],"message":"Concurrent request detected","code":"%1"}]}}}', Comment = '%1 = Error code', Locked = true;
    begin
        case RetryScenario of
            RetryScenario::Success:
                ResponseJson := SuccessResponseTxt;
            RetryScenario::FailOnceThenSucceed:
                if CallCount <= 1 then
                    ResponseJson := StrSubstNo(ErrorResponseTxt, ErrorCode)
                else
                    ResponseJson := SuccessResponseTxt;
            RetryScenario::AlwaysFail:
                ResponseJson := StrSubstNo(ErrorResponseTxt, ErrorCode);
        end;

        HttpResponseMessage.Content.WriteFrom(ResponseJson);
        exit(HttpResponseMessage);
    end;
}
