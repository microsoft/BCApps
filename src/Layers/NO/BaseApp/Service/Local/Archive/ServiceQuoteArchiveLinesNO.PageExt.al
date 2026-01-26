// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Contract;
using Microsoft.Service.Archive;

pageextension 10604 "Service Quote Archive Lines NO" extends "Service Quote Archive Lines"
{
    layout
    {
        addlast(ServiceQuoteArchiveLines)
        {
            field("Account Code"; Rec."Account Code")
            {
                ApplicationArea = Service;
            }
        }
    }
}