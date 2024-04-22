// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.TestLibraries.AI;

using System.AI;

codeunit 132933 "Azure OpenAI Test Library"
{

    procedure GetAOAIHistory(HistoryLength: Integer; var AOAIChatMessages: Codeunit "AOAI Chat Messages"): JsonArray
    var
        SystemMessageTokenCount: Integer;
        MessagesTokenCount: Integer;
    begin
        AOAIChatMessages.SetHistoryLength(HistoryLength);
        exit(AOAIChatMessages.AssembleHistory(SystemMessageTokenCount, MessagesTokenCount));
    end;

    procedure GetAOAIAssembleTools(var AOAIChatMessages: Codeunit "AOAI Chat Messages"): JsonArray
    begin
        exit(AOAIChatMessages.AssembleTools());
    end;

}