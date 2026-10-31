namespace Microsoft.Agent.PayablesAgent;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Processing.Import;

codeunit 3320 "PA Draft Based Setup"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        PayablesAgentEDocServiceTok: Label 'AGENT', Locked = true;


    procedure GetOrCreateAgentEDocumentService() EDocumentService: Record "E-Document Service"
    var
        EDocServiceSupportedType: Record "E-Doc. Service Supported Type";
    begin
        if not EDocumentService.Get(PayablesAgentEDocServiceTok) then begin
            EDocumentService.Code := PayablesAgentEDocServiceTok;
            EDocumentService.Insert(true);
        end;
        EDocServiceSupportedType.InsertDefaultIfMissing(EDocumentService.Code, "E-Document Type"::"Purchase Invoice", "E-Doc. Supp. Type Direction"::Incoming);
        EDocServiceSupportedType.InsertDefaultIfMissing(EDocumentService.Code, "E-Document Type"::"Purchase Credit Memo", "E-Doc. Supp. Type Direction"::Incoming);
    end;

    procedure AllowCreditMemosOnAgentEDocumentService()
    var
        EDocumentService: Record "E-Document Service";
        EDocServiceSupportedType: Record "E-Doc. Service Supported Type";
    begin
        if EDocumentService.Get(PayablesAgentEDocServiceTok) then
            EDocServiceSupportedType.InsertDefaultIfMissing(EDocumentService.Code, "E-Document Type"::"Purchase Credit Memo", "E-Doc. Supp. Type Direction"::Incoming);
    end;

    procedure OpenAdditionalFieldsSetup(): Boolean
    var
        EDocAdditionalFieldsSetup: Page "EDoc Additional Fields Setup";
    begin
        EDocAdditionalFieldsSetup.SetEDocumentService(GetOrCreateAgentEDocumentService());
        Commit();
        EDocAdditionalFieldsSetup.LookupMode := true;
        exit(EDocAdditionalFieldsSetup.RunModal() = Action::LookupOK);
    end;
}