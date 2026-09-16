namespace System.TestLibraries.Agents;

using System.TestTools.TestRunner;

/// <summary>
/// Executes a parsed AIT query through a request provider without evaluating the answer or writing AIT output.
/// </summary>
interface "IAITRequestSender"
{
    /// <summary>
    /// Executes one turn and replaces RequestResult with its execution status, assistant text, and diagnostics.
    /// Execution success indicates completion without an unexpected error or timeout, not answer correctness.
    /// The caller owns RequestContext and may retain it across turns; providers update it with task or conversation state.
    /// Diagnostics must be sanitized and must not contain credentials or authorization headers.
    /// </summary>
    /// <param name="QueryInput">The parsed query for the current turn.</param>
    /// <param name="RequestContext">Optional provider state. Non-BC providers do not require an agent or task.</param>
    /// <param name="RequestResult">The result for this turn, separate from caller-side evaluation and AIT output.</param>
    procedure SendRequest(QueryInput: Codeunit "Test Input Json"; var RequestContext: Codeunit "AIT Request Context"; var RequestResult: Codeunit "AIT Request Result")
}