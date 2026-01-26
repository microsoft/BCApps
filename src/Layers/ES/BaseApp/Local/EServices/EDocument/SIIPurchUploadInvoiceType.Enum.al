// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

enum 10713 "SII Purch. Upload Invoice Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; " ") { Caption = ' '; }
    value(1; "F1 Invoice") { Caption = 'F1 Invoice'; }
    value(2; "F2 Simplified Invoice") { Caption = 'F2 Simplified Invoice'; }
    value(3; "F3 Invoice issued to replace simplified invoices") { Caption = 'F3 Invoice issued to replace simplified invoices'; }
    value(4; "F4 Invoice summary entry") { Caption = 'F4 Invoice summary entry'; }
    value(5; "F5 Imports (DUA)") { Caption = 'F5 Imports (DUA)'; }
    value(6; "F6 Accounting support material") { Caption = 'F6 Accounting support material'; }
    value(7; "Customs - Complementary Liquidation") { Caption = 'Customs - Complementary Liquidation'; }
    value(8; "R1 Corrected Invoice") { Caption = 'R1 Corrected Invoice'; }
    value(9; "R2 Corrected Invoice (Art. 80.3)") { Caption = 'R2 Corrected Invoice (Art. 80.3)'; }
    value(10; "R3 Corrected Invoice (Art. 80.4)") { Caption = 'R3 Corrected Invoice (Art. 80.4)'; }
    value(11; "R4 Corrected Invoice (Other)") { Caption = 'R4 Corrected Invoice (Other)'; }
    value(12; "R5 Corrected Invoice in Simplified Invoices") { Caption = 'R5 Corrected Invoice in Simplified Invoices'; }
}
