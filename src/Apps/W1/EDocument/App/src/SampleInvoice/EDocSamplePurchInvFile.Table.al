// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument.Processing.Import.Purchase;

table 6120 "E-Doc Sample Purch. Inv File"
{
    Caption = 'E-Doc Sample Purchase Invoice File';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "File Name"; Text[100])
        {
            Caption = 'File Name';
        }
        field(2; "File Content"; Blob)
        {
            Caption = 'File Content';
        }
    }
}