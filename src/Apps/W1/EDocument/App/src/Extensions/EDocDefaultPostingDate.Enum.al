// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

enum 6162 "E-Doc. Default Posting Date"
{
    Extensible = false;
    Caption = 'E-Document Default Posting Date';

    value(0; "Work Date")
    {
        Caption = 'Work Date';
    }
    value(1; "Document Date")
    {
        Caption = 'Document Date';
    }
}
