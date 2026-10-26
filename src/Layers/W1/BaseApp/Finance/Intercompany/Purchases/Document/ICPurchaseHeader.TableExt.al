// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Document;

using Microsoft.Intercompany;
using Microsoft.Intercompany.Partner;
using System.Automation;

tableextension 8445 "IC Purchase Header" extends "Purchase Header"
{
    fields
    {
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
                    TestField("Buy-from IC Partner Code");
                    TestField("IC Direction", "IC Direction"::Outgoing);
                end;
            end;
        }
        field(124; "IC Status"; Enum Microsoft.Intercompany.Setup."Purchase Document IC Status")
        {
            Caption = 'IC Status';
            DataClassification = CustomerContent;
        }
        field(125; "Buy-from IC Partner Code"; Code[20])
        {
            Caption = 'Buy-from IC Partner Code';
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = "IC Partner";
        }
        field(126; "Pay-to IC Partner Code"; Code[20])
        {
            Caption = 'Pay-to IC Partner Code';
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = "IC Partner";
        }
        field(127; "IC Reference Document No."; Code[20])
        {
            Caption = 'IC Reference Document No.';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(129; "IC Direction"; Enum Microsoft.Intercompany.Setup."IC Direction Type")
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

    procedure SendICPurchaseDoc(var PurchaseHeader: Record "Purchase Header")
    var
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        ICInOutboxMgt: Codeunit ICInboxOutboxMgt;
    begin
        if PurchaseHeader.FindSet() then
            repeat
                if ApprovalsMgmt.PrePostApprovalCheckPurch(PurchaseHeader) then
                    ICInOutboxMgt.SendPurchDoc(PurchaseHeader, false);
            until PurchaseHeader.Next() = 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateSendICDocument(var PurchaseHeader: Record "Purchase Header"; xPurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;
}