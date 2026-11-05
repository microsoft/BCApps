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
#if not CLEANSCHEMA33
        field(2; Description; Text[50])
        {
            Caption = 'Description';
            ToolTip = 'Specifies the description of the registrating unit.';
#if not CLEAN30
            ObsoleteState = Pending;
            ObsoleteTag = '30.0';
#else
            ObsoleteState = Removed;
            ObsoleteTag = '33.0';
#endif
            ObsoleteReason = 'The field has been replaced by the Extended Description field, because its length (50) was too short to describe the registrating unit.';
        }
#endif
        field(3; "Extended Description"; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies the description of the registrating unit, for example its address or other details that identify the unit.';
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
#if not CLEANSCHEMA33
        field(17; "Certificate Code"; Code[10])
        {
            Caption = 'Certificate Code';
            TableRelation = "Certificate Code CZL";
            ToolTip = 'Specifies the certificate used to sign the data messages. It is used by every registrating unit and cash register that does not specify its own certificate.';
#if not CLEAN30
            ObsoleteState = Pending;
            ObsoleteTag = '30.0';
#else
            ObsoleteState = Removed;
            ObsoleteTag = '33.0';
#endif
            ObsoleteReason = 'The field has been replaced by the Taxpayer Certificate Code field, because its length (10) did not match the length of the Code field (20) in the Certificate Code CZL table, so certificates with a longer code could not be selected.';
        }
#endif
        field(18; "Taxpayer Certificate Code"; Code[20])
        {
            Caption = 'Taxpayer Certificate Code';
            TableRelation = "Certificate Code CZL";
            ToolTip = 'Specifies the certificate used to sign the data messages. It is used by every registrating unit and cash register that does not specify its own certificate.';
        }
        field(30; "Taxpayer ID"; Code[20])
        {
            Caption = 'Taxpayer ID';
            ToolTip = 'Specifies the registered identification number of the taxpayer who owns this registrating unit. Leave it blank if the registrating unit is your own.';
        }
        field(35; "Authorizing Taxpayer ID"; Code[20])
        {
            Caption = 'Authorizing Taxpayer ID';
            ToolTip = 'Specifies the registered identification number of the taxpayer authorizing you to report sales. Leave it blank to report your own sales. The value is only copied to new cash registers of this registrating unit, it is not applied to existing ones.';
        }
        field(36; "Multiple Taxpayer Auth."; Boolean)
        {
            Caption = 'Multiple Taxpayer Authorization';
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

