// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocumentConnector.Avalara;

using System.IO;

/// <summary>
/// Extends the Transformation Rule Type enum with an Avalara Lookup option for table-based value transformation.
/// </summary>
enumextension 6372 "Avalara Trans. Rule Type" extends "Transformation Rule Type"
{
    value(6372; "Avalara Lookup")
    {
        Caption = 'Avalara Lookup';
    }
}
