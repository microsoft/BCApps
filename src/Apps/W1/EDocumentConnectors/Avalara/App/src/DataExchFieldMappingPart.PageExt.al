// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocumentConnector.Avalara;

using System.IO;

/// <summary>
/// Extends the Data Exchange Field Mapping Part page to expose the Default Value field.
/// </summary>
pageextension 6372 "Data Exch Field Mapping Part" extends "Data Exch Field Mapping Part"
{
    layout
    {
        addafter(Priority)
        {
            field("Default Value"; Rec."Default Value")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the default value for the field mapping.';
            }
        }
    }
}
