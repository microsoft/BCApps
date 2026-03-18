// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Profiling;

#pragma warning disable AL0659
enum 5085 "Profile Quest. Cust. Class. Field"
#pragma warning restore AL0659
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; " ") { Caption = ' '; }
    value(1; "Sales (LCY)") { Caption = 'Sales (LCY)'; }
    value(2; "Profit (LCY)") { Caption = 'Profit (LCY)'; }
    value(3; "Sales Frequency (Invoices/Year)") { Caption = 'Sales Frequency (Invoices/Year)'; }
    value(4; "Avg. Invoice Amount (LCY)") { Caption = 'Avg. Invoice Amount (LCY)'; }
    value(5; "Discount (%)") { Caption = 'Discount (%)'; }
    value(6; "Avg. Overdue (Day)") { Caption = 'Avg. Overdue (Day)'; }
}
