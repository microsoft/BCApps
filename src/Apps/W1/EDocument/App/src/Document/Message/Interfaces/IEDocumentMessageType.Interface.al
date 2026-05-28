// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

/// <summary>
/// The Type owns identity + applicability + protocol-level **semantics** of a message kind.
/// Returns Reader / Writer interfaces for IO and declares state-transition intent on an
/// "E-Doc. Msg. Apply Context" — the framework executes the actual mutation, persistence,
/// locking, logging, and workflow event firing uniformly.
/// </summary>
interface IEDocumentMessageType
{
    /// <summary>
    /// Capability discovery — the framework helper "GetApplicableMessages" iterates registered
    /// Types and calls this. UIs use the filtered list to drive the "Send Message" modal.
    /// </summary>
    procedure IsApplicableFor(
        ParentEDocument: Record "E-Document";
        Direction: Enum "E-Document Direction";
        TriggerSource: Enum "E-Doc. Msg. Trigger Source"
    ): Boolean;

    /// <summary>
    /// Which directions the Type supports in principle. The framework will not invoke
    /// GetReader() for a Type that doesn't list Incoming, or GetWriter() for one that
    /// doesn't list Outgoing.
    /// </summary>
    procedure GetSupportedDirections(): List of [Enum "E-Document Direction"];

    /// <summary>
    /// Inbound IO. May throw if "Incoming" is not in GetSupportedDirections().
    /// </summary>
    procedure GetReader(): Interface IEDocumentMessageReader;

    /// <summary>
    /// Outbound IO. May throw if "Outgoing" is not in GetSupportedDirections().
    /// </summary>
    procedure GetWriter(): Interface IEDocumentMessageWriter;

    /// <summary>
    /// State-transition intent. Framework calls this after Reader.ParseMessage succeeded (inbound)
    /// OR after Writer.GenerateMessage + IDocumentSenderMessages.SendMessage both succeeded
    /// (outbound). The Type declares what to do via Context (set parent status, signal ignored,
    /// set error, add log notes). The framework executes — locking, persistence, logging, event
    /// firing are framework concerns.
    /// </summary>
    procedure ApplyMessage(
        var Msg: Record "E-Document Message";
        var Context: Codeunit "E-Doc. Msg. Apply Context"
    ): Boolean;

    /// <summary>
    /// UX delegation. The Type opens whatever page makes sense for the format (Order Response
    /// Review, MLR validation-rules display, etc.). No generic framework page beyond the lookup modal.
    /// </summary>
    procedure ViewMessage(Msg: Record "E-Document Message");
}
