// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocumentConnector;

using Microsoft.EServices.EDocument;

tableextension 6372 "Avalara E-Doc." extends "E-Document"
{
    fields
    {
        field(6373; "Avalara Document Id"; Text[50])
        {
            Caption = 'Avalara Document Id';
            DataClassification = CustomerContent;
        }
        field(6374; "Avalara Response Value"; Text[100])
        {
            Caption = 'Avalara Response Value';
            DataClassification = CustomerContent;
        }
    }
}