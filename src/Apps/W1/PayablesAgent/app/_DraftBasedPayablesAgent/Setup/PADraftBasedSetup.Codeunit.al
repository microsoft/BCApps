namespace Microsoft.Agent.PayablesAgent;

using Microsoft.eServices.EDocument;

codeunit 3320 "PA Draft Based Setup"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure GetOrCreateAgentEDocumentService() EDocumentService: Record "E-Document Service"
    var
        EDocServiceSupportedType: Record "E-Doc. Service Supported Type";
    begin
        if not EDocumentService.Get(PayablesAgentEDocServiceTok) then begin
            EDocumentService.Code := PayablesAgentEDocServiceTok;
            EDocumentService.Insert(true);

            EDocServiceSupportedType.Init();
            EDocServiceSupportedType."E-Document Service Code" := EDocumentService.Code;
            EDocServiceSupportedType."Source Document Type" := EDocServiceSupportedType."Source Document Type"::"Purchase Invoice";
            EDocServiceSupportedType.Direction := EDocServiceSupportedType.Direction::Incoming;
            EDocServiceSupportedType.Insert(false);
        end;
    end;

    var
        PayablesAgentEDocServiceTok: Label 'AGENT', Locked = true;

}