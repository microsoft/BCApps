// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Setup;

using Microsoft.Foundation.Company;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.Journal;

codeunit 99000790 "Mfg. Company Initialize"
{
    Permissions = tabledata "Manufacturing Setup" = i;

    var
        ConsumpJnlTxt: Label 'CONSUMPJNL', MaxLength = 10;
        OutputJnlTxt: Label 'POINOUTJNL', MaxLength = 10;
        CapacityJnlTxt: Label 'CAPACITJNL', MaxLength = 10;
        ProdOrderTxt: Label 'PRODORDER', MaxLength = 10;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Company-Initialize", 'OnAfterInitSetupTables', '', false, false)]
    local procedure OnAfterInitSetupTables()
    var
        ManufacturingSetup: Record "Manufacturing Setup";
    begin
        if not ManufacturingSetup.Get() then begin
            ManufacturingSetup.Init();
            ManufacturingSetup.Insert();
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Company-Initialize", 'OnBeforeSourceCodeSetupInsert', '', false, false)]
    local procedure OnBeforeSourceCodeSetupInsert(var SourceCodeSetup: Record "Source Code Setup"; sender: Codeunit "Company-Initialize")
    begin
        sender.InsertSourceCode(SourceCodeSetup."Consumption Journal", ConsumpJnlTxt, sender.PageName(Page::"Consumption Journal"));
        sender.InsertSourceCode(SourceCodeSetup."Output Journal", OutputJnlTxt, sender.PageName(Page::"Output Journal"));
        sender.InsertSourceCode(SourceCodeSetup."Production Journal", ProdOrderTxt, sender.PageName(Page::"Production Journal"));
        sender.InsertSourceCode(SourceCodeSetup."Capacity Journal", CapacityJnlTxt, sender.PageName(Page::"Capacity Journal"));
    end;
}
