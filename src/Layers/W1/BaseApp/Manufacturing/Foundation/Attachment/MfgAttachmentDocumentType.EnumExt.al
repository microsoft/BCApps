// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Attachment;

enumextension 99000801 "Mfg. Attachment Document Type" extends "Attachment Document Type"
{
    value(61; "Simulated Production Order") { Caption = 'Simulated Production Order'; }
    value(62; "Planned Production Order") { Caption = 'Planned Production Order'; }
    value(63; "Firm Planned Production Order") { Caption = 'Firm Planned Production Order'; }
    value(64; "Released Production Order") { Caption = 'Released Production Order'; }
    value(65; "Finished Production Order") { Caption = 'Finished Production Order'; }
}
