// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Contract;
using Microsoft.Service.Archive;

pageextension 10603 "Service Order Archives NO" extends "Service Order Archives"
{
    layout
    {
        modify("External Document No.")
        {
            Visible = false;
        }
        addafter(Name)
        {
            field("External Document No. NO"; Rec."External Document No. NO")
            {
                ApplicationArea = Service;
            }
        }
    }
}