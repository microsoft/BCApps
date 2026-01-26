// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

enum 10704 "SII Operation Date Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Posting Date") { Caption = 'Posting Date'; }
    value(1; "Document Date") { Caption = 'Document Date'; }
    value(2; "VAT Reporting Date") { Caption = 'VAT Date'; }
}
