// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Spike.Contoso;

using Microsoft.eServices.EDocument;

enumextension 6950 "Contoso Format Ext" extends "E-Document Format"
{
    value(6900; "Contoso Invoice")
    {
        Caption = 'Contoso Invoice (Spike)';
        Implementation = "E-Document" = "Contoso Invoice Format";
    }
}
