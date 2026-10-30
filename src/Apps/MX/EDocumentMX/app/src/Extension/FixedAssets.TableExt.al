// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.EServices.EDocument.Interfactura;

using Microsoft.FixedAssets.FixedAsset;

tableextension 3353 FixedAssetsTableExt extends "Fixed Asset"
{
    fields
    {
        field(3353; "Property tax account No"; Text[150])
        {
            Caption = 'Property tax account No';
            DataClassification = CustomerContent;
        }
    }
}