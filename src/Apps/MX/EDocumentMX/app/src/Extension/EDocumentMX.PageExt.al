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
}
