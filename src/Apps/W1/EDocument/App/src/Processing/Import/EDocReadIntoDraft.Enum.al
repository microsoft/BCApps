// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Import;

using Microsoft.eServices.EDocument.Format;
using Microsoft.eServices.EDocument.Processing.Interfaces;

/// <summary>
/// Specifies how a structured data type should be interpreted and read into a draft.
/// </summary>
enum 6109 "E-Doc. Read into Draft" implements IStructuredFormatReader, IOrderResponseBuilder
{
    Extensible = true;
    DefaultImplementation = IStructuredFormatReader = "E-Doc. Unspecified Impl.",
                            IOrderResponseBuilder = "E-Doc. Unspecified Impl.";

    value(0; "Unspecified")
    {
        Caption = 'Unspecified';
        Implementation = IStructuredFormatReader = "E-Doc. Unspecified Impl.";
    }
    value(1; "Blank Draft")
    {
        Caption = 'Blank Draft';
        Implementation = IStructuredFormatReader = "E-Doc. Empty Draft";
    }
    value(2; "ADI")
    {
        Caption = 'ADI';
        Implementation = IStructuredFormatReader = "E-Document ADI Handler";
    }
    value(3; "PEPPOL")
    {
        Caption = 'PEPPOL';
        Implementation = IStructuredFormatReader = "E-Document PEPPOL Handler",
                         IOrderResponseBuilder = "E-Document PEPPOL Handler";
    }
    value(4; "MLLM")
    {
        Caption = 'MLLM';
        Implementation = IStructuredFormatReader = "E-Document MLLM Handler";
    }
    value(5; "Data Exchange Purchase")
    {
        Caption = 'Data Exchange Purchase';
        Implementation = IStructuredFormatReader = "E-Doc. DataExch. Purch Handler";
    }
}
