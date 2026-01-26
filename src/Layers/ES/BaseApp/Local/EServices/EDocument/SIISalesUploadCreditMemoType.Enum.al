// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

enum 10714 "SII Sales Upload Credit Memo Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; " ") { Caption = ' '; }
    value(1; "R1 Corrected Invoice") { Caption = 'R1 Corrected Invoice'; }
    value(2; "R2 Corrected Invoice (Art. 80.3)") { Caption = 'R2 Corrected Invoice (Art. 80.3)'; }
    value(3; "R3 Corrected Invoice (Art. 80.4)") { Caption = 'R3 Corrected Invoice (Art. 80.4)'; }
    value(4; "R4 Corrected Invoice (Other)") { Caption = 'R4 Corrected Invoice (Other)'; }
    value(5; "R5 Corrected Invoice in Simplified Invoices") { Caption = 'R5 Corrected Invoice in Simplified Invoices'; }
    value(6; "F1 Invoice") { Caption = 'F1 Invoice'; }
    value(7; "F2 Simplified Invoice") { Caption = 'F2 Simplified Invoice'; }
    value(8; "F3 Invoice issued to replace simplified invoices") { Caption = 'F3 Invoice issued to replace simplified invoices'; }
    value(9; "F4 Invoice summary entry") { Caption = 'F4 Invoice summary entry'; }
}
