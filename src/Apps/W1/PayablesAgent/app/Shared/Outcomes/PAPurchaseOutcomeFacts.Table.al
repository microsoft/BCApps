// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

using Microsoft.Purchases.Document;

table 3352 "PA Purchase Outcome Facts"
{
    Access = Internal;
    InherentEntitlements = RIMDX;
    InherentPermissions = RIMDX;
    Extensible = false;
    TableType = Temporary;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Document Type"; Enum "Purchase Document Type") { }
        field(2; Posted; Boolean) { }
        field(3; "Document No."; Code[20]) { }
        field(4; "Vendor Document No."; Text[50]) { }
        field(5; "Vendor No."; Code[20]) { }
        field(6; "Vendor Name"; Text[100]) { }
    }
}
