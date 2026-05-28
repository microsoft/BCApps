// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

/// <summary>
/// Default implementation for the "Unknown" member of the "E-Document Message Type" enum.
/// Never applicable; never has Reader / Writer; never advances state. Exists so the enum
/// binding is complete out of the box and the default value is safe.
/// </summary>
codeunit 6343 "EDoc Unknown Msg Type" implements IEDocumentMessageType
{
    Access = Internal;

    procedure IsApplicableFor(ParentEDocument: Record "E-Document"; Direction: Enum "E-Document Direction"; TriggerSource: Enum "E-Doc. Msg. Trigger Source"): Boolean
    begin
        exit(false);
    end;

    procedure GetSupportedDirections(): List of [Enum "E-Document Direction"]
    var
        Empty: List of [Enum "E-Document Direction"];
    begin
        exit(Empty);
    end;

    procedure GetReader(): Interface IEDocumentMessageReader
    begin
        Error('Unknown message type — no Reader.');
    end;

    procedure GetWriter(): Interface IEDocumentMessageWriter
    begin
        Error('Unknown message type — no Writer.');
    end;

    procedure ApplyMessage(var Msg: Record "E-Document Message"; var Context: Codeunit "E-Doc. Msg. Apply Context"): Boolean
    begin
        exit(false);
    end;

    procedure ViewMessage(Msg: Record "E-Document Message")
    begin
        Error('Unknown message type — no view.');
    end;
}
