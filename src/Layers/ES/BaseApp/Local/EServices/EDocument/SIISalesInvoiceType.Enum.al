// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

enum 10706 "SII Sales Invoice Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "F1 Invoice") { Caption = 'F1 Invoice'; }
    value(1; "F2 Simplified Invoice") { Caption = 'F2 Simplified Invoice'; }
    value(2; "F3 Invoice issued to replace simplified invoices") { Caption = 'F3 Invoice issued to replace simplified invoices'; }
    value(3; "F4 Invoice summary entry") { Caption = 'F4 Invoice summary entry'; }
    value(4; "R1 Corrected Invoice") { Caption = 'R1 Corrected Invoice'; }
    value(5; "R2 Corrected Invoice (Art. 80.3)") { Caption = 'R2 Corrected Invoice (Art. 80.3)'; }
    value(6; "R3 Corrected Invoice (Art. 80.4)") { Caption = 'R3 Corrected Invoice (Art. 80.4)'; }
    value(7; "R4 Corrected Invoice (Other)") { Caption = 'R4 Corrected Invoice (Other)'; }
    value(8; "R5 Corrected Invoice in Simplified Invoices") { Caption = 'R5 Corrected Invoice in Simplified Invoices'; }
}
