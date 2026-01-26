// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Contract;
using Microsoft.Service.Archive;

pageextension 10606 "Service List Archive NO" extends "Service List Archive"
{
    layout
    {
        modify("External Document No.")
        {
            Visible = false;
        }
        addlast(ServiceArchives)
        {
            field("External Document No. NO"; Rec."External Document No. NO")
            {
                ApplicationArea = Service;
            }
        }
    }
}