// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT;

using Microsoft.Finance.VAT.RateChange;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Manufacturing.MachineCenter;

codeunit 99000775 "Mfg. VAT Rate Change Mgt."
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"VAT Rate Change Conversion", 'OnAfterUpdateTables', '', false, false)]
    local procedure OnAfterUpdateTables(var VATRateChangeSetup: Record "VAT Rate Change Setup"; sender: Codeunit "VAT Rate Change Conversion")
    begin
        sender.UpdateTable(
          Database::"Production Order",
          sender.ConvertVATProdPostGrp(VATRateChangeSetup."Update Production Orders"), sender.ConvertGenProdPostGrp(VATRateChangeSetup."Update Production Orders"));
        sender.UpdateTable(
          Database::"Work Center",
          sender.ConvertVATProdPostGrp(VATRateChangeSetup."Update Work Centers"), sender.ConvertGenProdPostGrp(VATRateChangeSetup."Update Work Centers"));
        sender.UpdateTable(
          Database::"Machine Center",
          sender.ConvertVATProdPostGrp(VATRateChangeSetup."Update Machine Centers"), sender.ConvertGenProdPostGrp(VATRateChangeSetup."Update Machine Centers"));
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"VAT Rate Change Conversion", 'OnAfterAreTablesSelected', '', false, false)]
    local procedure OnAfterAreTablesSelected(var VATRateChangeSetup: Record "VAT Rate Change Setup"; var Result: Boolean)
    begin
        if VATRateChangeSetup."Update Production Orders" <> VATRateChangeSetup."Update Production Orders"::No then
            Result := true;
        if VATRateChangeSetup."Update Work Centers" <> VATRateChangeSetup."Update Work Centers"::No then
            Result := true;
        if VATRateChangeSetup."Update Machine Centers" <> VATRateChangeSetup."Update Machine Centers"::No then
            Result := true;
    end;
}
