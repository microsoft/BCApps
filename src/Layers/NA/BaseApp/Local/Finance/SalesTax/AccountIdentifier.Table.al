// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.SalesTax;

table 10100 "Account Identifier"
{
    Caption = 'Account Identifier';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Business No."; Code[20])
        {
            Caption = 'Business No.';
        }
        field(2; "Program Identifier"; Option)
        {
            BlankZero = true;
            Caption = 'Program Identifier';
            NotBlank = true;
            OptionCaption = ' ,RC,RM,RP,RT,RR,RD,RE,RN,RG';
            OptionMembers = " ",RC,RM,RP,RT,RR,RD,RE,RN,RG;
        }
        field(3; "Reference No."; Code[4])
        {
            Caption = 'Reference No.';
            NotBlank = true;
            Numeric = true;

            trigger OnValidate()
            var
                AIRecordRef: RecordRef;
                PIFieldRef: FieldRef;
                Text001: Label 'Reference No. can not be less than 4 digits.';
            begin
                if StrLen("Reference No.") < 4 then
                    Error(Text001);

                AIRecordRef.GetTable(Rec);
                PIFieldRef := AIRecordRef.Field(FieldNo("Program Identifier"));

                "Business Number" :=
                  CopyStr(
                    "Business No." + SelectStr("Program Identifier" + 1, PIFieldRef.OptionMembers) + "Reference No.",
                    1, MaxStrLen("Business Number"));
            end;
        }
        field(4; "Business Number"; Code[20])
        {
            Caption = 'Business Number';
        }
    }

    keys
    {
        key(Key1; "Business No.", "Program Identifier")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

