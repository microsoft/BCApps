// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Setup;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;

table 250 "Gen. Business Posting Group"
{
    Caption = 'Gen. Business Posting Group';
    DataCaptionFields = "Code", Description;
    LookupPageID = "Gen. Business Posting Groups";
    Permissions = tabledata "Gen. Business Posting Group" = r;
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
        field(3; "Def. VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'Def. VAT Bus. Posting Group';
            TableRelation = "VAT Business Posting Group";

            trigger OnValidate()
            begin
                if "Def. VAT Bus. Posting Group" <> xRec."Def. VAT Bus. Posting Group" then begin
                    GLAcc.SetCurrentKey("Gen. Bus. Posting Group");
                    GLAcc.SetRange("Gen. Bus. Posting Group", Code);
                    GLAcc.SetRange("VAT Bus. Posting Group", xRec."Def. VAT Bus. Posting Group");
                    if GLAcc.Find('-') then
                        repeat
                            GLAcc2 := GLAcc;
                            GLAcc2."VAT Bus. Posting Group" := "Def. VAT Bus. Posting Group";
                            OnValidateDefVATBusPostingGroupOnBeforeModifyGLAccount(Rec, GLAcc2);
                            GLAcc2.Modify();
                        until GLAcc.Next() = 0;

                    Cust.SetCurrentKey("Gen. Bus. Posting Group");
                    Cust.SetRange("Gen. Bus. Posting Group", Code);
                    Cust.SetRange("VAT Bus. Posting Group", xRec."Def. VAT Bus. Posting Group");
                    if Cust.Find('-') then
                        repeat
                            Cust2 := Cust;
                            Cust2."VAT Bus. Posting Group" := "Def. VAT Bus. Posting Group";
                            Cust2.Modify();
                        until Cust.Next() = 0;

                    Vend.SetCurrentKey("Gen. Bus. Posting Group");
                    Vend.SetRange("Gen. Bus. Posting Group", Code);
                    Vend.SetRange("VAT Bus. Posting Group", xRec."Def. VAT Bus. Posting Group");
                    if Vend.Find('-') then
                        repeat
                            Vend2 := Vend;
                            Vend2."VAT Bus. Posting Group" := "Def. VAT Bus. Posting Group";
                            Vend2.Modify();
                        until Vend.Next() = 0;
                end;
            end;
        }
        field(4; "Auto Insert Default"; Boolean)
        {
            Caption = 'Auto Insert Default';
            InitValue = true;
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(Brick; "Code", Description, "Def. VAT Bus. Posting Group")
        {
        }
    }

    var
        GLAcc: Record "G/L Account";
        GLAcc2: Record "G/L Account";
        Cust: Record Customer;
        Cust2: Record Customer;
        Vend: Record Vendor;
        Vend2: Record Vendor;

    procedure ValidateVatBusPostingGroup(var GenBusPostingGrp: Record "Gen. Business Posting Group"; EnteredGenBusPostingGroup: Code[20]): Boolean
    begin
        if EnteredGenBusPostingGroup <> '' then
            GenBusPostingGrp.Get(EnteredGenBusPostingGroup)
        else
            GenBusPostingGrp.Init();
        exit(GenBusPostingGrp."Auto Insert Default");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateDefVATBusPostingGroupOnBeforeModifyGLAccount(var Rec: Record "Gen. Business Posting Group"; var GLAccount: Record "G/L Account")
    begin
    end;
}

