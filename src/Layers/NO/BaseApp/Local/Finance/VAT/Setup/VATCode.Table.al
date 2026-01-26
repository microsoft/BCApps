#if not CLEANSCHEMA26 
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Setup;

table 10602 "VAT Code"
{
    Caption = 'VAT Code';
    ObsoleteReason = 'Use the table "VAT Reporting Code" instead.';
    ObsoleteState = Removed;
    ObsoleteTag = '26.0';
    DataClassification = CustomerContent;
    ReplicateData = false;

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
        }
        field(2; "Gen. Posting Type"; Option)
        {
            Caption = 'Gen. Posting Type';
            OptionCaption = ' ,Purchase,Sale';
            OptionMembers = " ",Purchase,Sale;
        }
        field(3; "Test Gen. Posting Type"; Option)
        {
            Caption = 'Test Gen. Posting Type';
            OptionCaption = ' ,Mandatory,Same';
            OptionMembers = " ",Mandatory,Same;
        }
        field(4; Description; Text[30])
        {
            Caption = 'Description';
        }
        field(5; "Trade Settlement 2017 Box No."; Option)
        {
            Caption = 'Trade Settlement 2017 Box No.';
            OptionCaption = ' ,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19';
            OptionMembers = " ","1","2","3","4","5","6","7","8","9","10","11","12","13","14","15","16","17","18","19";
        }
        field(6; "Reverse Charge Report Box No."; Option)
        {
            Caption = 'Reverse Charge Report Box No.';
            OptionCaption = ' ,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19';
            OptionMembers = " ","1","2","3","4","5","6","7","8","9","10","11","12","13","14","15","16","17","18","19";
        }
        field(9; "VAT Specification Code"; Code[50])
        {
            Caption = 'VAT Specification Code';
            TableRelation = "VAT Specification";
        }
        field(10; "SAF-T VAT Code"; Code[10])
        {
            Caption = 'SAF-T Code';
            TableRelation = "VAT Code";
            ObsoleteReason = 'Use the field "SAF-T VAT Code" in the table "VAT Reporting Code" instead.';
            ObsoleteState = Removed;
            ObsoleteTag = '26.0';
        }
        field(11; "VAT Note Code"; Code[50])
        {
            Caption = 'VAT Note Code';
            TableRelation = "VAT Note";
        }
        field(10621; "Linked VAT Reporting Code"; Code[20]) { }
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
        fieldgroup(DropDown; "Code", Description, "Gen. Posting Type")
        {
        }
    }
}

 
#endif