// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats;

using Microsoft.eServices.EDocument;

/// <summary>
/// Session-scoped context that carries the triggering <c>E-Document Service</c> from the ZUGFeRD
/// format bridge into the report-rendering path that builds the ZUGFeRD XML.
///
/// <para>
/// <b>Why this exists.</b> The ZUGFeRD export produces a PDF/A-3: "Export ZUGFeRD Document".Run()
/// renders the posted-document report, and the XML is built during rendering by the report
/// extensions (Posted Sales Invoice / Cr.Memo, Posted Service Invoice / Cr.Memo) which each
/// instantiate their OWN "Export ZUGFeRD Document" instance and call
/// CreateAndAddXMLAttachmentToRenderingPayload -> CreateXML. That is a different instance from the
/// one Run() executes on, so a setter called before Run() cannot reach the XML builder. This
/// context is the carrier: the format pushes the service before triggering report generation, and
/// each report extension reads it back while rendering and pushes it onto its local instance.
/// </para>
///
/// <para>
/// <b>Pattern.</b> Mirrors "PEPPOL30 DE Context". The codeunit is declared
/// <c>EventSubscriberInstance = Manual</c>: a caller creates a local instance and calls
/// <see cref="Start"/> which runs <c>BindSubscription(this)</c> to register that instance as the
/// live carrier for the current call stack. State lives on the bound instance, not on a singleton.
/// Set/Get/HasContext publish internal IntegrationEvents that only the bound instance answers.
/// <see cref="Stop"/> unbinds and clears the captured state. A <c>SingleInstance</c> singleton was
/// deliberately not used: it would share state across all sessions on the NST, so a UI export and a
/// Job Queue batch running in parallel would stomp on each other. BindSubscription is per-session,
/// so each parallel export keeps its own bound instance and value.
/// </para>
///
/// <para>
/// <b>Lifecycle.</b> The format calls <see cref="Start"/> and <see cref="SetEDocumentService"/>
/// before running the export and <see cref="Stop"/> after it returns. Stop() is best-effort: if the
/// export errors it is skipped, because the error-catching form of Codeunit.Run cannot be used once
/// the surrounding transaction has pending writes. Note that a later <see cref="Start"/> does NOT
/// rescue a skipped Stop(), since each export uses a fresh context instance and Start() only clears
/// its own state - the real protection is AL unbinding the instance when it goes out of scope. A
/// leaked binding would therefore affect only the (typically short-lived) session that leaked it,
/// and <see cref="HasContext"/> additionally requires a non-blank service before it reports true.
/// </para>
///
/// <para>
/// <b>Safety.</b> <see cref="HasContext"/> means "an instance is bound AND a non-blank service was
/// pushed" - not merely "bound". A blank service is refused by the carrier. This matters because
/// pushing a service onto "Export ZUGFeRD Document" suppresses its legacy FindLast fallback: if a
/// bound-but-empty context reported true, the export would silently use a blank service with no
/// fallback. Report extensions gate their read on <see cref="HasContext"/> and additionally refuse
/// to push a blank service, so a plain print, a bound-but-unset context, or a blank push all leave
/// the legacy lookup intact.
/// </para>
/// </summary>
codeunit 11039 "ZUGFeRD Export Context"
{
    EventSubscriberInstance = Manual;
    Access = Public;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        EDocumentServiceValue: Record "E-Document Service";
        EDocumentServiceIsSet: Boolean;

    /// <summary>
    /// Binds this instance as the active ZUGFeRD export context for the current call stack and
    /// resets any captured service. Pair with <see cref="Stop"/>.
    /// </summary>
    procedure Start()
    begin
        if BindSubscription(this) then;
        Clear(EDocumentServiceValue);
        Clear(EDocumentServiceIsSet);
    end;

    /// <summary>
    /// Unbinds this instance from the current session's subscriber chain and clears the captured
    /// service so later operations in the same session do not see a stale value.
    /// </summary>
    procedure Stop()
    begin
        if UnbindSubscription(this) then;
        Clear(EDocumentServiceValue);
        Clear(EDocumentServiceIsSet);
    end;

    /// <summary>
    /// Publishes the triggering E-Document Service to the active bound context instance. Only
    /// meaningful between <see cref="Start"/> and <see cref="Stop"/>; when no instance is bound the
    /// publish has no observable effect.
    /// </summary>
    /// <param name="NewEDocumentService">
    /// The service that triggered the export. A blank service (empty Code) is deliberately refused:
    /// it would make <see cref="HasContext"/> report true and suppress the legacy FindLast fallback
    /// in "Export ZUGFeRD Document" while carrying no usable service.
    /// </param>
    procedure SetEDocumentService(NewEDocumentService: Record "E-Document Service")
    begin
        OnSetEDocumentService(NewEDocumentService);
    end;

    /// <summary>
    /// Returns whether an instance is bound on the active session and call stack AND a non-blank
    /// E-Document Service was pushed into it. Report extensions gate their service read on this, so
    /// a plain print, a context that was started but never set, and a blank push all leave the
    /// legacy FindLast lookup in "Export ZUGFeRD Document" intact.
    /// </summary>
    procedure HasContext() Result: Boolean
    begin
        OnHasContext(Result);
    end;

    /// <summary>
    /// Returns the E-Document Service pushed by the format via <see cref="SetEDocumentService"/> on
    /// the active bound instance, or a blank record when no context is bound.
    /// </summary>
    procedure GetEDocumentService(var EDocumentService: Record "E-Document Service")
    begin
        OnGetEDocumentService(EDocumentService);
    end;

    #region Internal pub/sub bridge - the bound instance captures writes and answers reads
    [IntegrationEvent(false, false)]
    local procedure OnSetEDocumentService(NewEDocumentService: Record "E-Document Service")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnHasContext(var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetEDocumentService(var EDocumentService: Record "E-Document Service")
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"ZUGFeRD Export Context", OnSetEDocumentService, '', false, false)]
    local procedure SubOnSetEDocumentService(NewEDocumentService: Record "E-Document Service")
    begin
        // Refuse a blank service: accepting it would make HasContext report true and suppress the
        // legacy FindLast fallback while carrying nothing usable.
        if NewEDocumentService.Code = '' then
            exit;
        EDocumentServiceValue := NewEDocumentService;
        EDocumentServiceIsSet := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"ZUGFeRD Export Context", OnHasContext, '', false, false)]
    local procedure SubOnHasContext(var Result: Boolean)
    begin
        // "Bound" alone is not enough - only report true once a real service was pushed.
        Result := EDocumentServiceIsSet;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"ZUGFeRD Export Context", OnGetEDocumentService, '', false, false)]
    local procedure SubOnGetEDocumentService(var EDocumentService: Record "E-Document Service")
    begin
        EDocumentService := EDocumentServiceValue;
    end;
    #endregion
}
