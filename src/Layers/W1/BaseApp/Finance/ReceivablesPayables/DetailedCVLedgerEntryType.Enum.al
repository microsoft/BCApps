// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.ReceivablesPayables;

enum 379 "Detailed CV Ledger Entry Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "") { Caption = ''; }
    value(1; "Initial Entry") { Caption = 'Initial Entry'; }
    value(2; "Application") { Caption = 'Application'; }
    value(3; "Unrealized Loss") { Caption = 'Unrealized Loss'; }
    value(4; "Unrealized Gain") { Caption = 'Unrealized Gain'; }
    value(5; "Realized Loss") { Caption = 'Realized Loss'; }
    value(6; "Realized Gain") { Caption = 'Realized Gain'; }
    value(7; "Payment Discount") { Caption = 'Payment Discount'; }
    value(8; "Payment Discount (VAT Excl.)") { Caption = 'Payment Discount (VAT Excl.)'; }
    value(9; "Payment Discount (VAT Adjustment)") { Caption = 'Payment Discount (VAT Adjustment)'; }
    value(10; "Appln. Rounding") { Caption = 'Appln. Rounding'; }
    value(11; "Correction of Remaining Amount") { Caption = 'Correction of Remaining Amount'; }
    value(12; "Payment Tolerance") { Caption = 'Payment Tolerance'; }
    value(13; "Payment Discount Tolerance") { Caption = 'Payment Discount Tolerance'; }
    value(14; "Payment Tolerance (VAT Excl.)") { Caption = 'Payment Tolerance (VAT Excl.)'; }
    value(15; "Payment Tolerance (VAT Adjustment)") { Caption = 'Payment Tolerance (VAT Adjustment)'; }
    value(16; "Payment Discount Tolerance (VAT Excl.)") { Caption = 'Payment Discount Tolerance (VAT Excl.)'; }
    value(17; "Payment Discount Tolerance (VAT Adjustment)") { Caption = 'Payment Discount Tolerance (VAT Adjustment)'; }
}
