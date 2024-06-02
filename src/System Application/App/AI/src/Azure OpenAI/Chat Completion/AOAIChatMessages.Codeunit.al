// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.AI;

/// <summary>
/// Helper functions for the AOAI Chat Message table.
/// </summary>
codeunit 7763 "AOAI Chat Messages"
{
    Access = Public;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        AOAIChatMessagesImpl: Codeunit "AOAI Chat Messages Impl";
        AOAIToolsImpl: Codeunit "AOAI Tools Impl";

    /// <summary>
    /// Sets the system message which is always at the top of the chat messages history provided to the model.
    /// </summary>
    /// <param name="Message">The primary system message.</param>
    [NonDebuggable]
    procedure SetPrimarySystemMessage(Message: SecretText)
    begin
        AOAIChatMessagesImpl.SetPrimarySystemMessage(Message);
    end;

    /// <summary>
    /// Adds a system message to the chat messages history.
    /// </summary>
    /// <param name="NewMessage">The message to add.</param>
    [NonDebuggable]
    procedure AddSystemMessage(NewMessage: Text)
    begin
        AOAIChatMessagesImpl.AddSystemMessage(NewMessage);
    end;

    /// <summary>
    /// Adds a user message to the chat messages history.
    /// </summary>
    /// <param name="NewMessage">The message to add.</param>
    [NonDebuggable]
    procedure AddUserMessage(NewMessage: Text)
    begin
        AOAIChatMessagesImpl.AddUserMessage(NewMessage);
    end;

    /// <summary>
    /// Adds a user message to the chat messages history.
    /// </summary>
    /// <param name="NewMessage">The message to add.</param>
    /// <param name="NewName">The name of the user.</param>
    [NonDebuggable]
    procedure AddUserMessage(NewMessage: Text; NewName: Text[2048])
    begin
        AOAIChatMessagesImpl.AddUserMessage(NewMessage, NewName);
    end;

    /// <summary>
    /// Adds a assistant message to the chat messages history.
    /// </summary>
    /// <param name="NewMessage">The message to add.</param>
    [NonDebuggable]
    procedure AddAssistantMessage(NewMessage: Text)
    begin
        AOAIChatMessagesImpl.AddAssistantMessage(NewMessage);
    end;

    /// <summary>
    /// Adds a tool result to the chat messages history.
    /// </summary>
    /// <param name="ToolCallId">The id of the tool call.</param>
    /// <param name="FunctionName">The name of the called function.</param>
    /// <param name="FunctionResult">The result of the tool call.</param>
    [NonDebuggable]
    procedure AddToolMessage(ToolCallId: Text; FunctionName: Text; FunctionResult: Text)
    begin
        AOAIChatMessagesImpl.AddToolMessage(ToolCallId, FunctionName, FunctionResult);
    end;

    /// <summary>
    /// Modifies a message in the chat messages history.
    /// </summary>
    /// <param name="Id">Id of the message.</param>
    /// <param name="NewMessage">The new message.</param>
    /// <param name="NewRole">The new role.</param>
    /// <param name="NewName">The new name.</param>
    /// <error>Message id does not exist.</error>
    [NonDebuggable]
    procedure ModifyMessage(Id: Integer; NewMessage: Text; NewRole: Enum "AOAI Chat Roles"; NewName: Text[2048])
    begin
        AOAIChatMessagesImpl.ModifyMessage(Id, NewMessage, NewRole, NewName);
    end;

    /// <summary>
    /// Deletes a message from the chat messages history.
    /// </summary>
    /// <param name="Id">Id of the message.</param>
    /// <error>Message id does not exist.</error>
    [NonDebuggable]
    procedure DeleteMessage(Id: Integer)
    begin
        AOAIChatMessagesImpl.DeleteMessage(Id);
    end;

    /// <summary>
    /// Gets the history of chat messages.
    /// </summary>
    /// <returns>List of chat messages.</returns>
    [NonDebuggable]
    procedure GetHistory(): List of [Text]
    begin
        exit(AOAIChatMessagesImpl.GetHistory());
    end;

    /// <summary>
    /// Gets the history names of chat messages.
    /// </summary>
    /// <returns>List of names of chat messages.</returns>
    [NonDebuggable]
    procedure GetHistoryNames(): List of [Text[2048]]
    begin
        exit(AOAIChatMessagesImpl.GetHistoryNames());
    end;

    /// <summary>
    /// Gets the history roles of chat messages.
    /// </summary>
    /// <returns>List of roles of chat messages.</returns>
    [NonDebuggable]
    procedure GetHistoryRoles(): List of [Enum "AOAI Chat Roles"]
    begin
        exit(AOAIChatMessagesImpl.GetHistoryRoles());
    end;

    /// <summary>
    /// Gets the last chat message.
    /// </summary>
    /// <returns>The last chat message.</returns>
    [NonDebuggable]
    procedure GetLastMessage(): Text
    begin
        exit(AOAIChatMessagesImpl.GetLastMessage());
    end;

    /// <summary>
    /// Gets the last chat message role.
    /// </summary>
    /// <returns>The last chat message role.</returns>
    [NonDebuggable]
    procedure GetLastRole(): Enum "AOAI Chat Roles"
    begin
        exit(AOAIChatMessagesImpl.GetLastRole());
    end;

    /// <summary>
    /// Gets the last chat message name.
    /// </summary>
    /// <returns>The last chat message name.</returns>
    [NonDebuggable]
    procedure GetLastName(): Text[2048]
    begin
        exit(AOAIChatMessagesImpl.GetLastName());
    end;

    /// <summary>
    /// Set the length of history that is used by the model.
    /// </summary>
    /// <param name="NewLength">The new length.</param>
    /// <error>History length must be greater than 0.</error>
    [NonDebuggable]
    procedure SetHistoryLength(NewLength: Integer)
    begin
        AOAIChatMessagesImpl.SetHistoryLength(NewLength);
    end;

    /// <summary>
    /// Prepares the history of messages to be sent to the deployment model.
    /// </summary>
    /// <param name="SystemMessageTokenCount">The number tokens used by the primary system messages.</param>
    /// <param name="MessagesTokenCount">The number tokens used by all other messages.</param>
    /// <returns>History of messages in a JsonArray.</returns>
    /// <remarks>Use this after adding messages, to construct a json array of all messages.</remarks>
    [NonDebuggable]
    internal procedure AssembleHistory(var SystemMessageTokenCount: Integer; var MessagesTokenCount: Integer): JsonArray
    begin
        exit(AOAIChatMessagesImpl.PrepareHistory(SystemMessageTokenCount, MessagesTokenCount));
    end;

    /// <summary>
    /// Gets the number of tokens used by the primary system messages and all other messages.
    /// </summary>
    [NonDebuggable]
    procedure GetHistoryTokenCount(): Integer
    begin
        exit(AOAIChatMessagesImpl.GetHistoryTokenCount());
    end;

#if not CLEAN25
    /// <summary>
    /// Appends a Tool to the payload.
    /// </summary>
    /// <param name="NewTool">The Tool to be added to the payload.</param>
    /// <remarks>See more details here: https://go.microsoft.com/fwlink/?linkid=2254538</remarks>
    [NonDebuggable]
    [Obsolete('Use AddTool that takes in an AOAI Function interface.', '25.0')]
    procedure AddTool(NewTool: JsonObject)
    begin
#pragma warning disable AL0432
        AOAIToolsImpl.AddTool(NewTool);
#pragma warning restore AL0432
    end;

    /// <summary>
    /// Modifies a Tool in the list of Tool.
    /// </summary>
    /// <param name="Id">Id of the message.</param>
    /// <param name="NewTool">The new Tool.</param>
    /// <error>Message id does not exist.</error>
    [NonDebuggable]
    [Obsolete('Deprecated with no replacement. Use DeleteFunctionTool and AddTool.', '25.0')]
    procedure ModifyTool(Id: Integer; NewTool: JsonObject)
    begin
#pragma warning disable AL0432
        AOAIToolsImpl.ModifyTool(Id, NewTool);
#pragma warning restore AL0432
    end;

    /// <summary>
    /// Deletes a Tool from the list of Tool.
    /// </summary>
    /// <param name="Id">Id of the Tool.</param>
    /// <error>Message id does not exist.</error>
    [Obsolete('Use DeleteFunctionTool that takes in a function name instead.', '25.0')]
    procedure DeleteTool(Id: Integer)
    begin
#pragma warning disable AL0432
        AOAIToolsImpl.DeleteTool(Id);
#pragma warning restore AL0432
    end;
#endif

    /// <summary>
    /// Adds a function to the payload.
    /// </summary>
    /// <param name="Function">The function to be added</param>
    procedure AddTool(Function: Interface "AOAI Function")
    begin
        AOAIToolsImpl.AddTool(Function);
    end;

    /// <summary>
    /// Deletes a Function from the list of Functions.
    /// </summary>
    /// <param name="Name">Name of the Function.</param>
    /// <error>Message id does not exist.</error>
    procedure DeleteFunctionTool(Name: Text): Boolean
    begin
        exit(AOAIToolsImpl.DeleteTool(Name));
    end;

    /// <summary>
    /// Remove all tools.
    /// </summary>
    procedure ClearTools()
    begin
        AOAIToolsImpl.ClearTools();
    end;

    /// <summary>
    /// Gets the function associated with the specified name.
    /// </summary>
    /// <param name="Name">Name of the function to get.</param>
    /// <returns>The function codeunit.</returns>
    /// <error>Tool not found.</error>
    procedure GetFunctionTool(Name: Text; var Function: Interface "AOAI Function"): Boolean
    begin
        exit(AOAIToolsImpl.GetTool(Name, Function));
    end;

    /// <summary>
    /// Gets the list of names of Function Tools that have been added.
    /// </summary>
    /// <returns>List of function tool names.</returns>
    procedure GetFunctionTools(): List of [Text]
    begin
        exit(AOAIToolsImpl.GetFunctionTools());
    end;

#if not CLEAN25
    /// <summary>
    /// Gets the list of Tools.
    /// </summary>
    /// <returns>List of Tools.</returns>
    [NonDebuggable]
    [Obsolete('Use GetFunctionTool() that takes in a function name and returns the interface.', '25.0')]
    procedure GetTools(): List of [JsonObject]
    begin
#pragma warning disable AL0432
        exit(AOAIToolsImpl.GetTools());
#pragma warning restore AL0432
    end;
#endif

    /// <summary>
    /// Checks if at least one Tools exists in the list.
    /// </summary>
    /// <returns>True if Tools exists, false otherwise.</returns>
    procedure ToolsExists(): Boolean
    begin
        exit(AOAIToolsImpl.ToolsExists());
    end;

    /// <summary>
    /// Sets the Tools to be added to the payload.
    /// </summary>
    /// <param name="AddToolsToPayload">True if Tools is to be added to the payload, false otherwise.</param>
    procedure SetAddToolsToPayload(AddToolsToPayload: Boolean)
    begin
        AOAIToolsImpl.SetAddToolToPayload(AddToolsToPayload);
    end;

    /// <summary>
    /// Sets the Tool choice, which allow model to determine how Tools should be called.
    /// </summary>
    /// <param name="Toolchoice">The Tool choice parameter. </param>
    /// <remarks>See more details here: https://go.microsoft.com/fwlink/?linkid=2254538</remarks>
    [NonDebuggable]
    procedure SetToolChoice(ToolChoice: Text)
    begin
        AOAIToolsImpl.SetToolChoice(ToolChoice);
    end;

    /// <summary>
    /// Sets the function as the tool choice to be called.
    /// </summary>
    /// <param name="FunctionName">The function name parameter. </param>
    /// <remarks>See more details here: https://go.microsoft.com/fwlink/?linkid=2254538</remarks>
    [NonDebuggable]
    procedure SetFunctionAsToolChoice(FunctionName: Text)
    begin
        AOAIToolsImpl.SetFunctionAsToolChoice(FunctionName);
    end;

    /// <summary>
    /// Sets the function as the tool choice to be called.
    /// </summary>
    /// <param name="Function">The function codeunit.</param>
    /// <remarks>See more details here: https://go.microsoft.com/fwlink/?linkid=2254538</remarks>
    [NonDebuggable]
    procedure SetFunctionAsToolChoice(Function: Interface "AOAI Function")
    begin
        AOAIToolsImpl.SetFunctionAsToolChoice(Function);
    end;

    /// <summary>
    /// Gets the Tool choice parameter.
    /// </summary>
    /// <returns>The Tool choice parameter.</returns>
    [NonDebuggable]
    procedure GetToolChoice(): Text
    begin
        exit(AOAIToolsImpl.GetToolChoice());
    end;

    /// <summary>
    /// Prepares the Tools to be sent to the deployment model.
    /// </summary>
    /// <returns>Tools in a JsonArray.</returns>
    /// <remarks>Use this after adding Tools, to construct a json array of all Tools.</remarks>
    [NonDebuggable]
    internal procedure AssembleTools(): JsonArray
    begin
        exit(AOAIToolsImpl.PrepareTools());
    end;
}