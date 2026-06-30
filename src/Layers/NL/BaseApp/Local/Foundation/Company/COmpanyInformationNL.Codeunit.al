// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Company;

using Microsoft.Utilities;

codeunit 11361 "Company Information NL"
{

    [EventSubscriber(ObjectType::Table, Database::"Company Information", 'OnAfterValidateEvent', 'Bank Account No.', false, false)]
    local procedure OnAfterValidateEventBankAccountNo(var Rec: Record "Company Information"; var xRec: Record "Company Information")
    begin
        if not LocalFunctionalityMgt.CheckBankAccNo(Rec."Bank Account No.", Rec."Country/Region Code", Rec."Bank Account No.") then
            Message(IncorrectAccountNoMsg, Rec."Bank Account No.");
    end;

    var
        LocalFunctionalityMgt: Codeunit "Local Functionality Mgt.";
        IncorrectAccountNoMsg: Label 'Bank Account No. %1 may be incorrect.', Comment = '%1 - Bank Account No.';
}