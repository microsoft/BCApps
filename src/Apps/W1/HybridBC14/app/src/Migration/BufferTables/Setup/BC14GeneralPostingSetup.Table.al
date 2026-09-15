// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation;

table 46910 "BC14 General Posting Setup"
{
    Caption = 'General Posting Setup Migration Data';
    DataClassification = CustomerContent;
    InherentEntitlements = X;
    InherentPermissions = RIMDX;
    ReplicateData = false;
    Extensible = false;

    fields
    {
        field(1; "Gen. Bus. Posting Group"; Code[20]) { Caption = 'Gen. Bus. Posting Group'; }
        field(2; "Gen. Prod. Posting Group"; Code[20]) { Caption = 'Gen. Prod. Posting Group'; }
        field(3; "Sales Account"; Code[20]) { Caption = 'Sales Account'; }
        field(4; "Sales Line Disc. Account"; Code[20]) { Caption = 'Sales Line Disc. Account'; }
        field(5; "Sales Inv. Disc. Account"; Code[20]) { Caption = 'Sales Inv. Disc. Account'; }
        field(6; "Sales Pmt. Disc. Debit Acc."; Code[20]) { Caption = 'Sales Pmt. Disc. Debit Acc.'; }
        field(7; "Sales Credit Memo Account"; Code[20]) { Caption = 'Sales Credit Memo Account'; }
        field(8; "Purch. Account"; Code[20]) { Caption = 'Purch. Account'; }
        field(9; "Purch. Line Disc. Account"; Code[20]) { Caption = 'Purch. Line Disc. Account'; }
        field(10; "Purch. Inv. Disc. Account"; Code[20]) { Caption = 'Purch. Inv. Disc. Account'; }
        field(11; "Purch. Pmt. Disc. Credit Acc."; Code[20]) { Caption = 'Purch. Pmt. Disc. Credit Acc.'; }
        field(12; "Purch. Credit Memo Account"; Code[20]) { Caption = 'Purch. Credit Memo Account'; }
        field(13; "COGS Account"; Code[20]) { Caption = 'COGS Account'; }
        field(14; "Inventory Adjmt. Account"; Code[20]) { Caption = 'Inventory Adjmt. Account'; }
        field(15; "Invt. Accrual Acc. (Interim)"; Code[20]) { Caption = 'Invt. Accrual Acc. (Interim)'; }
        field(16; "Sales Pmt. Disc. Credit Acc."; Code[20]) { Caption = 'Sales Pmt. Disc. Credit Acc.'; }
        field(17; "Purch. Pmt. Disc. Debit Acc."; Code[20]) { Caption = 'Purch. Pmt. Disc. Debit Acc.'; }
        field(18; "Sales Pmt. Tol. Debit Acc."; Code[20]) { Caption = 'Sales Pmt. Tol. Debit Acc.'; }
        field(19; "Sales Pmt. Tol. Credit Acc."; Code[20]) { Caption = 'Sales Pmt. Tol. Credit Acc.'; }
        field(20; "Purch. Pmt. Tol. Debit Acc."; Code[20]) { Caption = 'Purch. Pmt. Tol. Debit Acc.'; }
        field(21; "Purch. Pmt. Tol. Credit Acc."; Code[20]) { Caption = 'Purch. Pmt. Tol. Credit Acc.'; }
        field(22; "Sales Prepayments Account"; Code[20]) { Caption = 'Sales Prepayments Account'; }
        field(23; "Purch. Prepayments Account"; Code[20]) { Caption = 'Purch. Prepayments Account'; }
        field(24; "COGS Account (Interim)"; Code[20]) { Caption = 'COGS Account (Interim)'; }
        field(25; "Direct Cost Applied Account"; Code[20]) { Caption = 'Direct Cost Applied Account'; }
        field(26; "Overhead Applied Account"; Code[20]) { Caption = 'Overhead Applied Account'; }
        field(27; "Purchase Variance Account"; Code[20]) { Caption = 'Purchase Variance Account'; }
        field(30; "Mfg. Overhead Applied Account"; Code[20]) { Caption = 'Mfg. Overhead Applied Account'; }
        field(31; "Material Variance Account"; Code[20]) { Caption = 'Material Variance Account'; }
        field(32; "Capacity Variance Account"; Code[20]) { Caption = 'Capacity Variance Account'; }
        field(33; "Mfg. Overhead Variance Account"; Code[20]) { Caption = 'Mfg. Overhead Variance Account'; }
        field(34; "Cap. Overhead Variance Account"; Code[20]) { Caption = 'Cap. Overhead Variance Account'; }
        field(35; "Subcontracted Variance Account"; Code[20]) { Caption = 'Subcontracted Variance Account'; }
        field(36; "Cap. Overhead Applied Account"; Code[20]) { Caption = 'Cap. Overhead Applied Account'; }
    }

    keys
    {
        key(Key1; "Gen. Bus. Posting Group", "Gen. Prod. Posting Group") { Clustered = true; }
    }
}
