// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.History;

#if not CLEANSCHEMA33
tableextension 13410 "Service Invoice Header FI" extends "Service Invoice Header"
{
    fields
    {
        field(32000000; "Reference No."; Code[20])
        {
            Caption = 'Reference No.';
            ObsoleteReason = 'Moved to Banking and Payments FI app.';
#if not CLEAN30
            ObsoleteState = Pending;
            ObsoleteTag = '30.0';
#else
            ObsoleteState = Removed;
            ObsoleteTag = '33.0';
#endif
            DataClassification = CustomerContent;
            Editable = true;
        }
    }
}
#endif