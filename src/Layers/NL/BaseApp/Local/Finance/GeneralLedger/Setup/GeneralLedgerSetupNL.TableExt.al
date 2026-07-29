// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Setup;

using Microsoft.Finance.Currency;

tableextension 11385 "General Ledger Setup NL" extends "General Ledger Setup"
{
    fields
    {
        field(11400; "Local SEPA Instr. Priority"; Boolean)
        {
            Caption = 'Local SEPA Instr. Priority';
            DataClassification = CustomerContent;
            InitValue = true;
        }
#if not CLEANSCHEMA28
        field(11401; "Use New Apply G/L Entries Page"; Boolean)
        {
            Caption = 'Use New Apply G/L Entries Page';
            DataClassification = CustomerContent;
            ObsoleteReason = 'New page 11310 will unconditionally replace the old 11309.';
            ObsoleteTag = '22.0';
            ObsoleteState = Removed;
        }
#endif
        field(11000000; "Local Currency"; Option)
        {
            Caption = 'Local Currency';
            DataClassification = CustomerContent;
            OptionCaption = ',Euro,Other';
            OptionMembers = ,Euro,Other;

            trigger OnValidate()
            begin
                if "Local Currency" = "Local Currency"::Euro then
                    "Currency Euro" := '';
            end;
        }
        field(11000002; "Currency Euro"; Code[10])
        {
            Caption = 'Currency Euro';
            DataClassification = CustomerContent;
            TableRelation = Currency;

            trigger OnValidate()
            begin
                if "Local Currency" = "Local Currency"::Euro then
                    Error(
                      NotAllowedToSpecifyErr,
                      FieldCaption("Currency Euro"),
                      FieldCaption("Local Currency"),
                      "Local Currency");
            end;
        }
    }

    var
        NotAllowedToSpecifyErr: Label 'It is not allowed to specify %1 when %2 is %3.', Comment = '%1 - Field Caption of the field causing the error, %2 - Field Caption of the Local Currency field, %3 - Value of the Local Currency field';
}

