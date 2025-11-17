// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Import.Purchase;

enum 6112 "E-Doc. PO M. Config. Receipt"
{
    Access = Internal;
    Extensible = false;

    value(0; "Always ask")
    {
        Caption = 'Always ask';
    }
    value(1; "Always receive at posting")
    {
        Caption = 'Always receive at posting';
    }
    value(2; "Never receive at posting")
    {
        Caption = 'Never receive at posting';
    }
}