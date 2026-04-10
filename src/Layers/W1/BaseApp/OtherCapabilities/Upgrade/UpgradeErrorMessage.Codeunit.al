// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Upgrade;

using System.Upgrade;
using System.Utilities;

codeunit 104055 "Upgrade - Error Message"
{
    Subtype = Upgrade;

    trigger OnUpgradePerCompany()
    begin
        UpdateErrorMessageDescription();
        UpdateErrorMessageRegisterDescription();
    end;

    local procedure UpdateErrorMessageDescription()
    var
        ErrorMessage: Record "Error Message";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        ErrorMessageDataTransfer: DataTransfer;
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetErrorMessageDescriptionUpgradeTag()) then
            exit;

        ErrorMessageDataTransfer.SetTables(Database::"Error Message", Database::"Error Message");
        ErrorMessageDataTransfer.AddFieldValue(ErrorMessage.FieldNo(Description), ErrorMessage.FieldNo(Message));
        ErrorMessageDataTransfer.CopyFields();

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetErrorMessageDescriptionUpgradeTag());
    end;

    local procedure UpdateErrorMessageRegisterDescription()
    var
        ErrorMessageRegister: Record "Error Message Register";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        ErrorMessageRegisterDataTransfer: DataTransfer;
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetErrorMessageRegisterDescriptionUpgradeTag()) then
            exit;

        ErrorMessageRegisterDataTransfer.SetTables(Database::"Error Message Register", Database::"Error Message Register");
        ErrorMessageRegisterDataTransfer.AddFieldValue(ErrorMessageRegister.FieldNo(Description), ErrorMessageRegister.FieldNo(Message));
        ErrorMessageRegisterDataTransfer.CopyFields();

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetErrorMessageRegisterDescriptionUpgradeTag());
    end;

}