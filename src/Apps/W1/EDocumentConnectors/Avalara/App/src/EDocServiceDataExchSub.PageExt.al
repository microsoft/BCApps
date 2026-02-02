/// <summary>
/// Extends E-Document Service Data Exchange Subpage with Avalara-specific field mapping.
/// Adds AssistEdit to Document Type field to configure mandate-specific input fields.
/// </summary>
pageextension 6374 "E-Doc. Service Data Exch. Sub" extends "E-Doc. Service Data Exch. Sub"
{
    layout
    {
        modify("Document Type")
        {
            AssistEdit = true;

            trigger OnAssistEdit()
            var
                EDocService: Record "E-Document Service";
                AvalaraInputFieldsPage: Page "Avalara Input Fields";
                MandateType: Text;
            begin
                if not IsAvalaraService() then
                    exit;

                if not EDocService.Get(Rec."E-Document Format Code") then
                    exit;

                if EDocService."Avalara Mandate" = '' then
                    Error(MandateNotConfiguredErr);

                MandateType := GetMandateTypeForDocument(Rec."Document Type");
                if MandateType = '' then
                    exit; // Document type not supported for Avalara

                AvalaraInputFieldsPage.SetFilterByMandate(EDocService."Avalara Mandate", MandateType);
                AvalaraInputFieldsPage.RunModal();
            end;
        }
    }

    var
        MandateNotConfiguredErr: Label 'Avalara mandate is not configured for this E-Document service.';
        UBLCreditNoteTxt: Label 'ubl-creditnote', Locked = true;
        UBLInvoiceTxt: Label 'ubl-invoice', Locked = true;

    /// <summary>
    /// Checks if the current service is configured for Avalara.
    /// </summary>
    /// <returns>True if the service has an Avalara mandate configured.</returns>
    local procedure IsAvalaraService(): Boolean
    var
        EDocService: Record "E-Document Service";
    begin
        if EDocService.Get(Rec."E-Document Format Code") then
            exit(EDocService."Avalara Mandate" <> '');
        exit(false);
    end;

    /// <summary>
    /// Returns the appropriate mandate type string based on the document type.
    /// </summary>
    /// <param name="DocumentType">The E-Document type to get mandate for.</param>
    /// <returns>Mandate type identifier ('ubl-invoice' or 'ubl-creditnote'), or empty string if not supported.</returns>
    local procedure GetMandateTypeForDocument(DocumentType: Enum "E-Document Type"): Text
    begin
        case DocumentType of
            DocumentType::"Sales Credit Memo",
            DocumentType::"Purchase Credit Memo":
                exit(UBLCreditNoteTxt);
            DocumentType::"Sales Invoice",
            DocumentType::"Purchase Invoice":
                exit(UBLInvoiceTxt);
            else
                exit(''); // Unsupported document type
        end;
    end;
}
