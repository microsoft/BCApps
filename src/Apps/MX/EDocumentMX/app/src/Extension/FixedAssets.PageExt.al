// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.EServices.EDocument.Interfactura;

using Microsoft.FixedAssets.FixedAsset;

pageextension 3352 FixedAssetsPageExt extends "Fixed Asset Card"
{
    layout
    {
        addlast("Electronic Document")
        {
            field("Property tax account No"; Rec."Property tax account No")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the property tax account number for the fixed asset.';
            }
        }
    }
}