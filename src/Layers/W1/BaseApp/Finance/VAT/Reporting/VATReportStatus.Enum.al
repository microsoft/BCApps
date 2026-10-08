// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

enum 700 "VAT Report Status"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Open") { Caption = 'Open'; }
    value(1; "Released") { Caption = 'Released'; }
    value(2; "Submitted") { Caption = 'Submitted'; }
    value(3; "Accepted") { Caption = 'Accepted'; }
    value(4; "Closed") { Caption = 'Closed'; }
    value(5; "Rejected") { Caption = 'Rejected'; }
    value(6; "Canceled") { Caption = 'Canceled'; }
}
