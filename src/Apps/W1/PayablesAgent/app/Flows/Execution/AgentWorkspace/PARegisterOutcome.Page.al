// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;

page 3334 "PA Register Outcome"
{
    Caption = 'Register Outcome';
    PageType = StandardDialog;
    ApplicationArea = All;
    UsageCategory = None;
    Extensible = false;
    InherentEntitlements = X;
    InherentPermissions = X;

    layout
    {
        area(Content)
        {
            field(RecordType; RecordType)
            {
                Caption = 'Record Type';
                ToolTip = 'Specifies the type of purchase document that is the outcome of the task.';
                OptionCaption = 'Purchase Invoice,Purchase Order,Purchase Credit Memo,Posted Purchase Invoice,Posted Purchase Credit Memo';
                trigger OnValidate()
                begin
                    DocumentNo := '';
                end;
            }
            field(DocumentNo; DocumentNo)
            {
                Caption = 'No.';
                ToolTip = 'Specifies the number of the purchase document that is the outcome of the task.';
                trigger OnValidate()
                begin
                    if DocumentNo <> '' then
                        GetOutcome();
                end;
                trigger OnLookup(var Text: Text): Boolean
                var
                    PurchaseHeader: Record "Purchase Header";
                    PostedInvoice: Record "Purch. Inv. Header";
                    PostedCreditMemo: Record "Purch. Cr. Memo Hdr.";
                begin
                    case RecordType of
                        RecordType::"Posted Purchase Invoice":
                            begin
                                if Page.RunModal(0, PostedInvoice) <> Action::LookupOK then
                                    exit(false);
                                Text := PostedInvoice."No.";
                            end;
                        RecordType::"Posted Purchase Credit Memo":
                            begin
                                if Page.RunModal(0, PostedCreditMemo) <> Action::LookupOK then
                                    exit(false);
                                Text := PostedCreditMemo."No.";
                            end;
                        else begin
                            PurchaseHeader.SetRange("Document Type", GetDocumentType());
                            if Page.RunModal(0, PurchaseHeader) <> Action::LookupOK then
                                exit(false);
                            Text := PurchaseHeader."No.";
                        end;
                    end;
                    exit(true);
                end;
            }
        }
    }

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction = Action::OK then
            Task.RegisterOutcome(GetOutcome());
        exit(true);
    end;

    var
        Task: Codeunit "Payables Agent Task";
        TaskNotFoundErr: Label 'The task does not exist.';
        RecordType: Option "Purchase Invoice","Purchase Order","Purchase Credit Memo","Posted Purchase Invoice","Posted Purchase Credit Memo";
        DocumentNo: Code[20];
        DocumentNotFoundErr: Label 'The selected purchase document %1 does not exist.', Comment = '%1 = document number';

    internal procedure SetTask(NewTask: Codeunit "Payables Agent Task")
    begin
        if not Task.Load(NewTask.GetAgentTaskId()) then
            Error(TaskNotFoundErr);
    end;

    local procedure GetOutcome(): RecordId
    var
        PurchaseHeader: Record "Purchase Header";
        PostedInvoice: Record "Purch. Inv. Header";
        PostedCreditMemo: Record "Purch. Cr. Memo Hdr.";
    begin
        case RecordType of
            RecordType::"Posted Purchase Invoice":
                if PostedInvoice.Get(DocumentNo) then
                    exit(PostedInvoice.RecordId());
            RecordType::"Posted Purchase Credit Memo":
                if PostedCreditMemo.Get(DocumentNo) then
                    exit(PostedCreditMemo.RecordId());
            else
                if PurchaseHeader.Get(GetDocumentType(), DocumentNo) then
                    exit(PurchaseHeader.RecordId());
        end;
        Error(DocumentNotFoundErr, DocumentNo);
    end;

    local procedure GetDocumentType(): Enum "Purchase Document Type"
    begin
        case RecordType of
            RecordType::"Purchase Order":
                exit("Purchase Document Type"::Order);
            RecordType::"Purchase Credit Memo":
                exit("Purchase Document Type"::"Credit Memo");
            else
                exit("Purchase Document Type"::Invoice);
        end;
    end;
}
