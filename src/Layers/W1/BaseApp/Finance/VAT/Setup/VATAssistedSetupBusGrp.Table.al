// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Setup;

using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;

table 1879 "VAT Assisted Setup Bus. Grp."
{
    Caption = 'VAT Assisted Setup Bus. Grp.';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(3; Selected; Boolean)
        {
            Caption = 'Selected';
        }
        field(4; Default; Boolean)
        {
            Caption = 'Default';
        }
    }

    keys
    {
        key(Key1; "Code", Default)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        Code001Tok: Label 'DOMESTIC', Comment = 'the same as values in Bus. posting group';
        Code002Tok: Label 'EU', Comment = 'the same as values in Bus. posting group';
        Code003Tok: Label 'EXPORT', Comment = 'the same as values in Bus. posting group';
        Text001Txt: Label 'Domestic customers and vendors';
        Text002Txt: Label 'Customers and vendors in EU';
        Text003Txt: Label 'Other customers and vendors (not EU)';

    procedure PopulateVATBusGrp()
    begin
        SetRange(Default, false);
        DeleteAll();

        SetRange(Default, true);
        if not FindSet() then begin
            InitWithStandardValues();
            FindSet();
        end;

        repeat
            InsertBusPostingGrp(Code, Description, false);
        until Next() = 0;
    end;

    procedure InsertBusPostingGrp(GrpCode: Code[20]; GrpDesc: Text[100]; IsDefault: Boolean)
    var
        VATAssistedSetupBusGrp: Record "VAT Assisted Setup Bus. Grp.";
    begin
        VATAssistedSetupBusGrp.Init();
        VATAssistedSetupBusGrp.Code := GrpCode;
        VATAssistedSetupBusGrp.Description := GrpDesc;
        VATAssistedSetupBusGrp.Selected := true;
        VATAssistedSetupBusGrp.Default := IsDefault;
        VATAssistedSetupBusGrp.Insert();
    end;

    procedure ValidateVATBusGrp(): Boolean
    begin
        SetRange(Selected, true);
        SetRange(Default, false);
        exit(not IsEmpty);
    end;

    procedure CheckExistingCustomersAndVendorsWithVAT(VATBusPostingGroupCode: Code[20]): Boolean
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
    begin
        Customer.SetRange("VAT Bus. Posting Group", VATBusPostingGroupCode);
        Vendor.SetRange("VAT Bus. Posting Group", VATBusPostingGroupCode);
        exit((not Vendor.IsEmpty) or (not Customer.IsEmpty));
    end;

    local procedure InitWithStandardValues()
    begin
        InsertBusPostingGrp(Code001Tok, Text001Txt, true);
        InsertBusPostingGrp(Code002Tok, Text002Txt, true);
        InsertBusPostingGrp(Code003Tok, Text003Txt, true);
    end;
}

