// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats;

using Microsoft.eServices.EDocument;
using System.Utilities;

pageextension 10974 "E-Reporting E-Documents" extends "E-Documents"
{
    layout
    {
        addlast(DocumentList)
        {
            field("Clearance Date"; Rec."Clearance Date")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'E-Reporting Acceptance Date';
                ToolTip = 'Specifies the date and time when the e-reporting transaction was accepted by the tax authority.';
            }
        }
    }

    actions
    {
        addlast(Processing)
        {
            action(AcceptFREInvoice)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Accept E-Invoice';
                Image = Approve;
                ToolTip = 'Accept the incoming French electronic purchase invoice and send the response to the supplier.';
                Visible = (Rec.Direction = Rec.Direction::Incoming) and (Rec."Document Type" = Rec."Document Type"::"Purchase Invoice");

                trigger OnAction()
                var
                    FREInvoiceBuyerResponseMgt: Codeunit "FR E-Inv. Buyer Resp. Mgt.";
                begin
                    FREInvoiceBuyerResponseMgt.AcceptInvoice(Rec);
                    CurrPage.Update(false);
                end;
            }
            action(RefuseFREInvoice)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Refuse E-Invoice';
                Image = Reject;
                ToolTip = 'Refuse the incoming French electronic purchase invoice and send the response to the supplier.';
                Visible = (Rec.Direction = Rec.Direction::Incoming) and (Rec."Document Type" = Rec."Document Type"::"Purchase Invoice");

                trigger OnAction()
                var
                    FREInvoiceBuyerResponseMgt: Codeunit "FR E-Inv. Buyer Resp. Mgt.";
                    FREInvoiceRefusalDialog: Page "FR E-Invoice Refusal Dialog";
                    ReasonCode: Code[20];
                    ReasonDescription: Text[500];
                begin
                    if FREInvoiceRefusalDialog.RunModal() <> Action::OK then
                        exit;
                    FREInvoiceRefusalDialog.GetReason(ReasonCode, ReasonDescription);
                    FREInvoiceBuyerResponseMgt.RefuseInvoice(Rec, ReasonCode, ReasonDescription);
                    CurrPage.Update(false);
                end;
            }
            action(ImportFREInvoiceLifecycleResponse)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Import E-Invoice Lifecycle Response';
                Image = Import;
                ToolTip = 'Import a French electronic invoice lifecycle response for this e-document.';

                trigger OnAction()
                var
                    FREInvoiceLifecycleImport: Codeunit "FR E-Invoice Lifecycle Import";
                    TempBlob: Codeunit "Temp Blob";
                    InStream: InStream;
                    OutStream: OutStream;
                    FileName: Text;
                    ResponseEntryNo: Integer;
                begin
                    Rec.TestField(Direction, Rec.Direction::Outgoing);
                    if not UploadIntoStream(ImportResponseDialogTitleLbl, '', XmlFileFilterTxt, FileName, InStream) then
                        exit;

                    TempBlob.CreateOutStream(OutStream);
                    CopyStream(OutStream, InStream);
                    ResponseEntryNo := FREInvoiceLifecycleImport.ImportResponse(Rec, TempBlob);
                    Message(ResponseImportedMsg, ResponseEntryNo);
                    CurrPage.Update(false);
                end;
            }
            action(ViewFREInvoiceLifecycles)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'E-Invoice Lifecycles';
                Image = History;
                ToolTip = 'View French electronic invoice lifecycle occurrences for this e-document.';

                trigger OnAction()
                var
                    FREInvoiceLifecycle: Record "FR E-Invoice Lifecycle";
                begin
                    FREInvoiceLifecycle.SetCurrentKey("E-Document Entry No.", "Created At");
                    FREInvoiceLifecycle.SetRange("E-Document Entry No.", Rec."Entry No");
                    Page.Run(Page::"FR E-Invoice Lifecycles", FREInvoiceLifecycle);
                end;
            }
            action(ViewFREInvoiceLifecycleResponses)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'E-Invoice Lifecycle Responses';
                Image = History;
                ToolTip = 'View French electronic invoice lifecycle responses for this e-document.';

                trigger OnAction()
                var
                    FREInvoiceLifecycleResponse: Record "FR E-Invoice Lifecycle Resp.";
                begin
                    FREInvoiceLifecycleResponse.SetCurrentKey("E-Document Entry No.", "Received At");
                    FREInvoiceLifecycleResponse.SetRange("E-Document Entry No.", Rec."Entry No");
                    Page.Run(Page::"FR E-Inv. Lifecycle Responses", FREInvoiceLifecycleResponse);
                end;
            }
            action(ViewFREInvoiceBuyerResponses)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'E-Invoice Buyer Responses';
                Image = History;
                ToolTip = 'View French buyer responses for this e-document.';

                trigger OnAction()
                var
                    FREInvoiceBuyerResponse: Record "FR E-Invoice Buyer Response";
                begin
                    FREInvoiceBuyerResponse.SetRange("E-Document Entry No.", Rec."Entry No");
                    Page.Run(Page::"FR E-Inv. Buyer Responses", FREInvoiceBuyerResponse);
                end;
            }
        }
    }

    var
        ImportResponseDialogTitleLbl: Label 'Select a French e-invoice lifecycle response';
        XmlFileFilterTxt: Label 'XML files (*.xml)|*.xml', Locked = true;
        ResponseImportedMsg: Label 'French e-invoice lifecycle response %1 was imported.', Comment = '%1 = lifecycle response entry number';
}
