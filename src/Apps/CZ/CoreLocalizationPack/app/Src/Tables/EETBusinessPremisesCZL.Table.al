// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance;

using System.Security.Encryption;
using System.Utilities;

table 31126 "EET Business Premises CZL"
{
    Caption = 'EET Registrating Unit';
    LookupPageId = "EET Business Premises CZL";
    DataClassification = OrganizationIdentifiableInformation;

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
            ToolTip = 'Specifies the code of the registrating unit. The code is used only in Business Central, the number that is sent to the EET service is specified in the Unit ID field.';
        }
        field(2; Description; Text[50])
        {
            Caption = 'Description';
            ToolTip = 'Specifies the description of the registrating unit.';
        }
        field(15; Identification; Code[6])
        {
            Caption = 'Identification';
            Numeric = true;
            ToolTip = 'Specifies the identification number of the registrating unit that was used in the EET system version 1.0. The field is replaced by the Unit ID field and it is no longer sent to the EET service.';
        }
        field(16; "Unit ID"; Code[20])
        {
            Caption = 'Unit ID';
            Numeric = true;
            ToolTip = 'Specifies the identification number of the registrating unit that is assigned by the tax authority and sent in the data message. The number must be in the range from 1 to 999999999.';
        }
        field(17; "Certificate Code"; Code[10])
        {
            Caption = 'Certificate Code';
            TableRelation = "Certificate Code CZL";
            ToolTip = 'Specifies the certificate used to sign the data messages of this registrating unit. Leave it blank to use the certificate from the EET service setup. The certificate must be issued to the taxpayer specified on this registrating unit.';
        }
        field(30; "Taxpayer ID"; Code[20])
        {
            Caption = 'Taxpayer ID';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the registered identification number of the taxpayer who owns this registrating unit. Leave it blank if the registrating unit is your own.';
        }
        field(35; "Authorizing Taxpayer ID"; Code[20])
        {
            Caption = 'Authorizing Taxpayer ID';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the registered identification number of the taxpayer authorizing you to report sales. Leave it blank to report your own sales. The value is only copied to new cash registers of this registrating unit, it is not applied to existing ones.';
        }
        field(36; "Multiple Taxpayer Auth."; Boolean)
        {
            Caption = 'Multiple Taxpayer Authorization';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies whether the transaction is recorded on behalf of multiple taxpayers. The value is only copied to new cash registers of this registrating unit, it is not applied to existing ones.';
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    trigger OnInsert()
    var
        EETServiceSetupCZL: Record "EET Service Setup CZL";
    begin
        if EETServiceSetupCZL.Get() then begin
            "Authorizing Taxpayer ID" := EETServiceSetupCZL."Authorizing Taxpayer ID";
            "Multiple Taxpayer Auth." := EETServiceSetupCZL."Multiple Taxpayer Auth.";
        end;
    end;

    trigger OnDelete()
    var
        EETEntryCZL: Record "EET Entry CZL";
        EETCashRegisterCZL: Record "EET Cash Register CZL";
        ConfirmManagement: Codeunit "Confirm Management";
        EntryExistsErr: Label 'You cannot delete %1 %2 because there is at least one EET entry.', Comment = '%1 = Table Caption;%2 = Primary Key';
        CashRegExistsQst: Label 'Do you really want to delete %1 %2, even if at least one cash register exists?', Comment = '%1 = Table Caption;%2 = Primary Key';
    begin
        EETEntryCZL.SetCurrentKey("Business Premises Code", "Cash Register Code");
        EETEntryCZL.SetRange("Business Premises Code", Code);
        if not EETEntryCZL.IsEmpty then
            Error(EntryExistsErr, TableCaption, Code);

        EETCashRegisterCZL.SetRange("Business Premises Code", Code);
        if not EETCashRegisterCZL.IsEmpty then
            if ConfirmManagement.GetResponseOrDefault(StrSubstNo(CashRegExistsQst, TableCaption, Code), true) then
                EETCashRegisterCZL.DeleteAll(true);
    end;
}

