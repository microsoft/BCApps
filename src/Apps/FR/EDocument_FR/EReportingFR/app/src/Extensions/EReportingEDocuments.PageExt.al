// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats;

using Microsoft.eServices.EDocument;

pageextension 10974 "E-Reporting E-Documents" extends "E-Documents"
{
    layout
    {
        addlast(DocumentList)
        {
            field("Clearance Date"; Rec."Clearance Date")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'E-Reporting Acceptance Date';
            }
        }
    }
}
