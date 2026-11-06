namespace Microsoft.Agent.PayablesAgent;

using Microsoft.eServices.EDocument.Processing.Import;

codeunit 3320 "PA Draft Based Setup"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure AllowCreditMemosOnAgentEDocumentService()
    var
        DraftBasedSetupStore: Codeunit "PA Draft Based Setup Store";
    begin
        DraftBasedSetupStore.AllowCreditMemos();
    end;

    procedure OpenAdditionalFieldsSetup(): Boolean
    var
        DraftBasedSetupStore: Codeunit "PA Draft Based Setup Store";
        EDocAdditionalFieldsSetup: Page "EDoc Additional Fields Setup";
    begin
        EDocAdditionalFieldsSetup.SetEDocumentService(DraftBasedSetupStore.GetOrCreateService());
        Commit();
        EDocAdditionalFieldsSetup.LookupMode := true;
        exit(EDocAdditionalFieldsSetup.RunModal() = Action::LookupOK);
    end;
}