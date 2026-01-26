// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Contract;
using Microsoft.Service.Archive;

pageextension 10600 "Service Quote Archive NO" extends "Service Quote Archive"
{
    layout
    {
        modify("External Document No.")
        {
            Visible = false;
        }
        addlast(General)
        {
            field("External Document No. NO"; Rec."External Document No. NO")
            {
                ApplicationArea = Service;
            }
        }
    }
}