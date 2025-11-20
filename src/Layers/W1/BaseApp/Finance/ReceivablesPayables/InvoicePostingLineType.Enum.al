// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.ReceivablesPayables;

enum 49 "Invoice Posting Line Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Prepmt. Exch. Rate Difference") { Caption = 'Prepmt. Exch. Rate Difference'; }
    value(1; "G/L Account") { Caption = 'G/L Account'; }
    value(2; Item) { Caption = 'Item'; }
    value(3; "Resource") { Caption = 'Resource'; }
    value(4; "Fixed Asset") { Caption = 'Fixed Asset'; }
}
