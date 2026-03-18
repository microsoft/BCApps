// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.AuditCodes;

#pragma warning disable AS0125
tableextension 243 SourceCodeSetupExt extends "Source Code Setup"
{
    fields
    {
        field(2; Sales; Code[10])
        {
            Caption = 'Sales';
            TableRelation = "Source Code";
            DataClassification = CustomerContent;
#if not CLEANSCHEMA27
            MovedFrom = 'f3552374-a1f2-4356-848e-196002525837';
#endif
        }
        field(3; Purchases; Code[10])
        {
            Caption = 'Purchases';
            TableRelation = "Source Code";
            DataClassification = CustomerContent;
#if not CLEANSCHEMA27
            MovedFrom = 'f3552374-a1f2-4356-848e-196002525837';
#endif
        }
        field(4; "Inventory Post Cost"; Code[10])
        {
            Caption = 'Inventory Post Cost';
            TableRelation = "Source Code";
            DataClassification = CustomerContent;
#if not CLEANSCHEMA27
            MovedFrom = 'f3552374-a1f2-4356-848e-196002525837';
#endif
        }
        field(5; "Exchange Rate Adjmt."; Code[10])
        {
            Caption = 'Exchange Rate Adjmt.';
            TableRelation = "Source Code";
            DataClassification = CustomerContent;
#if not CLEANSCHEMA27
            MovedFrom = 'f3552374-a1f2-4356-848e-196002525837';
#endif
        }
        field(6; "Post Recognition"; Code[10])
        {
            Caption = 'Post Recognition';
            TableRelation = "Source Code";
            DataClassification = CustomerContent;
#if not CLEANSCHEMA27
            MovedFrom = 'f3552374-a1f2-4356-848e-196002525837';
#endif
        }
        field(7; "Post Value"; Code[10])
        {
            Caption = 'Post Value';
            TableRelation = "Source Code";
            DataClassification = CustomerContent;
#if not CLEANSCHEMA27
            MovedFrom = 'f3552374-a1f2-4356-848e-196002525837';
#endif
        }
        field(8; "Close Income Statement"; Code[10])
        {
            Caption = 'Close Income Statement';
            TableRelation = "Source Code";
            DataClassification = CustomerContent;
#if not CLEANSCHEMA27
            MovedFrom = 'f3552374-a1f2-4356-848e-196002525837';
#endif
        }
        field(9; Consolidation; Code[10])
        {
            Caption = 'Consolidation';
            TableRelation = "Source Code";
            DataClassification = CustomerContent;
#if not CLEANSCHEMA27
            MovedFrom = 'f3552374-a1f2-4356-848e-196002525837';
#endif
        }
        field(10; "General Journal"; Code[10])
        {
            Caption = 'General Journal';
            TableRelation = "Source Code";
            DataClassification = CustomerContent;
#if not CLEANSCHEMA27
            MovedFrom = 'f3552374-a1f2-4356-848e-196002525837';
#endif
        }
        field(11; "Sales Journal"; Code[10])
        {
            Caption = 'Sales Journal';
            TableRelation = "Source Code";
            DataClassification = CustomerContent;
#if not CLEANSCHEMA27
            MovedFrom = 'f3552374-a1f2-4356-848e-196002525837';
#endif
        }
        field(12; "Purchase Journal"; Code[10])
        {
            Caption = 'Purchase Journal';
            TableRelation = "Source Code";
            DataClassification = CustomerContent;
#if not CLEANSCHEMA27
            MovedFrom = 'f3552374-a1f2-4356-848e-196002525837';
#endif
        }
        field(13; "Cash Receipt Journal"; Code[10])
        {
            Caption = 'Cash Receipt Journal';
            TableRelation = "Source Code";
            DataClassification = CustomerContent;
#if not CLEANSCHEMA27
            MovedFrom = 'f3552374-a1f2-4356-848e-196002525837';
#endif
        }
        field(14; "Payment Journal"; Code[10])
        {
            Caption = 'Payment Journal';
            TableRelation = "Source Code";
            DataClassification = CustomerContent;
#if not CLEANSCHEMA27
            MovedFrom = 'f3552374-a1f2-4356-848e-196002525837';
#endif
        }
        field(16; "Item Journal"; Code[10])
        {
            Caption = 'Item Journal';
            TableRelation = "Source Code";
            DataClassification = CustomerContent;
#if not CLEANSCHEMA27
            MovedFrom = 'f3552374-a1f2-4356-848e-196002525837';
#endif
        }
        field(19; "Resource Journal"; Code[10])
        {
            Caption = 'Resource Journal';
            TableRelation = "Source Code";
            DataClassification = CustomerContent;
#if not CLEANSCHEMA27
            MovedFrom = 'f3552374-a1f2-4356-848e-196002525837';
#endif
        }
        field(20; "Job Journal"; Code[10])
        {
            Caption = 'Job Journal';
            TableRelation = "Source Code";
            DataClassification = CustomerContent;
#if not CLEANSCHEMA27
            MovedFrom = 'f3552374-a1f2-4356-848e-196002525837';
#endif
        }
        field(21; "Sales Entry Application"; Code[10])
        {
            Caption = 'Sales Entry Application';
            TableRelation = "Source Code";
            DataClassification = CustomerContent;
#if not CLEANSCHEMA27
            MovedFrom = 'f3552374-a1f2-4356-848e-196002525837';
#endif
        }
        field(22; "Purchase Entry Application"; Code[10])
        {
            Caption = 'Purchase Entry Application';
            TableRelation = "Source Code";
            DataClassification = CustomerContent;
#if not CLEANSCHEMA27
            MovedFrom = 'f3552374-a1f2-4356-848e-196002525837';
#endif
        }
        field(23; "VAT Settlement"; Code[10])
        {
            Caption = 'VAT Settlement';
            TableRelation = "Source Code";
            DataClassification = CustomerContent;
#if not CLEANSCHEMA27
            MovedFrom = 'f3552374-a1f2-4356-848e-196002525837';
#endif
        }
        field(24; "Compress G/L"; Code[10])
        {
            Caption = 'Compress G/L';
            TableRelation = "Source Code";
            DataClassification = CustomerContent;
#if not CLEANSCHEMA27
            MovedFrom = 'f3552374-a1f2-4356-848e-196002525837';
#endif
        }
        field(25; "Compress VAT Entries"; Code[10])
        {
            Caption = 'Compress VAT Entries';
            TableRelation = "Source Code";
            DataClassification = CustomerContent;
#if not CLEANSCHEMA27
            MovedFrom = 'f3552374-a1f2-4356-848e-196002525837';
#endif
        }
        field(26; "Compress Cust. Ledger"; Code[10])
        {
            Caption = 'Compress Cust. Ledger';
            TableRelation = "Source Code";
            DataClassification = CustomerContent;
#if not CLEANSCHEMA27
            MovedFrom = 'f3552374-a1f2-4356-848e-196002525837';
#endif
        }
        field(27; "Compress Vend. Ledger"; Code[10])
        {
            Caption = 'Compress Vend. Ledger';
            TableRelation = "Source Code";
            DataClassification = CustomerContent;
#if not CLEANSCHEMA27
            MovedFrom = 'f3552374-a1f2-4356-848e-196002525837';
#endif
        }
        field(28; "Compress Item Ledger"; Code[10])
        {
            Caption = 'Compress Item Ledger';
            TableRelation = "Source Code";
            DataClassification = CustomerContent;
#if not CLEANSCHEMA27
            MovedFrom = 'f3552374-a1f2-4356-848e-196002525837';
#endif
        }
        field(31; "Compress Res. Ledger"; Code[10])
        {
            Caption = 'Compress Res. Ledger';
            TableRelation = "Source Code";
            DataClassification = CustomerContent;
#if not CLEANSCHEMA27
            MovedFrom = 'f3552374-a1f2-4356-848e-196002525837';
#endif
        }
        field(32; "Compress Job Ledger"; Code[10])
        {
            Caption = 'Compress Job Ledger';
            TableRelation = "Source Code";
            DataClassification = CustomerContent;
#if not CLEANSCHEMA27
            MovedFrom = 'f3552374-a1f2-4356-848e-196002525837';
#endif
        }
        field(33; "Item Reclass. Journal"; Code[10])
        {
            Caption = 'Item Reclass. Journal';
            TableRelation = "Source Code";
            DataClassification = CustomerContent;
#if not CLEANSCHEMA27
            MovedFrom = 'f3552374-a1f2-4356-848e-196002525837';
#endif
        }
        field(34; "Phys. Inventory Journal"; Code[10])
        {
            Caption = 'Phys. Inventory Journal';
            TableRelation = "Source Code";
            DataClassification = CustomerContent;
#if not CLEANSCHEMA27
            MovedFrom = 'f3552374-a1f2-4356-848e-196002525837';
#endif
        }
        field(35; "Compress Bank Acc. Ledger"; Code[10])
        {
            Caption = 'Compress Bank Acc. Ledger';
            TableRelation = "Source Code";
            DataClassification = CustomerContent;
#if not CLEANSCHEMA27
            MovedFrom = 'f3552374-a1f2-4356-848e-196002525837';
#endif
        }
        field(36; "Compress Check Ledger"; Code[10])
        {
            Caption = 'Compress Check Ledger';
            TableRelation = "Source Code";
            DataClassification = CustomerContent;
#if not CLEANSCHEMA27
            MovedFrom = 'f3552374-a1f2-4356-848e-196002525837';
#endif
        }
        field(37; "Financially Voided Check"; Code[10])
        {
            Caption = 'Financially Voided Check';
            TableRelation = "Source Code";
            DataClassification = CustomerContent;
#if not CLEANSCHEMA27
            MovedFrom = 'f3552374-a1f2-4356-848e-196002525837';
#endif
        }
        field(38; "Finance Charge Memo"; Code[10])
        {
            Caption = 'Finance Charge Memo';
            TableRelation = "Source Code";
            DataClassification = CustomerContent;
#if not CLEANSCHEMA27
            MovedFrom = 'f3552374-a1f2-4356-848e-196002525837';
#endif
        }
        field(39; Reminder; Code[10])
        {
            Caption = 'Reminder';
            TableRelation = "Source Code";
            DataClassification = CustomerContent;
#if not CLEANSCHEMA27
            MovedFrom = 'f3552374-a1f2-4356-848e-196002525837';
#endif
        }
        field(40; "Deleted Document"; Code[10])
        {
            Caption = 'Deleted Document';
            TableRelation = "Source Code";
            DataClassification = CustomerContent;
#if not CLEANSCHEMA27
            MovedFrom = 'f3552374-a1f2-4356-848e-196002525837';
#endif
        }
        field(41; "Adjust Add. Reporting Currency"; Code[10])
        {
            Caption = 'Adjust Add. Reporting Currency';
            TableRelation = "Source Code";
            DataClassification = CustomerContent;
#if not CLEANSCHEMA27
            MovedFrom = 'f3552374-a1f2-4356-848e-196002525837';
#endif
        }
        field(42; "Trans. Bank Rec. to Gen. Jnl."; Code[10])
        {
            Caption = 'Trans. Bank Rec. to Gen. Jnl.';
            TableRelation = "Source Code";
            DataClassification = CustomerContent;
#if not CLEANSCHEMA27
            MovedFrom = 'f3552374-a1f2-4356-848e-196002525837';
#endif
        }
        field(43; "IC General Journal"; Code[10])
        {
            Caption = 'IC General Journal';
            TableRelation = "Source Code";
            DataClassification = CustomerContent;
#if not CLEANSCHEMA27
            MovedFrom = 'f3552374-a1f2-4356-848e-196002525837';
#endif
        }
        field(44; "Unapplied Empl. Entry Appln."; Code[10])
        {
            Caption = 'Unapplied Empl. Entry Appln.';
            TableRelation = "Source Code";
            DataClassification = CustomerContent;
#if not CLEANSCHEMA27
            MovedFrom = 'f3552374-a1f2-4356-848e-196002525837';
#endif
        }
        field(45; "Unapplied Sales Entry Appln."; Code[10])
        {
            Caption = 'Unapplied Sales Entry Appln.';
            TableRelation = "Source Code";
            DataClassification = CustomerContent;
#if not CLEANSCHEMA27
            MovedFrom = 'f3552374-a1f2-4356-848e-196002525837';
#endif
        }
        field(46; "Unapplied Purch. Entry Appln."; Code[10])
        {
            Caption = 'Unapplied Purch. Entry Appln.';
            TableRelation = "Source Code";
            DataClassification = CustomerContent;
#if not CLEANSCHEMA27
            MovedFrom = 'f3552374-a1f2-4356-848e-196002525837';
#endif
        }
        field(47; Reversal; Code[10])
        {
            Caption = 'Reversal';
            TableRelation = "Source Code";
            DataClassification = CustomerContent;
#if not CLEANSCHEMA27
            MovedFrom = 'f3552374-a1f2-4356-848e-196002525837';
#endif
        }
        field(48; "Employee Entry Application"; Code[10])
        {
            Caption = 'Employee Entry Application';
            TableRelation = "Source Code";
            DataClassification = CustomerContent;
#if not CLEANSCHEMA27
            MovedFrom = 'f3552374-a1f2-4356-848e-196002525837';
#endif
        }
        field(49; "Payment Reconciliation Journal"; Code[10])
        {
            Caption = 'Payment Reconciliation Journal';
            TableRelation = "Source Code";
            DataClassification = CustomerContent;
#if not CLEANSCHEMA27
            MovedFrom = 'f3552374-a1f2-4356-848e-196002525837';
#endif
        }
        field(50; "G/L Currency Revaluation"; Code[10])
        {
            Caption = 'G/L Currency Revaluation';
            TableRelation = "Source Code";
            DataClassification = CustomerContent;
        }
        field(840; "Cash Flow Worksheet"; Code[10])
        {
            Caption = 'Cash Flow Worksheet';
            TableRelation = "Source Code";
            DataClassification = CustomerContent;
#if not CLEANSCHEMA27
            MovedFrom = 'f3552374-a1f2-4356-848e-196002525837';
#endif
        }
        field(900; Assembly; Code[10])
        {
            Caption = 'Assembly';
            TableRelation = "Source Code";
            DataClassification = CustomerContent;
#if not CLEANSCHEMA27
            MovedFrom = 'f3552374-a1f2-4356-848e-196002525837';
#endif
        }
        field(1000; "Job G/L Journal"; Code[10])
        {
            Caption = 'Job G/L Journal';
            TableRelation = "Source Code";
            DataClassification = CustomerContent;
#if not CLEANSCHEMA27
            MovedFrom = 'f3552374-a1f2-4356-848e-196002525837';
#endif
        }
        field(1001; "Job G/L WIP"; Code[10])
        {
            Caption = 'Job G/L WIP';
            TableRelation = "Source Code";
            DataClassification = CustomerContent;
#if not CLEANSCHEMA27
            MovedFrom = 'f3552374-a1f2-4356-848e-196002525837';
#endif
        }
        field(1100; "G/L Entry to CA"; Code[10])
        {
            Caption = 'G/L Entry to CA';
            TableRelation = "Source Code";
            DataClassification = CustomerContent;
#if not CLEANSCHEMA27
            MovedFrom = 'f3552374-a1f2-4356-848e-196002525837';
#endif
        }
        field(1102; "Cost Journal"; Code[10])
        {
            Caption = 'Cost Journal';
            TableRelation = "Source Code";
            DataClassification = CustomerContent;
#if not CLEANSCHEMA27
            MovedFrom = 'f3552374-a1f2-4356-848e-196002525837';
#endif
        }
        field(1104; "Cost Allocation"; Code[10])
        {
            Caption = 'Cost Allocation';
            TableRelation = "Source Code";
            DataClassification = CustomerContent;
#if not CLEANSCHEMA27
            MovedFrom = 'f3552374-a1f2-4356-848e-196002525837';
#endif
        }
        field(1105; "Transfer Budget to Actual"; Code[10])
        {
            Caption = 'Transfer Budget to Actual';
            TableRelation = "Source Code";
            DataClassification = CustomerContent;
#if not CLEANSCHEMA27
            MovedFrom = 'f3552374-a1f2-4356-848e-196002525837';
#endif
        }
        field(1700; "General Deferral"; Code[10])
        {
            Caption = 'General Deferral';
            TableRelation = "Source Code";
            DataClassification = CustomerContent;
#if not CLEANSCHEMA27
            MovedFrom = 'f3552374-a1f2-4356-848e-196002525837';
#endif
        }
        field(1701; "Sales Deferral"; Code[10])
        {
            Caption = 'Sales Deferral';
            TableRelation = "Source Code";
            DataClassification = CustomerContent;
#if not CLEANSCHEMA27
            MovedFrom = 'f3552374-a1f2-4356-848e-196002525837';
#endif
        }
        field(1702; "Purchase Deferral"; Code[10])
        {
            Caption = 'Purchase Deferral';
            TableRelation = "Source Code";
            DataClassification = CustomerContent;
#if not CLEANSCHEMA27
            MovedFrom = 'f3552374-a1f2-4356-848e-196002525837';
#endif
        }
        field(5400; "Consumption Journal"; Code[10])
        {
            Caption = 'Consumption Journal';
            TableRelation = "Source Code";
            DataClassification = CustomerContent;
#if not CLEANSCHEMA27
            MovedFrom = 'f3552374-a1f2-4356-848e-196002525837';
#endif
        }
        field(5402; "Output Journal"; Code[10])
        {
            Caption = 'Output Journal';
            TableRelation = "Source Code";
            DataClassification = CustomerContent;
#if not CLEANSCHEMA27
            MovedFrom = 'f3552374-a1f2-4356-848e-196002525837';
#endif
        }
        field(5403; Flushing; Code[10])
        {
            Caption = 'Flushing';
            TableRelation = "Source Code";
            DataClassification = CustomerContent;
#if not CLEANSCHEMA27
            MovedFrom = 'f3552374-a1f2-4356-848e-196002525837';
#endif
        }
        field(5404; "Capacity Journal"; Code[10])
        {
            Caption = 'Capacity Journal';
            TableRelation = "Source Code";
            DataClassification = CustomerContent;
#if not CLEANSCHEMA27
            MovedFrom = 'f3552374-a1f2-4356-848e-196002525837';
#endif
        }
        field(5500; "Production Journal"; Code[10])
        {
            Caption = 'Production Journal';
            TableRelation = "Source Code";
            DataClassification = CustomerContent;
#if not CLEANSCHEMA27
            MovedFrom = 'f3552374-a1f2-4356-848e-196002525837';
#endif
        }
        field(5502; "Production Order"; Code[10])
        {
            Caption = 'Production Order';
            TableRelation = "Source Code";
            DataClassification = CustomerContent;
#if not CLEANSCHEMA27
            MovedFrom = 'f3552374-a1f2-4356-848e-196002525837';
#endif
        }
        field(5600; "Fixed Asset Journal"; Code[10])
        {
            Caption = 'Fixed Asset Journal';
            TableRelation = "Source Code";
            DataClassification = CustomerContent;
#if not CLEANSCHEMA27
            MovedFrom = 'f3552374-a1f2-4356-848e-196002525837';
#endif
        }
        field(5601; "Fixed Asset G/L Journal"; Code[10])
        {
            Caption = 'Fixed Asset G/L Journal';
            TableRelation = "Source Code";
            DataClassification = CustomerContent;
#if not CLEANSCHEMA27
            MovedFrom = 'f3552374-a1f2-4356-848e-196002525837';
#endif
        }
        field(5602; "Insurance Journal"; Code[10])
        {
            Caption = 'Insurance Journal';
            TableRelation = "Source Code";
            DataClassification = CustomerContent;
#if not CLEANSCHEMA27
            MovedFrom = 'f3552374-a1f2-4356-848e-196002525837';
#endif
        }
        field(5603; "Compress FA Ledger"; Code[10])
        {
            Caption = 'Compress FA Ledger';
            TableRelation = "Source Code";
            DataClassification = CustomerContent;
#if not CLEANSCHEMA27
            MovedFrom = 'f3552374-a1f2-4356-848e-196002525837';
#endif
        }
        field(5604; "Compress Maintenance Ledger"; Code[10])
        {
            Caption = 'Compress Maintenance Ledger';
            TableRelation = "Source Code";
            DataClassification = CustomerContent;
#if not CLEANSCHEMA27
            MovedFrom = 'f3552374-a1f2-4356-848e-196002525837';
#endif
        }
        field(5605; "Compress Insurance Ledger"; Code[10])
        {
            Caption = 'Compress Insurance Ledger';
            TableRelation = "Source Code";
            DataClassification = CustomerContent;
#if not CLEANSCHEMA27
            MovedFrom = 'f3552374-a1f2-4356-848e-196002525837';
#endif
        }
        field(5700; Transfer; Code[10])
        {
            Caption = 'Transfer';
            TableRelation = "Source Code";
            DataClassification = CustomerContent;
#if not CLEANSCHEMA27
            MovedFrom = 'f3552374-a1f2-4356-848e-196002525837';
#endif
        }
        field(5800; "Revaluation Journal"; Code[10])
        {
            Caption = 'Revaluation Journal';
            TableRelation = "Source Code";
            DataClassification = CustomerContent;
#if not CLEANSCHEMA27
            MovedFrom = 'f3552374-a1f2-4356-848e-196002525837';
#endif
        }
        field(5801; "Adjust Cost"; Code[10])
        {
            Caption = 'Adjust Cost';
            TableRelation = "Source Code";
            DataClassification = CustomerContent;
#if not CLEANSCHEMA27
            MovedFrom = 'f3552374-a1f2-4356-848e-196002525837';
#endif
        }
        field(5850; "Invt. Receipt"; Code[10])
        {
            Caption = 'Item Doc. Receipt';
            TableRelation = "Source Code";
            DataClassification = CustomerContent;
#if not CLEANSCHEMA27
            MovedFrom = 'f3552374-a1f2-4356-848e-196002525837';
#endif
        }
        field(5851; "Invt. Shipment"; Code[10])
        {
            Caption = 'Item Doc. Shipment';
            TableRelation = "Source Code";
            DataClassification = CustomerContent;
#if not CLEANSCHEMA27
            MovedFrom = 'f3552374-a1f2-4356-848e-196002525837';
#endif
        }
        field(5875; "Phys. Invt. Orders"; Code[10])
        {
            Caption = 'Phys. Invt. Orders';
            TableRelation = "Source Code";
            DataClassification = CustomerContent;
#if not CLEANSCHEMA27
            MovedFrom = 'f3552374-a1f2-4356-848e-196002525837';
#endif
        }
        field(7139; "Compress Item Budget"; Code[10])
        {
            Caption = 'Compress Item Budget';
            TableRelation = "Source Code";
            DataClassification = CustomerContent;
#if not CLEANSCHEMA27
            MovedFrom = 'f3552374-a1f2-4356-848e-196002525837';
#endif
        }
        field(7300; "Whse. Item Journal"; Code[10])
        {
            Caption = 'Whse. Item Journal';
            TableRelation = "Source Code";
            DataClassification = CustomerContent;
#if not CLEANSCHEMA27
            MovedFrom = 'f3552374-a1f2-4356-848e-196002525837';
#endif
        }
        field(7302; "Whse. Phys. Invt. Journal"; Code[10])
        {
            Caption = 'Whse. Phys. Invt. Journal';
            TableRelation = "Source Code";
            DataClassification = CustomerContent;
#if not CLEANSCHEMA27
            MovedFrom = 'f3552374-a1f2-4356-848e-196002525837';
#endif
        }
        field(7303; "Whse. Reclassification Journal"; Code[10])
        {
            Caption = 'Whse. Reclassification Journal';
            TableRelation = "Source Code";
            DataClassification = CustomerContent;
#if not CLEANSCHEMA27
            MovedFrom = 'f3552374-a1f2-4356-848e-196002525837';
#endif
        }
        field(7304; "Whse. Put-away"; Code[10])
        {
            Caption = 'Whse. Put-away';
            TableRelation = "Source Code";
            DataClassification = CustomerContent;
#if not CLEANSCHEMA27
            MovedFrom = 'f3552374-a1f2-4356-848e-196002525837';
#endif
        }
        field(7305; "Whse. Pick"; Code[10])
        {
            Caption = 'Whse. Pick';
            TableRelation = "Source Code";
            DataClassification = CustomerContent;
#if not CLEANSCHEMA27
            MovedFrom = 'f3552374-a1f2-4356-848e-196002525837';
#endif
        }
        field(7306; "Whse. Movement"; Code[10])
        {
            Caption = 'Whse. Movement';
            TableRelation = "Source Code";
            DataClassification = CustomerContent;
#if not CLEANSCHEMA27
            MovedFrom = 'f3552374-a1f2-4356-848e-196002525837';
#endif
        }
        field(7307; "Compress Whse. Entries"; Code[10])
        {
            Caption = 'Compress Whse. Entries';
            TableRelation = "Source Code";
            DataClassification = CustomerContent;
#if not CLEANSCHEMA27
            MovedFrom = 'f3552374-a1f2-4356-848e-196002525837';
#endif
        }
    }
}