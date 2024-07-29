// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.AI;

/// <summary>
/// The tool invocation preference for tool call responses.
/// </summary>
enum 7776 "AOAI Tool Invoke Preference"
{
    Access = Public;
    Extensible = false;

    /// <summary>
    /// Only invoke the tool calls returned from the LLM, do not send the results back to the LLM (default).
    /// Appends the tool results to the chat history.
    /// </summary>
    value(0; InvokeToolsOnly)
    {
        Caption = 'Invoke Tools Only', Locked = true;
    }

    /// <summary>
    /// Require manually invocation of the tool calls (i.e. the Copilot toolkit will not invoke the tools).
    /// Does not append the tool results to the chat history.
    /// </summary>
    value(1; Manual)
    {
        Caption = 'Manual', Locked = true;
    }

    /// <summary>
    /// Automatically invoke the tool calls, and send them back to the LLM until no more tool calls are returned before returning to the caller.
    /// </summary>
    value(2; Automatic)
    {
        Caption = 'Automatic', Locked = true;
    }
}