// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.ReceivablesPayables;

enum 10724 "Cartera Document Status"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Open") { Caption = 'Open'; }
    value(1; "Honored") { Caption = 'Honored'; }
    value(2; "Rejected") { Caption = 'Rejected'; }
}
