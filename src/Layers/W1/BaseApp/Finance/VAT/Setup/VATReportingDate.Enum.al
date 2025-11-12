// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Setup;

#pragma warning disable AS0090
enum 255 "VAT Reporting Date"
{
    value(0; "Posting Date") { Caption = 'Posting Date'; }
    value(1; "Document Date") { Caption = 'Document Date'; }
}
#pragma warning restore
