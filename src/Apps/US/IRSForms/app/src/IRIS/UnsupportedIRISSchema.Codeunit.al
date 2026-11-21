// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using System.Utilities;

codeunit 10062 "Unsupported IRIS Schema" implements "IRIS XML Schema"
{
    Access = Internal;

    procedure GetVersionText(): Text
    begin
        UnsupportedSchema();
    end;

    procedure ValidateTransmission(Transmission: Record "Transmission IRIS")
    begin
        UnsupportedSchema();
    end;

    // The interface requires var, but this implementation always raises an error.
#pragma warning disable AA0150
    procedure CreateTransmissionXmlContent(var Transmission: Record "Transmission IRIS"; TransmissionType: Enum "Transmission Type IRIS"; CorrectionToZeroMode: Boolean; var UniqueTransmissionId: Text[100]; var TempDocHeader: Record "IRS 1099 Form Doc. Header" temporary; var TempBlob: Codeunit "Temp Blob")
    begin
        UnsupportedSchema();
    end;
#pragma warning restore AA0150

    local procedure UnsupportedSchema()
    var
        Helper: Codeunit "Helper IRIS";
    begin
        Helper.UnsupportedSchema();
    end;
}
