#if not CLEAN26
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Upgrade;

codeunit 104052 "Upgrade Rcvd. Country Code"
{
    Subtype = Upgrade;
    ObsoleteReason = 'This function is obsolete.';
    ObsoleteState = Pending;
    ObsoleteTag = '26.0';

    [Obsolete('This function is obsolete.', '26.0')]
    procedure UpdateData();
    begin
    end;
}
#endif