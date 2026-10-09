// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument.Interfactura;

using Microsoft.eServices.EDocument;

pageextension 3364 "EDoc CFDI E-Document Ext" extends "E-Document"
{
    layout
    {
        addlast(ClearanceInfo)
        {
            field(FiscalInvoiceNumberPAC; FiscalInvoiceNumberPAC)
            {
                ApplicationArea = All;
                Caption = 'Fiscal Invoice Number PAC';
                Editable = false;
                ToolTip = 'Specifies the UUID assigned by SAT when the CFDI document was stamped (cleared).';
            }
        }
    }

    actions
    {
        addlast(Processing)
        {
            action(PrintCFDI)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Print CFDI';
                ToolTip = 'Prints the CFDI electronic document as a PDF.';
                Image = Print;
                Visible = Rec.Direction = Rec.Direction::Outgoing;

                trigger OnAction()
                var
                    EDocCFDIPrintMX: Codeunit "EDoc CFDI Print MX";
                begin
                    EDocCFDIPrintMX.PrintCFDI(Rec);
                end;
            }
            action(MarkAsCanceled)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Mark as Canceled';
                ToolTip = 'Manually marks this CFDI document as canceled in Business Central without contacting the PAC. Use this when the document is already canceled in SAT but the status has not been updated here.';
                Image = Cancel;
                Visible = Rec.Direction = Rec.Direction::Outgoing;

                trigger OnAction()
                var
                    EDocumentService: Record "E-Document Service";
                    EDocumentServiceStatus: Record "E-Document Service Status";
                    EDocumentProcessing: Codeunit "E-Document Processing";
                    EDocumentServices: Page "E-Document Services";
                begin
                    if not Confirm(MarkAsCanceledConfirmQst, false) then
                        exit;

                    EDocumentServiceStatus.SetRange("E-Document Entry No", Rec."Entry No");
                    case EDocumentServiceStatus.Count() of
                        0:
                            Error(NoLinkedServiceErr);
                        1:
                            begin
                                EDocumentServiceStatus.FindFirst();
                                EDocumentService.Get(EDocumentServiceStatus."E-Document Service Code");
                            end;
                        else begin
                            EDocumentServices.LookupMode := true;
                            if EDocumentServices.RunModal() <> Action::LookupOK then
                                exit;
                            EDocumentServices.GetRecord(EDocumentService);
                        end;
                    end;

                    EDocumentServiceStatus.Get(Rec."Entry No", EDocumentService.Code);
                    if not (EDocumentServiceStatus.Status in [
                        Enum::"E-Document Service Status"::Sent,
                        Enum::"E-Document Service Status"::"Pending Response",
                        Enum::"E-Document Service Status"::"Cancel Error"])
                    then
                        Error(InvalidStatusForMarkAsCanceledErr, EDocumentServiceStatus.Status);

                    EDocumentProcessing.ModifyServiceStatus(Rec, EDocumentService, Enum::"E-Document Service Status"::Canceled);
                    EDocumentProcessing.ModifyEDocumentStatus(Rec);
                    CurrPage.Update(false);
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        CFDIWriteBackMX: Codeunit "CFDI Write-Back MX";
    begin
        if Rec.Direction = Rec.Direction::Outgoing then
            FiscalInvoiceNumberPAC := CopyStr(CFDIWriteBackMX.GetUUIDForDocument(Rec."Document Record ID"), 1, MaxStrLen(FiscalInvoiceNumberPAC))
        else
            FiscalInvoiceNumberPAC := CopyStr(Rec."Source Details", 1, MaxStrLen(FiscalInvoiceNumberPAC));
    end;

    var
        FiscalInvoiceNumberPAC: Text[50];
        MarkAsCanceledConfirmQst: Label 'This will mark the document as Canceled in Business Central without contacting the PAC. Only use this if you have confirmed the document is already canceled in SAT. Do you want to continue?';
        NoLinkedServiceErr: Label 'No E-Document service is linked to this document.';
        InvalidStatusForMarkAsCanceledErr: Label 'The document cannot be marked as canceled because it has status %1. Only documents with status Sent, Pending Response, or Cancel Error can be manually marked as canceled.', Comment = '%1 = current service status';
}
