// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using System.Utilities;

codeunit 148002 "Mock IRIS XML" implements "IRS 1099 IRIS Xml"
{
    procedure CreateTransmissionXmlContent(var Transmission: Record "Transmission IRIS"; TransmissionType: Enum "Transmission Type IRIS"; CorrectionToZeroMode: Boolean; var UniqueTransmissionId: Text[100]; var TempDocHeader: Record "IRS 1099 Form Doc. Header" temporary; var TempBlob: Codeunit "Temp Blob")
    var
        IRS1099IRISImpl: Codeunit "IRS 1099 IRIS Impl.";
    begin
        IRS1099IRISImpl.CreateTransmissionXmlContent(Transmission, TransmissionType, CorrectionToZeroMode, UniqueTransmissionId, TempDocHeader, TempBlob);
    end;

    procedure CreateGetStatusRequestXmlContent(SearchParamType: Enum "Search Param Type IRIS"; SearchId: Text; var TempBlob: Codeunit "Temp Blob")
    begin
        WriteRequest(TempBlob, 'PartnerStatus:' + SearchId);
    end;

    procedure CreateAcknowledgmentRequestXmlContent(SearchParamType: Enum "Search Param Type IRIS"; SearchId: Text; var TempBlob: Codeunit "Temp Blob")
    begin
        WriteRequest(TempBlob, 'PartnerAcknowledgment:' + SearchId);
    end;

    local procedure WriteRequest(var TempBlob: Codeunit "Temp Blob"; Content: Text)
    var
        ContentStream: OutStream;
    begin
        TempBlob.CreateOutStream(ContentStream, TextEncoding::UTF8);
        ContentStream.WriteText(Content);
    end;
}
