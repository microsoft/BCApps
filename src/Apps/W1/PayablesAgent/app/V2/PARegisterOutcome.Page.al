// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

#pragma warning disable AS0007
namespace Microsoft.Agent.PayablesAgent;

using Microsoft.Purchases.Document;

/// <summary>
/// Registers the purchase document that a Payables Agent v2 task produced as the task outcome.
/// </summary>
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
                OptionCaption = 'Purchase Invoice,Purchase Order,Purchase Credit Memo';

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
                var
                    PurchaseHeader: Record "Purchase Header";
                begin
                    if DocumentNo <> '' then
                        GetPurchaseHeader(PurchaseHeader);
                end;

                trigger OnLookup(var Text: Text): Boolean
                var
                    PurchaseHeader: Record "Purchase Header";
                begin
                    PurchaseHeader.SetRange("Document Type", GetDocumentType());
                    if Page.RunModal(0, PurchaseHeader) <> Action::LookupOK then
                        exit(false);
                    Text := PurchaseHeader."No.";
                    exit(true);
                end;
            }
        }
    }

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        PurchaseHeader: Record "Purchase Header";
        PATaskMgt: Codeunit "PA Task Mgt.";
    begin
        if CloseAction <> Action::OK then
            exit(true);

        GetPurchaseHeader(PurchaseHeader);
        if not PayablesAgentTask.Get(PayablesAgentTask."Entry No.") then
            Error(TaskNotFoundErr);
        PATaskMgt.RegisterOutcome(PayablesAgentTask, PurchaseHeader.RecordId);
        exit(true);
    end;

    procedure SetTask(NewPayablesAgentTask: Record "Payables Agent Task")
    begin
        PayablesAgentTask := NewPayablesAgentTask;
    end;

    local procedure GetPurchaseHeader(var PurchaseHeader: Record "Purchase Header")
    begin
        if not PurchaseHeader.Get(GetDocumentType(), DocumentNo) then
            Error(DocumentNotFoundErr, SelectStr(RecordType + 1, RecordTypeTxt), DocumentNo);
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

    var
        PayablesAgentTask: Record "Payables Agent Task";
        RecordType: Option "Purchase Invoice","Purchase Order","Purchase Credit Memo";
        DocumentNo: Code[20];
        RecordTypeTxt: Label 'Purchase Invoice,Purchase Order,Purchase Credit Memo';
        DocumentNotFoundErr: Label '%1 %2 does not exist.', Comment = '%1 = record type, such as Purchase Invoice, %2 = document number';
        TaskNotFoundErr: Label 'The task to register the outcome for does not exist.';
}
