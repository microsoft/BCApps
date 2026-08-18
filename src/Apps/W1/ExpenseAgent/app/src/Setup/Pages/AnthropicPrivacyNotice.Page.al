#if not CLEAN29
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Privacy;

page 7078 "Anthropic Privacy Notice"
{
    Caption = 'Please review terms and conditions';
    PageType = NavigatePage;
    SourceTable = "Privacy Notice";
    SourceTableTemporary = true;
    Extensible = false;
    InherentEntitlements = X;
    InherentPermissions = X;
    ObsoleteReason = 'The Expense Agent no longer uses this privacy notice.';
    ObsoleteState = Pending;
    ObsoleteTag = '29.0';

    layout
    {
        area(Content)
        {
            label(ObsoleteNotice)
            {
                ApplicationArea = All;
                Caption = 'This privacy notice is no longer used.';
            }
        }
    }
}
#endif
