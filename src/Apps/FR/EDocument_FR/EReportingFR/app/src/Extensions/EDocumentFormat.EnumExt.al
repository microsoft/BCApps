// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats;

using Microsoft.eServices.EDocument;

enumextension 10970 "E-Document Format" extends "E-Document Format"
{
    value(10970; "E-Reporting FR")
    {
        Caption = 'E-Reporting FR';
        Implementation = "E-Document" = "E-Reporting Format";
    }
    value(10977; "Peppol BIS 3.0 FR")
    {
        Caption = 'Peppol BIS 3.0 FR';
        Implementation = "E-Document" = "Peppol BIS 3.0 FR Format";
    }
    value(10978; "Factur-X FR")
    {
        Caption = 'Factur-X FR';
        Implementation = "E-Document" = "Factur-X Format";
    }
}
