namespace Microsoft.Agent.PayablesAgent;

using Microsoft.eServices.EDocument.Processing.Import;

codeunit 3320 "PA Draft Based Setup"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure AllowCreditMemosOnAgentEDocumentService()
    var
        DraftBasedSetupBacking: Codeunit "PA Draft Based Setup Backing";
    begin
        DraftBasedSetupBacking.AllowCreditMemos();
    end;

    procedure OpenAdditionalFieldsSetup(): Boolean
    var
        DraftBasedSetupBacking: Codeunit "PA Draft Based Setup Backing";
        EDocAdditionalFieldsSetup: Page "EDoc Additional Fields Setup";
    begin
        EDocAdditionalFieldsSetup.SetEDocumentService(DraftBasedSetupBacking.GetOrCreateService());
        Commit();
        EDocAdditionalFieldsSetup.LookupMode := true;
        exit(EDocAdditionalFieldsSetup.RunModal() = Action::LookupOK);
    end;
}