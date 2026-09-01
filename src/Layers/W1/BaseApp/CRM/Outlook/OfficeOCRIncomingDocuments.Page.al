// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Outlook;

using Microsoft.EServices.EDocument;

page 1626 "Office OCR Incoming Documents"
{
    Caption = 'Office Incoming Documents';
    DataCaptionExpression = PageCaptionTxt;
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = StandardDialog;
    SourceTable = "Exchange Object";
    SourceTableTemporary = true;
    SourceTableView = sorting(Name)
                      order(ascending);

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(Selected; Rec.Selected)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Send';

                    trigger OnValidate()
                    begin
                        if (IncomingDocumentAttachment."Document No. Filter" <> '') and (Rec.Count > 1) and Rec.Selected then begin
                            Rec.ModifyAll(Selected, false);
                            Rec.Selected := true;
                        end;
                    end;
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        if Rec.Count = 1 then begin
            Rec.Selected := true;
            Rec.Modify();
        end else
            if IncomingDocumentAttachment."Document No. Filter" <> '' then
                Rec.ModifyAll(Selected, false);
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        IncomingDocument: Record "Incoming Document";
    begin
        if CloseAction in [ACTION::OK, ACTION::LookupOK] then
            onSave(IncomingDocument);
    end;

    local procedure onSave(IncomingDocument: Record "Incoming Document"): Boolean
    begin
        Rec.SetRange(Selected, true);
        if Rec.FindSet() then begin
            repeat
                case Rec.InitiatedAction of
                    Rec.InitiatedAction::InitiateSendToIncomingDocuments:
                        OfficeMgt.SendToIncomingDocument(Rec, IncomingDocument, IncomingDocumentAttachment);
                    Rec.InitiatedAction::InitiateSendToOCR:
                        if OfficeMgt.SendToIncomingDocument(Rec, IncomingDocument, IncomingDocumentAttachment) then
                            OfficeMgt.SendToOCR(IncomingDocument);
                    Rec.InitiatedAction::InitiateSendToWorkFlow:
                        if OfficeMgt.SendToIncomingDocument(Rec, IncomingDocument, IncomingDocumentAttachment) then
                            OfficeMgt.SendApprovalRequest(IncomingDocument);
                end;
            until Rec.Next() = 0;
            OfficeMgt.DisplaySuccessMessage(Rec);
        end;
    end;

    var
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        OfficeMgt: Codeunit "Office Management";
        PageCaptionTxt: Label 'Select Attachment to Send';

    procedure InitializeIncomingDocumentAttachment(LinkedIncomingDocumentAttachment: Record "Incoming Document Attachment")
    begin
        IncomingDocumentAttachment := LinkedIncomingDocumentAttachment;
    end;

    procedure InitializeExchangeObject(var TempExchangeObject: Record "Exchange Object" temporary)
    begin
        if TempExchangeObject.FindSet() then
            repeat
                TempExchangeObject.CalcFields(Content);
                Rec.TransferFields(TempExchangeObject);
                Rec.Insert();
            until TempExchangeObject.Next() = 0;
    end;
}

