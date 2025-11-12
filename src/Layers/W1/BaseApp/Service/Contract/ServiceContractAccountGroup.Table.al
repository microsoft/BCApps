// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Contract;

using Microsoft.Finance.GeneralLedger.Account;

table 5973 "Service Contract Account Group"
{
    Caption = 'Service Contract Account Group';
    DrillDownPageID = "Serv. Contract Account Groups";
    LookupPageID = "Serv. Contract Account Groups";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(3; "Non-Prepaid Contract Acc."; Code[20])
        {
            Caption = 'Non-Prepaid Contract Acc.';
            TableRelation = "G/L Account"."No.";

            trigger OnValidate()
            begin
                if "Non-Prepaid Contract Acc." <> '' then begin
                    GLAcc.Get("Non-Prepaid Contract Acc.");
                    if CheckProdPostingGroups() then begin
                        GLAcc.TestField("Gen. Prod. Posting Group");
                        GLAcc.TestField("VAT Prod. Posting Group");
                    end else
                        GLAcc.TestField("Tax Group Code");
                end;
            end;
        }
        field(4; "Prepaid Contract Acc."; Code[20])
        {
            Caption = 'Prepaid Contract Acc.';
            TableRelation = "G/L Account"."No.";

            trigger OnValidate()
            begin
                if "Prepaid Contract Acc." <> '' then begin
                    GLAcc.Get("Prepaid Contract Acc.");
                    if CheckProdPostingGroups() then begin
                        GLAcc.TestField("Gen. Prod. Posting Group");
                        GLAcc.TestField("VAT Prod. Posting Group");
                    end else
                        GLAcc.TestField("Tax Group Code");
                end;
            end;
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
    }

    var
        GLAcc: Record "G/L Account";

    procedure CheckProdPostingGroups(): Boolean
    var
        ApplicationAreaMgmt: Codeunit System.Environment.Configuration."Application Area Mgmt.";
        IsHandled: Boolean;
        Result: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckProdPostingGroups(Result, IsHandled);
        if IsHandled then
            exit(Result);

        exit(not ApplicationAreaMgmt.IsSalesTaxEnabled());
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckProdPostingGroups(var Result: Boolean; var IsHandled: Boolean)
    begin
    end;
}

