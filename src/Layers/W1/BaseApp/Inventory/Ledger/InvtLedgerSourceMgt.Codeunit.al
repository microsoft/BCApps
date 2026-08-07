// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Ledger;

using Microsoft.Foundation.Enums;

codeunit 5861 "Invt. Ledger Source Mgt."
{
    procedure GetSourceDescription(SourceType: Enum "Analysis Source Type"; SourceNo: Code[20]) SourceDescription: Text
    var
        IsHandled: Boolean;
    begin
        OnBeforeGetSourceDescription(SourceType, SourceNo, SourceDescription, IsHandled);
        if IsHandled then
            exit;
        OnGetSourceDescription(SourceType, SourceNo, SourceDescription);
    end;

#if not CLEAN29
    [Obsolete('Replaced by GetSourceOrderNo(DocType, DocNo, DocLineNo)', '29.0')]
    procedure GetSourceOrderNo(DocType: Enum "Item Ledger Document Type"; DocNo: Code[20]) SourceOrderNo: Code[20]
    begin
        exit(GetSourceOrderNo(DocType, DocNo, 0));
    end;
#endif

    procedure GetSourceOrderNo(DocType: Enum "Item Ledger Document Type"; DocNo: Code[20]; DocLineNo: Integer) SourceOrderNo: Code[20]
    var
        IsHandled: Boolean;
    begin
        OnBeforeGetSourceOrderNo(DocType, DocNo, DocLineNo, SourceOrderNo, IsHandled);
        if IsHandled then
            exit;
        OnGetSourceOrderNo(DocType, DocNo, DocLineNo, SourceOrderNo);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetSourceDescription(SourceType: Enum "Analysis Source Type"; SourceNo: Code[20]; var SourceDescription: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetSourceDescription(SourceType: Enum "Analysis Source Type"; SourceNo: Code[20]; var SourceDescription: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetSourceOrderNo(DocType: Enum "Item Ledger Document Type"; DocNo: Code[20]; DocLineNo: Integer; var SourceOrderNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetSourceOrderNo(DocType: Enum "Item Ledger Document Type"; DocNo: Code[20]; DocLineNo: Integer; var SourceOrderNo: Code[20])
    begin
    end;
}