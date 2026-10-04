// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance;

using Microsoft.Foundation.NoSeries;
using System.Security.Encryption;

table 31127 "EET Cash Register CZL"
{
    Caption = 'EET Cash Register';
    LookupPageId = "EET Cash Registers CZL";

    fields
    {
        field(1; "Business Premises Code"; Code[10])
        {
            Caption = 'Registrating Unit Code';
            NotBlank = true;
            TableRelation = "EET Business Premises CZL";
            DataClassification = OrganizationIdentifiableInformation;
            ToolTip = 'Specifies the code of the registrating unit.';
        }
        field(2; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the code of the cash register.';
        }
        field(10; "Cash Register Type"; Enum "EET Cash Register Type CZL")
        {
            Caption = 'Cash Register Type';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the type of the cash register.';

            trigger OnValidate()
            begin
                if "Cash Register Type" = xRec."Cash Register Type" then
                    exit;

                Validate("Cash Register No.", '');
                if "Cash Register Type" = "Cash Register Type"::Default then
                    "Cash Register Name" := GetCashRegisterName();
            end;
        }
        field(12; "Cash Register No."; Code[20])
        {
            Caption = 'Cash Register No.';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the number of the record, such as a cash desk or a bank account, that the cash register is linked to.';

            trigger OnValidate()
            begin
                if "Cash Register No." = '' then
                    "Cash Register Name" := '';
                if ("Cash Register No." <> xRec."Cash Register No.") and ("Cash Register No." <> '') then begin
                    CheckCashRegisterDuplication();
                    "Cash Register Name" := GetCashRegisterName();
                end;
            end;

            trigger OnLookup()
            begin
                if LookupCashRegisterNo("Cash Register No.") then
                    Validate("Cash Register No.");
            end;
        }
        field(15; "Cash Register Name"; Text[100])
        {
            Caption = 'Cash Register Name';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the name of the cash register.';
        }
        field(17; "Certificate Code"; Code[10])
        {
            Caption = 'Certificate Code';
            TableRelation = "Certificate Code CZL";
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the certificate used to sign the data messages of this cash register. Leave it blank to use the certificate from the registrating unit or from the EET service setup.';
        }
        field(20; "Receipt Serial Nos."; Code[20])
        {
            Caption = 'Receipt Serial Nos.';
            TableRelation = "No. Series";
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the number series for the receipt serial numbers.';
        }
        field(35; "Authorizing Taxpayer ID"; Code[20])
        {
            Caption = 'Authorizing Taxpayer ID';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the registered identification number of the taxpayer authorizing you to report sales. Leave it blank to report your own sales. The value is used as it is, it is never taken from the registrating unit or from the service setup.';
        }
        field(36; "Multiple Taxpayer Auth."; Boolean)
        {
            Caption = 'Multiple Taxpayer Authorization';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies whether the transaction is recorded on behalf of multiple taxpayers. The value is used as it is, it is never taken from the registrating unit or from the service setup.';
        }
    }

    keys
    {
        key(Key1; "Business Premises Code", "Code")
        {
            Clustered = true;
        }
        key(Key2; "Cash Register Type", "Cash Register No.")
        {
        }
    }

    trigger OnInsert()
    var
        EETBusinessPremisesCZL: Record "EET Business Premises CZL";
    begin
        if "Cash Register Name" = '' then
            "Cash Register Name" := GetCashRegisterName();
        if EETBusinessPremisesCZL.Get("Business Premises Code") then begin
            "Authorizing Taxpayer ID" := EETBusinessPremisesCZL."Authorizing Taxpayer ID";
            "Multiple Taxpayer Auth." := EETBusinessPremisesCZL."Multiple Taxpayer Auth.";
        end;
    end;

    trigger OnDelete()
    var
        EETEntryCZL: Record "EET Entry CZL";
        EntryExistsErr: Label 'You cannot delete %1 %2 because there is at least one EET entry.', Comment = '%1 = Table Caption;%2 = Primary Key';
    begin
        EETEntryCZL.SetCurrentKey("Business Premises Code", "Cash Register Code");
        EETEntryCZL.SetRange("Business Premises Code", "Business Premises Code");
        EETEntryCZL.SetRange("Cash Register Code", Code);
        if not EETEntryCZL.IsEmpty() then
            Error(EntryExistsErr, TableCaption, Code);
    end;

    local procedure GetCashRegisterName(): Text[100]
    var
        EETCashRegisterCZL: Interface "EET Cash Register CZL";
    begin
        EETCashRegisterCZL := "Cash Register Type";
        exit(EETCashRegisterCZL.GetCashRegisterName("Cash Register No."));
    end;

    local procedure LookupCashRegisterNo(var CashRegisterNo: Code[20]): Boolean
    var
        EETCashRegisterCZL: Interface "EET Cash Register CZL";
    begin
        EETCashRegisterCZL := "Cash Register Type";
        exit(EETCashRegisterCZL.LookupCashRegisterNo(CashRegisterNo));
    end;

    local procedure CheckCashRegisterDuplication()
    var
        EETCashRegisterCZL: Record "EET Cash Register CZL";
        CashRegisterDuplicatedErr: Label 'Cash Register No. %1 is already defined for EET Cash Register: %2 %3.', Comment = '%1=Cash Register Number, %2=Registrating Unit Code, %3=Cach Register Code';
    begin
        if EETCashRegisterCZL.FindByCashRegisterNo("Cash Register Type", "Cash Register No.") then
            Error(CashRegisterDuplicatedErr, "Cash Register No.", EETCashRegisterCZL."Business Premises Code", EETCashRegisterCZL.Code);
    end;

    procedure FindByCashRegisterNo(CashRegisterType: Enum "EET Cash Register Type CZL"; CashRegisterNo: Code[20]): Boolean
    begin
        Reset();
        SetCurrentKey("Cash Register Type", "Cash Register No.");
        SetRange("Cash Register Type", CashRegisterType);
        SetRange("Cash Register No.", CashRegisterNo);
        exit(FindFirst());
    end;
}

