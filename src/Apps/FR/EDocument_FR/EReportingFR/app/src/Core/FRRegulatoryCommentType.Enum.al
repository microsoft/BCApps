// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats;

enum 10971 "FR Regulatory Comment Type"
{
    Extensible = true;

    value(0; None)
    {
        Caption = '';
    }
    value(1; AAA)
    {
        Caption = 'AAA - Goods description';
    }
    value(2; AAB)
    {
        Caption = 'AAB - Terms of payments';
    }
    value(3; AAC)
    {
        Caption = 'AAC - Dangerous goods additional information';
    }
    value(4; AAI)
    {
        Caption = 'AAI - General information';
    }
    value(5; AAJ)
    {
        Caption = 'AAJ - Additional conditions of sale/purchase';
    }
    value(6; AAK)
    {
        Caption = 'AAK - Price conditions';
    }
    value(7; ABN)
    {
        Caption = 'ABN - Accounting information';
    }
    value(8; ABR)
    {
        Caption = 'ABR - Documents delivery instructions';
    }
    value(9; ACB)
    {
        Caption = 'ACB - Additional information';
    }
    value(10; ACD)
    {
        Caption = 'ACD - Reason';
    }
    value(11; ACE)
    {
        Caption = 'ACE - Dispute';
    }
    value(12; ALC)
    {
        Caption = 'ALC - Allowance/charge information';
    }
    value(13; CUR)
    {
        Caption = 'CUR - Customer remarks';
    }
    value(14; DEL)
    {
        Caption = 'DEL - Delivery information';
    }
    value(15; GEN)
    {
        Caption = 'GEN - Entire transaction set';
    }
    value(16; INV)
    {
        Caption = 'INV - Invoice instruction';
    }
    value(17; PAI)
    {
        Caption = 'PAI - Payment instructions information';
    }
    value(18; PMD)
    {
        Caption = 'PMD - Payment detail/remittance information';
    }
    value(19; PMT)
    {
        Caption = 'PMT - Payment information';
    }
    value(20; PRD)
    {
        Caption = 'PRD - Product information';
    }
    value(21; REG)
    {
        Caption = 'REG - Regulatory information';
    }
    value(22; SUR)
    {
        Caption = 'SUR - Supplier remarks';
    }
    value(23; TXD)
    {
        Caption = 'TXD - Tax declaration';
    }
    value(24; ZZZ)
    {
        Caption = 'ZZZ - Mutually defined';
    }
}