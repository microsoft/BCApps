// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Setup;

table 11018 "VAT Cipher Setup"
{
    Caption = 'VAT Cipher Setup';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(2; "Total Revenue"; Code[20])
        {
            Caption = 'Total Revenue';
            Description = 'Cipher 200';
            TableRelation = "VAT Cipher Code";
        }
        field(3; "Revenue of Non-Tax. Services"; Code[20])
        {
            Caption = 'Revenue of Non-Tax. Services';
            Description = 'Cipher 205';
            TableRelation = "VAT Cipher Code";
        }
        field(4; "Deduction of Tax-Exempt"; Code[20])
        {
            Caption = 'Deduction of Tax-Exempt';
            Description = 'Cipher 220';
            TableRelation = "VAT Cipher Code";
        }
        field(5; "Deduction of Services Abroad"; Code[20])
        {
            Caption = 'Deduction of Services Abroad';
            Description = 'Cipher 221';
            TableRelation = "VAT Cipher Code";
        }
        field(6; "Deduction of Transfer"; Code[20])
        {
            Caption = 'Deduction of Transfer';
            Description = 'Cipher 225';
            TableRelation = "VAT Cipher Code";
        }
        field(7; "Deduction of Non-Tax. Services"; Code[20])
        {
            Caption = 'Deduction of Non-Tax. Services';
            Description = 'Cipher 230';
            TableRelation = "VAT Cipher Code";
        }
        field(8; "Reduction in Payments"; Code[20])
        {
            Caption = 'Reduction in Payments';
            Description = 'Cipher 235';
            TableRelation = "VAT Cipher Code";
        }
        field(9; Miscellaneous; Code[20])
        {
            Caption = 'Miscellaneous';
            Description = 'Cipher 280';
            TableRelation = "VAT Cipher Code";
        }
        field(10; "Total Deductions"; Code[20])
        {
            Caption = 'Total Deductions';
            Description = 'Cipher 289';
            TableRelation = "VAT Cipher Code";
        }
        field(11; "Total Taxable Revenue"; Code[20])
        {
            Caption = 'Total Taxable Revenue';
            Description = 'Cipher 299';
            TableRelation = "VAT Cipher Code";
        }
        field(12; "Tax Normal Rate Serv. Before"; Code[20])
        {
            Caption = 'Tax Normal Rate Serv. Before';
            Description = 'Cipher 301';
            TableRelation = "VAT Cipher Code";
        }
        field(13; "Tax Normal Rate Serv. After"; Code[20])
        {
            Caption = 'Tax Normal Rate Serv. After';
            Description = 'Cipher 302';
            TableRelation = "VAT Cipher Code";
        }
        field(14; "Tax Reduced Rate Serv. Before"; Code[20])
        {
            Caption = 'Tax Reduced Rate Serv. Before';
            Description = 'Cipher 311';
            TableRelation = "VAT Cipher Code";
        }
        field(15; "Tax Reduced Rate Serv. After"; Code[20])
        {
            Caption = 'Tax Reduced Rate Serv. After';
            Description = 'Cipher 312';
            TableRelation = "VAT Cipher Code";
        }
        field(16; "Tax Hotel Rate Serv. Before"; Code[20])
        {
            Caption = 'Tax Hotel Rate Serv. Before';
            Description = 'Cipher 341';
            TableRelation = "VAT Cipher Code";
        }
        field(17; "Tax Hotel Rate Serv. After"; Code[20])
        {
            Caption = 'Tax Hotel Rate Serv. After';
            Description = 'Cipher 342';
            TableRelation = "VAT Cipher Code";
        }
        field(18; "Acquisition Tax Before"; Code[20])
        {
            Caption = 'Acquisition Tax Before';
            Description = 'Cipher 381';
            TableRelation = "VAT Cipher Code";
        }
        field(19; "Acquisition Tax After"; Code[20])
        {
            Caption = 'Acquisition Tax After';
            Description = 'Cipher 382';
            TableRelation = "VAT Cipher Code";
        }
        field(20; "Total Owned Tax"; Code[20])
        {
            Caption = 'Total Owned Tax';
            Description = 'Cipher 399';
            TableRelation = "VAT Cipher Code";
        }
        field(21; "Input Tax on Material and Serv"; Code[20])
        {
            Caption = 'Input Tax on Material and Serv';
            Description = 'Cipher 400';
            TableRelation = "VAT Cipher Code";
        }
        field(22; "Input Tax on Investsments"; Code[20])
        {
            Caption = 'Input Tax on Investsments';
            Description = 'Cipher 405';
            TableRelation = "VAT Cipher Code";
        }
        field(23; "Deposit Tax"; Code[20])
        {
            Caption = 'Deposit Tax';
            Description = 'Cipher 410';
            TableRelation = "VAT Cipher Code";
        }
        field(24; "Input Tax Corrections"; Code[20])
        {
            Caption = 'Input Tax Corrections';
            Description = 'Cipher 415';
            TableRelation = "VAT Cipher Code";
        }
        field(25; "Input Tax Cutbacks"; Code[20])
        {
            Caption = 'Input Tax Cutbacks';
            Description = 'Cipher 420';
            TableRelation = "VAT Cipher Code";
        }
        field(26; "Total Input Tax"; Code[20])
        {
            Caption = 'Total Input Tax';
            Description = 'Cipher 479';
            TableRelation = "VAT Cipher Code";
        }
        field(27; "Tax Amount to Pay"; Code[20])
        {
            Caption = 'Tax Amount to Pay';
            Description = 'Cipher 500';
            TableRelation = "VAT Cipher Code";
        }
        field(28; "Credit of Taxable Person"; Code[20])
        {
            Caption = 'Credit of Taxable Person';
            Description = 'Cipher 501';
            TableRelation = "VAT Cipher Code";
        }
        field(29; "Cash Flow Taxes"; Code[20])
        {
            Caption = 'Cash Flow Taxes';
            Description = 'Cipher 900';
            TableRelation = "VAT Cipher Code";
        }
        field(30; "Cash Flow Compensations"; Code[20])
        {
            Caption = 'Cash Flow Compensations';
            Description = 'Cipher 910';
            TableRelation = "VAT Cipher Code";
        }
    }

    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

