// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting.Test;

using Microsoft.Manufacturing.Document;

pageextension 139980 "Subc. ProdOComp TestExt" extends "Prod. Order Components"
{
    layout
    {
        modify("Location Code")
        {
            Visible = true;
        }
    }
}