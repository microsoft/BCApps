// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Interaction;

#pragma warning disable AL0659
enum 5099 "Interaction Log Entry Document Type"
#pragma warning restore AL0659
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; " ")
    {
    }
    value(1; "Sales Qte.")
    {
        Caption = 'Sales Qte.';
    }
    value(2; "Sales Blnkt. Ord")
    {
        Caption = 'Sales Blnkt. Ord';
    }
    value(3; "Sales Ord. Cnfrmn.")
    {
        Caption = 'Sales Ord. Cnfrmn.';
    }
    value(4; "Sales Inv.")
    {
        Caption = 'Sales Inv.';
    }
    value(5; "Sales Shpt. Note")
    {
        Caption = 'Sales Shpt. Note';
    }
    value(6; "Sales Cr. Memo")
    {
        Caption = 'Sales Cr. Memo';
    }
    value(7; "Sales Stmnt.")
    {
        Caption = 'Sales Stmnt.';
    }
    value(8; "Sales Rmdr.")
    {
        Caption = 'Sales Rmdr.';
    }
    value(9; "Serv. Ord. Create")
    {
        Caption = 'Serv. Ord. Create';
    }
    value(10; "Serv. Ord. Post")
    {
        Caption = 'Serv. Ord. Post';
    }
    value(11; "Purch.Qte.")
    {
        Caption = 'Purch.Qte.';
    }
    value(12; "Purch. Blnkt. Ord.")
    {
        Caption = 'Purch. Blnkt. Ord.';
    }
    value(13; "Purch. Ord.")
    {
        Caption = 'Purch. Ord.';
    }
    value(14; "Purch. Inv.")
    {
        Caption = 'Purch. Inv.';
    }
    value(15; "Purch. Rcpt.")
    {
        Caption = 'Purch. Rcpt.';
    }
    value(16; "Purch. Cr. Memo")
    {
        Caption = 'Purch. Cr. Memo';
    }
    value(17; "Cover Sheet")
    {
        Caption = 'Cover Sheet';
    }
    value(18; "Sales Return Order")
    {
        Caption = 'Sales Return Order';
    }
    value(19; "Sales Finance Charge Memo")
    {
        Caption = 'Sales Finance Charge Memo';
    }
    value(20; "Sales Return Receipt")
    {
        Caption = 'Sales Return Receipt';
    }
    value(21; "Purch. Return Shipment")
    {
        Caption = 'Purch. Return Shipment';
    }
    value(22; "Purch. Return Ord. Cnfrmn.")
    {
        Caption = 'Purch. Return Ord. Cnfrmn.';
    }
    value(23; "Service Contract")
    {
        Caption = 'Service Contract';
    }
    value(24; "Service Contract Quote")
    {
        Caption = 'Service Contract Quote';
    }
    value(25; "Service Quote")
    {
        Caption = 'Service Quote';
    }
    value(26; "Sales Draft Invoice")
    {
        Caption = 'Sales Draft Invoice';
    }
}
