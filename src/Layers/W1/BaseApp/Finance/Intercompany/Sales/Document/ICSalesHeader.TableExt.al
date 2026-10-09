// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

using Microsoft.Intercompany;
using Microsoft.Intercompany.Partner;
using Microsoft.Intercompany.Setup;
using System.Automation;

/// <summary>
/// Extends Sales Header with Intercompany-specific fields and logic.
/// </summary>
tableextension 8479 ICSalesHeader extends "Sales Header"
{
    fields
    {
        /// <summary>
        /// Indicates whether an intercompany document should be sent to the IC partner.
        /// </summary>
        field(123; "Send IC Document"; Boolean)
        {
            Caption = 'Send IC Document';
            DataClassification = CustomerContent;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateSendICDocument(Rec, xRec, IsHandled);
                if IsHandled then
                    exit;

                if "Send IC Document" then begin
                    if "Bill-to IC Partner Code" = '' then
                        TestField("Sell-to IC Partner Code");
                    IsHandled := false;
                    OnValidateSendICDocumentOnBeforeCheckICDirection(Rec, IsHandled);
                    if not IsHandled then
                        TestField("IC Direction", "IC Direction"::Outgoing);
                end;
            end;
        }
        /// <summary>
        /// Specifies the intercompany processing status of the document.
        /// </summary>
        field(124; "IC Status"; Enum Microsoft.Intercompany.Setup."Sales Document IC Status")
        {
            Caption = 'IC Status';
            DataClassification = CustomerContent;
        }
        /// <summary>
        /// Specifies the intercompany partner code of the sell-to customer.
        /// </summary>
        field(125; "Sell-to IC Partner Code"; Code[20])
        {
            Caption = 'Sell-to IC Partner Code';
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = "IC Partner";
        }
        /// <summary>
        /// Specifies the intercompany partner code of the bill-to customer.
        /// </summary>
        field(126; "Bill-to IC Partner Code"; Code[20])
        {
            Caption = 'Bill-to IC Partner Code';
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = "IC Partner";
        }
        /// <summary>
        /// Specifies the document number from the intercompany partner.
        /// </summary>
        field(127; "IC Reference Document No."; Code[20])
        {
            Caption = 'IC Reference Document No.';
            DataClassification = CustomerContent;
            Editable = false;
        }
        /// <summary>
        /// Specifies whether this is an outgoing or incoming intercompany document.
        /// </summary>
        field(129; "IC Direction"; Enum "IC Direction Type")
        {
            Caption = 'IC Direction';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                if "IC Direction" = "IC Direction"::Incoming then
                    "Send IC Document" := false;
            end;
        }
    }

    /// <summary>
    /// Sends filtered sales documents to intercompany partners through the IC inbox/outbox.
    /// </summary>
    /// <param name="SalesHeader">Specifies the filtered sales header records to send.</param>
    procedure SendICSalesDoc(var SalesHeader: Record "Sales Header")
    var
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        ICInOutboxMgt: Codeunit ICInboxOutboxMgt;
    begin
        if SalesHeader.FindSet() then
            repeat
                if ApprovalsMgmt.PrePostApprovalCheckSales(SalesHeader) then
                    ICInOutboxMgt.SendSalesDoc(SalesHeader, false);
            until SalesHeader.Next() = 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateSendICDocument(var SalesHeader: Record "Sales Header"; xSalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateSendICDocumentOnBeforeCheckICDirection(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;
}
