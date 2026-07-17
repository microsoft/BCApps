namespace Microsoft.eServices.EDocument.RemittanceAdvice;

using Microsoft.eServices.EDocument;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Reports;

reportextension 6101 "E-Doc. Remit. Advice Entries" extends "Remittance Advice - Entries"
{
    dataset
    {
        modify("Vendor Ledger Entry")
        {
            trigger OnAfterAfterGetRecord()
            var
                EDocument: Record "E-Document";
                RecRef: RecordRef;
                AllowReExport: Boolean;
            begin
                if not CreateEDocuments then
                    exit;

                RecRef.GetTable("Vendor Ledger Entry");
                AllowReExport := false;
                if EDocRemittanceAdviceMgt.FindEDocument(EDocument, RecRef) then begin
                    if not GuiAllowed() then
                        exit;
                    if not Confirm(ReExportConfirmQst) then
                        exit;
                    AllowReExport := true;
                end;

                EDocRemitAdviceExport.ExportFromPostedPayment("Vendor Ledger Entry", AllowReExport);
            end;
        }
    }

    requestpage
    {
        layout
        {
            addlast(Content)
            {
                group(ElectronicDocument)
                {
                    Caption = 'Electronic Document';

                    field(CreateEDocuments; CreateEDocuments)
                    {
                        ApplicationArea = All;
                        Caption = 'Create E-Documents';
                        ToolTip = 'Specifies that an electronic document is created for each payment on the report when it is run.';
                    }
                }
            }
        }
    }

    var
        EDocRemittanceAdviceMgt: Codeunit "E-Doc. Remittance Advice Mgt.";
        EDocRemitAdviceExport: Codeunit "E-Doc. Remit. Advice Export";
        CreateEDocuments: Boolean;
        ReExportConfirmQst: Label 'An e-document was already created for this payment. Create again?';
}
