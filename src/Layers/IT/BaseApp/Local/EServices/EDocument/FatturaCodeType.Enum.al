// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

enum 12198 "Fattura Code Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Payment Method") { Caption = 'Payment Method'; }
    value(1; "Payment Terms") { Caption = 'Payment Terms'; }
}
