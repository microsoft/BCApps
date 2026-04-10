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
    /// Only invoke the tool calls returned from the LLM, do not send the results back to the LLM.
    /// Appends the tool results to the chat history.
    /// </summary>
    /// <remarks>This is the default preference.</remarks>
    value(0; "Invoke Tools Only")
    {
        Caption = 'Invoke Tools Only';
    }

    /// <summary>
    /// Require manual invocation of the tool calls (i.e. the Copilot toolkit will not invoke the tools).
    /// Does not append the tool results to the chat history.
    /// </summary>
    value(1; Manual)
    {
        Caption = 'Manual';
    }

    /// <summary>
    /// Invoke the tool calls returned from the LLM, and send them back to the LLM until no more tool calls are returned.
    /// Appends all the tool results to the chat history.
    /// </summary>
    value(2; Automatic)
    {
        Caption = 'Automatic';
    }
}