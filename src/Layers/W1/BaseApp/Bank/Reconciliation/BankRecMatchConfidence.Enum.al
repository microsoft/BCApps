// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reconciliation;

enum 1252 "Bank Rec. Match Confidence"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "None") { Caption = 'None'; }
    value(1; "Low") { Caption = 'Low'; }
    value(2; "Medium") { Caption = 'Medium'; }
    value(3; "High") { Caption = 'High'; }
    value(4; "High - Text-to-Account Mapping") { Caption = 'High - Text-to-Account Mapping'; }
    value(5; "Manual") { Caption = 'Manual'; }
    value(6; "Accepted") { Caption = 'Accepted'; }
}
