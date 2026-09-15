// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

using Microsoft.eServices.EDocument.Processing.Import.Purchase;

tableextension 11042 "E-Doc. Purchase Header DE" extends "E-Document Purchase Header"
{
    fields
    {
        /// <summary>
        /// BT-10 Buyer reference. For German public sector buyers this carries the Leitweg-ID that
        /// identifies the receiving authority.
        /// </summary>
        field(11042; "Buyer Reference DE"; Text[100])
        {
            Caption = 'Buyer Reference';
            DataClassification = CustomerContent;
        }
    }
}
