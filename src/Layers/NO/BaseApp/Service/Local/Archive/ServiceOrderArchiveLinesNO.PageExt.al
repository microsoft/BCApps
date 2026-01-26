// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Contract;
using Microsoft.Service.Archive;

pageextension 10605 "Service Order Archive Lines NO" extends "Service Order Archive Lines"
{
    layout
    {
        addlast(ServiceOrderArchiveLines)
        {
            field("Account Code"; Rec."Account Code")
            {
                ApplicationArea = Service;
            }
        }
    }
}