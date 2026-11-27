// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using System.Utilities;

interface "IRIS XML Schema"
{
    procedure GetVersionText(): Text;

    procedure ValidateTransmission(Transmission: Record "Transmission IRIS");

    procedure CreateTransmissionXmlContent(var Transmission: Record "Transmission IRIS"; TransmissionType: Enum "Transmission Type IRIS"; CorrectionToZeroMode: Boolean; var UniqueTransmissionId: Text[100]; var TempDocHeader: Record "IRS 1099 Form Doc. Header" temporary; var TempBlob: Codeunit "Temp Blob");
}
