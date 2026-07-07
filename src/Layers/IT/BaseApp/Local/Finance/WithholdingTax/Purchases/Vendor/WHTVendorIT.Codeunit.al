// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Vendor;

codeunit 12211 "WHT Vendor IT"
{

    [EventSubscriber(ObjectType::Table, Database::Vendor, 'OnAfterGetTaxCode', '', true, false)]
    local procedure OnAfterGetTaxCode(Rec: Record Vendor; var TaxCode: Code[20])
    begin
        if Rec."Fiscal Code" <> '' then
            TaxCode := Rec."Fiscal Code";
    end;
}