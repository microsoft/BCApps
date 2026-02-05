// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.QualityManagement;

using Microsoft.Manufacturing.Document;

pageextension 139956 "Qlty. Test Prod. Order Routing" extends "Prod. Order Routing"
{
    layout
    {
        modify("Routing Status")
        {
            Visible = true;
        }
    }
}
