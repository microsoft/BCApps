// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

enum 740 "VAT Report Configuration"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "EC Sales List") { Caption = 'EC Sales List'; }
    value(1; "VAT Return") { Caption = 'VAT Return'; }
    value(2; "Intrastat Report") { Caption = 'Intrastat Report'; }
}
