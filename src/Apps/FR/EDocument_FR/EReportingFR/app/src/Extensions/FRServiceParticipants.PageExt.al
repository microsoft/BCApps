// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats;

using Microsoft.eServices.EDocument.Service.Participant;

pageextension 10980 "FR Service Participants" extends "Service Participants"
{
    layout
    {
        addafter("Participant Identifier")
        {
            field("FR Identifier Scheme"; Rec."FR Identifier Scheme")
            {
                ApplicationArea = All;
            }
        }
    }
}