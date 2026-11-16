// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.TaxEngine.JsonExchange;

codeunit 18009 "Cess Use Case Setup"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Tax Engine Assisted Setup", 'OnSetupUseCases', '', false, false)]
    local procedure OnSetupUseCases()
    var
        TaxJsonDeserialization: Codeunit "Tax Json Deserialization";
        ImportGSTUseCase: Codeunit "Import GST Use Case";
    begin
        if not GuiAllowed then
            TaxJsonDeserialization.HideDialog(true);

        ImportGSTUseCase.ImportUseCases(ImportGSTUseCase.GetResourceForUseCase(GSTCessResFileLbl));
    end;


    var
        GSTCessResFileLbl: Label 'GSTCESS', MaxLength = 20;
}
