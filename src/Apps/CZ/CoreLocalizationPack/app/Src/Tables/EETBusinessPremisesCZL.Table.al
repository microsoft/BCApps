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

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
            DataClassification = OrganizationIdentifiableInformation;
            ToolTip = 'Specifies the code of the registrating unit.';
        }
        field(2; Description; Text[50])
        {
            Caption = 'Description';
            DataClassification = OrganizationIdentifiableInformation;
            ToolTip = 'Specifies the description of the registrating unit.';
        }
        field(15; Identification; Code[6])
        {
            Caption = 'Identification';
            Numeric = true;
            DataClassification = OrganizationIdentifiableInformation;
            ToolTip = 'Specifies the identification number of the registrating unit.';
        }
        field(17; "Certificate Code"; Code[10])
        {
            Caption = 'Certificate Code';
            TableRelation = "Certificate Code CZL";
            DataClassification = OrganizationIdentifiableInformation;
            ToolTip = 'Specifies the certificate needed to register sales.';
        }
        field(30; Representation; Enum "EET Representation CZL")
        {
            Caption = 'Representation';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies whether the registrating unit reports sales directly or indirectly.';
        }
        field(35; Authorization; Boolean)
        {
            Caption = 'Authorization';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies whether the taxpayer is authorized to report sales on behalf of another taxpayer.';
        }
        field(36; "Multiple Taxpayer Auth."; Boolean)
        {
            Caption = 'Multiple Taxpayer Authorization';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies whether the transaction is recorded on behalf of multiple taxpayers.';
        }
        field(40; "Authorized Taxpayer ID"; Code[20])
        {
            Caption = 'Authorized Taxpayer';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the registered identification number of the taxpayer authorized to report sales.';
        }
        field(41; "Authorizing Taxpayer ID"; Code[20])
        {
            Caption = 'Authorizing Taxpayer ID';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the registered identification number of the taxpayer authorizing another taxpayer to report sales.';
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

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

