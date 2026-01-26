// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Consolidation;

using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.VAT.Ledger;
using System.Environment;

table 11604 "BAS Calc. Sheet Entry"
{
    Caption = 'BAS Calc. Sheet Entry';
    DataPerCompany = false;
    DrillDownPageID = "BAS Calc. Sheet Entries";
    LookupPageID = "BAS Calc. Sheet Entries";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Company Name"; Text[30])
        {
            Caption = 'Company Name';
            TableRelation = Company;
        }
        field(2; "BAS Document No."; Code[11])
        {
            Caption = 'BAS Document No.';
        }
        field(3; "BAS Version"; Integer)
        {
            Caption = 'BAS Version';
        }
        field(4; "Field Label No."; Text[30])
        {
            Caption = 'Field Label No.';
        }
        field(5; Amount; Decimal)
        {
            Caption = 'Amount';
        }
        field(6; "Entry No."; Integer)
        {
            Caption = 'Entry No.';

            trigger OnLookup()
            var
                GLEntry: Record "G/L Entry";
                VATEntry: Record "VAT Entry";
                Text000: Label 'You cannot lookup consolidated entries.';
            begin
                if "Company Name" = CompanyName then
                    case Type of
                        Type::"G/L Entry":
                            begin
                                GLEntry.ChangeCompany("Company Name");
                                GLEntry.SetRange("Entry No.", "Entry No.");
                                PAGE.RunModal(PAGE::"General Ledger Entries", GLEntry);
                            end;
                        Type::"GST Entry":
                            begin
                                VATEntry.ChangeCompany("Company Name");
                                VATEntry.SetRange("Entry No.", "Entry No.");
                                PAGE.RunModal(PAGE::"VAT Entries", VATEntry);
                            end;
                    end
                else
                    Message(Text000);
            end;
        }
        field(7; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = 'G/L Entry,GST Entry';
            OptionMembers = "G/L Entry","GST Entry";
        }
        field(8; "Amount Type"; Option)
        {
            Caption = 'Amount Type';
            OptionCaption = ' ,Amount,Base,Unrealized Amount,Unrealized Base,GST Amount';
            OptionMembers = " ",Amount,Base,"Unrealized Amount","Unrealized Base","GST Amount";
        }
        field(10; "Consol. BAS Doc. No."; Code[11])
        {
            Caption = 'Consol. BAS Doc. No.';
        }
        field(11; "Consol. Version No."; Integer)
        {
            Caption = 'Consol. Version No.';
        }
        field(12; "Gen. Posting Type"; Option)
        {
            Caption = 'Gen. Posting Type';
            OptionCaption = ' ,Purchase,Sale,Settlement';
            OptionMembers = " ",Purchase,Sale,Settlement;
        }
        field(13; "GST Bus. Posting Group"; Code[20])
        {
            Caption = 'GST Bus. Posting Group';
        }
        field(14; "GST Prod. Posting Group"; Code[20])
        {
            Caption = 'GST Prod. Posting Group';
        }
        field(15; "BAS Adjustment"; Boolean)
        {
            Caption = 'BAS Adjustment';
        }
    }

    keys
    {
        key(Key1; "Company Name", "BAS Document No.", "BAS Version", "Field Label No.", Type, "Entry No.", "Amount Type")
        {
            Clustered = true;
            SumIndexFields = Amount;
        }
        key(Key2; "Consol. BAS Doc. No.", "Consol. Version No.")
        {
        }
        key(Key3; "Company Name", "BAS Document No.", "BAS Version", "Field Label No.", "GST Bus. Posting Group", "GST Prod. Posting Group", "BAS Adjustment")
        {
        }
        key(Key4; "Company Name", Type, "Entry No.", "BAS Document No.", "BAS Version")
        {
        }
    }

    fieldgroups
    {
    }
}

