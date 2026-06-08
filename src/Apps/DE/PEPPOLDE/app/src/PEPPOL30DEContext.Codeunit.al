// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Peppol.DE;

/// <summary>
/// Session-scoped context that carries DE-specific state from the EDocumentDE bridge into the
/// DE PEPPOL interface implementations (Sales/Service Validation, Document Info Provider,
/// Party Info Provider) during a single PEPPOL export.
///
/// <para>
/// <b>Why this exists.</b> The new W1 PEPPOL app exposes a fixed interface contract: the methods
/// on "PEPPOL30 Validation", "PEPPOL Document Info Provider", and "PEPPOL Party Info Provider"
/// only receive a record/variant — they cannot accept an arbitrary "context" argument. The DE
/// implementations need information that is not on the document itself:
/// <list type="bullet">
/// <item>The active <i>buyer-reference mode</i> ("Customer Reference" vs "Your Reference") configured
///       on the E-Document Service. The Sales Validation uses this to decide whether to skip the
///       Customer GLN/VAT identifier check.</item>
/// <item>The resolved <i>buyer-reference value</i> (computed by EDocumentDE's InitBuyerReference
///       from either the Customer's E-Invoice Routing No. or the document's Your Reference field).
///       The Doc Info Provider returns this in the PEPPOL XML BuyerReference element.</item>
/// </list>
/// This codeunit is the carrier. The bridge pushes values before calling W1; the DE interface
/// impls read them while W1 is running.
/// </para>
///
/// <para>
/// <b>Pattern.</b> Copied from "E-Doc. Imp. Session Telemetry" in E-Document Core. The codeunit is
/// declared <c>EventSubscriberInstance = Manual</c> — instances are NOT auto-bound at session start.
/// A caller creates a local instance, calls <see cref="Start"/> which runs <c>BindSubscription(this)</c>
/// to register that specific instance as the live subscriber for the current call stack. State
/// (BuyerReferenceValue, IsCustomerReferenceModeValue) lives on the instance, not on a singleton.
/// Calls to the public Set/Get/Has methods publish internal IntegrationEvents that the bound
/// instance answers via its own subscribers. <see cref="Stop"/> calls <c>UnbindSubscription(this)</c>
/// and clears the captured state.
/// </para>
///
/// <para>
/// <b>Concurrency.</b> A <c>SingleInstance</c> singleton would share state across all sessions on
/// the same NST — a UI export and a Job Queue batch running in parallel would stomp on each other.
/// <c>BindSubscription</c> is per-session, so each session's bound instance is isolated. Two parallel
/// PEPPOL exports each have their own bound instance, their own captured values, and each session's
/// IntegrationEvent publishes only reach its own bound subscriber.
/// </para>
///
/// <para>
/// <b>Error safety.</b> <see cref="Start"/> clears state on every bind, so if a previous Stop() was
/// skipped because of an error inside the W1 bridge, the next Start() resets to a clean slate before
/// the next export begins. Stop() is best-effort: a leaked binding affects only the (typically
/// short-lived) session that leaked it.
/// </para>
///
/// <para>
/// <b>Lifecycle (typical caller).</b>
/// <code>
/// DEContext: Codeunit "PEPPOL30 DE Context";
/// begin
///     DEContext.Start();
///     DEContext.SetBuyerReference(value);
///     DEContext.SetIsCustomerReferenceMode(mode);
///     EDocPEPPOLBIS30.Check(...);   // DE interface impls read via Has/Get*
///     DEContext.Stop();
/// end;
/// </code>
/// </para>
/// </summary>
codeunit 37404 "PEPPOL30 DE Context"
{
    EventSubscriberInstance = Manual;
    Access = Public;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        BuyerReferenceValue: Text;
        IsCustomerReferenceModeValue: Boolean;

    /// <summary>
    /// Binds this codeunit instance as the active DE PEPPOL context for the current call stack
    /// and resets any captured state. Must be called before pushing values with the Set* methods
    /// and before invoking the W1 EDoc PEPPOL bridge so the DE interface implementations can read
    /// the context state during validation / XML generation.
    /// </summary>
    /// <remarks>
    /// Pair with <see cref="Stop"/>. Calling Start() while already bound is safe: the second
    /// BindSubscription is silently swallowed and the captured state is re-cleared.
    /// </remarks>
    procedure Start()
    begin
        if BindSubscription(this) then;
        Clear(BuyerReferenceValue);
        Clear(IsCustomerReferenceModeValue);
    end;

    /// <summary>
    /// Unbinds this instance from the current session's subscriber chain and clears its captured
    /// state. Must be called after the PEPPOL export through the W1 bridge has returned so that
    /// later operations in the same session do not see stale DE context values.
    /// </summary>
    /// <remarks>
    /// Calling Stop() without a preceding Start() is a no-op. If an error inside the W1 bridge
    /// short-circuits the export and Stop() is skipped, the next Start() in the same session will
    /// re-clear state before re-binding, so no stale values leak into the next export.
    /// </remarks>
    procedure Stop()
    begin
        if UnbindSubscription(this) then;
        Clear(BuyerReferenceValue);
        Clear(IsCustomerReferenceModeValue);
    end;

    /// <summary>
    /// Publishes the resolved DE buyer-reference value to the active bound context instance.
    /// The DE Document Info Provider returns this value from <c>GetBuyerReference</c>, which
    /// the W1 Sales Invoice / Sales Cr.Memo PEPPOL30 XmlPort renders into the
    /// <c>cbc:BuyerReference</c> element on the exported document.
    /// </summary>
    /// <param name="NewBuyerReference">
    /// The buyer-reference text as computed by EDocumentDE's <c>InitBuyerReference</c>
    /// (either the Customer's E-Invoice Routing No. when the service is configured for
    /// "Customer Reference" mode, or the document's Your Reference value when in
    /// "Your Reference" mode).
    /// </param>
    /// <remarks>
    /// Only meaningful between Start() and Stop(). When no instance is bound the publish has no
    /// observable effect.
    /// </remarks>
    procedure SetBuyerReference(NewBuyerReference: Text)
    begin
        OnSetBuyerReference(NewBuyerReference);
    end;

    /// <summary>
    /// Publishes whether the active E-Document Service is configured with buyer-reference mode
    /// equal to "Customer Reference". The DE Sales Validation reads this flag to decide whether
    /// to skip the Customer GLN/VAT identifier check (in Customer Reference mode the customer
    /// identity is established via the routing number, so the W1 GLN/VAT requirement is relaxed).
    /// </summary>
    /// <param name="NewValue">
    /// <c>true</c> when the active <c>E-Document Service."Buyer Reference"</c> is "Customer Reference";
    /// <c>false</c> otherwise (Your Reference or unknown).
    /// </param>
    /// <remarks>
    /// Only meaningful between Start() and Stop(). When no instance is bound the publish has no
    /// observable effect.
    /// </remarks>
    procedure SetIsCustomerReferenceMode(NewValue: Boolean)
    begin
        OnSetIsCustomerReferenceMode(NewValue);
    end;

    /// <summary>
    /// Returns whether a DE PEPPOL context is currently bound on the active session and call stack.
    /// The DE interface implementations use this to gate behaviour that is only valid mid-export —
    /// outside an export they must fall back to the standard W1 behaviour rather than honour stale
    /// or empty context values.
    /// </summary>
    /// <returns>
    /// <c>true</c> when some "PEPPOL30 DE Context" instance has called Start() in the current
    /// call stack and not yet Stop()'d; <c>false</c> otherwise.
    /// </returns>
    procedure HasContext() Result: Boolean
    begin
        OnHasContext(Result);
    end;

    /// <summary>
    /// Returns the buyer-reference value pushed by the EDocumentDE bridge via
    /// <see cref="SetBuyerReference"/> on the active bound instance.
    /// </summary>
    /// <returns>
    /// The captured buyer-reference text, or an empty string when no context is bound or no value
    /// has been pushed. Callers should combine this with <see cref="HasContext"/> if they need to
    /// distinguish "no context" from "context bound with empty value".
    /// </returns>
    procedure GetBuyerReference() Result: Text
    begin
        OnGetBuyerReference(Result);
    end;

    /// <summary>
    /// Returns the buyer-reference mode flag pushed by the EDocumentDE bridge via
    /// <see cref="SetIsCustomerReferenceMode"/> on the active bound instance.
    /// </summary>
    /// <returns>
    /// <c>true</c> when the active E-Document Service is in "Customer Reference" mode; <c>false</c>
    /// when no context is bound or the mode is "Your Reference". Callers that need to disambiguate
    /// "no context" from "explicit false" should test <see cref="HasContext"/> first.
    /// </returns>
    procedure GetIsCustomerReferenceMode() Result: Boolean
    begin
        OnGetIsCustomerReferenceMode(Result);
    end;

    #region Internal pub/sub bridge - the bound instance captures writes and answers reads
    [IntegrationEvent(false, false)]
    local procedure OnSetBuyerReference(NewBuyerReference: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetIsCustomerReferenceMode(NewValue: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnHasContext(var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetBuyerReference(var Result: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetIsCustomerReferenceMode(var Result: Boolean)
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"PEPPOL30 DE Context", OnSetBuyerReference, '', false, false)]
    local procedure SubOnSetBuyerReference(NewBuyerReference: Text)
    begin
        BuyerReferenceValue := NewBuyerReference;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"PEPPOL30 DE Context", OnSetIsCustomerReferenceMode, '', false, false)]
    local procedure SubOnSetIsCustomerReferenceMode(NewValue: Boolean)
    begin
        IsCustomerReferenceModeValue := NewValue;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"PEPPOL30 DE Context", OnHasContext, '', false, false)]
    local procedure SubOnHasContext(var Result: Boolean)
    begin
        Result := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"PEPPOL30 DE Context", OnGetBuyerReference, '', false, false)]
    local procedure SubOnGetBuyerReference(var Result: Text)
    begin
        Result := BuyerReferenceValue;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"PEPPOL30 DE Context", OnGetIsCustomerReferenceMode, '', false, false)]
    local procedure SubOnGetIsCustomerReferenceMode(var Result: Boolean)
    begin
        Result := IsCustomerReferenceModeValue;
    end;
    #endregion
}
