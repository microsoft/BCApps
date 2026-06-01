namespace Microsoft.SubscriptionBilling;

using System.IO;
using System.Utilities;

codeunit 8115 "Create Sub. Bill. Gen. Sett."
{
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions =
        tabledata "Data Exch." = rd,
        tabledata "Sub. Billing Module Setup" = r;

    trigger OnRun()
    var
        SubBillingModuleSetup: Record "Sub. Billing Module Setup";
        ContosoSubscriptionBilling: Codeunit "Contoso Subscription Billing";
        CreateSubBillSupplier: Codeunit "Create Sub. Bill. Supplier";
    begin
        SubBillingModuleSetup.Get();
        if SubBillingModuleSetup."Import Data Exch. Definition" then begin
            ImportGenericDataExchangeDefinition();
            ContosoSubscriptionBilling.InsertGenericImportSettings(CreateSubBillSupplier.Generic(), UsageDataGenericUsTok, false, true, Enum::"Additional Processing Type"::None, false);
        end else
            ContosoSubscriptionBilling.InsertGenericImportSettings(CreateSubBillSupplier.Generic(), '', false, true, Enum::"Additional Processing Type"::None, false);
    end;

    local procedure ImportGenericDataExchangeDefinition()
    var
        DataExchDef: Record "Data Exch. Def";
        TempBlob: Codeunit "Temp Blob";
        XMLOutStream: OutStream;
        XMLInStream: InStream;
    begin

        if DataExchDef.Get(UsageDataGenericUsTok) then
            DataExchDef.Delete(true);

        TempBlob.CreateOutStream(XMLOutStream);
        XMLOutStream.WriteText(NavApp.GetResourceAsText('USAGE-GENERIC-US.xml', TextEncoding::UTF8));
        TempBlob.CreateInStream(XMLInStream);
        Xmlport.Import(Xmlport::"Imp / Exp Data Exch Def & Map", XMLInStream);
        Clear(TempBlob);
    end;

    var
        UsageDataGenericUsTok: Label 'USAGE-GENERIC-US', Locked = true;
}