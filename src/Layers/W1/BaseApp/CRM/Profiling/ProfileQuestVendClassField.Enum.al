// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Profiling;

#pragma warning disable AL0659
enum 5086 "Profile Quest. Vend. Class. Field"
#pragma warning restore AL0659
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; " ") { Caption = ' '; }
    value(1; "Purchase (LCY)") { Caption = 'Purchase (LCY)'; }
    value(2; "Purchase Frequency (Invoices/Year)") { Caption = 'Purchase Frequency (Invoices/Year)'; }
    value(3; "Avg. Ticket Size (LCY)") { Caption = 'Avg. Ticket Size (LCY)'; }
    value(4; "Discount (%)") { Caption = 'Discount (%)'; }
    value(5; "Avg. Overdue (Day)") { Caption = 'Avg. Overdue (Day)'; }
}
