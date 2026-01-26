// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

enum 10709 "SII Purch. Credit Memo Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "R1 Corrected Invoice") { Caption = 'R1 Corrected Invoice'; }
    value(1; "R2 Corrected Invoice (Art. 80.3)") { Caption = 'R2 Corrected Invoice (Art. 80.3)'; }
    value(2; "R3 Corrected Invoice (Art. 80.4)") { Caption = 'R3 Corrected Invoice (Art. 80.4)'; }
    value(3; "R4 Corrected Invoice (Other)") { Caption = 'R4 Corrected Invoice (Other)'; }
    value(4; "R5 Corrected Invoice in Simplified Invoices") { Caption = 'R5 Corrected Invoice in Simplified Invoices'; }
    value(5; "F1 Invoice") { Caption = 'F1 Invoice'; }
    value(6; "F2 Simplified Invoice") { Caption = 'F2 Simplified Invoice'; }
}
