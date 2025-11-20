// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.RateChange;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Setup;

table 551 "VAT Rate Change Conversion"
{
    Caption = 'VAT Rate Change Conversion';
    DataClassification = CustomerContent;

    fields
    {
        field(1; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = 'VAT Prod. Posting Group,Gen. Prod. Posting Group';
            OptionMembers = "VAT Prod. Posting Group","Gen. Prod. Posting Group";
        }
        field(2; "From Code"; Code[20])
        {
            Caption = 'From Code';
            NotBlank = true;
            TableRelation = if (Type = const("VAT Prod. Posting Group")) "VAT Product Posting Group"
            else
            if (Type = const("Gen. Prod. Posting Group")) "Gen. Product Posting Group";

            trigger OnValidate()
            begin
                CheckforLoop();
            end;
        }
        field(3; "To Code"; Code[20])
        {
            Caption = 'To Code';
            NotBlank = true;
            TableRelation = if (Type = const("VAT Prod. Posting Group")) "VAT Product Posting Group"
            else
            if (Type = const("Gen. Prod. Posting Group")) "Gen. Product Posting Group";

            trigger OnValidate()
            begin
                if "To Code" <> xRec."To Code" then
                    "Converted Date" := 0D;

                CheckforLoop();
            end;
        }
        field(10; "Converted Date"; Date)
        {
            Caption = 'Converted Date';
            Editable = false;
        }
    }

    keys
    {
        key(Key1; Type, "From Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        TestField("To Code");
    end;

    trigger OnRename()
    begin
        "Converted Date" := 0D;
    end;

    var
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text0001: Label 'This entry will create a loop with the entry where the %1 field is set to %2.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    local procedure CheckforLoop()
    var
        VATRateChangeConversion: Record "VAT Rate Change Conversion";
    begin
        VATRateChangeConversion.Reset();
        VATRateChangeConversion.SetRange(Type, Type);
        VATRateChangeConversion.SetRange("From Code", "To Code");
        if VATRateChangeConversion.FindFirst() then
            Error(Text0001, FieldCaption("From Code"), VATRateChangeConversion."From Code");

        VATRateChangeConversion.Reset();
        VATRateChangeConversion.SetRange(Type, Type);
        VATRateChangeConversion.SetRange("To Code", "From Code");
        if VATRateChangeConversion.FindFirst() then
            Error(Text0001, FieldCaption("To Code"), VATRateChangeConversion."To Code");
    end;
}

