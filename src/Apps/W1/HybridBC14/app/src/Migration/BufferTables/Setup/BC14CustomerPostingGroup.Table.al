// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation;

table 46904 "BC14 Customer Posting Group"
{
    Caption = 'Customer Posting Group Migration Data';
    DataClassification = CustomerContent;
    InherentEntitlements = X;
    InherentPermissions = RIMDX;
    ReplicateData = false;
    Extensible = false;

    fields
    {
        field(1; "Code"; Code[20]) { Caption = 'Code'; }
        field(2; "Receivables Account"; Code[20]) { Caption = 'Receivables Account'; }
        field(3; "Service Charge Acc."; Code[20]) { Caption = 'Service Charge Acc.'; }
        field(4; "Payment Disc. Debit Acc."; Code[20]) { Caption = 'Payment Disc. Debit Acc.'; }
        field(5; "Invoice Rounding Account"; Code[20]) { Caption = 'Invoice Rounding Account'; }
        field(6; "Additional Fee Account"; Code[20]) { Caption = 'Additional Fee Account'; }
        field(7; "Interest Account"; Code[20]) { Caption = 'Interest Account'; }
        field(9; "Debit Curr. Appln. Rndg. Acc."; Code[20]) { Caption = 'Debit Curr. Appln. Rndg. Acc.'; }
        field(10; "Credit Curr. Appln. Rndg. Acc."; Code[20]) { Caption = 'Credit Curr. Appln. Rndg. Acc.'; }
        field(11; "Debit Rounding Account"; Code[20]) { Caption = 'Debit Rounding Account'; }
        field(12; "Credit Rounding Account"; Code[20]) { Caption = 'Credit Rounding Account'; }
        field(13; "Payment Disc. Credit Acc."; Code[20]) { Caption = 'Payment Disc. Credit Acc.'; }
        field(14; "Payment Tolerance Debit Acc."; Code[20]) { Caption = 'Payment Tolerance Debit Acc.'; }
        field(15; "Payment Tolerance Credit Acc."; Code[20]) { Caption = 'Payment Tolerance Credit Acc.'; }
        field(16; "Add. Fee per Line Account"; Code[20]) { Caption = 'Add. Fee per Line Account'; }
        field(20; "Description"; Text[100]) { Caption = 'Description'; }
    }

    keys
    {
        key(Key1; "Code") { Clustered = true; }
    }
}
